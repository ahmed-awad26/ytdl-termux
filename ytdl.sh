#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#   ytdl.sh — Main Runner with Full TUI
# ============================================================

# ── Colors & styles ─────────────────────────────────────────
RED='\033[0;31m';    GREEN='\033[0;32m';  YELLOW='\033[1;33m'
CYAN='\033[0;36m';   BLUE='\033[0;34m';  MAGENTA='\033[0;35m'
WHITE='\033[1;37m';  RESET='\033[0m';    BOLD='\033[1m'
DIM='\033[2m';       BG_BLUE='\033[44m'; BG_DARK='\033[40m'

# ── Load config ──────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$SCRIPT_DIR/.config"

if [ -f "$CONFIG" ]; then
  source "$CONFIG"
else
  # Fallback detection
  for dir in "$HOME/storage/shared" "/sdcard" "/storage/emulated/0"; do
    if [ -d "$dir" ] && [ -w "$dir" ]; then
      SDCARD="$dir"; break
    fi
  done
  SDCARD="${SDCARD:-$HOME/downloads}"
  DOWNLOAD_ROOT="$SDCARD/Download/YT-Channels"
fi

mkdir -p "$DOWNLOAD_ROOT"

# ── Helpers ──────────────────────────────────────────────────
clear_screen() { clear; }

draw_box() {
  local title="$1"
  local width=52
  local pad=$(( (width - ${#title} - 2) / 2 ))
  echo -e "${CYAN}${BOLD}"
  printf "  ╔"; printf '═%.0s' $(seq 1 $width); printf "╗\n"
  printf "  ║%${pad}s${WHITE}%s${CYAN}%${pad}s  ║\n" "" "$title" ""
  printf "  ╚"; printf '═%.0s' $(seq 1 $width); printf "╝\n"
  echo -e "${RESET}"
}

divider() {
  echo -e "  ${DIM}${CYAN}──────────────────────────────────────────────────────${RESET}"
}

menu_item() {
  local num="$1"; local icon="$2"; local text="$3"; local desc="$4"
  echo -e "  ${CYAN}[${WHITE}${BOLD}$num${RESET}${CYAN}]${RESET} $icon ${WHITE}${BOLD}$text${RESET}  ${DIM}$desc${RESET}"
}

# ── Main banner ──────────────────────────────────────────────
show_main_banner() {
  clear_screen
  echo -e "${CYAN}"
  echo "  ╔══════════════════════════════════════════════════════╗"
  echo "  ║                                                      ║"
  echo "  ║   ██╗   ██╗████████╗    ██████╗ ██╗                 ║"
  echo "  ║   ╚██╗ ██╔╝╚══██╔══╝    ██╔══██╗██║                 ║"
  echo "  ║    ╚████╔╝    ██║       ██║  ██║██║                 ║"
  echo "  ║     ╚██╔╝     ██║       ██║  ██║██║                 ║"
  echo "  ║      ██║      ██║       ██████╔╝███████╗            ║"
  echo "  ║      ╚═╝      ╚═╝       ╚═════╝ ╚══════╝            ║"
  echo "  ║                                                      ║"
  echo -e "  ║   ${WHITE}${BOLD}  YouTube Channel Downloader — Termux v2.0${CYAN}        ║"
  echo "  ║                                                      ║"
  echo "  ╚══════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
  echo -e "  ${DIM}📁 مجلد التحميل: ${CYAN}$DOWNLOAD_ROOT${RESET}"
  echo -e "  ${DIM}⏰ $(date '+%Y-%m-%d %H:%M')${RESET}"
  echo ""
}

# ── Quality selector ─────────────────────────────────────────
select_quality() {
  clear_screen
  draw_box "🎬 اختر جودة الفيديو"
  echo ""
  menu_item "1" "🏆" "أعلى جودة (Best)"    "يختار أفضل فيديو + صوت تلقائياً"
  menu_item "2" "📺" "4K / 2160p"          "Ultra HD — ملفات كبيرة جداً"
  menu_item "3" "🖥"  "1080p Full HD"       "جودة ممتازة — موصى به"
  menu_item "4" "💻" "720p HD"             "جودة عالية — حجم متوسط"
  menu_item "5" "📱" "480p"               "جودة متوسطة — مناسب للموبايل"
  menu_item "6" "💾" "360p"               "جودة منخفضة — أصغر حجم"
  menu_item "7" "🎵" "صوت فقط MP3"        "تحميل الصوت فقط بجودة عالية"
  menu_item "8" "🎧" "صوت فقط M4A"        "تحميل الصوت بصيغة M4A"
  echo ""
  divider
  echo -e "  ${CYAN}اختر [1-8]:${RESET} "
  read -r quality_choice

  case "$quality_choice" in
    1) FORMAT="bestvideo+bestaudio/best"; EXT="mp4"; QUALITY_NAME="Best" ;;
    2) FORMAT="bestvideo[height<=2160]+bestaudio/best[height<=2160]"; EXT="mp4"; QUALITY_NAME="4K" ;;
    3) FORMAT="bestvideo[height<=1080]+bestaudio/best[height<=1080]"; EXT="mp4"; QUALITY_NAME="1080p" ;;
    4) FORMAT="bestvideo[height<=720]+bestaudio/best[height<=720]"; EXT="mp4"; QUALITY_NAME="720p" ;;
    5) FORMAT="bestvideo[height<=480]+bestaudio/best[height<=480]"; EXT="mp4"; QUALITY_NAME="480p" ;;
    6) FORMAT="bestvideo[height<=360]+bestaudio/best[height<=360]"; EXT="mp4"; QUALITY_NAME="360p" ;;
    7) FORMAT="bestaudio/best"; EXT="mp3"; QUALITY_NAME="MP3 Audio"; AUDIO_ONLY=true ;;
    8) FORMAT="bestaudio/best"; EXT="m4a"; QUALITY_NAME="M4A Audio"; AUDIO_ONLY=true ;;
    *) FORMAT="bestvideo[height<=1080]+bestaudio/best[height<=1080]"; EXT="mp4"; QUALITY_NAME="1080p (افتراضي)" ;;
  esac

  ok_msg "✅ الجودة المختارة: $QUALITY_NAME"
}

