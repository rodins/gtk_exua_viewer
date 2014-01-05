#!/bin/sh
# Лицензия: GNU GPL v.3.
# Copyright Sergey Rodin 2013
# GUI version

export currLink=$1
export playFile=$2

declare -a subtitleLinkArr
declare -a subtitleHeader

# Получение ссылок на субтитры
subtitlesLinks(){
	count=1
	while read line
	do 
	   if [ -n "$line" ]
	   then
	       subtitleLinkArr[$count]=$line 
	       (( count++ ))
	   fi
	done
	return $count
}<<EOF
$(curl -s $currLink | grep ".srt" | grep -o "<a href=[^<]\+" | grep -o "/get/[0-9]\+")
EOF
export -f subtitlesLinks

# Получение заголовков для субтитров
subtitlesHeaders(){
	count=1
	while read line
	do 
	   if [ -n "$line" ]
	   then
	       subtitleHeader[$count]=${line%*.*} # убрать расширение файла из заголовка
	       (( count++ ))
	   fi
	done
}<<EOF
$(curl -s $currLink | grep ".srt" | grep -o "<a href=[^<]\+" | cut -d'>' -f2)
EOF
export -f subtitlesHeaders

# Заполнение списка
resultsLst_Input(){
	subtitlesHeaders
	subtitlesLinks
	count=$?
	if [ $count -gt 1 ] 
	then
	    for (( i=1; i<$count; i++ ))
	    do
	        echo "${subtitleHeader[i]}|${subtitleLinkArr[i]}" | sed -e "s/&#39;/'/g" | sed -e "s/&quot;/'/g"
	    done
	fi
}
export -f resultsLst_Input

# Обработчик кнопки
playBtn_Click(){
	subtitleCommand="-sub http://www.ex.ua$resultsLst"
	mplayer -cache 1000 "$playFile" -subcp windows-1251 $subtitleCommand &
	exit 0
}
export -f playBtn_Click

gtkdialog --file=exua_subtitles.xml 