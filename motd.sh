#!/bin/bash
# motd.sh - A script to display system information in the message of the day (MOTD)
# Created by februu @github.com/februu

COLOR1="\e[38;5;220m" 
COLOR2="\e[38;5;214m"  
COLOR3="\e[38;5;208m"  
COLOR4="\e[38;5;202m" 
RESET="\e[0m" 
WHITE="\e[97m" 
SPACER=$(echo -e "   \e[38;5;165m>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\e[0m")

# Get system info
[ -r /etc/lsb-release ] && . /etc/lsb-release
TIME=$(date | awk '{print $1 " " $2 " " $3 " " $6 " " $4 " " $5}')
UPTIME=$(uptime -p)
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4 "%"}')
MEM_USAGE=$(free -h --si | awk '/Mem:/ {print $3 "B / " $2 "B"}')
DISK_USAGE=$(df -h / | awk 'NR==2 {print $3 "B / " $2 "B"}')
LOGGED_IN_USERS=$(who | wc -l)
LAST_LOGIN=$(last -n 1 | head -1 | awk '{print $4 " " $5 " " $6 " " $7 ", " $3}')

# Print ASCII banner
# You can replace this with your own ASCII art. https://patorjk.com/software/taag/ is a good place to start :)
echo
echo -e "${COLOR1}  _____     ___.                                    "
echo -e "${COLOR2}_/ ____\____\_ |_________ __ _____  ________  ______"
echo -e "${COLOR3}\   __\/ __ \| __ \_  __ \  |  \  \/ /\____ \/  ___/"
echo -e "${COLOR4} |  | \  ___/| \_\ \  | \/  |  /\   / |  |_> >___ \ "
echo -e "${COLOR3} |__|  \___  >___  /__|  |____/  \_/  |   __/____  >"
echo -e "${COLOR2}           \/    \/                   |__|       \/${RESET}"
echo

echo "${SPACER}"

# Print system information
echo
echo -e " * ${WHITE}System Version:       ${COLOR1}$DISTRIB_DESCRIPTION${RESET}"
echo -e " * ${WHITE}Server Time:          ${COLOR1}$TIME${RESET}"
echo -e " * ${WHITE}Uptime:               ${COLOR2}${UPTIME:3}${RESET}"
echo -e " * ${WHITE}CPU Usage:            ${COLOR3}$CPU_USAGE${RESET}"
echo -e " * ${WHITE}Memory Usage:         ${COLOR4}$MEM_USAGE${RESET}"
echo -e " * ${WHITE}Disk Usage:           ${COLOR3}$DISK_USAGE${RESET}"
echo -e " * ${WHITE}Logged-in Users:      ${COLOR2}$LOGGED_IN_USERS${RESET}"
echo -e " * ${WHITE}Last Login:           ${COLOR1}$LAST_LOGIN${RESET}"
echo

echo "${SPACER}"

echo

TMUX_SESSIONS=$(tmux list-sessions 2>/dev/null | wc -l)
if [ "$TMUX_SESSIONS" -gt 0 ]; then
        echo -e " \e[97;46m[!] $TMUX_SESSIONS tmux sessions currently running.${RESET}"
        echo
fi

UPDATE_COUNT=$(apt list --upgradable 2>/dev/null | grep -c "upgradable")
if [ "$UPDATE_COUNT" -gt 0 ]; then
        echo -e " \e[97;42m[!] $UPDATE_COUNT updates available.${RESET}"
        echo
fi

if [ -f /var/run/reboot-required ]; then
        echo -e " \e[97;42m[!] System reboot required.${RESET}"
        echo
fi