ok_msg() { echo -e "  ${GREEN}$1${RESET}"; sleep 1; }
err_msg() { echo -e "  ${RED}✘ $1${RESET}"; }

# ── Mode selector ─────────────────────────────────────────────
select_mode() {
  clear_screen
  draw_box "📂 اختر طريقة التنزيل"
  echo ""
  menu_item "1" "📋" "Playlists فقط"           "تنزيل قوائم التشغيل فقط"
  menu_item "2" "📤" "Uploads فقط"             "تنزيل جميع مقاطع القناة"
  menu_item "3" "🌐" "Playlists + Uploads"      "الكل — قوائم التشغيل + المقاطع"
  menu_item "4" "🗂" "+ مقاطع غير مصنفة"        "كل شيء + المقاطع خارج أي قائمة"
  menu_item "5" "⏱" "آخر تحديث فقط"            "مقاطع تم رفعها بعد تشغيل السكريبت"
  echo ""
  divider
  echo -e "  ${CYAN}اختر [1-5]:${RESET} "
  read -r mode_choice

  case "$mode_choice" in
    1) DL_MODE="playlists";    MODE_NAME="Playlists فقط" ;;
    2) DL_MODE="uploads";      MODE_NAME="Uploads فقط" ;;
    3) DL_MODE="all";          MODE_NAME="Playlists + Uploads" ;;
    4) DL_MODE="all_uncategorized"; MODE_NAME="الكل + غير مصنفة" ;;
    5) DL_MODE="latest";       MODE_NAME="آخر تحديث" ;;
    *) DL_MODE="all";          MODE_NAME="الكل (افتراضي)" ;;
  esac

  ok_msg "✅ الوضع المختار: $MODE_NAME"
}

