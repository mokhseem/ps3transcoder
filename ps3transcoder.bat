@echo off
title PS3 Transcoder
chcp 866
cls

echo Выберите директорию для поиска файлов:
echo 1) Текущая папка
echo 2) Папка Загрузки
echo 3) Другая папка
choice /c 123 /m "Указать номер ответа"
if %ERRORLEVEL%==1 goto cwd
if %ERRORLEVEL%==2 goto userdldir
if %ERRORLEVEL%==3 goto etcdir

:cwd
echo Поиск файлов будет производиться в текущей папке
set srcdir=%~dp0
set srcdir=%srcdir:~0,-1%
goto subdirchk

:userdldir
echo Поиск файлов будет производиться в папке Загрузки
set srcdir=%USERPROFILE%\Downloads

:subdirchk
cd /d %srcdir%
choice /c yn /m "Выбрать подпапку"
if %ERRORLEVEL%==1 goto subdirsel
if %ERRORLEVEL%==2 goto input

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
set /p audiotrackcount=<temp.txt && del temp.txt
ffprobe -i "%input%" 2>&1 | find /c "Subtitle" > temp.txt
set /p intsubscount=<temp.txt && del temp.txt
echo Количество аудиодорожек: %audiotrackcount%
echo Количество субтитров: %intsubscount%
if %audiotrackcount% gtr 1 (goto audiotracksel) else (set audiotrack=0 && goto subschk)

:audiotracksel
echo Список аудиодорожек:
ffprobe -i "%input%" 2>&1 | find "Audio"
for /l %%i in (1,1,%audiotrackcount%) do set /p="%%i" <nul >> temp.txt
set /p audiotrackseq=<temp.txt && del temp.txt
choice /c %audiotrackseq% /m "Какую аудиодорожку использовать"
set audiotrack=%ERRORLEVEL% && set /a audiotrack-=1

:subschk
choice /c yn /m "Использовать внешние субтитры"
if %ERRORLEVEL%==1 goto extsubs
if %ERRORLEVEL%==2 goto intsubs

:extsubs
echo Укажите файл субтитров (только *.ass):
set /p extsubs=
set extsubs=%srcdir%\%extsubs:"=%
goto destdir

:intsubs
set subs=%input%
if %intsubscount%==0 goto extsubs
if %intsubscount%==1 (
  set intsubstrack=:si=0
  echo Выбраны субтитры по умолчанию
  goto destdir
) else (goto intsubstracksel)

:intsubstracksel
echo Список субтитров:
ffprobe -i "%input%" 2>&1 | find "Subtitle"
for /l %%i in (1,1,%intsubscount%) do set /p="%%i" <nul >> temp.txt
set /p intsubsseq=<temp.txt && del temp.txt
choice /c %intsubsseq% /m "Какие субтитры использовать"
set intsubstrack=%ERRORLEVEL% && set /a intsubstrack-=1
set intsubstrack=:si=%intsubstrack%

:destdir
choice /c yn /m "Использовать текущую папку для сохранения"
if %ERRORLEVEL%==1 cd /d %~dp0 && goto output
if %ERRORLEVEL%==2 echo Укажите полный путь к папке: && set /p destdir=
if not exist %destdir% mkdir %destdir%
cd /d %destdir%

:output
echo Придумайте название для конечного файла:
set /p output=
echo Перекодирование займет много времени и ресурсов процессора
pause

mkdir temp && cd temp
ffmpeg -i "%input%" -c copy -an mos.mkv
if defined extsubs (copy "%extsubs%" subs.ass && set subs=subs.ass) else (set subs=mos.mkv)
ffmpeg -i mos.mkv -vf subtitles=%subs%%intsubstrack% -sn hardsub.mkv && del mos.mkv
ffmpeg -i "%input%" -map 0:a:%audiotrack% -c copy -c:a ac3 dd.mkv
ffmpeg -i hardsub.mkv -i dd.mkv -c:v copy -c:a copy hardsub-dd.mkv && del hardsub.mkv dd.mkv

echo MUXOPT --no-pcr-on-video-pid --new-audio-pes --hdmv-descriptors --vbr  --vbv-len=500 > remux.meta
echo V_MPEG4/ISO/AVC, "%cd%\hardsub-dd.mkv", insertSEI, contSPS, track=1, lang=rus >> remux.meta
echo A_AC3, "%cd%\hardsub-dd.mkv", track=2, lang=jpn >> remux.meta
tsmuxer remux.meta "..\%output%.m2ts"

cd .. && rmdir /s /q temp
pause
exit
