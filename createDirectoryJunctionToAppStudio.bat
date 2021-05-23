::  ---Create a directory junction link
::  Between the code folder in this repo and the current user's AppStudio
::  apps directory.

@ECHO OFF
FOR %%I IN (.) DO SET CurrentD=%%~nI%%~xI
echo Name of project folder: %CurrentD%
echo User Profile directory: %UserProfile%
echo.
mklink /J "%UserProfile%\ArcGIS\AppStudio\Apps\%CurrentD%" %~dp0code

pause
