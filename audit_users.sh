#!/bin/bash


csv_file="users.csv"
LOG_FILE="/var/log/user_audit.log"

# final report holders
total=0
errors=0
compliant=0
fixxed=0
# logger file creating timestamped log reports
log()  {
	sudo echo "$(date '+%Y -%M_%D %H:%M_%S') $*" >> "$LOG_FILE"
}

# starts reading file
 while IFS=',' read -r name role shell; do
	((total++))
	#Skips empty lines
	if [[ -z "$name" ||  -z "$role" || -z "$shell" ]]; then
	log "Error: empty Field"
	((errors++)) 
	continue
	fi
	#If  name starts with letters
	if [[ "$name" =~ ^[a-z][a-z0-9_-]*$  ]]; then
	:
	else
        log  "Error: Invaid Username"
	((errors++))
	continue
	fi

	# Checks length of name 
	if [[ "${#name}" -gt 32 ]]; then 
	log "Error: exceeds 32 character limit"
	((errors++))
	continue
	fi

#Checks if  user exists
if id "$name" &>/dev/null; then
    echo "User exists"
	log "Compliant: User Exists"
	((Compliant++))

else
#addes user if user doesn't exist
   sudo  useradd  -m -s "$shell" "$name"
    log "Error: User doesn't exist and User created"
   ((fixxed++)) 

continue
fi

#check shell if its correct
if id "$name" &>/dev/null; then
	currentShell=$(getent passwd "$name" | cut -d: -f7)
	echo "$shell or $currentShell"

if [[ "$currentShell" == "$shell" ]]; then
    log "Compliant: Shells Matches"
else
    sudo usermod -s "$shell" "$name"
    log "Fixed: Shell mismatch fixed"
    ((fixxed++))
fi
fi

#Splits groups apart
IFS='/' read -ra groups <<< "$role"

for group in "${groups[@]}"; do
#checks if groups exist
    if getent group "$group" >/dev/null; then
        log "Compliant: group $group exists"
    else
#creates  group if doesn't exist
        log "Fixed: group $group created"
        groupadd "$group"
        ((fixxed++)) 
 fi
# adds user to groups
    usermod -aG "$group" "$name"

done

owner=$(ls -ld "/home/$name" | awk '{print $3}')

if [ "$owner" = "$name" ]; then
    log "Compliant: $name owns /home/$name"
else
    chown "$name" "/home/$name"
    log "Error: $name does not own /home/$name"
    ((fixxed++))
fi


echo "DEBUG: fixxed = $fixxed"
#finished reading files
done < <(tail -n +2 "$csv_file")


# prints final report
echo ""
echo "===== AUDIT SUMMARY ====="
echo "Total lines read: $total"
echo "Total errors:     $errors"
echo "Total compliant:  $compliant"
echo "Total fixxed:     $fixxed"
