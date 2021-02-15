new=$(notmuch  search 'tag:inbox and tag:unread and NOT path:*/archive NOT tag:archive and NOT tag:spam and NOT tag:sent and NOT tag:draft' | wc -l)

if [[ $new != 0 ]]
then
dunstify --icon='/home/yigit/.icons/mail.png' -a 'New Email' "You have $new new mail."
fi

echo $new > /home/yigit/.config/mail_num