# ── Channel URL input ────────────────────────────────────────
get_channel_url() {
  clear_screen
  draw_box "🔗 رابط القناة"
  echo ""
  echo -e "  ${WHITE}أمثلة على الروابط المقبولة:${RESET}"
  echo -e "  ${DIM}• https://www.youtube.com/@ChannelName${RESET}"
  echo -e "  ${DIM}• https://www.youtube.com/channel/UCxxxxxxx${RESET}"
  echo -e "  ${DIM}• https://www.youtube.com/c/ChannelName${RESET}"
  echo -e "  ${DIM}• https://www.youtube.com/user/Username${RESET}"
  echo ""
  divider
  echo -e "  ${CYAN}أدخل رابط القناة:${RESET} "
  read -r CHANNEL_URL

  if [[ -z "$CHANNEL_URL" ]]; then
    err_msg "الرابط فارغ! يرجى المحاولة مرة أخرى."
    sleep 1
    get_channel_url
    return
  fi

  # Extract channel name
  CHANNEL_NAME=$(yt-dlp --no-playlist --print "%(channel)s" \
    --playlist-items 1 "$CHANNEL_URL" 2>/dev/null | head -1)

  if [[ -z "$CHANNEL_NAME" ]]; then
    CHANNEL_NAME="Unknown_Channel_$(date +%s)"
    warn_msg "⚠ تعذّر استخراج اسم القناة — سيُستخدم: $CHANNEL_NAME"
  else
    ok_msg "✅ القناة: $CHANNEL_NAME"
  fi

  # Sanitize name
  CHANNEL_SAFE=$(echo "$CHANNEL_NAME" | tr -dc 'a-zA-Z0-9_\-\u0600-\u06FF ' | tr ' ' '_')
  CHANNEL_DIR="$DOWNLOAD_ROOT/$CHANNEL_SAFE"
  mkdir -p "$CHANNEL_DIR"
}

warn_msg() { echo -e "  ${YELLOW}$1${RESET}"; sleep 1; }

# ── Confirm summary ──────────────────────────────────────────
confirm_download() {
  clear_screen
  draw_box "✅ ملخص التنزيل"
  echo ""
  echo -e "  ${WHITE}القناة:${RESET}    ${CYAN}$CHANNEL_NAME${RESET}"
  echo -e "  ${WHITE}الجودة:${RESET}    ${GREEN}$QUALITY_NAME${RESET}"
  echo -e "  ${WHITE}الوضع:${RESET}     ${YELLOW}$MODE_NAME${RESET}"
  echo -e "  ${WHITE}مجلد الحفظ:${RESET} ${MAGENTA}$CHANNEL_DIR${RESET}"
  echo ""
  divider
  echo -e "  ${CYAN}[Y]${RESET} ابدأ التنزيل   ${RED}[N]${RESET} إلغاء"
  echo ""
  echo -e "  اختر: "
  read -r confirm

  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "  ${YELLOW}تم الإلغاء.${RESET}"
    main_menu
    return
  fi
}

# ── Live progress display ────────────────────────────────────
show_download_ui() {
  clear_screen
  echo -e "${CYAN}"
  echo "  ╔══════════════════════════════════════════════════════╗"
  echo -e "  ║   ${WHITE}${BOLD}⬇  جاري التنزيل...${CYAN}                               ║"
  echo "  ╚══════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
  echo -e "  ${WHITE}القناة:${RESET} ${CYAN}$CHANNEL_NAME${RESET}"
  echo -e "  ${WHITE}الوضع:${RESET}  ${YELLOW}$MODE_NAME${RESET}"
  echo -e "  ${WHITE}الجودة:${RESET} ${GREEN}$QUALITY_NAME${RESET}"
  echo ""
  divider
  echo ""
}

