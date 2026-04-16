# Synology AWS S3 Backup Setup

## Summary
AWS account configured for Synology NAS backup to S3 with automated tiering and security controls.

---

## AWS Account Details
- **Account ID**: 823704761294
- **Account Name**: vaxlan
- **Region**: us-east-1

---

## Placeholders to Replace Before Use
- {{AWS_ACCESS_KEY_ID_ADMIN}}: Admin user access key (vaxocentric)
- {{AWS_SECRET_ACCESS_KEY_ADMIN}}: Admin user secret key
- {{AWS_ACCESS_KEY_ID_NAS_BACKUP}}: Service user (nas-backup) access key
- {{AWS_SECRET_ACCESS_KEY_NAS_BACKUP}}: Service user secret key

Search for {{AWS_ and replace each with your actual values when needed. Never commit secrets to version control.

## IAM Users

### Admin User: vaxocentric
- **Purpose**: Your personal administrative access
- **Access Key ID**: {{AWS_ACCESS_KEY_ID_ADMIN}}
- **Secret Access Key**: {{AWS_SECRET_ACCESS_KEY_ADMIN}}
- **Permissions**: Full AdministratorAccess
- **AWS CLI Profile**: `vaxocentric` (already configured)

### Service User: nas-backup
- **Purpose**: Synology NAS backup operations
- **Access Key ID**: {{AWS_ACCESS_KEY_ID_NAS_BACKUP}}
- **Secret Access Key**: {{AWS_SECRET_ACCESS_KEY_NAS_BACKUP}}
- **Permissions**: Limited to read/write/restore on the three backup buckets only
- **Use these credentials in Synology Hyper Backup or Cloud Sync**

---

## S3 Buckets

### 1. vaxlan-synology-personal
- **Purpose**: Personal files (~1TB)
- **Region**: us-east-1
- **Encryption**: SSE-S3 (AWS-managed)
- **Versioning**: Suspended (as of Jan 5, 2026)
- **Lifecycle Policy**:
  - Immediately move to Intelligent-Tiering (auto-optimizes between Standard/IA)
  - Old versions deleted after 7 days
- **Use Case**: Files you need to restore quickly if NAS fails
- **Recovery**: Instant access, no retrieval fees

### 2. vaxlan-synology-media
- **Purpose**: Media files (TB+, rarely restored)
- **Region**: us-east-1
- **Encryption**: SSE-S3 (AWS-managed)
- **Versioning**: Disabled
- **Lifecycle Policy**:
  - Immediately move to Deep Archive (cheapest storage)
- **Use Case**: Long-term archive, re-download preferred over restore
- **Recovery**: 12-48 hours retrieval time, fees apply

### 3. vaxlan-synology-surveillance
- **Purpose**: Surveillance footage (every 5-15 minutes)
- **Region**: us-east-1
- **Encryption**: SSE-S3 (AWS-managed)
- **Versioning**: Disabled
- **Lifecycle Policy**:
  - Day 1: Move to Glacier Instant Retrieval
  - Day 91: Move to Deep Archive (cheapest)
- **Use Case**: Evidence retention, rarely accessed
- **Recovery**: 12-48 hours retrieval time for old footage, fees apply

---

## Security Features
- ✅ All buckets block public access
- ✅ Server-side encryption (SSE-S3) enabled by default
- ✅ nas-backup user has least-privilege access (only these 3 buckets)
- ✅ Versioning on personal files suspended (Hyper Backup provides version history)

---

## Synology Configuration

### Hyper Backup - Personal Files
**Backup Destination:**
- S3 Server: **Amazon S3**
- Access Key: `{{AWS_ACCESS_KEY_ID_NAS_BACKUP}}`
- Secret Key: `{{AWS_SECRET_ACCESS_KEY_NAS_BACKUP}}`
- Bucket: `vaxlan-synology-personal`
- Storage Class: **STANDARD**

**Backup Settings:**
- Compress backup data: **Unchecked**
  - Rationale: Direct S3 file access without Hyper Backup
  - Allows independent file recovery in catastrophic failure scenarios
  - Compression testing showed minimal space savings (~5-10%) due to already-compressed media files
  - Builds trust in backup/restore process before adding encryption complexity
- Enable file change detail log: **Checked** (helpful for restore)
- Enable transfer encryption: **Unchecked** (unencrypted for direct access, can enable later once restore process is trusted)

**Rotation Settings:**
- Enable backup rotation: **Yes**
- Method: **Smart Recycle** (keeps hourly/daily/weekly/monthly)
- Alternative: Keep last 30 versions for daily backups

**Schedule:** Daily at 2:00 AM (or off-peak time)

### Cloud Sync - Media Files
**Use Cloud Sync instead of Hyper Backup for incremental sync**

**Connection Settings:**
- Cloud Provider: **Amazon S3**
- S3 Server: **Amazon S3**
- Access Key: `{{AWS_ACCESS_KEY_ID_NAS_BACKUP}}`
- Secret Key: `{{AWS_SECRET_ACCESS_KEY_NAS_BACKUP}}`
- Bucket: `vaxlan-synology-media`

**Task Settings:**
- Local path: Your media folder path
- Remote path: `/Media` (or preferred path)
- Sync direction: **Upload local changes only**
- Part size: **16 MB**
- Storage Class: **Standard Storage** (lifecycle moves to Deep Archive)
- Polling Period: **86400 seconds** (daily sync)

**Advanced Settings:**
- Enable advanced consistency check: **Unchecked**
- Data encryption (client-side): **Unchecked**
- Don't remove files in destination when removed from source: **Checked** (optional - keeps all files)
- Enable server side encryption (AES-256): **Checked** (SSE-S3)

**Schedule:**
- Enable Schedule Settings: **Checked**
- Run time window: **2:00 AM - 8:00 AM**
- Runs once daily during this window

### Cloud Sync - Surveillance
**Use Cloud Sync instead of Hyper Backup for real-time sync**

**Connection Settings:**
- Cloud Provider: **Amazon S3**
- S3 Server: **Amazon S3**
- Access Key: `{{AWS_ACCESS_KEY_ID_NAS_BACKUP}}`
- Secret Key: `{{AWS_SECRET_ACCESS_KEY_NAS_BACKUP}}`
- Bucket: `vaxlan-synology-surveillance`

**Task Settings:**
- Local path: **/surveillance** (your Surveillance Station path)
- Remote path: **/Surveillance**
- Sync direction: **Upload local changes only**
- Part size: **16 MB**
- Storage Class: **Standard Storage**

**Advanced Settings:**
- Enable advanced consistency check: **Unchecked**
- Data encryption (client-side): **Unchecked**
- Don't remove files in destination when removed from source: **Checked** (keep all footage)
- Enable server side encryption (AES-256): **Checked** (SSE-S3)

**Schedule:** Enable **real-time sync** or run every 5-15 minutes

---

## Cost Estimates (Approximate)

### Storage Costs (per month)
- **Personal (1TB)**: ~$11/month (Intelligent-Tiering Standard tier)
- **Media (3TB)**: ~$3.60/month (Deep Archive = $0.00099/GB)
- **Surveillance (depends on retention)**: 
  - First day: Standard S3 = ~$0.023/GB/month
  - After 1 day: Glacier IR = ~$0.004/GB/month
  - After 91 days: Deep Archive = ~$0.00099/GB/month

### Data Transfer
- **Upload**: FREE
- **Download**: $0.09/GB after first 100GB/month (free tier)

### Retrieval Costs (only when restoring)
- Personal: FREE (Intelligent-Tiering)
- Media/Surveillance: $0.02/GB + $0.10/1000 requests (Deep Archive Standard retrieval)

---

## Next Steps

1. ✅ AWS account configured
2. ✅ Buckets created with lifecycle policies
3. ✅ IAM users and permissions configured
4. ⏳ **Configure Synology to use nas-backup credentials**
5. ⏳ Test backup and restore for each data type
6. ⏳ Set up monitoring/alerts (optional)

---

## Notes

- **Encryption**: Currently using SSE-S3. You can enable client-side encryption in Synology for additional security (recommended for personal files).
- **Lifecycle changes**: 
  - Surveillance files take 91 days to reach Deep Archive (AWS requirement)
  - Media files move to Deep Archive immediately (Day 0) for cheapest storage
- **Versioning**: Suspended on personal bucket (Jan 5, 2026). Hyper Backup Smart Recycle provides version history.
- **Media Strategy**: Uses Cloud Sync (no versioning) instead of Hyper Backup for incremental daily syncs with immediate Deep Archive transition
- **Credential security**: Store the nas-backup credentials securely. They're already limited to these 3 buckets only.

---

## Useful AWS CLI Commands (using vaxocentric profile)

```bash
# List all buckets
aws s3 ls --profile vaxocentric

# Check bucket size
aws s3 ls s3://vaxlan-synology-personal --recursive --summarize --profile vaxocentric

# List objects in a bucket
aws s3 ls s3://vaxlan-synology-personal/ --profile vaxocentric

# Download a specific file
aws s3 cp s3://vaxlan-synology-personal/path/to/file.txt . --profile vaxocentric

# Restore from Glacier/Deep Archive (initiate restore, then download after waiting)
aws s3api restore-object --bucket vaxlan-synology-surveillance --key path/to/file --restore-request Days=7,GlacierJobParameters={Tier=Standard} --profile vaxocentric
```

---

## AWS CLI Setup Commands

### Configure Admin Profile
```bash
aws configure set aws_access_key_id "{{AWS_ACCESS_KEY_ID_ADMIN}}" --profile vaxocentric
aws configure set aws_secret_access_key "{{AWS_SECRET_ACCESS_KEY_ADMIN}}" --profile vaxocentric
aws configure set region us-east-1 --profile vaxocentric

# Verify
aws sts get-caller-identity --profile vaxocentric
```

### Create Buckets
```bash
aws s3api create-bucket --bucket vaxlan-synology-personal --region us-east-1 --profile vaxocentric
aws s3api create-bucket --bucket vaxlan-synology-media --region us-east-1 --profile vaxocentric
aws s3api create-bucket --bucket vaxlan-synology-surveillance --region us-east-1 --profile vaxocentric
```

### Enable Versioning (Personal Only)
```bash
aws s3api put-bucket-versioning --bucket vaxlan-synology-personal --versioning-configuration Status=Enabled --profile vaxocentric
```

### Block Public Access (All Buckets)
```bash
for bucket in vaxlan-synology-personal vaxlan-synology-media vaxlan-synology-surveillance; do
  aws s3api put-public-access-block --bucket $bucket \
    --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true \
    --profile vaxocentric
done
```

### Apply Lifecycle Policies
```bash
# Use lifecycle JSON files in config/ directory
aws s3api put-bucket-lifecycle-configuration --bucket vaxlan-synology-personal --lifecycle-configuration file://config/lifecycle-personal.json --profile vaxocentric
aws s3api put-bucket-lifecycle-configuration --bucket vaxlan-synology-media --lifecycle-configuration file://config/lifecycle-media.json --profile vaxocentric
aws s3api put-bucket-lifecycle-configuration --bucket vaxlan-synology-surveillance --lifecycle-configuration file://config/lifecycle-surveillance.json --profile vaxocentric
```

### Create and Attach IAM Policy
```bash
aws iam create-policy --policy-name SynologyBackupAccess --policy-document file://config/nas-backup-policy.json --profile vaxocentric

# Attach to nas-backup user
aws iam attach-user-policy --user-name nas-backup --policy-arn arn:aws:iam::823704761294:policy/SynologyBackupAccess --profile vaxocentric
```

---

## Rebuild from Scratch Checklist

### AWS Side (Manual Steps)
1. Create IAM users in AWS Console:
   - vaxocentric (admin) with AdministratorAccess
   - nas-backup (service) with no initial permissions
2. Generate access keys for both users
3. Save keys securely and replace placeholders in this document

### AWS Side (CLI Commands)
1. Configure AWS CLI with admin profile (see commands above)
2. Create S3 buckets
3. Enable versioning on personal bucket
4. Block public access on all buckets
5. Apply lifecycle policies (JSON files in config/ directory)
6. Create and attach IAM policy for nas-backup user

### Synology Side
1. Install Hyper Backup and Cloud Sync packages
2. Configure Hyper Backup for Personal files (see settings above)
3. Configure Hyper Backup for Media files (see settings above)
4. Configure Cloud Sync for Surveillance (see settings above)
5. Test each backup/sync task
6. Verify files appear in S3

---

## Monitoring Commands

```bash
# Check bucket sizes
aws s3 ls s3://vaxlan-synology-personal --recursive --summarize --profile vaxocentric
aws s3 ls s3://vaxlan-synology-media --recursive --summarize --profile vaxocentric
aws s3 ls s3://vaxlan-synology-surveillance --recursive --summarize --profile vaxocentric

# List recent surveillance uploads
aws s3 ls s3://vaxlan-synology-surveillance/ --recursive --human-readable --profile vaxocentric | tail -20

# Restore archived file (Deep Archive/Glacier)
aws s3api restore-object --bucket vaxlan-synology-media --key path/to/file \
  --restore-request Days=7,GlacierJobParameters={Tier=Standard} --profile vaxocentric
```

---

## Support

For questions about AWS costs, check: https://calculator.aws/
For Synology backup configuration: https://kb.synology.com/
