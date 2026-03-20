# ---------------- CONFIG ----------------
# $PHONE_IP = "192.168.1.105"

$USERNAME = "u0_a235"
$PORT = 8022

# Use CURRENT directory where script is executed
$BASE_DIR = Get-Location

# Local files on PC
$LOCAL_SYNC_SCRIPT = Join-Path $BASE_DIR "photo_sync.sh"
$LOCAL_DAEMON_SCRIPT = Join-Path $BASE_DIR "start_sync_daemon.sh"
$BOOT_DAEMON = Join-Path $BASE_DIR "start_daemon.sh"

# Remote paths in Termux
$REMOTE_HOME = "/data/data/com.termux/files/home"
$REMOTE_BOOT = "$REMOTE_HOME/.termux/boot"

Add-Type -AssemblyName Microsoft.VisualBasic

# Prompt user for IP address
$PHONE_IP = [Microsoft.VisualBasic.Interaction]::InputBox(
    "Enter your phone IP address:",
    "Termux Deployment",
    "192.168.1.106"
)

# Validate input
if ([string]::IsNullOrWhiteSpace($PHONE_IP)) {
    Write-Host "❌ No IP provided. Exiting." -ForegroundColor Red
    exit 1
}

# ---------------- FUNCTIONS ----------------

function Upload-IfExists {
    param (
        [string]$LocalFile,
        [string]$RemotePath,
        [string]$RemoteFileName
    )

    if (Test-Path $LocalFile) {
        Write-Host "Uploading $RemoteFileName..."

        scp -P $PORT $LocalFile "${USERNAME}@${PHONE_IP}:$RemotePath/$RemoteFileName"

        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Failed to upload $RemoteFileName" -ForegroundColor Red
            exit 1
        }

        Write-Host "✅ $RemoteFileName uploaded successfully." -ForegroundColor Green
    }
    else {
        Write-Host "⚠️ File not found: $LocalFile — skipping." -ForegroundColor Yellow
    }
}

# ---------------- START ----------------

Write-Host "🚀 Starting deployment..."

# Ensure Termux boot directory exists
Write-Host "📁 Ensuring ~/.termux/boot exists..."
ssh -p $PORT "${USERNAME}@${PHONE_IP}" "mkdir -p ~/.termux/boot"

# Upload main sync script to home
Upload-IfExists -LocalFile $LOCAL_SYNC_SCRIPT -RemotePath $REMOTE_HOME -RemoteFileName "photo_sync.sh"

# Upload daemon script to Termux folder
Upload-IfExists -LocalFile $LOCAL_DAEMON_SCRIPT -RemotePath $REMOTE_HOME -RemoteFileName "start_sync_daemon.sh"

# Upload daemon script to Termux boot folder
Upload-IfExists -LocalFile $BOOT_DAEMON -RemotePath $REMOTE_BOOT -RemoteFileName "start_daemon.sh"

# ---------------- VERIFY ----------------

Write-Host "🔍 Verifying files on Termux..."

ssh -p $PORT "${USERNAME}@${PHONE_IP}" "echo '--- HOME DIR ---'; ls -l ~; echo '--- BOOT DIR ---'; ls -l ~/.termux/boot; [ -f ~/photo_sync.sh ] && echo 'photo_sync.sh exists' || echo 'photo_sync.sh missing'; [ -f ~/.termux/boot/start_daemon.sh ] && echo 'start_daemon.sh exists in boot' || echo 'start_daemon.sh missing in boot'"

# ---------------- PERMISSIONS ----------------

Write-Host "🔧 Setting permissions..."

ssh -p $PORT "${USERNAME}@${PHONE_IP}" "
if [ -f ~/photo_sync.sh ]; then
    chmod +x ~/photo_sync.sh
    dos2unix ~/photo_sync.sh 2>/dev/null || true
fi

if [ -f ~/.termux/boot/start_daemon.sh ]; then
    chmod +x ~/.termux/boot/start_daemon.sh
    dos2unix ~/.termux/boot/start_daemon.sh 2>/dev/null || true
fi
"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Permission setup failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Deployment completed!" -ForegroundColor Green

# ---------------- OPTIONAL: START DAEMON ----------------

$startNow = Read-Host "Start daemon now? (y/n)"

if ($startNow -eq "y") {
    Write-Host "▶️ Starting daemon..."

    ssh -p $PORT "${USERNAME}@${PHONE_IP}" "bash ~/start_sync_daemon.sh start"

    Write-Host "✅ Daemon started!"
}
else {
    Write-Host "⏭️ Skipped daemon start."
}
