--[[

Copyright © 2025, Quenala of Asura
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Limbox nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL QUENALA BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

]]

_addon.name = 'Limbox'
_addon.author = 'Quenala'
_addon.version = '1.3'
_addon.commands = {'limbox'}

require('logger')
require('sets')
texts = require('texts')
res = require('resources')
config = require('config')

-- Default settings
local default_settings = {
	pos = {x = 100, y = 200},
	text = {size = 10},
	compact = false,
}
local settings = config.load(default_settings)

-- Temenos towers and floors
local temenos_towers = {

	North = {prefix = 'N', floors = 7},
	East  = {prefix = 'E', floors = 7},
	West  = {prefix = 'W', floors = 7},
	Central = {prefix = 'C', floors = 4},
}
local temenos_order = {'North', 'West', 'East', 'Central'}

-- Apollyon areas and floors
local apollyon_towers = {
	NW = {floors = 5},
	SW = {floors = 4},
	NE = {floors = 5},
	SE = {floors = 4},
}
local apollyon_order = {'NW', 'SW', 'NE', 'SE'}

-- Build lookup tables
local temenos_map = {}
for tower, data in pairs(temenos_towers) do
	for i = 1, data.floors do
		local full_name = string.format('Temenos %s tower F%d data', tower:lower(), i)
		local short_name = string.format('Tem. %s-F%d', data.prefix, i)
		temenos_map[full_name] = short_name
	end
end

local apollyon_map = {}
for tower, data in pairs(apollyon_towers) do
	for i = 1, data.floors do
		local full_name = string.format('Apollyon %s #%d', tower, i)
		apollyon_map[full_name] = full_name
	end
end

local mode = nil
local point_total = 0
last_inventory_scan = 0

local box = texts.new({
	pos = {x = settings.pos.x, y = settings.pos.y},
	text = {size = settings.text.size},
	bg = {alpha = 150},
	flags = {},
})
box:draggable(true)
box:show()

local function scan_temenos()
	local temp_bag = windower.ffxi.get_items().temporary
	local found = {}
	for index = 1, #temp_bag do
		local entry = temp_bag[index]
		if entry and entry.id and entry.id ~= 0 then
			local item = res.items[entry.id]
			if item then
				for full_name, short_name in pairs(temenos_map) do
					if item.name == short_name then
						found[full_name] = true
					end
				end
			end
		end
	end
	return found
end

local function scan_apollyon()
	local temp_bag = windower.ffxi.get_items().temporary
	local found = {}
	for index = 1, #temp_bag do
		local entry = temp_bag[index]
		if entry and entry.id and entry.id ~= 0 then
			local item = res.items[entry.id]
			if item then
				for full_name in pairs(apollyon_map) do
					if item.name == full_name then
						found[full_name] = true
					end
				end
			end
		end
	end
	return found
end

local function get_current_temenos_tower()
	local me = windower.ffxi.get_mob_by_target('me')
	if not me then return nil end
	local x, y = me.x, me.y
	
	if x > 520 and y > -100 then return 'Lobby'
	elseif y >= 350 and y <= 600 then return 'North'
	elseif y >= 0 and y <= 350 then return 'West'
	elseif y >= -200 and y <= 0 then return 'East'
	elseif y < -300 then return 'Central' end
	
	return nil
end

local function get_current_apollyon_area()
	local me = windower.ffxi.get_mob_by_target('me')
	if not me then return nil end
	local x, y = me.x, me.y
	
	if x >= -682 and x <= -558 and y >= -682 and y <= -558 then return 'Lobby'
	elseif x >= 558 and x <= 682 and y >= -682 and y <= -558 then return 'Lobby'
	elseif x >= -651 and x <= -186 and y >= -95 and y <= 682 then return 'NW'
	elseif x >= -651 and x <= -62 and y >= -651 and y <= -217 then return 'SW'
	elseif x >= 186 and x <= 650 and y >= -124 and y <= 682 then return 'NE'
	elseif x >= 93 and x <= 651 and y >= -651 and y <= -217 then return 'SE' end
	
	return nil
end

