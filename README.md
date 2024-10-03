# DisplayFilter

DisplayFilter is a minimalist macOS app that combines features similar to MonitorControl and f.lux. It allows users to adjust screen brightness and apply color filters to reduce eye strain and improve visual comfort.

## Main Focus of this app
- Simple software brightness control and color filters, not for changing the actual brightness of the display hardware. 
- This tool lets you control the brightness over the hardware limitations of your Mac's display, when you are using an external display.

## Features

- Adjust screen brightness
- Apply color filters (Orange, Red, Green, Blue)
- Control filter intensity
- Accessible from the menu bar
- Supports multiple displays

## Installation

1. Download the latest release from the [Releases](https://github.com/uyasarkocal/DisplayFilter/releases) page.
2. Unzip the downloaded file.
3. Drag the DisplayFilter app to your Applications folder.
4. Launch DisplayFilter from your Applications folder or using Spotlight.

## Usage

1. Click on the DisplayFilter icon in the menu bar to open the control panel.
2. Use the brightness slider to adjust screen brightness. (This is a software brightness control, not for changing the actual brightness of the display hardware.)
3. Click on a color dot to apply a color filter.
4. Use the intensity slider to adjust the strength of the color filter.
5. Click the reset button to return to default settings.

## Building from Source

To build DisplayFilter from source:

1. Clone this repository:
   ```
   git clone https://github.com/uyasarkocal/DisplayFilter.git
   ```
2. Open the project in Xcode.
3. Build and run the project (Cmd + R).

## Requirements

- macOS 11.0 or later
- Xcode 12.0 or later (for building from source)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

The app does not have an icon, I will be happy to add one if you send me a nice one.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by [MonitorControl](https://github.com/MonitorControl/MonitorControl) and [f.lux](https://justgetflux.com/). Both are great software and I am grateful for their existence, but also I was tired of running two apps to control my displays.
- Built with SwiftUI

## Support

If you encounter any issues or have questions, please [open an issue](https://github.com/uyasarkocal/DisplayFilter/issues) on GitHub. I am not a Swift developer and made this app for my own needs, so I appreciate any help.