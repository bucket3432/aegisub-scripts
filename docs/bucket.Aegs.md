# Aegs

Utilities to work with the [aegs][] format.

[aegs]: https://github.com/butterfansubs/aegsc#the-aegs-format

## Requirements

- [petzkuLib](https://typesettingtools.github.io/depctrl-browser/modules/petzku.util/)
- [`aegsc`][aegsc] available in PATH

[aegsc]: https://github.com/butterfansubs/aegsc#installation

## Installation

Copy [`macros/bucket.Aegs.lua`][bucket.Aegs.lua] into `automation/autoload`
in your Aegisub user config directory.

The script will register itself with Dependency Control if it is available.

[bucket.Aegs.lua](https://raw.githubusercontent.com/bucket3432/aegisub-scripts/main/macros/bucket.Aegs.lua)

## Usage

### Import

1. Save your `.aegs` template to a file.
2. Navigate to `Automation > Aegs template > Import...`.
3. Enter the full path to the `.aegs` file.
4. Click OK.

The compiled template should now appear at the top of the file,
along with a line that has `aegs:end` in the Effect field.
This line should be changed to ensure that the style exists
and the times will not interfere with other tooling
(e.g. SubKt, which will throw an error if shifting a line results in negative times).

Updates may be made in the `.aegs` template 
nd re-imported using the same steps above.
All lines up to but not including the `aegs:end` line will be deleted
and replaced with the new output.

- - -

View the repo on [GitHub](https://github.com/bucket3432/aegisub-scripts).
