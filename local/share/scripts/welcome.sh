NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHTGRAY='\033[0;37m'
DARKGRAY='\033[1;30m'
LIGHTRED='\033[1;31m'
LIGHTGREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHTBLUE='\033[1;34m'
LIGHTPURPLE='\033[1;35m'
LIGHTCYAN='\033[1;36m'
WHITE='\033[1;37m'
COLUMNS=$(tput cols)
PADDING="\t"

echo -en "\n${CYAN}"
figlet -w $COLUMNS -c -f nancyj "Fr1nge"
echo -en ${NC}
footer="${BLUE}$(whoami)${NC}${YELLOW}@${NC}${RED}$(hostname)${NC}"
footer_nc="$(whoami)@$(hostname)"
printf "%*s" $((($COLUMNS-${#footer_nc})/2)) ""
echo -e "$footer"

echo ""
