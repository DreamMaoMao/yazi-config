# win-clipboard.yazi
Copy files to the clipboard by calling windows build-incopy function without generating disk garbage

## dependcy
- powershell

> [!NOTE]
> You need yazi 3.x for this plugin to work.


## Configuration

Copy or install this plugin and add the following keymap to your `manager.prepend_keymap`:

```toml
on = "<C-y>"
run = ["plugin win-clipboard"]
```

