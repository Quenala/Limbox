Limbox - Limbus Tracker for Windower

Author: Quenala Version: 1.3

Description

Limbox is a Windower addon that helps you track your progress inside Limbus (Temenos and Apollyon) areas in Final Fantasy XI. It reads your temporary key items and displays which floors you have cleared in real-time. It also tracks the points earned during your run. It supports both Temenos and Apollyon zones with automatic zone detection and dynamically changes its display based on your current tower or area.

<img width="84" height="384" alt="image" src="https://github.com/user-attachments/assets/5efa2a11-62a6-4f88-9be0-72b13a550833" />


Features:

Automatic zone detection for Temenos and Apollyon.
- Scans your temporary items to determine cleared floors.
- Compact and expanded display modes.
- Real-time point tracking from system messages.
- Drag-and-drop GUI window with persistent position.
- Configurable font size and compact mode saved in config file.

Commands:

//limbox show
Show the tracker window (if hidden).

//limbox hide
Hide the tracker window.

//limbox compact
Toggle between compact and full view modes.

//limbox fontsize <size>
Change the font size of the tracker window.

//limbox save
Saves the current location of the tracker window.

Installation
Copy the limbox addon folder into your Windower addons directory.
Load the addon using //lua load limbox.
The addon will automatically activate when you enter Temenos (zone 37) or Apollyon (zone 38).

Configuration
The addon creates a configuration file automatically when first loaded.
GUI position, font size, and compact mode preferences are saved automatically when adjusted.
You can drag the display window to reposition it, when you are happy with location use command //limbox save
