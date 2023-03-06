@echo off
title PS3 Transcoder
cls
echo v0.3.2
echo ������ ����� �㤥� �ᯮ�짮���� ��� ࠡ���
set cwd=%cd%
echo ����� ����� � ��室�� 䨫쬮�/ᥧ����:
set /p raw=
set raw=%raw:"=%
cd /d %raw%
dir /d
echo �롥� 䨫�/��� ��� ��ᠡ [Tab]:
set /p ep=
set ep=%ep:"=%
set ep=%raw%\%ep%
choice /c yn /m "C����� �⤥��� 䠩���"
set chksub=%errorlevel%
if %chksub% == 1 echo �롥� 䠩� ����஢ (⮫쪮 *.ass): && goto extsubs
if %chksub% == 2 echo ���� ����� ���� ������ �� ���⥩��� && goto name
:extsubs
set /p sub=
set sub=%sub:"=%
set sub=%raw%\%sub%
:name
cd /d %cwd%
echo ��� �㤥� ���뢠���� 䨫�/��� �� ��室�?
set /p final=
mkdir temp && cd temp
echo ��४���஢���� ������ ����� �६��� � ����ᮢ ������
pause
rem ����� ��� ��㪠
ffmpeg -i "%ep%" -c copy -an mute.mkv
rem ��४���஢���� � ��ᠡ
if %chksub% == 1 copy "%sub%" sub.ass && ffmpeg -i mute.mkv -vf "ass=sub.ass" hsub-mute.mkv
if %chksub% == 2 ffmpeg -i mute.mkv -vf "subtitles=mute.mkv:stream_index=0" hsub-mute.mkv
del mute.mkv
rem ��४���஢���� ��㪠 � �����
ffmpeg -sn -i hsub-mute.mkv -vn -sn -i "%ep%" -c:v copy -c copy -c:a ac3 hsub-dd.mkv
del hsub-mute.mkv
rem ��ᨭ� � ���३-���⥩���
echo MUXOPT --no-pcr-on-video-pid --new-audio-pes --hdmv-descriptors --vbr  --vbv-len=500 > remux.meta
echo V_MPEG4/ISO/AVC, "%cd%\hsub-dd.mkv", insertSEI, contSPS, track=1, lang=rus >> remux.meta
echo A_AC3, "%cd%\hsub-dd.mkv", track=2, lang=jpn >> remux.meta
tsmuxer remux.meta remux.m2ts
move remux.m2ts "..\%final%.m2ts" && cd ..
rmdir /s /q temp
pause
exit