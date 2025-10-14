@echo off
echo Setting up splash screen for Civic Pulse...
echo.

echo Installing dependencies...
flutter pub get

echo.
echo Generating native splash screen files...
flutter pub run flutter_native_splash:create

echo.
echo Generating app icons...
flutter pub run flutter_launcher_icons:main

echo.
echo Splash screen setup complete!
echo.
echo To test the app:
echo flutter run
echo.
pause
