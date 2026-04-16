#!/bin/bash
# Daily S3 Storage Usage Tracker
# Run this daily to track storage growth and costs

DATE=$(date +%Y-%m-%d)
OUTPUT_FILE="$HOME/Documents/Warp Personal/vaxlan/synology/backup/logs/s3_usage_log.csv"

# Create CSV header if file doesn't exist
if [ ! -f "$OUTPUT_FILE" ]; then
    echo "Date,Personal_GB,Personal_Objects,Personal_Cost,Media_GB,Media_Objects,Media_Cost,Surveillance_GB,Surveillance_Objects,Surveillance_Cost,Total_GB,Total_Cost" > "$OUTPUT_FILE"
fi

# Get Personal bucket stats
PERSONAL_DATA=$(aws s3api list-objects-v2 --bucket vaxlan-synology-personal --query "[sum(Contents[].Size), length(Contents[])]" --profile vaxocentric 2>/dev/null)
PERSONAL_BYTES=$(echo "$PERSONAL_DATA" | jq '.[0]')
PERSONAL_OBJECTS=$(echo "$PERSONAL_DATA" | jq '.[1]')
PERSONAL_GB=$(echo "scale=2; $PERSONAL_BYTES / 1073741824" | bc)
PERSONAL_COST=$(echo "scale=2; $PERSONAL_GB * 0.011" | bc)

# Get Media bucket stats
MEDIA_DATA=$(aws s3api list-objects-v2 --bucket vaxlan-synology-media --query "[sum(Contents[].Size), length(Contents[])]" --profile vaxocentric 2>/dev/null)
MEDIA_BYTES=$(echo "$MEDIA_DATA" | jq '.[0]')
MEDIA_OBJECTS=$(echo "$MEDIA_DATA" | jq '.[1]')
MEDIA_GB=$(echo "scale=2; $MEDIA_BYTES / 1073741824" | bc)
MEDIA_COST=$(echo "scale=2; $MEDIA_GB * 0.00099" | bc)

# Get Surveillance bucket stats
SURV_DATA=$(aws s3api list-objects-v2 --bucket vaxlan-synology-surveillance --query "[sum(Contents[].Size), length(Contents[])]" --profile vaxocentric 2>/dev/null)
SURV_BYTES=$(echo "$SURV_DATA" | jq '.[0]')
SURV_OBJECTS=$(echo "$SURV_DATA" | jq '.[1]')
SURV_GB=$(echo "scale=2; $SURV_BYTES / 1073741824" | bc)
# Surveillance uses lifecycle - first day Standard, then Glacier IR, then Deep Archive
# Using average cost estimate of $0.004/GB
SURV_COST=$(echo "scale=2; $SURV_GB * 0.004" | bc)

# Calculate totals
TOTAL_GB=$(echo "scale=2; $PERSONAL_GB + $MEDIA_GB + $SURV_GB" | bc)
TOTAL_COST=$(echo "scale=2; $PERSONAL_COST + $MEDIA_COST + $SURV_COST" | bc)

# Append to CSV
echo "$DATE,$PERSONAL_GB,$PERSONAL_OBJECTS,$PERSONAL_COST,$MEDIA_GB,$MEDIA_OBJECTS,$MEDIA_COST,$SURV_GB,$SURV_OBJECTS,$SURV_COST,$TOTAL_GB,$TOTAL_COST" >> "$OUTPUT_FILE"

# Display current stats
echo "S3 Usage Report - $DATE"
echo "=================================="
echo "Personal:     ${PERSONAL_GB} GB (${PERSONAL_OBJECTS} objects) = \$${PERSONAL_COST}/month"
echo "Media:        ${MEDIA_GB} GB (${MEDIA_OBJECTS} objects) = \$${MEDIA_COST}/month"
echo "Surveillance: ${SURV_GB} GB (${SURV_OBJECTS} objects) = \$${SURV_COST}/month"
echo "=================================="
echo "TOTAL:        ${TOTAL_GB} GB = \$${TOTAL_COST}/month"
echo ""
echo "Log saved to: $OUTPUT_FILE"
