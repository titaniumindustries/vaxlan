# S3 Usage Tracking

## Current Usage (2026-04-16 audit)

| Bucket | Size (GB) | Objects | Est. Storage Cost | Notes |
|--------|-----------|---------|-------------------|-------|
| **Personal** | 1,720 GB | 73,091 | $7.31 | 1,681 GB in IT-AIA; rest in IT-IA/FA |
| **Media** | 4,720 GB | ~121,239 | $4.67 | Down from 6,034 GB (Jan 2026) after Media.hbk delete |
| **Surveillance** | 11 GB | ~1,819 | $0.04 | Mostly Deep Archive |
| **TOTAL storage** | **~6,451 GB** | **~196K** | **~$12.02** | |
| + Standard-lag, requests, monitoring | | | ~$14 | Includes lifecycle-transition Standard overhead |
| **ACTUAL BILL (March 2026)** | | | **$28.93** | |
| **ACTUAL PROJECTED (April 2026)** | | | **~$25.80** | From AWS Cost Explorer partial month |

### Previous snapshot

| Date | Personal | Media | Surveillance | Total | Est. Cost |
|------|----------|-------|--------------|-------|-----------|
| 2026-01-04 | 1,679 GB / 69,731 obj | 6,034 GB / 121,239 obj | 12 GB / 1,819 obj | 7,726 GB / 192,789 obj | $24.49 (from old script, undercount) |

## Cost Breakdown by Storage Class

### Personal Bucket
- Storage Class: Intelligent-Tiering (Standard tier)
- Rate: $0.011/GB/month
- Versioning: Suspended (7-day noncurrent expiration)
- Notes: Uncompressed for direct S3 access

### Media Bucket  
- Storage Class: Deep Archive (after Day 0)
- Rate: $0.00099/GB/month
- Versioning: Disabled
- Notes: Via Cloud Sync, daily sync 2-8 AM

### Surveillance Bucket
- Storage Class: Lifecycle transitions
  - Days 0: Standard ($0.023/GB)
  - Days 1-90: Glacier IR ($0.004/GB)
  - Days 91+: Deep Archive ($0.00099/GB)
- Rate: ~$0.004/GB/month (average)
- Notes: Real-time Cloud Sync

---

## Daily Tracking

### Manual Tracking
Run the tracking script daily:
```bash
~/Documents/Warp\ Personal/vaxlan/synology/backup/scripts/track_s3_usage.sh
```

This appends data to `logs/s3_usage_log.csv` for tracking over time.

### Automated Daily Tracking (Optional)

Add to crontab to run daily at 11 PM:
```bash
# Edit crontab
crontab -e

# Add this line:
0 23 * * * ~/Documents/Warp\ Personal/vaxlan/synology/backup/scripts/track_s3_usage.sh >> /tmp/s3_tracking.log 2>&1
```

---

## CSV Log Format

The log file `logs/s3_usage_log.csv` contains:
- Date
- Personal: GB, Object count, Estimated cost
- Media: GB, Object count, Estimated cost  
- Surveillance: GB, Object count, Estimated cost
- Total: GB, Total estimated cost

### Example Usage

**View in terminal:**
```bash
column -t -s, ~/Documents/Warp\ Personal/vaxlan/synology/backup/logs/s3_usage_log.csv
```

**Import to spreadsheet:**
- Open Numbers/Excel
- Import CSV file
- Create charts for growth tracking

**Calculate monthly total:**
```bash
# Get current month's average cost
awk -F',' 'NR>1 && $1 ~ /^2026-01/ {sum+=$12; count++} END {print "Average: $"sum/count}' logs/s3_usage_log.csv
```

---

## Growth Analysis

### Track Growth Rate
```bash
# Compare first and last entries
head -2 logs/s3_usage_log.csv | tail -1
tail -1 logs/s3_usage_log.csv
```

### View Last 7 Days
```bash
tail -7 logs/s3_usage_log.csv | column -t -s,
```

---

## Cost Optimization Notes

### Personal Bucket (Largest Cost Driver)
Current: $18.47/month for 1,679 GB

**Potential savings:**
1. Reduce backup versions (currently Smart Recycle)
2. Disable S3 versioning (saves ~10%)
3. Archive old files to cheaper storage class

### Media Bucket (Most Efficient)
Current: $5.97/month for 6,034 GB (cheapest per GB)

Already optimized with Deep Archive.

### Surveillance Bucket (Minimal Cost)
Current: $0.05/month for 12 GB

Auto-tiering to cheap storage, no action needed.

---

## Storage Growth Expectations

Based on your stated 1% monthly growth:

| Month | Total GB | Est. Monthly Cost |
|-------|----------|-------------------|
| Current | 7,726 | $24.49 |
| +3 months | 7,962 | $25.24 |
| +6 months | 8,205 | $26.02 |
| +12 months | 8,694 | $27.59 |

---

## Manual S3 Commands

### Check Current Sizes
```bash
# Personal bucket
aws s3 ls s3://vaxlan-synology-personal --recursive --summarize --human-readable --profile vaxocentric | tail -2

# Media bucket  
aws s3 ls s3://vaxlan-synology-media --recursive --summarize --human-readable --profile vaxocentric | tail -2

# Surveillance bucket
aws s3 ls s3://vaxlan-synology-surveillance --recursive --summarize --human-readable --profile vaxocentric | tail -2
```

### Check Storage Classes
```bash
# See what storage classes are being used
aws s3api list-objects-v2 --bucket vaxlan-synology-media --query "Contents[*].StorageClass" --output text --profile vaxocentric | sort | uniq -c
```

---

## Monthly Cost Estimation

The tracking script estimates costs based on:
- **Personal**: $0.011/GB (Intelligent-Tiering Standard)
- **Media**: $0.00099/GB (Deep Archive)
- **Surveillance**: $0.004/GB (blended average across lifecycle)

**Actual AWS bill includes:**
- Storage costs (tracked above)
- API requests (~$0.01-0.10/month)
- Data transfer OUT (free for uploads, $0.09/GB after 100GB/month for downloads)

Your actual bill will be very close to tracked estimates since you rarely download/restore.

---

## Monitoring AWS Billing Dashboard

Check actual costs monthly:
1. Log into AWS Console (account 823704761294)
2. Go to: Billing Dashboard
3. View: Cost Explorer
4. Filter by: S3 service
5. Compare with tracking estimates

---

## Backup Correlation

Use the object count to correlate with backups:

**Personal (69,731 objects):**
- Hyper Backup versioning
- Smart Recycle retention
- Includes old versions (S3 versioning suspended, cleaning up)

**Media (121,239 objects):**
- Cloud Sync (no versioning)
- Should be ~1:1 with files on NAS

**Surveillance (1,819 objects):**
- Cloud Sync (real-time)
- Continuous accumulation until deleted locally

Track object count changes to identify when large backups occur.
