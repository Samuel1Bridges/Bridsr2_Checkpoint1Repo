#!/bin/bash
LOG_FILE="sys_log.txt"
REPORT="log_report.txt"

# Check if file exists
if [ -f "$LOG_FILE" ]; then
    echo "File exists"
else
    echo "Error: File doesn't exist" >&2
    exit 1
fi

# Check if file is readable
if [ -r "$LOG_FILE" ]; then
    echo "File is readable"
else
    echo "Error: File isn't readable" >&2
    exit 1
fi

# Check if file has contents
if [ -s "$LOG_FILE" ]; then
    echo "File is full"
else
    echo "Error: File is empty" >&2
    exit 1
fi

{
        echo "=============================================="
        echo " SYSTEM LOG REPORT"
        echo " Generated : $(date '+%Y-%m%d %H:%M:%S')"
        echo " Log file  : $LOG_FILE"
	echo "=============================================="
} > "$REPORT" #sending  text to report file

#counting  files
TOTAL=$(wc -l < "$LOG_FILE")

echo "Total lines analysed: $TOTAL" >> "$REPORT"

echo "Activity by Service" >> "$REPORT"

#sorting services by activity 
awk '{print $5}' "$LOG_FILE" | sed 's/\[[0-9]*\]//; s/:$//' | sort | uniq -c | sort -rn >> "$REPORT"



# Count problem lines
PROBLEMS=$(grep -Eic 'error|fail|critical|denied|warning' "$LOG_FILE")

#calculates percentage 
PERCENT=$((PROBLEMS * 100 / TOTAL))

echo "PROBLEM LINES: $PROBLEMS of $TOTAL ($PERCENT%)" >> "$REPORT"

echo "TOP 5 SERVICES BY PROBLEM LINES" >> "$REPORT"

#finds responsable service
grep -Ei 'error|fail|critical|denied|warning' "$LOG_FILE" |

#  gets service feild , counts them, sorts them least, aand takes the top 5 problem services
awk '{print $5}' | sed 's/\[[0-9]*\]//; s/:$//' | sort | uniq -c | sort -rn | head -5 >> "$REPORT"
