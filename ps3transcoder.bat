@echo off
title PS3 Transcoder
cls
echo Текущая папка будет использована как рабочая
set cwd=%cd%
echo Укажи папку с исходным фильмом/сезоном:
set /p raw=
set raw=%raw:"=%
cd /d %raw% && dir /d
echo Выбери фильм/серию под хардсаб [Tab]:
set /p ep=
set ep=%raw%\%ep:"=%
choice /c yn /m "Cубтитры отдельным файлом"
set chksub=%errorlevel%
if %chksub% == 1 goto extsubs
if %chksub% == 2 goto intsubs
:extsubs
echo Выбери файл субтитров (только *.ass):
set /p sub=
set sub=%raw%\%sub:"=%
goto name
:intsubs
ffprobe -i "%ep%" 2>&1 | find "Subtitle"
echo Выбраны субтитры по-умолчанию
:name
cd /d %cwd%
echo Как будет называться фильм/серия на выходе?
set /p final=
mkdir temp && cd temp
echo Перекодирование займет много времени и ресурсов процессора
pause
ffmpeg -i "%ep%" -c copy -an mute.mkv
:hardsub
if %chksub% == 1 copy "%sub%" sub.ass && ffmpeg -i mute.mkv -vf "ass=sub.ass" hsub-mute.mkv
if %chksub% == 2 ffmpeg -i mute.mkv -vf subtitles=mute.mkv hsub-mute.mkv
del mute.mkv
:dolby
ffmpeg -i hsub-mute.mkv -vn -i "%ep%" -c:v copy -c copy -c:a ac3 -sn hsub-dd.mkv
del hsub-mute.mkv
:remux
echo MUXOPT --no-pcr-on-video-pid --new-audio-pes --hdmv-descriptors --vbr  --vbv-len=500 > remux.meta
echo V_MPEG4/ISO/AVC, "%cd%\hsub-dd.mkv", insertSEI, contSPS, track=1, lang=rus >> remux.meta
echo A_AC3, "%cd%\hsub-dd.mkv", track=2, lang=jpn >> remux.meta
tsmuxer remux.meta "..\%final%.m2ts"
:end
cd .. && rmdir /s /q temp
pause
exit
