#!/bin/bash
# Fetch S3 storage metrics from AWS CloudWatch
# AWS tracks these automatically - no need to calculate!

DAYS=${1:-30}  # Default to last 30 days, or specify as argument
PROFILE="vaxocentric"

echo "Fetching S3 Storage Metrics from AWS CloudWatch"
echo "Period: Last $DAYS days"
echo "=========================================="
echo ""

# Calculate start time
START_TIME=$(date -u -v-${DAYS}d +%Y-%m-%dT00:00:00)
END_TIME=$(date -u +%Y-%m-%dT23:59:59)

# Function to get bucket metrics and format output
get_bucket_metrics() {
    local BUCKET=$1
    local STORAGE_TYPE=$2
    local COST_PER_GB=$3
    
    echo "Bucket: $BUCKET ($STORAGE_TYPE)"
    echo "----------------------------------------"
    
    # Get metrics from CloudWatch
    METRICS=$(aws cloudwatch get-metric-statistics \
        --namespace AWS/S3 \
        --metric-name BucketSizeBytes \
        --dimensions Name=BucketName,Value=$BUCKET Name=StorageType,Value=$STORAGE_TYPE \
        --start-time $START_TIME \
        --end-time $END_TIME \
        --period 86400 \
        --statistics Average \
        --profile $PROFILE \
        --output json 2>/dev/null)
    
    # Parse and display sorted by date
    echo "$METRICS" | jq -r '.Datapoints | sort_by(.Timestamp) | .[] | 
        "\(.Timestamp[0:10]) | \((.Average / 1073741824) | floor) GB | $\(((.Average / 1073741824) * '$COST_PER_GB') | floor / 100)"' | \
        column -t -s'|'
    
    echo ""
}

# Personal bucket — Intelligent-Tiering has multiple sub-tiers, each reported separately in CloudWatch
#   FA  = Frequent Access (new objects, <30 days untouched)        $0.023/GB
#   IA  = Infrequent Access (30-90 days untouched)                 $0.0125/GB
#   AIA = Archive Instant Access (90+ days untouched) — auto tier  $0.004/GB
#   AA  = Archive Access (opt-in, 90-730 days)                     $0.0036/GB
#   DAA = Deep Archive Access (opt-in, 180+ days)                  $0.00099/GB
# Also include StandardStorage to catch lifecycle transition lag.
echo "=== vaxlan-synology-personal (all tiers) ==="
get_bucket_metrics "vaxlan-synology-personal" "StandardStorage" "0.023"
get_bucket_metrics "vaxlan-synology-personal" "IntelligentTieringFAStorage" "0.023"
get_bucket_metrics "vaxlan-synology-personal" "IntelligentTieringIAStorage" "0.0125"
get_bucket_metrics "vaxlan-synology-personal" "IntelligentTieringAIAStorage" "0.004"
get_bucket_metrics "vaxlan-synology-personal" "IntelligentTieringAAStorage" "0.0036"
get_bucket_metrics "vaxlan-synology-personal" "IntelligentTieringDAAStorage" "0.00099"

# Media bucket (Deep Archive). Also query StandardStorage to catch lifecycle-lag.
echo "=== vaxlan-synology-media ==="
get_bucket_metrics "vaxlan-synology-media" "StandardStorage" "0.023"
get_bucket_metrics "vaxlan-synology-media" "DeepArchiveStorage" "0.00099"

# Surveillance bucket (multiple storage types due to lifecycle)
echo "Bucket: vaxlan-synology-surveillance (Mixed Storage Classes)"
echo "----------------------------------------"
echo "Note: Surveillance uses lifecycle transitions (Standard→Glacier IR→Deep Archive)"
echo "Querying each storage class separately..."
echo ""

# Standard
echo "Standard Storage (Day 0):"
get_bucket_metrics "vaxlan-synology-surveillance" "StandardStorage" "0.023"

# Glacier IR
echo "Glacier Instant Retrieval (Days 1-90):"
aws cloudwatch get-metric-statistics \
    --namespace AWS/S3 \
    --metric-name BucketSizeBytes \
    --dimensions Name=BucketName,Value=vaxlan-synology-surveillance Name=StorageType,Value=GlacierInstantRetrievalStorage \
    --start-time $START_TIME \
    --end-time $END_TIME \
    --period 86400 \
    --statistics Average \
    --profile $PROFILE \
    --output json 2>/dev/null | jq -r '.Datapoints | sort_by(.Timestamp) | .[] | 
    "\(.Timestamp[0:10]) | \((.Average / 1073741824) | floor) GB | $\(((.Average / 1073741824) * 0.004) | floor / 100)"' | \
    column -t -s'|'
echo ""

# Deep Archive
echo "Deep Archive (Days 91+):"
get_bucket_metrics "vaxlan-synology-surveillance" "DeepArchiveStorage" "0.00099"

echo "=========================================="
echo "To export to CSV, redirect output:"
echo "  $0 $DAYS > storage_report.csv"
echo ""
echo "To see more/fewer days:"
echo "  $0 7   # Last 7 days"
echo "  $0 90  # Last 90 days"
