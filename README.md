# Numbered Source Switcher

An OBS Studio Lua script that cycles through scene items whose source names end in a whole number.

For example, sources named `Lysic 1`, `Lyric 2`, and `Lyric 3` can be used as a simple sequence. The script makes one numbered source visible at a time and provides hotkeys for moving forward and backward through the sequence.

## Requirements

- OBS Studio with Lua scripting support
- A scene containing sources with text before a whole number, such as `Cam 1`, `Scene 2`, and `Title 3`

## Installation

1. Download or clone this repository.
2. In OBS Studio, open **Tools > Scripts**.
3. Click the **+** button and select `numbered_source_switcher.lua`.
4. Open **Settings > Hotkeys**.
5. Assign hotkeys to the commands you want to use:
   - **Numbered Source: Next**
   - **Numbered Source: Previous**
   - **Numbered Source: Show First**
   - **Numbered Source: Hide**
   - **Numbered Source: Show**

## Usage

The script checks the current scene whenever a hotkey is pressed. It parses the trailing whole number from each source name and sorts those sources numerically before switching their visibility so that only the selected source is visible.

- **Next** advances to the next numbered source.
- **Previous** moves to the previous numbered source.
- **Show First** shows the lowest numbered source.
- **Hide** hides all numbered sources while remembering the source that was visible.
- **Show** restores the numbered source that was visible before **Hide**. If there is no remembered source, it shows the lowest numbered source.
- **Next** stops at the highest numbered source and **Previous** stops at the lowest numbered source.
- If no numbered source is currently visible, **Next** selects the lowest number and **Previous** selects the highest number.

Source names are treated as numbered when they end in a whole number, such as `Cam 1`, `Scene 2`, or `3`. Names such as `1.5`, `camera`, or `Scene 1A` are not treated as numbered sources. If multiple sources share the same number, the first matching source in scene order wins.

## License

MIT
