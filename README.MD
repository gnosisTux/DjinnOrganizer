# DjinnOrganizer

Automatically organize your downloads by moving or deleting files based on rules.

## Installation

```bash
# Copy script to local bin
cp djinnorganizer.pl ~/.local/bin/djinnorganizer
chmod +x ~/.local/bin/djinnorganizer

# Create config folder
mkdir -p ~/.config/djinnorganizer

# Copy example config
cp config.yaml ~/.config/djinnorganizer/config.yaml
````


## Usage

```bash
perl djinnorganizer.pl [options]
````

### Options

* `--config_file <path>` : YAML configuration file (default: `~/.config/djinnorganizer/config.yaml`)
* `--help`, `-h`         : Show this help message

## Configuration (`config.yaml`)

Example:

```yaml
sorting:

  # Images → move to Pictures/Downloads
  - search: "~/Downloads"
    extensions: [".jpeg", ".jpg", ".png"]
    destination: "~/Pictures/Downloads"
    ignore_hidden: true

  # Videos → move to Videos/Downloads
  - search: "~/Downloads"
    extensions: [".mp4", ".mkv"]
    destination: "~/Videos/Downloads"
    ignore_hidden: true

  # ISOs → move to ~/ISOS, wait for files to finish downloading
  - search: "~/Downloads"
    extensions: [".img", ".iso"]
    destination: "~/ISOS"
    ignore_hidden: true
    wait_for_stable: true

sorting:

  # Images → move to Pictures/Downloads
  - search: "~/Downloads"
    extensions: [".jpeg", ".jpg", ".png"]
    destination: "~/Pictures/Downloads"
    ignore_hidden: true

  # Videos → move to Videos/Downloads
  - search: "~/Downloads"
    extensions: [".mp4", ".mkv"]
    destination: "~/Videos/Downloads"
    ignore_hidden: true

  # ISOs → move to ~/ISOS, wait for files to finish downloading
  - search: "~/Downloads"
    extensions: [".img", ".iso"]
    destination: "~/ISOS"
    ignore_hidden: true
    wait_for_stable: true

  # Delete everything else except .part files
  - search: "~/Downloads"
    all: true
    ignore_extensions: [".part"]
    delete: true
    ignore_hidden: true
    wait_for_stable: true

  # Books & documents → multiple source folders
  - search: 
      - "~/Downloads"
      - "~/Downloads/Telegram Desktop"
    extensions: [".pdf", ".epub", ".mobi", ".azw", ".azw3", ".djvu", ".cbz", ".cbr", ".txt", ".doc", ".docx", ".odt", ".rtf", ".html", ".xhtml", ".ppt", ".pptx"]
    destination: "~/Documents/Libros y Documentos/DjinnOrganizer"
    ignore_hidden: true

  # Delete everything else except .part files
  - search: "~/Downloads"
    all: true
    ignore_extensions: [".part"]
    delete: true
    ignore_hidden: true
    wait_for_stable: true
```

### Parameters

* `search` : folder or list of folders to scan (~ = home)
* `extensions` : process only these extensions
* `destination` : folder to move files to (ignored if `delete: true`)
* `delete` : remove files instead of moving
* `ignore_hidden` : skip files starting with `.`
* `wait_for_stable` : wait a few seconds to ensure file is fully downloaded
* `all` : process all files instead of only `extensions`
* `ignore_extensions` : extensions to skip when `all=true`

### Notes

* Hidden files are ignored by default.
* `destination` is ignored if `delete` is true.
* `wait_for_stable` ensures incomplete downloads are skipped.
* `search` now supports multiple source folders in a single rule.
