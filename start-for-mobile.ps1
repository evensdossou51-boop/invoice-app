# PowerShell script to start Flask and ngrok for mobile testing

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  INVOICE APP MOBILE TEST SETUP" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Flask is already running
$flaskProcess = Get-Process python -ErrorAction SilentlyContinue | Where-Object {$_.CommandLine -like "*app.py*"}
if ($flaskProcess) {
    Write-Host "Flask is already running (PID: $($flaskProcess.Id))" -ForegroundColor Yellow
    Write-Host "Stopping existing Flask process..." -ForegroundColor Yellow
    Stop-Process -Id $flaskProcess.Id -Force
    Start-Sleep -Seconds 2
}

# Start Flask
Write-Host "Starting Flask app..." -ForegroundColor Green
$flaskJob = Start-Job -Name "FlaskApp" -ScriptBlock {
    cd "C:\Users\evens\invoice-app"
    python app.py
}

Write-Host "Waiting for Flask to start..." -ForegroundColor Green
Start-Sleep -Seconds 5

# Check if Flask started successfully
if ($flaskJob.State -eq "Running") {
    Write-Host "✓ Flask app started successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Flask failed to start. Check app.py for errors." -ForegroundColor Red
    exit 1
}

# Check if ngrok exists
if (-not (Test-Path ".\ngrok.exe")) {
    Write-Host "Downloading ngrok..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-windows-amd64.zip" -OutFile "ngrok.zip"
    Expand-Archive ngrok.zip -DestinationPath . -Force
    Remove-Item ngrok.zip -ErrorAction SilentlyContinue
}

# Start ngrok
Write-Host "Starting ngrok tunnel..." -ForegroundColor Green
Start-Process -FilePath ".\ngrok.exe" -ArgumentList "http 5000" -NoNewWindow

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  SETUP COMPLETE!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Check the ngrok window for your mobile URL" -ForegroundColor White
Write-Host "2. Look for a line like: 'Forwarding https://abc-123.ngrok.io -> http://localhost:5000'" -ForegroundColor White
Write-Host "3. Open that URL on your mobile phone's browser" -ForegroundColor White
Write-Host ""
Write-Host "Press Ctrl+C in THIS window when you're done testing." -ForegroundColor Magenta
Write-Host "This will stop both Flask and ngrok." -ForegroundColor Magenta
Write-Host ""

# Keep running until user presses Ctrl+C
try {
    while ($true) {
        # Show status every 30 seconds
        Write-Host "Flask status: $($flaskJob.State) - $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray
        Start-Sleep -Seconds 30
    }
}
finally {
    Write-Host ""
    Write-Host "Cleaning up..." -ForegroundColor Yellow
    
    # Stop Flask job
    if ($flaskJob.State -eq "Running") {
        Stop-Job -Job $flaskJob -Force
        Remove-Job -Job $flaskJob -Force
    }
    
    # Stop ngrok processes
    $ngrokProcesses = Get-Process ngrok -ErrorAction SilentlyContinue
    if ($ngrokProcesses) {
        Stop-Process -Name ngrok -Force
    }
    
    Write-Host "All processes stopped. Goodbye!" -ForegroundColor Green
}
