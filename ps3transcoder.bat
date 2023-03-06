@echo off
title PS3 Transcoder
cls
echo v0.3.2
echo Текущая папка будет использована как рабочая
set cwd=%cd%
echo Укажи папку с исходным фильмом/сезоном:
set /p raw=
set raw=%raw:"=%
cd /d %raw%
dir /d
echo Выбери фильм/серию под хардсаб [Tab]:
set /p ep=
set ep=%ep:"=%
set ep=%raw%\%ep%
choice /c yn /m "Cубтитры отдельным файлом"
set chksub=%errorlevel%
if %chksub% == 1 echo Выбери файл субтитров (только *.ass): && goto extsubs
if %chksub% == 2 echo Будут взяты первые субтитры из контейнера && goto name
:extsubs
set /p sub=
set sub=%sub:"=%
set sub=%raw%\%sub%
:name
cd /d %cwd%
echo Как будет называться фильм/серия на выходе?
set /p final=
mkdir temp && cd temp
echo Перекодирование займет много времени и ресурсов процессора
pause
rem Копия без звука
ffmpeg -i "%ep%" -c copy -an mute.mkv
rem Перекодирование в хардсаб
if %chksub% == 1 copy "%sub%" sub.ass && ffmpeg -i mute.mkv -vf "ass=sub.ass" hsub-mute.mkv
if %chksub% == 2 ffmpeg -i mute.mkv -vf "subtitles=mute.mkv:stream_index=0" hsub-mute.mkv
del mute.mkv
rem Перекодирование звука в Долби
ffmpeg -sn -i hsub-mute.mkv -vn -sn -i "%ep%" -c:v copy -c copy -c:a ac3 hsub-dd.mkv
del hsub-mute.mkv
rem Муксинг в блюрей-контейнер
echo MUXOPT --no-pcr-on-video-pid --new-audio-pes --hdmv-descriptors --vbr  --vbv-len=500 > remux.meta
echo V_MPEG4/ISO/AVC, "%cd%\hsub-dd.mkv", insertSEI, contSPS, track=1, lang=rus >> remux.meta
echo A_AC3, "%cd%\hsub-dd.mkv", track=2, lang=jpn >> remux.meta
tsmuxer remux.meta remux.m2ts
move remux.m2ts "..\%final%.m2ts" && cd ..
rmdir /s /q temp
pause
exit