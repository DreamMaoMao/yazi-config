# autofilter.yazi

A [Yazi](https://github.com/sxyazi/yazi) plugin that support set filter for a folder, when you enter the foler, it will auto apply a filter that you set before


> [!NOTE]
> The latest main branch of Yazi is required at the moment.


## Installation

```sh
# Linux/macOS
git clone https://github.com/DreamMaoMao/autofilter.yazi.git ~/.config/yazi/plugins/autofilter.yazi

# Windows
git clone https://github.com/DreamMaoMao/autofilter.yazi.git $env:APPDATA\yazi\config\plugins\autofilter.yazi
```

## Usage

Add this to your `keymap.toml`:

```toml
[[manager.prepend_keymap]]
on = [ "u", "a" ]
run = "plugin autofilter --args='save'"
desc = "set filter for current folder"

[[manager.prepend_keymap]]
on = [ "u", "d" ]
run = "plugin autofilter --args='delete'"
desc = "Delete autofilter fo current folder"

[[manager.prepend_keymap]]
on = [ "u", "D" ]
run = "plugin autofilter --args='delete_all'"
desc = "Delete all autofilter"

```
