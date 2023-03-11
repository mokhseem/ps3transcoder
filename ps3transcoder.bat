@echo off
title PS3 Transcoder
chcp 866
cls
echo Выберите директорию для поиска файлов:
echo 1) Текущая папка
echo 2) Папка Загрузки
echo 3) Другая папка
choice /c 123 /m "Указать номер ответа"
if %errorlevel% == 1 goto currdir
if %errorlevel% == 2 goto udldir
if %errorlevel% == 3 goto etcdir
:currdir
echo Поиск файлов будет производиться в текущей папке
set srcdir=%~dp0
set srcdir=%srcdir:~0,-1%
goto subdirchk
:udldir
echo Поиск файлов будет производиться в папке Загрузки
set srcdir=%userprofile%\Downloads
goto subdirchk
:subdirchk
cd /d %srcdir%
choice /c yn /m "Выбрать подпапку"
if %errorlevel% == 1 goto subdirsel
if %errorlevel% == 2 goto input
:subdirsel
dir /a:d
echo Введите название подпапки:
set /p subdir=
set srcdir=%srcdir%\%subdir:"=%
goto input
:etcdir
echo Укажите полный путь к папке:
set /p srcdir=
set srcdir=%srcdir:"=%
:input
cd /d %srcdir% && dir
echo Выберите видеофайл [Tab]:
set /p input=
set input=%srcdir%\%input:"=%
ffprobe -i "%input%" 2>&1 | find /c "Audio" > temp.txt
set /p atrct=<temp.txt && del temp.txt
ffprobe -i "%input%" 2>&1 | find /c "Subtitle" > temp.txt
set /p strct=<temp.txt && del temp.txt
echo Количество аудиодорожек: %atrct%
echo Количество субтитров: %strct%
if %atrct% gtr 1 (goto atrsel) else (set atr=0 && goto subschk)
:atrsel
echo Список аудиодорожек:
ffprobe -i "%input%" 2>&1 | find "Audio"
for /l %%i in (1,1,%atrct%) do set /p="%%i" <nul >> temp.txt
set /p atrseq=<temp.txt && del temp.txt
choice /c %atrseq% /m "Какую аудиодорожку использовать"
set atr=%errorlevel%
set /a atr-=1
:subschk
choice /c yn /m "Использовать внешние субтитры"
if %errorlevel% == 1 goto extsubs
if %errorlevel% == 2 goto intsubs
:extsubs
echo Укажите файл субтитров (только *.ass):
set /p extsubs=
set extsubs=%srcdir%\%extsubs:"=%
goto destdir
:intsubs
set subs=%input%
if %strct% == 0 goto extsubs
if %strct% == 1 set str=:si=0 && echo Выбраны субтитры по умолчанию && goto destdir
if %strct% gtr 1 goto strsel
:strsel
echo Список субтитров:
ffprobe -i "%input%" 2>&1 | find "Subtitle"
for /l %%i in (1,1,%strct%) do set /p="%%i" <nul >> temp.txt
set /p strseq=<temp.txt && del temp.txt
choice /c %strseq% /m "Какие субтитры использовать"
set str=%errorlevel%
set /a str-=1
set str=:si=%str%
:destdir
choice /c yn /m "Использовать текущую папку для сохранения"
if %errorlevel% == 1 cd /d %~dp0 && goto output
if %errorlevel% == 2 echo Укажите полный путь к папке: && set /p destdir=
if not exist %destdir% mkdir %destdir%
cd /d %destdir%
:output
echo Придумайте название для конечного файла:
set /p output=
echo Перекодирование займет много времени и ресурсов процессора
pause
mkdir temp && cd temp
ffmpeg -i "%input%" -c copy -an mos.mkv
:hardsub
if defined extsubs (copy "%extsubs%" subs.ass && set subs=subs.ass) else (set subs=mos.mkv)
ffmpeg -i mos.mkv -vf subtitles=%subs%%str% -sn hardsub.mkv && del mos.mkv
:dolby
ffmpeg -i "%input%" -map 0:a:%atr% -c copy -c:a ac3 dd.mkv
:mux
ffmpeg -i hardsub.mkv -i dd.mkv -c:v copy -c:a copy hardsub-dd.mkv && del hardsub.mkv dd.mkv
:remux
echo MUXOPT --no-pcr-on-video-pid --new-audio-pes --hdmv-descriptors --vbr  --vbv-len=500 > remux.meta
echo V_MPEG4/ISO/AVC, "%cd%\hardsub-dd.mkv", insertSEI, contSPS, track=1, lang=rus >> remux.meta
echo A_AC3, "%cd%\hardsub-dd.mkv", track=2, lang=jpn >> remux.meta
tsmuxer remux.meta "..\%output%.m2ts"
:end
cd .. && rmdir /s /q temp
pause
exit
