#!/bin/sh
# Лицензия: GNU GPL v.3.
# Copyright Sergey Rodin 2013
# GUI version

export fullLink=$1

declare -a playFile
declare -a serialTitle

# Получение адреса для нескольких файлов
serialDetect(){
	count=0
	playFile=( )
	while read line
	do 
	   if [ -n "$line" ]
	   then
	       playFile[$count]=$line 
	       (( count++ ))
	   fi
	done
	return $count
}<<EOF
$(curl -s $fullLink | grep -o 'http://www.ex.ua[^"]\+.flv')
EOF
export -f serialDetect

# Получение заголовков для нескольких файлов
serialHeaders(){
	count=0
	serialTitle=( )
	while read line
	do 
	   if [ -n "$line" ]
	   then
	       serialTitle[$count]=${line%*.*} # убрать расширение файла из заголовка
	       (( count++ ))
	   fi
	done
}<<EOF
$(curl -s $fullLink | grep "player_info" | grep -o '{[^}]\+}' | grep -o "'[^']\+'" | cut -d"'" -f2)
EOF
export -f serialHeaders

resultsLst_Input(){
	serialDetect
	serDetExit=$?
	serialHeaders
	for (( j=0; j<serDetExit; j++ ))
	do
	    # Вывод результатов в список
	    echo "${serialTitle[j]}|${playFile[j]}" | sed -e "s/&#39;/'/g" | sed -e "s/&quot;/'/g" 
	done
}
export -f resultsLst_Input

playBtn_Click(){
	if [ $chkSubtitles == "true" ]
	then 
	    # Запуск скрипта для поиска и выбора субтитров
	    # Если субтитры есть - открыть окно, если нет - начать воспроизведение
	    curl -s $fullLink | grep -q ".srt"
	    if [ $? -eq 0 ]
	    then
	        ./exua_subtitles.sh $fullLink $resultsLst &
	    else
	        mplayer -cache 1000 $resultsLst &
	    fi
	else
	    mplayer -cache 1000 $resultsLst &
	fi
}
export -f playBtn_Click

gtkdialog --file=exua_serial.xml 