local function update_display()
	local lines = {}
	
	if mode == 'Temenos' then
		local found = scan_temenos()
		local current_tower = get_current_temenos_tower()
		
		table.insert(lines, 'Temenos')
		table.insert(lines, 'Points: '..point_total)
		
		if settings.compact then
			if current_tower and current_tower ~= 'Lobby' then
				local data = temenos_towers[current_tower]
				local line = ''
				for i = 1, data.floors do
					local full_name = string.format('Temenos %s tower F%d data', current_tower:lower(), i)
					if found[full_name] then
						line = line .. string.format('\\cs(0,255,0)%d\\cr', i)
					else
						line = line .. string.format('\\cs(255,0,0)%d\\cr', i)
					end
				end
				table.insert(lines, string.format('%s: %s', current_tower, line))
			else
				for _, tower in ipairs(temenos_order) do
					local data = temenos_towers[tower]
					local line = ''
					for i = 1, data.floors do
						local full_name = string.format('Temenos %s tower F%d data', tower:lower(), i)
						if found[full_name] then
							line = line .. string.format('\\cs(0,255,0)%d\\cr', i)
						else
							line = line .. string.format('\\cs(255,0,0)%d\\cr', i)
						end
					end
					table.insert(lines, string.format('%s: %s', tower, line))
				end
			end
		else
			if current_tower and current_tower ~= 'Lobby' then
				table.insert(lines, '')
				for i = 1, temenos_towers[current_tower].floors do
					local full_name = string.format('Temenos %s tower F%d data', current_tower:lower(), i)
					if found[full_name] then
						table.insert(lines, string.format('\\cs(0,255,0)%s F%d\\cr', current_tower, i))
					else
						table.insert(lines, string.format('%s F%d', current_tower, i))
					end
				end
			else
				for _, tower in ipairs(temenos_order) do
					table.insert(lines, '')
					for i = 1, temenos_towers[tower].floors do
						local full_name = string.format('Temenos %s tower F%d data', tower:lower(), i)
						if found[full_name] then
							table.insert(lines, string.format('\\cs(0,255,0)%s F%d\\cr', tower, i))
						else
							table.insert(lines, string.format('%s F%d', tower, i))
						end
					end
				end
			end
		end
		
	elseif mode == 'Apollyon' then
		local found = scan_apollyon()
		local current_area = get_current_apollyon_area()
		
		table.insert(lines, 'Apollyon')
		table.insert(lines, 'Points: '..point_total)
		
		if settings.compact then
			if current_area and current_area ~= 'Lobby' then
				local data = apollyon_towers[current_area]
				local line = ''
				for i = 1, data.floors do
					local full_name = string.format('Apollyon %s #%d', current_area, i)
					if found[full_name] then
						line = line .. string.format('\\cs(0,255,0)%d\\cr', i)
					else
						line = line .. string.format('\\cs(255,0,0)%d\\cr', i)
					end
				end
				table.insert(lines, string.format('%s: %s', current_area, line))
			else
				for _, tower in ipairs(apollyon_order) do
					local data = apollyon_towers[tower]
					local line = ''
					for i = 1, data.floors do
						local full_name = string.format('Apollyon %s #%d', tower, i)
						if found[full_name] then
							line = line .. string.format('\\cs(0,255,0)%d\\cr', i)
						else
							line = line .. string.format('\\cs(255,0,0)%d\\cr', i)
						end
					end
					table.insert(lines, string.format('%s: %s', tower, line))
				end
			end
		else
			if current_area and current_area ~= 'Lobby' then
				table.insert(lines, '')
				for i = 1, apollyon_towers[current_area].floors do
					local full_name = string.format('Apollyon %s #%d', current_area, i)
					if found[full_name] then
						table.insert(lines, string.format('\\cs(0,255,0)%s #%d\\cr', current_area, i))
					else
						table.insert(lines, string.format('%s #%d', current_area, i))
					end
				end
			else
				for _, tower in ipairs(apollyon_order) do
					table.insert(lines, '')
					for i = 1, apollyon_towers[tower].floors do
						local full_name = string.format('Apollyon %s #%d', tower, i)
						if found[full_name] then
							table.insert(lines, string.format('\\cs(0,255,0)%s #%d\\cr', tower, i))
						else
							table.insert(lines, string.format('%s #%d', tower, i))
						end
					end
				end
			end
		end
	else
		table.insert(lines, 'Outside Temenos/Apollyon')
	end
	
	box:text(table.concat(lines, '\n'))
end

windower.register_event('prerender', function()
	if mode then	
		local now = os.time()
		if now - last_inventory_scan >= 3 then
			update_display()
			last_inventory_scan = now
		end
	end
end)

windower.register_event('zone change', function(new_zone_id)
	if new_zone_id == 37 then
		mode = 'Temenos'
	elseif new_zone_id == 38 then
		mode = 'Apollyon'
	else
		mode = nil
	end
	point_total = 0
	if mode then box:show() else box:hide() end
	update_display()
end)

windower.register_event('load', function()
	local zone_id = windower.ffxi.get_info().zone
	if zone_id == 37 then
		mode = 'Temenos'
	elseif zone_id == 38 then
		mode = 'Apollyon'
	else
		mode = nil
	end
	point_total = 0
	if mode then box:show() else box:hide() end
	update_display()
end)

windower.register_event('incoming text', function(original)
	if mode then
		local point_gain = original:match(mode.." Units: (%d+)")
		if point_gain then
			point_total = point_total + tonumber(point_gain)
			update_display()
		end
	end
end)

windower.register_event('addon command', function(command, ...)
	command = command and command:lower() or ''
	if command == 'show' then
		if mode then box:show(); update_display() else windower.add_to_chat(207, 'Not in Temenos or Apollyon zone.') end
	elseif command == 'hide' then
		box:hide()
	elseif command =='save' then
		local x, y = box:pos()
		settings.pos.x = x
		settings.pos.y = y
		config.save(settings)
	elseif command == 'compact' then
		settings.compact = not settings.compact
		config.save(settings)
		windower.add_to_chat(207, 'Compact mode: '.. (settings.compact and 'ON' or 'OFF'))
		update_display()
	elseif command == 'fontsize' then
		local arg = ...
		local size = tonumber(arg)
		if size then
			settings.text.size = size
			box:size(size)
			config.save(settings)
			windower.add_to_chat(207, 'Font size set to ' .. size)
		end
	else
		windower.add_to_chat(207, '## Limbox commands: ##')
		windower.add_to_chat(207, '//limbox compact         | Switch GUI to compact mode')
		windower.add_to_chat(207, '//limbox show/hide       | Hides or shows the GUI')
		windower.add_to_chat(207, '//limbox fontsize <size> | Sets the size of the GUI')
		windower.add_to_chat(207, '//limbox save            | Save current position of the GUI')
	end
end)
