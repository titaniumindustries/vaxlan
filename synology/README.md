# Synology NAS

Configuration, backup, and management documentation for the Synology NAS.

## Structure

```
synology/
└── backup/              # AWS S3 backup system (Hyper Backup + Cloud Sync)
    ├── README.md         # Complete backup system documentation
    ├── SETUP.md          # AWS setup & rebuild instructions
    ├── CREDENTIALS.md    # Credential placeholders
    ├── USAGE_TRACKING.md # Storage usage tracking documentation
    ├── config/           # AWS lifecycle policies & IAM policy
    ├── scripts/          # Monitoring & tracking scripts
    └── logs/             # Usage tracking CSV data
```

## AWS Account

- **Account ID**: 823704761294
- **Account Name**: vaxlan
- **Region**: us-east-1
- **CLI Profile**: `vaxocentric`

## S3 Buckets

- `vaxlan-synology-personal` — Personal files (Intelligent-Tiering)
- `vaxlan-synology-media` — Media archive (Deep Archive)
- `vaxlan-synology-surveillance` — Surveillance footage (lifecycle tiered)

See `backup/README.md` for full details.
