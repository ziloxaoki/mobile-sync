# 📱 Termux Setup Guide (Storage Access + NAS Photo Sync)

This README provides a complete step-by-step guide to:

- Install and configure Termux
- Enable storage access
- Verify camera/photo directories
- Prepare the environment for automation and NAS uploads

---

# 📦 1. Install Termux (IMPORTANT)

⚠️ Do NOT install Termux from the Play Store (deprecated and unreliable).

### Recommended installation:
- Install Termux, Termux:API and Termux:Boot from **F-Droid**
https://f-droid.org/repo/com.termux_1022.apk
https://f-droid.org/repo/com.termux.api_1002.apk
https://f-droid.org/repo/com.termux.boot_1000.apk

To install Termux:API it is necessary to disable Google Play Protect:
OPEN PLAY STORE - GO TO PROFILE - CLICK "PLAY PROTECT" - PRESS THE GEAR ON THE TOP OF THE RIGHT - TURN OFF ALL GENERAL OPTIONS.

- Open Termux and runs:
$> whoami --> will show user id (u0_aXXX)
$> passwd --> will allow us to enter user password
---

# 🔄 2. Update Termux Packages

Run:

```bash
pkg update && pkg upgrade -y
🔐 3. Enable Storage Access
Run:

termux-setup-storage
Expected behavior:
Android permission popup appears

Grant access to files/media

After completion, Termux creates:

~/storage/
📂 4. Verify Storage Access
Run:

ls ~/storage
Expected output:

dcim
downloads
shared
documents

🧠 5. Understanding Storage Mapping
Termux creates symbolic links to Android storage:

Termux Path	Android Path
~/storage/dcim	/storage/emulated/0/DCIM
~/storage/downloads	/storage/emulated/0/Download
~/storage/shared	/storage/emulated/0
📸 6. Access Camera Photos
Check:

ls ~/storage/dcim
or directly:

ls /sdcard/DCIM/Camera
or:

ls /storage/emulated/0/DCIM/Camera
⚠️ Note on Camera Folder
The Camera subfolder may not always appear in Termux

Some devices store images directly inside DCIM

Windows (MTP) may still show DCIM\Camera

🔍 7. Troubleshooting Storage Access
If termux-setup-storage fails or crashes:

7.1 Check Android permissions manually
Go to:

Settings → Apps → Termux → Permissions
Also check:

Settings → Apps → Special app access → All files access
Enable if available.

7.2 Disable battery optimization
Settings → Apps → Termux → Battery → Unrestricted
7.3 Reset storage setup
rm -rf ~/storage
termux-setup-storage
📦 8. Install Required Tools
For scripting and NAS sync:

pkg install rclone -y
pkg install rsync -y
pkg install openssh -y
pkg install coreutils -y
pkg install termux-api -y

Run:
sshd 

Runs SSH so script can be uploaded to mobile using Powershell script (deploy_termux.ps1)

To run the ps1 script is it requried to give Powershell permission to execute scripts. 
Run: Set-ExecutionPolicy -Scope CurrentUser RemoteSigned


🌐 9. Configure Rclone for NAS
Run:

rclone config
Setup example:
Create new remote

Name: truenas

Storage type: SMB / CIFS (53)

Host: 192.168.1.13 (NAS ip)

user: ziloxaoki (SMB user used in the NAS to share the /uploads folder)

port: default (445)

Share: Photos

Default for the remaining questions

Username/password: NAS credentials

Path: uploads (if applicable)

🧪 10. Test NAS Connectivity
rclone lsd truenas:
If successful, you will see directories from your NAS.

📁 11. Example NAS Target Path
For a NAS path like:

\\192.168.1.13\Photos\uploads
Rclone mapping typically becomes:

truenas:uploads
▶️ 12. Running Scripts in Termux
Make script executable: (not required, deploy_termux.ps1 script will set the permissions automatically)

chmod +x script.sh
Run:

./script.sh
Debug mode:

bash -x script.sh
⚠️ 13. Common Mistakes
❌ Running scripts by tapping them in file manager

❌ Editing scripts with Windows line endings (CRLF)

❌ Missing execution permissions

❌ Incorrect storage paths

🔧 Fix Windows Line Endings
If edited on Windows:

pkg install dos2unix
dos2unix script.sh
🔁 14. Auto Execution / Daemon Options
You can run scripts periodically using:

Loop-based daemon:
while true; do
  # your sync logic
  sleep 300
done
Or scheduled approaches:
termux-job-scheduler

cron (via termux-services)

📍 15. Recommended Photo Source Path
Use one of:

/sdcard/DCIM/Camera
or:

/storage/emulated/0/DCIM/Camera
Fallback:

/sdcard/DCIM
🔒 16. Safety Notes
rm -rf ~/storage:

❌ Does NOT delete your photos

✅ Only removes Termux storage links

Always double-check paths before using rm

🧪 17. Useful Debug Commands
ls /sdcard/DCIM
find /sdcard/DCIM -type f -iname "*.jpg"