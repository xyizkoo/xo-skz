<img src="https://res.cloudinary.com/dsec3pqkf/image/upload/v1781369198/5.gif" alt="description">

Here's a complete, copy-paste-ready markdown tutorial for downloading YouTube playlists using Firefox cookies with the fast progressive method.

````markdown
# YouTube Playlist Downloader Tutorial (2026)

## Fast Method Using Firefox Cookies & Progressive Downloads

A complete, working guide to download entire YouTube playlists (100+ videos) using yt-dlp with Firefox cookies authentication.

---

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Step 1: Installation](#step-1-installation)
- [Step 2: Firefox Setup](#step-2-firefox-setup)
- [Step 3: The Download Script](#step-3-the-download-script)
- [Step 4: Running the Script](#step-4-running-the-script)
- [Step 5: Resume Interrupted Downloads](#step-5-resume-interrupted-downloads)
- [Troubleshooting](#troubleshooting)
- [Advanced Options](#advanced-options)

---

## Prerequisites

Before starting, ensure you have:

- **Firefox** installed and running
- **A YouTube account** (free, for authentication)
- **Stable internet connection**
- **Sufficient disk space** (approx 500MB per 10-minute 720p video)

---

## Step 1: Installation

Open a terminal and run these commands in order:

### 1.1 Install yt-dlp (Latest Version)

```bash
# Install or update to the latest version
pip install -U yt-dlp

# Verify installation
yt-dlp --version
# Should show 2026.06.09 or higher
```
````

### 1.2 Install ffmpeg (Required for merging video + audio)

```bash
# For Ubuntu/Debian Linux:
sudo apt update
sudo apt install ffmpeg -y

# For macOS:
brew install ffmpeg

# For Windows (using Chocolatey):
choco install ffmpeg

# For Arch Linux:
sudo pacman -S ffmpeg
```

### 1.3 Install Deno JS Runtime (Critical for 2026)

```bash
# Install Deno v2.3.0 or higher
curl -fsSL https://deno.land/install.sh | sh

# Add Deno to your PATH (add to ~/.bashrc or ~/.zshrc)
export DENO_INSTALL="$HOME/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"

# Reload your shell configuration
source ~/.bashrc  # or source ~/.zshrc

# Verify Deno installation
deno --version
# Should show deno 2.3.0 or higher
```

### 1.4 Verify All Components

```bash
# Quick verification script
echo "=== Installation Check ==="
echo "yt-dlp: $(yt-dlp --version 2>/dev/null || echo 'NOT FOUND')"
echo "ffmpeg: $(ffmpeg -version 2>/dev/null | head -1 | cut -d' ' -f3 || echo 'NOT FOUND')"
echo "deno: $(deno --version 2>/dev/null | head -1 | cut -d' ' -f2 || echo 'NOT FOUND')"
echo "=========================="
```

---

## Step 2: Firefox Setup

### 2.1 Prepare Firefox

1. **Open Firefox** on your VM/computer
2. **Navigate to YouTube** (https://www.youtube.com)
3. **Log into your YouTube account**
   - Click "Sign In" in the top right
   - Enter your credentials
   - **DO NOT close Firefox** after logging in

### 2.2 Keep Firefox Open

**⚠️ CRITICAL:** The script needs Firefox to remain OPEN and you must stay logged into YouTube. Minimizing Firefox is fine, but do not close it.

### 2.3 Test Cookie Access (Optional)

```bash
# Test if yt-dlp can access Firefox cookies
yt-dlp --cookies-from-browser firefox --cookies test_cookies.txt --simulate "https://www.youtube.com/watch?v=dQw4w9WgXcQ"

# Clean up test file
rm test_cookies.txt
```

---

## Step 3: The Download Script

### 3.1 Create the Script File

Create a new file named `download_playlist.sh`:

```bash
nano download_playlist.sh
```

### 3.2 Copy the Complete Script

Copy and paste the entire script below:

```bash
#!/bin/bash

################################################################################
# YouTube Playlist Downloader - Fast Progressive Method
# Uses Firefox cookies authentication
# Version: 2026.06.13
################################################################################

# ============================================================================
# CONFIGURATION SECTION - EDIT THESE VALUES AS NEEDED
# ============================================================================

# YouTube playlist URL (you can also pass as command line argument)
PLAYLIST_URL="${1:-}"

# Output directory for downloaded videos
OUTPUT_DIR="./youtube_downloads"

# Archive file to track downloaded videos (prevents re-downloading)
ARCHIVE_FILE="$OUTPUT_DIR/archive.txt"

# Maximum quality (height in pixels)
# Options: 720, 1080, 1440, 2160 (4K)
# Note: Higher quality uses more disk space and may be slower
MAX_HEIGHT="720"

# Retry settings - prevents stuck downloads
MAX_RETRIES="10"              # How many times to retry failed downloads
FRAGMENT_RETRIES="10"         # Retries for video fragments
FILE_ACCESS_RETRIES="5"       # Retries for file access errors
RETRY_SLEEP="5"               # Seconds to wait between retries

# Rate limiting - prevents YouTube from blocking you
SLEEP_BETWEEN_VIDEOS="5"      # Seconds to wait after each video
MAX_SLEEP="15"                # Maximum sleep when rate limited
SLEEP_BETWEEN_REQUESTS="2"    # Seconds between API requests

# Download speed limit (0 = unlimited)
# Example: "50M" for 50 megabits, "10M" for 10 megabits
SPEED_LIMIT="0"               # 0 = no limit

# JavaScript runtime (REQUIRED for YouTube in 2026)
JS_RUNTIME="deno"             # DO NOT CHANGE unless deno fails

# ============================================================================
# DO NOT EDIT BELOW THIS LINE UNLESS YOU KNOW WHAT YOU'RE DOING
# ============================================================================

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if playlist URL was provided
if [ -z "$PLAYLIST_URL" ]; then
    print_error "No playlist URL provided"
    echo ""
    echo "Usage: $0 \"YOUR_PLAYLIST_URL\""
    echo ""
    echo "Example: $0 \"https://www.youtube.com/playlist?list=PLABC123XYZ\""
    exit 1
fi

# Validate URL format
if [[ ! "$PLAYLIST_URL" =~ ^https?://(www\.)?(youtube\.com|youtu\.be) ]]; then
    print_error "Invalid YouTube URL"
    echo "URL should start with: https://www.youtube.com/..."
    exit 1
fi

# Check for required dependencies
print_status "Checking dependencies..."

# Check yt-dlp
if ! command -v yt-dlp &> /dev/null; then
    print_error "yt-dlp not found"
    echo "Install with: pip install -U yt-dlp"
    exit 1
fi

# Check ffmpeg
if ! command -v ffmpeg &> /dev/null; then
    print_error "ffmpeg not found"
    echo "Install with: sudo apt install ffmpeg (Ubuntu/Debian)"
    echo "Or: brew install ffmpeg (macOS)"
    exit 1
fi

# Check deno
if ! command -v deno &> /dev/null; then
    print_error "Deno JS runtime not found"
    echo "Install with: curl -fsSL https://deno.land/install.sh | sh"
    echo "Then restart your terminal or run: source ~/.bashrc"
    exit 1
fi

print_success "All dependencies found"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Display configuration
echo ""
echo "========================================="
echo "📺 YouTube Playlist Downloader"
echo "========================================="
echo "📍 URL: $PLAYLIST_URL"
echo "📁 Output: $OUTPUT_DIR"
echo "🎬 Quality: Up to ${MAX_HEIGHT}p"
echo "🔄 Retries: $MAX_RETRIES"
echo "⏱️  Delay between videos: ${SLEEP_BETWEEN_VIDEOS}s"
echo "========================================="
echo ""
print_warning "Keep Firefox OPEN and logged into YouTube!"
echo ""

# Wait for user confirmation
read -p "Press Enter to start downloading (or Ctrl+C to cancel)..."

echo ""
print_status "Starting playlist download..."
echo ""

# ============================================================================
# THE MAIN DOWNLOAD COMMAND
# ============================================================================

yt-dlp \
    --cookies-from-browser firefox \
    --js-runtimes "$JS_RUNTIME" \
    --continue \
    --retries "$MAX_RETRIES" \
    --fragment-retries "$FRAGMENT_RETRIES" \
    --file-access-retries "$FILE_ACCESS_RETRIES" \
    --retry-sleep "$RETRY_SLEEP" \
    --sleep-interval "$SLEEP_BETWEEN_VIDEOS" \
    --max-sleep-interval "$MAX_SLEEP" \
    --sleep-requests "$SLEEP_BETWEEN_REQUESTS" \
    --limit-rate "$SPEED_LIMIT" \
    --no-overwrites \
    --ignore-errors \
    --no-abort-on-error \
    --download-archive "$ARCHIVE_FILE" \
    --output "$OUTPUT_DIR/%(playlist_title)s/%(playlist_index)02d - %(title)s.%(ext)s" \
    --format "bestvideo[height<=$MAX_HEIGHT]+bestaudio/best[height<=$MAX_HEIGHT]" \
    --merge-output-format mp4 \
    --embed-thumbnail \
    --add-metadata \
    "$PLAYLIST_URL"

# Check exit status
DOWNLOAD_EXIT_CODE=$?

echo ""
if [ $DOWNLOAD_EXIT_CODE -eq 0 ]; then
    print_success "Download completed successfully!"
else
    print_warning "Download finished with some errors"
    print_warning "Check the output above for details"
fi

# Summary
echo ""
echo "========================================="
echo "📊 Download Summary"
echo "========================================="
echo "📁 Videos saved in: $OUTPUT_DIR"
echo "📝 Archive file: $ARCHIVE_FILE"
echo ""
echo "💡 Tips:"
echo "   - To resume interrupted download, run the same command again"
echo "   - Already downloaded videos will be skipped automatically"
echo "   - Check $ARCHIVE_FILE to see what was downloaded"
echo "========================================="
```

### 3.3 Save and Make Executable

```bash
# Make the script executable
chmod +x download_playlist.sh
```

---

## Step 4: Running the Script

### 4.1 Basic Usage

```bash
./download_playlist.sh "https://www.youtube.com/playlist?list=YOUR_PLAYLIST_ID"
```

### 4.2 Example with Real Playlist

```bash
# Replace with your actual playlist URL
./download_playlist.sh "https://www.youtube.com/playlist?list=PLABC123DEF456XYZ"
```

### 4.3 What You'll See

```
[14:32:01] Checking dependencies...
[SUCCESS] All dependencies found

=========================================
📺 YouTube Playlist Downloader
=========================================
📍 URL: https://www.youtube.com/playlist?list=...
📁 Output: ./youtube_downloads
🎬 Quality: Up to 720p
🔄 Retries: 10
⏱️  Delay between videos: 5s
=========================================

[WARNING] Keep Firefox OPEN and logged into YouTube!

Press Enter to start downloading (or Ctrl+C to cancel)...

[14:32:05] Starting playlist download...

[youtube] Extracting URL: ...
[youtube] Playlist ABC123: Downloading 101 videos
[download] Downloading video 1/101: Video Title
[download] Destination: ./youtube_downloads/Playlist Name/01 - Video Title.mp4
[download] 100% of 45.23MiB in 00:12
...
```

### 4.4 Monitor Download Progress

The script will show:

- **Current video number** (e.g., "Downloading video 45/101")
- **Download speed** and **progress percentage**
- **Remaining time** (estimate)
- **Any errors** (with retry attempts)

---

## Step 5: Resume Interrupted Downloads

### 5.1 Why You Might Need to Resume

- Network interruption
- You pressed Ctrl+C to pause
- VM rebooted
- YouTube rate limiting

### 5.2 How Resume Works

The script uses `--download-archive "$ARCHIVE_FILE"` which creates a file tracking every completed video.

### 5.3 To Resume

**Simply run the exact same command again:**

```bash
./download_playlist.sh "https://www.youtube.com/playlist?list=YOUR_PLAYLIST_ID"
```

The script will:

1. Read the archive file
2. Skip already downloaded videos
3. Continue from where it stopped

### 5.4 Check Archive File Contents

```bash
# View downloaded video IDs
cat ./youtube_downloads/archive.txt

# Count downloaded videos
wc -l ./youtube_downloads/archive.txt
```

---

## Troubleshooting

### Common Errors and Solutions

#### Error 1: "No supported JavaScript runtime could be found"

```
[ERROR] Deno JS runtime not found
```

**Solution:**

```bash
# Install Deno
curl -fsSL https://deno.land/install.sh | sh

# Add to PATH
export PATH="$HOME/.deno/bin:$PATH"

# Verify
deno --version
```

#### Error 2: "Sign in to confirm you're not a bot"

```
WARNING: Unable to download video: Sign in to confirm you're not a bot
```

**Solution:**

1. Keep Firefox OPEN
2. Refresh YouTube in Firefox
3. Ensure you're still logged in
4. Run the script again

#### Error 3: HTTP Error 429 (Too Many Requests)

```
ERROR: HTTP Error 429: Too Many Requests
```

**Solution:** Increase delays in script configuration:

```bash
# Edit these values in the script
SLEEP_BETWEEN_VIDEOS="10"      # Increase from 5 to 10
MAX_SLEEP="30"                  # Increase from 15 to 30
```

#### Error 4: Download gets stuck at 99%

```
[download] 99% of 50.23MiB
```

**Solution:** The fragment retry settings will handle this. Wait up to 60 seconds. If still stuck:

```bash
# Press Ctrl+C to cancel
# Resume by running the same command again
./download_playlist.sh "YOUR_URL"
```

#### Error 5: "ffmpeg not found"

```
[ERROR] ffmpeg not found
```

**Solution:**

```bash
# Ubuntu/Debian
sudo apt install ffmpeg -y

# macOS
brew install ffmpeg

# Verify
ffmpeg -version
```

#### Error 6: Playlist not found or private

```
ERROR: Playlist is private or does not exist
```

**Solution:**

1. Make sure you're logged into YouTube in Firefox
2. Check if playlist is set to "Unlisted" or "Public"
3. Try accessing the playlist in Firefox first

---

## Advanced Options

### Option A: Change Video Quality

Edit the `MAX_HEIGHT` variable in the script:

```bash
# For 1080p (best quality for most users)
MAX_HEIGHT="1080"

# For 480p (saves space)
MAX_HEIGHT="480"

# For 4K (large files, needs fast internet)
MAX_HEIGHT="2160"
```

### Option B: Download Only Audio (MP3)

Replace the `--format` line with:

```bash
--format "bestaudio" \
--extract-audio \
--audio-format mp3 \
--audio-quality 192K \
```

### Option C: Add Download Speed Limit

```bash
# Limit to 10 megabits per second
SPEED_LIMIT="10M"

# Limit to 5 megabits per second
SPEED_LIMIT="5M"
```

### Option D: Download Specific Range of Videos

Add this before the playlist URL:

```bash
# Download videos 1-50 only
--playlist-items 1-50 \

# Download videos 25, 30, and 40-45
--playlist-items 25,30,40-45 \
```

### Option E: Use aria2c for Even Faster Downloads

Install aria2c first:

```bash
sudo apt install aria2 -y  # Ubuntu/Debian
brew install aria2          # macOS
```

Then add these arguments to the yt-dlp command:

```bash
--downloader aria2c \
--downloader-args "aria2c:-x 16 -s 16 -k 1M" \
```

---

## Quick Reference Card

### One-Liner Commands

**Download playlist (720p, fast):**

```bash
yt-dlp --cookies-from-browser firefox --js-runtimes deno -f "bestvideo[height<=720]+bestaudio" -o "%(playlist_title)s/%(playlist_index)02d - %(title)s.%(ext)s" "PLAYLIST_URL"
```

**Download single video (best quality):**

```bash
yt-dlp --cookies-from-browser firefox --js-runtimes deno -f best "VIDEO_URL"
```

**Download audio only (MP3):**

```bash
yt-dlp --cookies-from-browser firefox --js-runtimes deno -x --audio-format mp3 "VIDEO_URL"
```

**Download playlist with resume capability:**

```bash
yt-dlp --cookies-from-browser firefox --js-runtimes deno --continue --download-archive archive.txt -f "bestvideo[height<=720]+bestaudio" -o "%(playlist_title)s/%(playlist_index)02d - %(title)s.%(ext)s" "PLAYLIST_URL"
```

---

## Final Notes

### Important Reminders:

1. **Always keep Firefox open** and logged into YouTube
2. **Be respectful** - Don't download aggressively (use the sleep delays)
3. **Check disk space** before downloading 100+ videos
4. **Use the archive feature** to avoid re-downloading
5. **Update yt-dlp regularly**: `pip install -U yt-dlp`

### Legal Disclaimer:

This tool is for downloading content you have permission to download. Respect copyright laws and YouTube's Terms of Service.

---

## Need Help?

- **yt-dlp documentation:** https://github.com/yt-dlp/yt-dlp/tree/master
- **Official issues:** https://github.com/yt-dlp/yt-dlp/issues
- **Deno installation help:** https://deno.com/

---

**Version:** 2026.06.13
**Last Updated:** June 13, 2026
**Compatible with:** yt-dlp >= 2026.06.09, Deno >= 2.3.0

```

This markdown file contains everything you need. Copy and save it as `YouTube_Playlist_Downloader_Tutorial.md` and you'll have a complete reference that works with the current (June 2026) requirements.
```
