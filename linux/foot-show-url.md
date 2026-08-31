# Foot Terminal: URL Handling Made Simple

## What is URL Mode?

Foot terminal has a clever feature that lets you open any URL in your terminal with just a few keystrokes. No mouse required.

## How It Works

Press **`Ctrl` + `Shift` + `u`** and Foot will:

1. Find all URLs in your terminal output
2. Underline them
3. Show a short key code next to each one

Type the code to open the link instantly.

## Example

```bash
# Your terminal shows this output:
Server started at https://localhost:3000/dashboard

# Press Ctrl+Shift+u
# Foot shows: [AF] https://localhost:3000/dashboard
# Press "AF" and it opens in your browser
```

## Configuration

Edit `~/.config/foot/foot.ini`:

```ini
[url]
# Default URL detection
regex=((https?://)?([a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*|localhost)(:[0-9]+)?(/[a-zA-Z0-9./?=&_~#%+-]*)?)

# Better version with proper domain/IP support
regex=((https?://)?(([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}|localhost|([0-9]{1,3}\.){3}[0-9]{1,3})(:[0-9]{1,5})?(/[^\s<>"']*)?)

# What happens when you open a URL
launch=xdg-open ${url}

[key-bindings]
# Open URLs
show-urls-launch=Control+Shift+u
# Copy URLs (disabled by default)
show-urls-copy=none
```

## Common Issues & Fixes

### Issue: IP addresses like `127.0.0.1:8080` not detected

**Fix:** Use the improved regex above that properly handles IPv4 addresses.

### Issue: URLs with special characters broken

**Fix:** The improved regex handles more characters in the path.

### Issue: URLs are not underlined/highlighted

**Fix:** Check that URL mode is working:
```bash
# Test with a simple echo
echo "https://example.com"
# Press Ctrl+Shift+u and look for highlights
```

## Quick Tips

| Action | Key Binding |
|--------|------------|
| Enter URL mode | `Ctrl` + `Shift` + `u` |
| Open selected URL | Type jump label (e.g., "AF") |
| Exit URL mode | `Esc` or `Ctrl` + `g` |
| Open last URL (if enabled) | Not set by default |

## Why Use This?

- **Faster** than grabbing your mouse
- **More accurate** than trying to highlight long URLs
- **Works in tmux** - Foot handles this natively
- **Keyboard-driven** - keeps your workflow smooth

## Fix Your Current Config

Replace your old regex with this improved version:

```ini
[url]
regex=((https?://)?(([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}|localhost|([0-9]{1,3}\.){3}[0-9]{1,3})(:[0-9]{1,5})?(/[^\s<>"']*)?)
```

## Troubleshooting

**URLs not showing?** Make sure you're in URL mode (`Ctrl+Shift+u`). URLs are only highlighted during this mode.

**Opening fails?** Check your `launch` command. On most Linux systems, `xdg-open` works. On macOS, you might use `open`.

**URL detected wrong?** Adjust the regex pattern to match your needs.

---

That's it! Now you can open URLs in Foot terminal like a pro.

-------

simplest

```ini
[url]
# Matches: https://example.com, example.com, localhost:4200, 127.0.0.1:8080
regex=((https?://)?(([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}|localhost|([0-9]{1,3}\.){3}[0-9]{1,3})(:[0-9]{1,5})?(/[a-zA-Z0-9./?=&_~#%+-]*)?)
launch=xdg-open ${url}

```

simplest script that handles without protocol



```bash

#!/usr/bin/env bash

# Just add http:// if no protocol
url="$1"

# If no protocol, add http:// (handles www too)
if [[ ! "$url" =~ ^https?:// ]] && [[ ! "$url" =~ ^[a-zA-Z]+:// ]]; then
    url="http://$url"
fi

xdg-open "$url"

```

then 

```bash
chmod +x ~/.local/bin/url-open.sh
```


then 

foot config

```ini

[url]
launch=/home/inxeoz/.local/bin/url-open.sh ${url}
regex=((https?://)?(([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}|localhost|([0-9]{1,3}\.){3}[0-9]{1,3})(:[0-9]{1,5})?(/[^\s<>"']*)?)

```


