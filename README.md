# Numbered Source Switcher

An OBS Studio Lua script that cycles through scene items whose source names are whole numbers.

For example, sources named `1`, `2`, `3`, and `4` can be used as a simple sequence. The script makes one numbered source visible at a time and provides hotkeys for moving forward and backward through the sequence.

## Requirements

- OBS Studio with Lua scripting support
- A scene containing sources named with whole numbers, such as `1`, `2`, and `3`

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

The script checks the current scene whenever a hotkey is pressed. It sorts numbered sources numerically and switches their visibility so that only the selected source is visible.

- **Next** advances to the next numbered source.
- **Previous** moves to the previous numbered source.
- **Show First** shows the lowest numbered source.
- **Hide** hides all numbered sources while remembering the source that was visible.
- **Show** restores the numbered source that was visible before **Hide**. If there is no remembered source, it shows the lowest numbered source.
- **Next** stops at the highest numbered source and **Previous** stops at the lowest numbered source.
- If no numbered source is currently visible, **Next** selects the lowest number and **Previous** selects the highest number.

Source names must be whole-number strings. Names such as `1.5`, `camera`, or `01` are not treated as numbered sources.

## License

MIT
