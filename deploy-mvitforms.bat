@echo off
echo Building Flutter Web App...
flutter build web --release

echo.
echo Deploying to mvitforms.web.app...
firebase deploy --only hosting:mvitforms

echo.
echo Deployment complete! 
echo Your app is now live at: https://mvitforms.web.app
pause