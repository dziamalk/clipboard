# Clipboard

Ditto-style clipboard history for macOS. Menu-bar app, native Swift.

## Build

    ./build.sh            # builds build/Clipboard.app
    ./build.sh install    # also copies to /Applications

Grant **Accessibility** permission on first launch (needed to auto-paste). Rebuilding changes the ad-hoc signature, so macOS may ask for it again.

## Use

- `Cmd+Shift+V` (rebindable in Settings) opens the popup at the cursor; type to search.
- `Up`/`Down` navigate, `Enter` pastes, `Shift+Enter` pastes as plain text, `Cmd+Backspace` deletes the item, `Esc` or clicking away closes.
- Menu bar icon: show history, pause recording, clear history, settings, quit.

History lives in `~/Library/Application Support/Clipboard/`. Defaults: 1000 items, expire after 7 days, text over 1 MB and images over 10 MB skipped. Items flagged concealed/transient (password managers) are ignored.