# ── Build yt-dlp arguments ───────────────────────────────────
build_ytdlp_args() {
  local url="$1"; local out_dir="$2"; local extra="$3"

  local args=(
    "--ignore-errors"
    "--no-abort-on-error"
    "--continue"
    "--retries" "5"
    "--fragment-retries" "10"
    "--retry-sleep" "3"
    "--concurrent-fragments" "4"
    "--merge-output-format" "mp4"
    "--embed-thumbnail"
    "--add-metadata"
    "--write-description"
    "--write-info-json"
    "--console-title"
    "--progress"
  )

  if [ "$AUDIO_ONLY" = true ]; then
    args+=("-x" "--audio-format" "$EXT" "--audio-quality" "0")
    args+=("-o" "$out_dir/%(title)s.%(ext)s")
  else
    args+=("-f" "$FORMAT")
    args+=("-o" "$out_dir/%(title)s [%(id)s].%(ext)s")
  fi

  [ -n "$extra" ] && args+=($extra)
  args+=("$url")

  echo "${args[@]}"
}

# ── Run download ─────────────────────────────────────────────
run_download() {
  local LOG="$CHANNEL_DIR/download_$(date +%Y%m%d_%H%M%S).log"
  local FAILED="$CHANNEL_DIR/failed_downloads.txt"
  AUDIO_ONLY=${AUDIO_ONLY:-false}

  show_download_ui

  case "$DL_MODE" in
    "uploads")
      echo -e "  ${CYAN}⬇ تنزيل جميع المقاطع (Uploads)...${RESET}\n"
      local upload_dir="$CHANNEL_DIR/Uploads"
      mkdir -p "$upload_dir"
      local args_str
      args_str=$(build_ytdlp_args "$CHANNEL_URL/videos" "$upload_dir")
      yt-dlp $args_str 2>&1 | tee "$LOG" | grep -E "^\[download\]|^\[ffmpeg\]|ERROR|WARNING" | \
        while IFS= read -r line; do
          if echo "$line" | grep -q "ERROR"; then
            echo -e "  ${RED}✘ $line${RESET}"
          elif echo "$line" | grep -q "WARNING"; then
            echo -e "  ${YELLOW}⚠ $line${RESET}"
          else
            echo -e "  ${GREEN}▶ $line${RESET}"
          fi
        done
      ;;

    "playlists")
      echo -e "  ${CYAN}⬇ تنزيل قوائم التشغيل...${RESET}\n"
      download_playlists
      ;;

    "all"|"all_uncategorized")
      echo -e "  ${CYAN}⬇ تنزيل كل شيء...${RESET}\n"
      download_playlists
      echo ""
      echo -e "  ${CYAN}⬇ تنزيل Uploads...${RESET}\n"
      local upload_dir="$CHANNEL_DIR/Uploads"
      mkdir -p "$upload_dir"
      local args_str
      args_str=$(build_ytdlp_args "$CHANNEL_URL/videos" "$upload_dir")
      yt-dlp $args_str 2>&1 | tee -a "$LOG" | grep -E "^\[download\]|ERROR" | \
        while IFS= read -r line; do
          echo -e "  ${GREEN}▶ $line${RESET}"
        done

      if [ "$DL_MODE" = "all_uncategorized" ]; then
        echo ""
        echo -e "  ${CYAN}⬇ تنزيل المقاطع غير المصنفة...${RESET}\n"
        local misc_dir="$CHANNEL_DIR/Uncategorized"
        mkdir -p "$misc_dir"
        # Download all then move uncategorized
        args_str=$(build_ytdlp_args \
          "$CHANNEL_URL" "$misc_dir" "--no-playlist")
        yt-dlp $args_str 2>&1 | tee -a "$LOG" | grep -E "^\[download\]|ERROR" | \
          while IFS= read -r line; do echo -e "  ${GREEN}▶ $line${RESET}"; done
      fi
      ;;

    "latest")
      echo -e "  ${CYAN}⬇ تنزيل أحدث المقاطع (منذ آخر تشغيل)...${RESET}\n"
      local DATEFILE="$CHANNEL_DIR/.last_run"
      local DATE_AFTER=""
      if [ -f "$DATEFILE" ]; then
        DATE_AFTER=$(cat "$DATEFILE")
        echo -e "  ${DIM}آخر تشغيل: $DATE_AFTER${RESET}"
      fi
      local upload_dir="$CHANNEL_DIR/Latest"
      mkdir -p "$upload_dir"
      local extra_args=""
      [ -n "$DATE_AFTER" ] && extra_args="--dateafter $DATE_AFTER"
      local args_str
      args_str=$(build_ytdlp_args "$CHANNEL_URL/videos" "$upload_dir" "$extra_args")
      yt-dlp $args_str 2>&1 | tee -a "$LOG" | grep -E "^\[download\]|ERROR" | \
        while IFS= read -r line; do echo -e "  ${GREEN}▶ $line${RESET}"; done
      date +%Y%m%d > "$DATEFILE"
      ;;
  esac

  echo ""
  divider
  show_completion "$LOG"
}

