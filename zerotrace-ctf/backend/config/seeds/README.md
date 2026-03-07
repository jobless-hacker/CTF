# Seed Security Notes

Public seed files intentionally use redacted flag values.

Use a private flags file when seeding:

```bash
cd zerotrace-ctf/backend
./venv/bin/python scripts/seed_intro_cybersecurity_track.py \
  --seed-file config/seeds/linux-challenges-11-22.seed.json \
  --flags-file config/seeds/private-flags.json
```

`--flags-file` format is a JSON object that maps challenge slug to plaintext flag.
See `private-flags.example.json` for structure.

The terminal lab service also reads private flags from runtime-only JSON.
By default it uses:

`config/seeds/private-flags.json`

Override with environment variable:

`LAB_PRIVATE_FLAGS_FILE=/absolute/or/relative/path/to/private-flags.json`

M11 Linux lab definitions are stored separately for modular updates:

`app/labs/m11/challenges/*.json`
`app/labs/m11/overlays/*.json`

`ChallengeLoader` merges `app/labs/base_filesystem.json` with each overlay at runtime.
