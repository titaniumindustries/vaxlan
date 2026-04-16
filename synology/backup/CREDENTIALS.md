# AWS Credentials Reference

**IMPORTANT**: Store actual credentials in a password manager. Never commit this file with real values to version control.

## Placeholders Used in Documentation

Replace these placeholders in `AWS_BACKUP_SETUP.md` when rebuilding:

```
{{AWS_ACCESS_KEY_ID_ADMIN}}
{{AWS_SECRET_ACCESS_KEY_ADMIN}}
{{AWS_ACCESS_KEY_ID_NAS_BACKUP}}
{{AWS_SECRET_ACCESS_KEY_NAS_BACKUP}}
```

## Quick Find/Replace

In your editor:
1. Find: `{{AWS_ACCESS_KEY_ID_ADMIN}}`
2. Find: `{{AWS_SECRET_ACCESS_KEY_ADMIN}}`
3. Find: `{{AWS_ACCESS_KEY_ID_NAS_BACKUP}}`
4. Find: `{{AWS_SECRET_ACCESS_KEY_NAS_BACKUP}}`

## Account Information (Non-Sensitive)

- **AWS Account ID**: 823704761294
- **AWS Account Name**: vaxlan
- **Region**: us-east-1
- **Admin IAM User**: vaxocentric
- **Service IAM User**: nas-backup

## S3 Buckets

- vaxlan-synology-personal
- vaxlan-synology-media
- vaxlan-synology-surveillance

## Credential Storage Locations

Store these securely:
- [ ] Admin access keys (vaxocentric) - in password manager
- [ ] Service access keys (nas-backup) - in password manager
- [ ] Hyper Backup encryption password (if enabled) - in password manager
- [ ] Cloud Sync settings - documented in AWS_BACKUP_SETUP.md
