# vaxlan

Home network infrastructure and automation configuration.

## Structure

```
vaxlan/
├── network/          # Network infrastructure (MikroTik router, VLANs, firewall)
│   ├── README.md     # Quick-start reference: key IPs, VLANs, router access
│   ├── TODO.md       # Open tasks and known issues
│   ├── docs/         # Detailed documentation (architecture, firewall, hardware)
│   └── mikrotik/     # Router configs, scripts, backups
│
├── homeassistant/    # Home Assistant configuration and automations
│   └── README.md     # HA system overview, add-ons, integrations
│
└── synology/         # Synology NAS configuration and management
    └── backup/       # AWS S3 backup system (config, scripts, docs)
```

See each subdirectory's `README.md` for details.
Use [`_init.md`](_init.md) as the bootstrap context for agent sessions in this project.

## Notes

- Keep this repository private (contains network topology and credentials)
