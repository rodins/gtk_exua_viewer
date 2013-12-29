#!/bin/bash
# Лицензия: GNU GPL v.3.
# Copyright Sergey Rodin 2013
# GUI version

export searchRequest="$1"
export page=$2
if [ $page -gt 0 ]
then export search="s=$searchRequest&p=$page"
else export search="s=$searchRequest"
fi

export resFile=$searchRequest$page.txt

export searchPattern='player_list'
export emergencyExit=0

showRequest(){
	echo -n "<b>Запрос:</b> <i><span color='darkgreen'>$searchRequest</span></i>"
    (( page++ ))
	echo " <b>Страница:</b> <span color='darkgreen'>$page</span>"
	(( page-- ))
	:> $resFile
}
export -f showRequest

searchPb_Input1(){ 
	echo 100
}
export -f searchPb_Input1

searchPb_Input(){
	:> "MAYHANGUP$resFile"
	echo "Подождите. Обработка информации..."
	i=1
	pbCount=0
	while read line
	do
	# Аварийный выход из скрипта
	if [[ -e "STOP$resFile" ]]
	then 
	rm "STOP$resFile"
	exit
	fi
	# Информация для progressbar
	let "x=($pbCount*100)/20"
	echo $x
	(( pbCount++ ))
	if [ -n "$searchRequest" ]
	then
	    link=$(echo $line | grep -o '/[0-9]\+')
	    title=$(echo $line | grep -o '>[^<]\+.<'| cut -d '>' -f2 | cut -d '<' -f1 | sed -e "s/|/-/g")
	    fullLink="http://www.ex.ua$link"
	    # Отображать ссылку только если на странице существует flv-файл
	    getFlv=$(curl -s $fullLink | grep -o 'http://www.ex.ua[^"]\+.flv')
	    # sed возвращает new line \n, потерянную при переходе в переменную
	    # теперь grep может правильно посчитать число ссылок и определить сериал это или нет
	    isSerial=$(echo $getFlv | sed -e "s% %\n%g" | grep -c '.flv')
	    playFlv=$(echo $getFlv | grep -m1 '.flv' | cut -d ' ' -f1)
	    if [ $isSerial -gt 0 ]
	    then
	        if [ $isSerial -gt 1 ]
	        then
	            icon="mini-Filesystem-filemanager"
	        else
	            icon="mini-Multimedia-video"
	        fi
	        # Вывод результатов в файл, sed используется для замены HTML-сущностей
	        echo "$i | $icon | $title | $playFlv | $isSerial | $fullLink" | sed -e "s/&#39;/'/g" | sed -e "s/&quot;/'/g" >> $resFile
	        (( i++ )) 
	    fi
	fi
	done
	echo 100
	echo "Поиск завершен"
	rm "MAYHANGUP$resFile"
}<<EOF
$(curl -s http://www.ex.ua/search?"$search"| grep '^<tr><td><a href=' | grep -o "</a><a href='/[0-9]\+'><b>[^<]\+.</b>")
EOF

export -f searchPb_Input

playBtn_Click(){
	selectedItem=$(grep "^$resultsLst" "$resFile")
	isSerial=$(echo $selectedItem | cut -d'|' -f5)
	if [ $isSerial -eq 1 ]
	then
	    if [ $chkSubtitles == "true" ]
	    then # Запуск скрипта для поиска и выбора субтитров
	        # Если субтитры есть - открыть окно, если нет - начать воспроизведение
	        curl -s $(echo $selectedItem | cut -d'|' -f6) | grep -q ".srt"
	        if [ $? -eq 0 ]
	        then
	             ./exua_subtitles.sh $(echo $selectedItem | cut -d'|' -f6) $(echo $selectedItem | cut -d'|' -f4) &
	        else
	            mplayer -cache 1000 $(echo $selectedItem | cut -d'|' -f4) &
	        fi   
	    else
	        mplayer -cache 1000 $(echo $selectedItem | cut -d'|' -f4) &
	    fi
    else
        # Вывод списка нескольких видеофайлов
        ./exua_serial.sh $(echo $selectedItem | cut -d'|' -f6) &
    fi
}
export -f playBtn_Click

window_OnClose(){
	# При закрытии окна создать файл который остановит фоновые процессы
	if [[ -e MAYHANGUP$resFile ]]
	then
	    :> "STOP$resFile"
	    sleep 3
	    # Через три секунды удалить этот файл
	    if [[ -e "STOP$resFile" ]]
	    then 
	    rm "STOP$resFile"
	    exit
	    fi
	    rm "MAYHANGUP$resFile"
	fi
	# Также удалить файл со списком результатов поиска
	if [[ -e "$resFile" ]]
	then 
	rm "$resFile"
	#echo "Debug mode, deletion disabled"
	fi
	if [[ -e "selectedItem$resFile" ]]
	then
	rm "selectedItem$resFile"
	fi
}
export -f window_OnClose

nextBtn_Click(){
	(( page++ ))
	./exua_searchres.sh "$searchRequest" $page &
}
export -f nextBtn_Click

gtkdialog --file=exua_searchres.xml 