# ── Download playlists ────────────────────────────────────────
download_playlists() {
  echo -e "  ${CYAN}جارٍ جلب قائمة Playlists...${RESET}"
  
  local PLAYLISTS
  PLAYLISTS=$(yt-dlp --flat-playlist --print "%(playlist_id)s\t%(playlist_title)s" \
    "$CHANNEL_URL/playlists" 2>/dev/null | sort -u)

  if [[ -z "$PLAYLISTS" ]]; then
    warn_msg "لم يتم العثور على Playlists في هذه القناة."
    return
  fi

  local count=0
  while IFS=$'\t' read -r pl_id pl_title; do
    [[ -z "$pl_id" || "$pl_id" == "NA" ]] && continue
    count=$((count+1))
    local safe_title
    safe_title=$(echo "$pl_title" | tr -dc 'a-zA-Z0-9_\-\u0600-\u06FF ' | tr ' ' '_' | head -c 60)
    safe_title="${safe_title:-Playlist_$count}"
    local pl_dir="$CHANNEL_DIR/Playlists/$safe_title"
    mkdir -p "$pl_dir"

    echo -e "\n  ${MAGENTA}[Playlist $count]${RESET} ${WHITE}$pl_title${RESET}"
    echo -e "  ${DIM}→ $pl_dir${RESET}"

    local args_str
    args_str=$(build_ytdlp_args \
      "https://www.youtube.com/playlist?list=$pl_id" "$pl_dir")
    yt-dlp $args_str 2>&1 | grep -E "^\[download\]|ERROR|already" | \
      while IFS= read -r line; do
        if echo "$line" | grep -q "already"; then
          echo -e "    ${DIM}↩ موجود مسبقاً: $line${RESET}"
        else
          echo -e "    ${GREEN}▶ $line${RESET}"
        fi
      done
  done <<< "$PLAYLISTS"
}

# ── Completion screen ─────────────────────────────────────────
show_completion() {
  local log="$1"
  local errors=0
  [ -f "$log" ] && errors=$(grep -c "ERROR" "$log" 2>/dev/null || echo 0)
  local total=0
  [ -f "$log" ] && total=$(grep -c "\[download\]" "$log" 2>/dev/null || echo 0)

  clear_screen
  echo -e "${GREEN}${BOLD}"
  echo "  ╔══════════════════════════════════════════════════════╗"
  echo "  ║                                                      ║"
  echo "  ║   🎉  اكتمل التنزيل!                                ║"
  echo "  ║                                                      ║"
  echo "  ╚══════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
  echo -e "  ${WHITE}القناة:${RESET}         ${CYAN}$CHANNEL_NAME${RESET}"
  echo -e "  ${WHITE}مجلد الحفظ:${RESET}      ${MAGENTA}$CHANNEL_DIR${RESET}"
  echo -e "  ${WHITE}عمليات التنزيل:${RESET} ${GREEN}$total${RESET}"
  [ "$errors" -gt 0 ] && \
    echo -e "  ${WHITE}أخطاء:${RESET}          ${RED}$errors${RESET} (راجع ملف الـ log)"
  echo -e "  ${WHITE}ملف السجل:${RESET}      ${DIM}$log${RESET}"
  echo ""
  divider
  echo ""
  echo -e "  ${CYAN}[1]${RESET} تنزيل قناة أخرى   ${CYAN}[2]${RESET} الخروج"
  echo ""
  echo -e "  اختر: "
  read -r next_action

  case "$next_action" in
    1) main_menu ;;
    *) goodbye ;;
  esac
}

