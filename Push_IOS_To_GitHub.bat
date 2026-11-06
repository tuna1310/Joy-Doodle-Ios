@echo off
title Push Joy Doodle iOS to GitHub
color 0A

echo ======================================================================
echo   DANG DAY MA NGUON JOY DOODLE IOS LEN GITHUB DE BUILD FILE .IPA
echo   Repository: https://github.com/tuna1310/Joy-Doodle-Ios
echo ======================================================================
echo.

git add .
git commit -m "Implement native Joy Doodle iOS (SwiftUI + Neon CoreGraphics)"
git push -u origin main --progress -v

echo.
if %ERRORLEVEL% EQU 0 (
    echo ======================================================================
    echo   DA DAY LEN GITHUB THANH CONG!
    echo   Vao Actions tren GitHub xem may chu Mac build file JoyDoodle.ipa nhe!
    echo ======================================================================
) else (
    echo ======================================================================
    echo   CO LOI TRONG QUA TRINH PUSH.
    echo ======================================================================
)
pause
