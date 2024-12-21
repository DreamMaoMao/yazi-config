# autosort.yazi

A [Yazi](https://github.com/sxyazi/yazi) plugin that support set sort for a folder, when you enter the foler, it will auto apply a sort that you set before


> [!NOTE]
> The latest main branch of Yazi is required at the moment.


## Installation

```sh
# Linux/macOS
git clone https://github.com/DreamMaoMao/autosort.yazi.git ~/.config/yazi/plugins/autosort.yazi

# Windows
git clone https://github.com/DreamMaoMao/autosort.yazi.git $env:APPDATA\yazi\config\plugins\autosort.yazi
```

## Usage

Add this to your `keymap.toml`:

```toml
[[manager.prepend_keymap]]
on = [ "u", "a" ]
run = "plugin autosort --args='save'"
desc = "set sort for current folder"

[[manager.prepend_keymap]]
on = [ "u", "d" ]
run = "plugin autosort --args='delete'"
desc = "Delete autosort fo current folder"

[[manager.prepend_keymap]]
on = [ "u", "D" ]
run = "plugin autosort --args='delete_all'"
desc = "Delete all autosort"

```
