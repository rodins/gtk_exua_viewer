#!/bin/sh

searchTxt_onChange(){
	if [ -z "$searchTxt" ]
	then echo false
	elif [ -n "$searchTxt" ]
	then echo true
	fi
}
export -f searchTxt_onChange

# Проверка подключения к Интернет
internet_status() {
  LANG=C route | grep -q 'default[ ].*[ ]0\.0\.0\.0[ ]' && grep -wq 'nameserver' /etc/resolv.conf #&& ping -c1 google.com &>/dev/null
}
export -f internet_status

searchBtn_Click(){
	if ! internet_status; then
        gtkdialog-splash -icon gtk-dialog-error  -fontsize large  -text "Проверьте подключение к Интернет"
    else
        # Проверка на наличие ссылки
        echo "$searchTxt" | grep -q '^http://www.ex.ua/[0-9]\+'
        if [ $? -eq 0 ]
        then
            ./exua_serial.sh "$searchTxt" &
        else
            ./exua_searchres.sh "$searchTxt" 0 &
        fi
    fi
}
export -f searchBtn_Click

gtkdialog --file=exua_viewer.xml 
