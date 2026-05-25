#!/bin/bash

# ==========================================
# 1. CẤU HÌNH ĐƯỜNG DẪN & MÀU SẮC
# ==========================================
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
PROJECT_DIR=$(dirname "$SCRIPT_DIR")

DATA_DIR="$PROJECT_DIR/data"
BACKUP_DIR="$PROJECT_DIR/backups"
LOG_FILE="$PROJECT_DIR/logs/backup.log"

# Mã màu Terminal (Dùng chữ đậm cho dễ nhìn)
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
BLUE='\033[1;34m'
RESET='\033[0m'

# ==========================================
# 2. CÁC HÀM CHỨC NĂNG CHÍNH
# ==========================================

# Hàm kiểm tra mạng nhanh
check_internet() {
    ping -c 1 8.8.8.8 &> /dev/null
    return $?
}

# Hàm xử lý Backup dữ liệu
do_backup() {
    echo -e "${BLUE}\n[*] Đang thực hiện backup dữ liệu...${RESET}"
    
    # Tạo thư mục backups nếu chưa có
    mkdir -p "$BACKUP_DIR"

    # Đặt tên file theo ngày_giờ (Ví dụ: backup_20260525_083000.tar.gz)
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.tar.gz"

    # Tiến hành nén thư mục data
    if tar -czf "$BACKUP_FILE" -C "$PROJECT_DIR" data 2>/dev/null; then
        echo -e "${GREEN}[OK] Đã tạo bản nén thành công!${RESET}"
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] SUCCESS: Backup created." >> "$LOG_FILE"
    else
        echo -e "${RED}[LỖI] Không thể nén dữ liệu!${RESET}"
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] FAILED: Backup failed." >> "$LOG_FILE"
        return 1
    fi

    # BONUS 1: Giữ lại đúng 5 file mới nhất (Xóa các file cũ hơn)
    cd "$BACKUP_DIR" && ls -t | tail -n +6 | xargs rm -f 2>/dev/null
    echo -e "${GREEN}[OK] Đã tự động dọn dẹp (Chỉ giữ 5 bản mới nhất).${RESET}"
    
    # BONUS 2: Tự động push lên GitHub nếu có mạng
    if check_internet; then
        echo -e "${BLUE}[*] Đang tự động cập nhật lên GitHub...${RESET}"
        cd "$PROJECT_DIR"
        git add . && git commit -m "Auto-backup: $TIMESTAMP" && git push origin main &> /dev/null
        echo -e "${GREEN}[OK] Đã đồng bộ với GitHub thành công!${RESET}"
    else
        echo -e "${YELLOW}[!] Không có Internet, bỏ qua bước push GitHub.${RESET}"
    fi
}

# ==========================================
# 3. GIAO DIỆN MENU CHÍNH
# ==========================================
while true; do
    echo -e "\n${BLUE}=========================================${RESET}"
    echo -e "${GREEN}        HỆ THỐNG QUẢN LÝ BACKUP          ${RESET}"
    echo -e "${BLUE}=========================================${RESET}"
    echo -e " [1] Tiến hành Backup dữ liệu"
    echo -e " [2] Xem danh sách file backup hiện có"
    echo -e " [3] Xem lịch sử Log hệ thống"
    echo -e " [4] Kiểm tra kết nối Internet"
    echo -e " [5] Thoát"
    echo -e "${BLUE}=========================================${RESET}"
    
    read -p "Nhập lựa chọn của bạn (1-5): " CHOICE

    case $CHOICE in
        1)  do_backup ;;
        2)  echo -e "${YELLOW}\n--- DANH SÁCH FILE BACKUP ---${RESET}"
            ls -lh "$BACKUP_DIR" 2>/dev/null || echo -e "${RED}Chưa có file backup nào.${RESET}"
            ;;
        3)  echo -e "${YELLOW}\n--- LỊCH SỬ LOG ---${RESET}"
            [ -f "$LOG_FILE" ] && cat "$LOG_FILE" || echo -e "${RED}Chưa có log.${RESET}"
            ;;
        4)  if check_internet; then
                echo -e "${GREEN}\n[OK] Kết nối Internet: Tốt!${RESET}"
            else
                echo -e "${RED}\n[LỖI] Thiết bị chưa kết nối Internet!${RESET}"
            fi
            ;;
        5)  echo -e "${GREEN}\nTạm biệt!${RESET}"; exit 0 ;;
        *)  echo -e "${RED}\nLựa chọn sai, vui lòng nhập lại!${RESET}" ;;
    esac
done
