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
