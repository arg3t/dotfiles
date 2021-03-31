#!/bin/sh

# Put the message, send to stdin, in a variable
m="$(cat -)"
m64="$(echo -e "$m" | base64)"
echo "$m64" > /tmp/test2
tracking_url=$(/home/yigit/.local/share/bin/gen_tracking_url "$m64" 2> /tmp/testerr)
echo $tracking_url > /tmp/test3
# Look at the first argument,
# Use it to determine the account to use
# If not set, assume work
# All remaining arguments should be recipient addresses which should be passed to msmtp
account="$1"

shift 1
cleanHeaders(){
    # In the headers, delete any lines starting with markdown
    cat - | sed '0,/^$/{/^markdown/Id;}'
}

echo "$@"
echo "$message" | cleanHeaders > /tmp/headers
echo "msmtp -a $account $@"
echo "$message" | sed '/^$/q' | grep -q -i 'markdown: true' \
    && msg=$(echo "$message  \n$tracking_url" | cleanHeaders | /home/yigit/.local/share/bin/convertToHtmlMultipart && echo 1 >> /tmp/state) || msg=$(echo "$message" | cleanHeaders)
echo "$msg" > /tmp/test
echo "$msg" | notmuch insert --folder="$account/sent" +sent -inbox
echo "$msg" | msmtp -a $account $@
