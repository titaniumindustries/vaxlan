# Complete Backup System Documentation

**Last Updated**: April 16, 2026  
**System Status**: Operational & Optimized

---

## Table of Contents
1. [System Architecture](#system-architecture)
2. [Backup Configuration by Data Type](#backup-configuration-by-data-type)
3. [Versioning Strategy](#versioning-strategy)
4. [Cost Analysis](#cost-analysis)
5. [Recovery Scenarios](#recovery-scenarios)
6. [Recent Optimizations](#recent-optimizations)
7. [Maintenance & Monitoring](#maintenance--monitoring)
8. [Decision Log](#decision-log)

---

## System Architecture

### Three-Tier Backup System

```
┌─────────────────────────────────────────────────────────────┐
│ Layer 1: Local Devices (Real-time sync)                     │
├─────────────────────────────────────────────────────────────┤
│ Mac Mini (80% usage) ←→ Synology Drive ←→ MacBook (Travel)  │
│   ~/Documents/              ↕                   ~/Documents/ │
│                                                               │
│           Synology NAS: /home/SynologyDrive/                 │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│ Layer 2: NAS Backup (Scheduled backups)                     │
├─────────────────────────────────────────────────────────────┤
│ Personal: Hyper Backup (Daily 2 AM, Smart Recycle)          │
│ Media: Cloud Sync (Daily 2-8 AM, No versioning)             │
│ Surveillance: Cloud Sync (Real-time, Lifecycle tiering)     │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│ Layer 3: Cloud Storage (AWS S3 us-east-1)                   │
├─────────────────────────────────────────────────────────────┤
│ vaxlan-synology-personal (1.68 TB)                          │
│ vaxlan-synology-media (4.7 TB)                              │
│ vaxlan-synology-surveillance (11 GB)                         │
│                                                               │
│ Total: ~6.4 TB | Cost: ~$26/month (April 2026 run rate)     │
└──────────────────────────────────────────────────────────────────┘
```

*Sizes reflect live audit 2026-04-16 after orphaned multipart cleanup. Media grew from 3.5 TB to 4.7 TB since Jan 2026.

---

## Backup Configuration by Data Type

### Personal Files (~1.68 TB)

**Sync Layer**: Synology Drive Client
- Mac paths: `~/Documents/` (both Mac Mini & MacBook)
- NAS path: `/home/SynologyDrive/Documents/`
- Method: Two-way real-time sync
- WiFi only: Yes
- Sync mode: Traditional (not On-Demand)

**Backup Layer**: Hyper Backup
- Schedule: Daily at 2:00 AM
- S3 path: `s3://vaxlan-synology-personal/Personal.hbk/`
- Compression: **Disabled** (direct S3 file access)
- Transfer encryption: **Disabled** (trust-building phase)
- File change log: **Enabled**
- Storage class: STANDARD → Intelligent-Tiering (automatic)

**Versioning Strategy**:
- Hyper Backup: Smart Recycle (hourly, daily, weekly, monthly)
- S3 Versioning: **Suspended** (as of Jan 5, 2026)
- Old version cleanup: 7 days (noncurrent versions)

**Recovery Capability**:
- Hyper Backup version restore (primary — use Hyper Backup Explorer desktop app or re-targeted DSM task)
- NAS copy available (Synology Drive version history)
- Multiple Mac copies (active Synology Drive sync)

**Note on "direct S3 access"**: Historically documented as a benefit of uncompressed storage. In practice, `s3://vaxlan-synology-personal/Personal.hbk/` is Hyper Backup's internal container format even when uncompressed; individual files cannot be trivially downloaded and opened from raw S3 — you need Hyper Backup Explorer or a Hyper Backup restore task. Uncompressed mode saves 5–10% storage vs compression-on with negligible recovery-flexibility benefit, and should be reconsidered.

**Cost (2026-04-16 audit)**: 
- ~$7.31/month storage (IT-AIA dominant at 1,681 GB, IT-IA 30 GB, IT-FA 8.5 GB)
- ~$0.17/month IT monitoring fees
- Previously documented $15–16/mo was wrong — the monitoring script missed the IT Archive Instant Access tier.

---

### Media Files (4.7 TB)

**Sync Layer**: Cloud Sync (replaced Hyper Backup Dec 8, 2025)
- NAS path: Media library folders
- S3 path: `s3://vaxlan-synology-media/Media Library/`
- Sync direction: Upload local changes only
- Schedule: Daily 2:00 AM - 8:00 AM window
- Polling period: 86400 seconds (24 hours)
- Part size: 16 MB

**Settings**:
- Storage class: STANDARD → Deep Archive (Day 0)
- Server-side encryption: **Enabled** (SSE-S3)
- Don't remove files when deleted locally: **Checked**
- Advanced consistency check: **Disabled**

**Versioning Strategy**:
- None (Cloud Sync mirrors current state)
- Lifecycle: Immediate transition to Deep Archive

**Recovery Capability**:
- Rarely needed (can re-download most content)
- 12-48 hour restore time from Deep Archive
- Selective file/folder restore via AWS Console

**Cost (2026-04-16 audit)**: ~$4.67/month storage (4,720 GB Deep Archive)

**Note**: Old Hyper Backup (`Media.hbk/`, 2.4 TB) deleted Jan 5, 2026. 1,899 orphaned multipart uploads from Cloud Sync failures (Dec 2025–Jan 2026) aborted on 2026-04-16 — they were being billed as Standard storage (~706 GB).

---

### Surveillance (12 GB)

**Sync Layer**: Cloud Sync
- NAS path: `/surveillance/` (Surveillance Station recordings)
- S3 path: `s3://vaxlan-synology-surveillance/Surveillance/`
- Sync direction: Upload local changes only
- Schedule: Real-time sync
- Part size: 16 MB

**Settings**:
- Storage class: STANDARD (lifecycle manages transitions)
- Server-side encryption: **Enabled** (SSE-S3)
- Don't remove files when deleted locally: **Checked**

**Lifecycle Transitions**:
- Day 0: STANDARD ($0.023/GB)
- Day 1: Glacier Instant Retrieval ($0.004/GB)
- Day 91: Deep Archive ($0.00099/GB)

**Versioning Strategy**:
- None (continuous real-time sync)
- Files accumulate until deleted locally

**Recovery Capability**:
- Evidence retention
- Selective restore (by date/time)
- Variable restore time (instant to 12-48 hours depending on age)

**Cost**: ~$0.05/month

---

## Versioning Strategy

### Design Philosophy

**Objective**: Balance protection vs. cost
- Critical data (Personal): Multiple version layers
- Media: No versioning (rarely need, can re-download)
- Surveillance: No versioning (continuous feed)

### Personal Files Versioning (Two-Layer Historical)

#### Layer 1: Hyper Backup Versioning
**Control**: Hyper Backup Smart Recycle
**Retention**: ~30+ versions
- Recent hourly backups
- Daily backups (last week)
- Weekly backups (last month)
- Monthly backups (long-term)

**Purpose**: Primary version history
**Recovery**: Via Hyper Backup interface
**Storage impact**: Incremental (only changed files)

#### Layer 2: S3 Versioning (SUSPENDED as of Jan 5, 2026)
**Previous state**: Enabled with 90-day retention
**Current state**: Suspended (no new versions)
**Cleanup**: Old versions expire after 7 days

**Reason for change**: 
- Redundant with Hyper Backup versioning
- Cost savings: ~$2-3/month
- Hyper Backup Smart Recycle provides sufficient protection

### Media & Surveillance: No Versioning

**Rationale**:
- Media: Rarely changes, can re-download if needed
- Surveillance: Continuous feed, no need for versions
- Cost optimization: Versioning expensive for large datasets

---

## Cost Analysis

### Current Monthly Costs (April 2026 — from AWS Cost Explorer)

March 2026 actual bill: **$28.93**. April 2026 partial-month run rate: **$25.80/mo projected**. Breakdown:

| Bucket | Size | Storage Class | Monthly Cost |
|--------|------|---------------|--------------|
| **Personal** | 1.68 TB | IT (mostly AIA) | ~$7.48 |
| **Media** | 4.72 TB | Deep Archive | ~$4.67 |
| **Surveillance** | 11 GB | Deep Archive | ~$0.05 |
| StandardStorage (lifecycle lag + orphaned multiparts†) | — | — | ~$14.54 |
| Requests (all tiers) | — | — | ~$1.21 |
| IT monitoring fees | — | — | ~$0.17 |
| **TOTAL** | **~6.4 TB** | | **~$28** |

† 1,905 orphaned multipart uploads aborted on 2026-04-16 (1,899 Media + 6 Surveillance). Expected to reduce Standard-storage line item substantially on next billing cycle. `AbortIncompleteMultipartUpload` lifecycle rules now active on all 3 buckets (7-day auto-abort).

### Cost Breakdown by Component

**Storage costs**:
- Personal: $0.011/GB (Intelligent-Tiering)
- Media: $0.00099/GB (Deep Archive)
- Surveillance: $0.004/GB average (blended across lifecycle)

**Additional costs** (minimal):
- API requests: ~$0.01-0.10/month
- Data transfer OUT: $0 (rarely restore)

### Cost History & Optimizations

| Date | Change | Impact | New Total |
|------|--------|--------|-----------|
| **Nov 2025** | Initial setup | - | ~$24.49/month |
| **Dec 2025** | Media: Hyper Backup → Cloud Sync | Avoided Deep Archive access issues | ~$24.49/month |
| **Jan 5, 2026** | Suspended S3 versioning (Personal) | -$2-3/month | ~$21-22/month |
| **Jan 5, 2026** | Deleted orphaned Media.hbk (2.4 TB) | -$2.51/month | ~$18.51-19.51/month |
| **Jan 5, 2026** | 7-day version cleanup (Personal) | Faster savings realization | ~$18.51-19.51/month |
| **Apr 16, 2026** | Aborted 1,905 orphaned multipart uploads | TBD on next bill (likely $5–10/mo off Standard line) | TBD |
| **Apr 16, 2026** | Added AbortIncompleteMultipartUpload lifecycle (7d) on all 3 buckets | Prevents future orphan accumulation | — |

**Note**: Media grew from 3.5 TB → 4.7 TB between Jan and Apr 2026 (normal addition, ~+$1.20/mo). Total bill trend is flat-to-up due to Media growth, but Standard-storage waste should drop after multipart cleanup.

### Projected Growth (1% monthly)

| Timeframe | Total Size | Est. Monthly Cost |
|-----------|------------|-------------------|
| **Current** | 5.2 TB | $18.51-19.51 |
| **+6 months** | 5.5 TB | $19.62-20.62 |
| **+12 months** | 5.8 TB | $20.77-21.77 |
| **+24 months** | 6.5 TB | $23.30-24.30 |

**Cost drivers**:
- Personal bucket (most expensive per GB)
- Media growth (cheapest per GB, but largest volume)

---

## Recovery Scenarios

### Scenario 1: Accidental File Deletion (Same Day)

**Example**: Delete important document Monday morning, realize by afternoon

**Recovery Options**:
1. **Synology NAS** (Fastest)
   - File still on NAS (Synology Drive hasn't synced deletion yet, or check NAS directly)
   - Time: Seconds
   
2. **Hyper Backup**
   - Restore from last night's backup
   - Time: Minutes
   
3. **S3 Direct**
   - Download from S3 (uncompressed)
   - Time: Minutes

**Success Rate**: 100%

---

### Scenario 2: File Corruption Noticed Days Later

**Example**: Corrupt spreadsheet on Tuesday, notice Friday (3 days later)

**Recovery Options**:
1. **Hyper Backup Smart Recycle**
   - Restore Monday's daily backup (before corruption)
   - Time: Minutes
   
2. **S3 Direct**
   - Download Monday's file from S3
   - Time: Minutes

**Success Rate**: 100% (within Smart Recycle retention)

---

### Scenario 3: Need Old File (2 Months Ago)

**Example**: Need document from November, now January

**Recovery Options**:
1. **Hyper Backup Monthly Snapshot**
   - Smart Recycle keeps monthly versions
   - Time: Minutes
   
2. **S3 Versioning (No longer available after Jan 5, 2026)**
   - Previously: Could restore from 90-day S3 versions
   - Now: Rely on Hyper Backup monthly snapshots

**Success Rate**: High (Hyper Backup Smart Recycle has monthly versions)

**Risk**: If corruption happened >90 days ago AND Hyper Backup monthly snapshot is also corrupted
- Mitigation: Smart Recycle keeps multiple monthly versions

---

### Scenario 4: Complete NAS Failure

**Example**: NAS hardware dies, need to restore everything

**Recovery Options**:
1. **Buy New NAS + Restore from S3**
   - Install Hyper Backup on new NAS
   - Connect to S3 with nas-backup credentials
   - Restore all Personal files from S3
   - Time: Hours to days (1.2-1.4 TB download)
   - Cost: ~$153 data transfer (1.4 TB @ $0.09/GB after first 100GB)
   
2. **Direct S3 Download**
   - Use AWS CLI to download Personal bucket
   - Files uncompressed = can browse/cherry-pick
   - Time: Hours to days
   
3. **Media/Surveillance**
   - Media: Re-download from sources (preferred)
   - Surveillance: Restore from S3 if needed (Deep Archive = 12-48 hour restore)

**Success Rate**: 100% for Personal files

---

### Scenario 5: Ransomware Attack

**Example**: Ransomware encrypts Mac Wednesday morning, syncs to NAS

**Recovery Steps**:
1. **Disconnect all devices** immediately
2. **Restore from Hyper Backup** Tuesday night's backup (before infection)
3. **Verify S3 backup** not synced encrypted files yet
4. **Clean devices** before reconnecting

**Recovery Time**: Hours (full system restore)

**Success Rate**: 100% (caught within daily backup window)

**Protection Layers**:
- Hyper Backup daily snapshots
- S3 offsite (geographic separation)
- Multiple local copies (Mac + NAS)

---

### Scenario 6: Mac Stolen/Lost While Traveling

**Example**: MacBook stolen abroad, need to work on borrowed computer

**Recovery Options**:
1. **Access NAS remotely** (QuickConnect)
   - Download specific files needed
   - Time: Minutes
   
2. **Download from S3**
   - AWS Console access from anywhere
   - Direct file download (uncompressed)
   - Time: Minutes per file

**Success Rate**: 100%

**Advantage**: Geographic redundancy + multiple access methods

---

## Recent Optimizations

### January 5, 2026: Cost Optimization Implementation

#### Change 1: Suspended S3 Versioning (Personal Bucket)
**Reason**: Redundant with Hyper Backup versioning
**Impact**: 
- No new S3 versions created
- Old versions expire after 7 days
- Storage reduction: 1.7 TB → 1.2-1.4 TB (over 7-14 days)
- Cost savings: ~$2-3/month

**Trade-off Accepted**:
- Lost: S3-level file versioning
- Kept: Hyper Backup Smart Recycle (sufficient protection)

#### Change 2: Accelerated Version Cleanup
**Previous**: 90-day noncurrent version expiration
**New**: 7-day noncurrent version expiration
**Impact**: Faster cost savings realization

#### Change 3: Deleted Orphaned Media Backup
**Deleted**: `Media.hbk/` folder (2.4 TB)
**Reason**: Old Hyper Backup data from before Cloud Sync transition
**Impact**: 
- Storage reduction: 2.4 TB freed
- Cost savings: ~$2.51/month
- Risk: None (Cloud Sync has current data)

**Total Optimization**: ~$5-6/month savings (20-25% reduction)

---

### December 8, 2025: Media Strategy Change

#### Problem
Hyper Backup couldn't manage Media versions when files transitioned to Deep Archive (Hyper Backup error: "Unable to access backup data")

#### Solution
**From**: Hyper Backup with versioning
**To**: Cloud Sync without versioning

**Rationale**:
- Media files rarely need restoration
- Would re-download rather than restore
- Deep Archive is cheapest storage class
- Daily incremental sync sufficient

**Implementation**:
- Created Cloud Sync task for Media
- Disabled Hyper Backup task
- Kept old Hyper Backup data temporarily (deleted Jan 5, 2026)

---

## Maintenance & Monitoring

### Weekly Tasks

**Check Backup Status**:
```bash
# Mac: Check Synology Drive sync status (menu bar icon)
# NAS: Check Hyper Backup logs (DSM → Hyper Backup)
# NAS: Check Cloud Sync logs (DSM → Cloud Sync)
```

**Monitor Storage**:
```bash
# Run weekly to track storage changes
~/Documents/Warp\ Personal/vaxlan/synology/backup/scripts/get_aws_storage_report.sh 7
```

### Monthly Tasks

**Review AWS Costs**:
1. Log into AWS Console (account 823704761294)
2. Billing Dashboard → Cost Explorer
3. Filter by S3 service
4. Compare with projections

**Verify Backups**:
- Test restore of sample file from Hyper Backup
- Verify files accessible in S3
- Check NAS available space

**Update Cost Tracking**:
- Note any significant storage changes
- Update projections if growth rate changes

### Quarterly Tasks

**Test Full Restore** (Small dataset):
- Restore a folder from Hyper Backup
- Verify file integrity
- Time the restore process

**Review Retention Settings**:
- Hyper Backup Smart Recycle still appropriate?
- Media/Surveillance storage growth acceptable?

**Security Review**:
- Rotate AWS access keys (if desired)
- Review IAM permissions
- Check for unauthorized S3 access (CloudTrail)

---

## Monitoring Commands

### Storage Sizes
```bash
# Get CloudWatch historical data (last 7 days)
~/Documents/Warp\ Personal/vaxlan/synology/backup/scripts/get_aws_storage_report.sh 7

# Current bucket sizes (live)
aws s3 ls s3://vaxlan-synology-personal --recursive --summarize --human-readable --profile vaxocentric | tail -2
aws s3 ls s3://vaxlan-synology-media --recursive --summarize --human-readable --profile vaxocentric | tail -2
aws s3 ls s3://vaxlan-synology-surveillance --recursive --summarize --human-readable --profile vaxocentric | tail -2
```

### Check Storage Classes
```bash
# See what storage classes are being used
aws s3api list-objects-v2 --bucket vaxlan-synology-media --query "Contents[*].StorageClass" --output text --profile vaxocentric | sort | uniq -c
```

### Verify Lifecycle Policies
```bash
# Personal bucket
aws s3api get-bucket-lifecycle-configuration --bucket vaxlan-synology-personal --profile vaxocentric

# Check versioning status
aws s3api get-bucket-versioning --bucket vaxlan-synology-personal --profile vaxocentric
```

### List Backup Versions (Hyper Backup)
- Access via Hyper Backup interface in DSM
- Or browse S3: `s3://vaxlan-synology-personal/Personal.hbk/`

---

## Decision Log

### Major Decisions & Rationale

#### Decision 1: Uncompressed Backups (Personal)
**Date**: November 2025
**Choice**: Disabled compression in Hyper Backup
**Rationale**:
1. Direct S3 file access for disaster recovery flexibility
2. Independent recovery if Hyper Backup unavailable
3. Compression testing showed minimal savings (5-10%)
4. Files already compressed (photos, videos)
5. Build trust in backup/restore before adding encryption

**Trade-off**: ~5-10% higher storage cost vs. flexibility

#### Decision 2: No Transfer Encryption (Personal)
**Date**: November 2025, Reaffirmed January 2026
**Choice**: Disabled client-side encryption
**Rationale**:
1. Building trust in restore process first
2. Direct S3 file access needed
3. SSE-S3 provides encryption at rest
4. Risk of losing encryption key > risk of AWS access
5. Can enable later once confident in system

**Future**: Re-evaluate in 6-12 months

#### Decision 3: Smart Recycle Retention (Personal)
**Date**: November 2025
**Choice**: Smart Recycle vs. fixed version count
**Rationale**:
1. Balanced protection (hourly, daily, weekly, monthly)
2. Long-term recovery capability (monthly snapshots)
3. Automatic cleanup of old versions
4. Cost acceptable for critical data

**Alternative considered**: Keep last 15-30 versions (would save $4-5/month)

#### Decision 4: Option 1 Versioning Strategy (Personal)
**Date**: January 5, 2026
**Choice**: Disable S3 versioning, keep Hyper Backup Smart Recycle
**Rationale**:
1. S3 versioning redundant with Hyper Backup
2. Cost savings: ~$2-3/month
3. Hyper Backup provides sufficient protection
4. Smart Recycle keeps monthly snapshots for long-term recovery
5. Minimal risk increase

**Alternatives considered**:
- Option 2: Reduce Hyper Backup to 15 versions (higher risk for long-term recovery)
- Option 3: Both changes (too aggressive, lost long-term recovery)

#### Decision 5: Cloud Sync for Media (Not Hyper Backup)
**Date**: December 8, 2025
**Choice**: Cloud Sync with no versioning
**Rationale**:
1. Hyper Backup incompatible with Deep Archive access
2. Media files rarely need restoration
3. Would re-download rather than restore
4. Daily incremental sync sufficient
5. No versioning = lower cost

#### Decision 6: Real-Time Surveillance Sync
**Date**: November 2025
**Choice**: Cloud Sync real-time vs. scheduled backups
**Rationale**:
1. Primary use case: Prevent loss if NAS stolen/destroyed
2. Near-real-time upload critical for security footage
3. Lifecycle handles cost optimization (auto-tiering)
4. Small data volume (12 GB)

---

## AWS Account Information

**Account ID**: 823704761294
**Account Name**: vaxlan
**Region**: us-east-1

### IAM Users

**Admin User**: vaxocentric
- Purpose: Personal administrative access
- Permissions: Full AdministratorAccess
- Access: AWS CLI profile `vaxocentric`

**Service User**: nas-backup
- Purpose: Synology NAS backup operations
- Permissions: Limited to three S3 buckets (SynologyBackupAccess policy)
- Access: Used by Hyper Backup and Cloud Sync

### S3 Buckets

- vaxlan-synology-personal
- vaxlan-synology-media
- vaxlan-synology-surveillance

### Security

- All buckets: Public access blocked
- Encryption: SSE-S3 (server-side encryption)
- Access: IAM user credentials (least privilege)
- Versioning: Suspended (Personal), Disabled (Media, Surveillance)

---

## File Locations

### Documentation
- `backup/README.md` (this file)
- `backup/SETUP.md` (setup/rebuild instructions)
- `backup/CREDENTIALS.md` (credential placeholders)
- `backup/USAGE_TRACKING.md` (usage tracking documentation)

### Scripts
- `backup/scripts/get_aws_storage_report.sh`
- `backup/scripts/track_s3_usage.sh`

### Configuration
- `backup/config/lifecycle-personal.json` (7-day noncurrent expiration)
- `backup/config/lifecycle-media.json`
- `backup/config/lifecycle-surveillance.json`
- `backup/config/nas-backup-policy.json`

### Logs
- `backup/logs/s3_usage_log.csv`

---

## Quick Reference

### Emergency Restore Contacts
- AWS Support: https://console.aws.amazon.com/support/
- Synology Support: https://account.synology.com/support

### Access Credentials
- AWS credentials: Stored securely (see CREDENTIALS.md)
- Synology NAS: QuickConnect enabled
- Hyper Backup encryption password: Not currently set

### Critical Reminders
- ⚠️ S3 versioning suspended (Personal) - rely on Hyper Backup for versions
- ⚠️ Media has no versioning - rely on re-download capability
- ⚠️ Transfer encryption disabled - can enable once confident in restore process
- ⚠️ Old S3 versions cleaning up over 7-14 days (storage will decrease)

---

## Next Actions

### Short-term (Next 2 Weeks)
- [ ] Monitor Personal bucket storage decrease (should drop to 1.2-1.4 TB)
- [ ] Verify cost savings appear in AWS bill (~$5-6/month reduction)
- [ ] Test restore from Hyper Backup to ensure versioning still works

### Medium-term (Next 3 Months)
- [ ] Review Smart Recycle retention (still appropriate?)
- [ ] Consider enabling transfer encryption once comfortable with restore
- [ ] Evaluate if 1% growth rate projection is accurate

### Long-term (6-12 Months)
- [ ] Test full disaster recovery (complete NAS restore)
- [ ] Re-evaluate encryption strategy
- [ ] Consider additional cost optimizations if needed

---

**Document Version**: 2.0
**Status**: Current as of January 5, 2026
**Next Review**: April 2026
