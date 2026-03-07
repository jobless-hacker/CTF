# Linux Lab Data

This folder stores terminal-lab filesystem data used by `ChallengeLoader`.

Structure:
- `base_filesystem.json`: baseline filesystem tree shared by Linux labs.
- `m11/challenges/*.json`: challenge metadata (`slug`, `startPath`, hints, flag target).
- `m11/overlays/*.json`: challenge-specific filesystem overlay merged onto base tree.

The backend lab engine merges:

`base_filesystem + overlay -> virtual filesystem`

then injects runtime private flag values into configured `flag.path`.