# ── Goodbye ──────────────────────────────────────────────────
goodbye() {
  clear_screen
  echo -e "${CYAN}"
  echo "  ╔══════════════════════════════════════════════════════╗"
  echo -e "  ║   ${WHITE}شكراً لاستخدام YT-DL Termux 👋${CYAN}                  ║"
  echo "  ╚══════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
  exit 0
}

# ── Check dependencies on start ──────────────────────────────
check_deps() {
  local missing=()
  for tool in yt-dlp ffmpeg python3; do
    command -v "$tool" &>/dev/null || missing+=("$tool")
  done
  if [ ${#missing[@]} -gt 0 ]; then
    err_msg "الأدوات التالية مفقودة: ${missing[*]}"
    echo -e "  ${YELLOW}يرجى تشغيل install.sh أولاً:  bash install.sh${RESET}"
    echo ""
    exit 1
  fi
}

# ── Main menu ─────────────────────────────────────────────────
main_menu() {
  check_deps
  show_main_banner

  draw_box "🚀 القائمة الرئيسية"
  echo ""
  menu_item "1" "⬇" "تنزيل قناة يوتيوب"   "ادخل الرابط واختر الخيارات"
  menu_item "2" "📁" "فتح مجلد التحميلات"  "عرض الملفات المحملة"
  menu_item "3" "🔄" "تحديث yt-dlp"        "للحصول على أحدث إصدار"
  menu_item "4" "ℹ" "معلومات النظام"       "إصدارات الأدوات"
  menu_item "5" "❌" "الخروج"              ""
  echo ""
  divider
  echo -e "  ${CYAN}اختر [1-5]:${RESET} "
  read -r main_choice

  case "$main_choice" in
    1)
      get_channel_url
      select_quality
      select_mode
      confirm_download
      run_download
      ;;
    2)
      echo -e "\n  ${CYAN}محتوى مجلد التحميلات:${RESET}"
      ls -lh "$DOWNLOAD_ROOT" 2>/dev/null || echo "  (فارغ)"
      echo ""
      echo -e "  ${DIM}اضغط ENTER للمتابعة...${RESET}"
      read -r
      main_menu
      ;;
    3)
      echo -e "\n  ${CYAN}جاري تحديث yt-dlp...${RESET}"
      pip install --upgrade yt-dlp 2>&1 | tail -3
      echo -e "  ${GREEN}تم التحديث!${RESET}"
      sleep 2
      main_menu
      ;;
    4)
      clear_screen
      draw_box "ℹ معلومات النظام"
      echo ""
      echo -e "  ${WHITE}yt-dlp:${RESET}  $(yt-dlp --version 2>/dev/null)"
      echo -e "  ${WHITE}ffmpeg:${RESET}  $(ffmpeg -version 2>/dev/null | head -1 | cut -d' ' -f3)"
      echo -e "  ${WHITE}python:${RESET}  $(python3 --version 2>/dev/null)"
      echo -e "  ${WHITE}مجلد:${RESET}    $DOWNLOAD_ROOT"
      local used
      used=$(du -sh "$DOWNLOAD_ROOT" 2>/dev/null | cut -f1)
      echo -e "  ${WHITE}مساحة مستخدمة:${RESET} ${used:-0}"
      echo ""
      divider
      echo -e "  ${DIM}اضغط ENTER للعودة...${RESET}"
      read -r
      main_menu
      ;;
    5) goodbye ;;
    *) main_menu ;;
  esac
}

# ── Entry point ──────────────────────────────────────────────
main_menu
