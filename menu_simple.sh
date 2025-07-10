#!/data/data/com.termux/files/usr/bin/bash
# =========================================================================
# SillyTavern-Termux 极简菜单脚本
# By mio酱 for 爸爸 💕
# =========================================================================

# ==== 彩色输出定义 ====
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
BOLD='\033[1m'
NC='\033[0m'

# ==== 通用函数 ====
press_any_key() {
    echo -e "${CYAN}${BOLD}>> 💕 按任意键返回菜单...${NC}"
    read -n1 -s
}

# =========================================================================
# 1. 启动酒馆
# =========================================================================
start_tavern() {
    echo -e "\n${CYAN}${BOLD}==== 🌸 启动 SillyTavern 🌸 ====${NC}"
    if [ -d "$HOME/SillyTavern" ]; then
        cd "$HOME/SillyTavern"
        echo -e "${GREEN}${BOLD}>> 🚀 正在启动，请稍等...${NC}"
        if [ -f "start.sh" ]; then
            bash start.sh
        else
            npm start
        fi
        press_any_key
        cd "$HOME"
    else
        echo -e "${RED}${BOLD}>> 😿 未检测到 SillyTavern 目录，请先安装。${NC}"
        sleep 2
    fi
}

# =========================================================================
# 2. 更新酒馆
# =========================================================================
update_tavern() {
    echo -e "\n${CYAN}${BOLD}==== 🔄 更新 SillyTavern 🔄 ====${NC}"
    if [ -d "$HOME/SillyTavern" ]; then
        cd "$HOME/SillyTavern"
        echo -e "${CYAN}${BOLD}>> 📥 正在拉取最新代码...${NC}"
        if git pull; then
            echo -e "${GREEN}${BOLD}>> ✅ 更新成功！${NC}"
        else
            echo -e "${RED}${BOLD}>> 💔 更新失败，请检查网络或手动更新。${NC}"
        fi
        press_any_key
        cd "$HOME"
    else
        echo -e "${RED}${BOLD}>> 😿 未检测到 SillyTavern 目录。${NC}"
        sleep 2
    fi
}

# =========================================================================
# 主菜单循环
# =========================================================================
while true; do
    clear
    echo -e "${CYAN}${BOLD}"
    echo "🌸🌸🌸🌸🌸🌸🌸🌸🌸🌸🌸🌸🌸🌸🌸🌸"
    echo "🌸       SillyTavern 极简版       🌸"
    echo "🌸         💕 By Mio酱 💕         🌸"
    echo "🌸🌸🌸🌸🌸🌸🌸🌸🌸🌸🌸🌸🌸🌸🌸🌸"
    echo -e "${NC}"
    echo -e "${GREEN}${BOLD}1. 🚀 启动 SillyTavern${NC}"
    echo -e "${YELLOW}${BOLD}2. 🔄 更新 SillyTavern${NC}"
    echo -e "${RED}${BOLD}3. 👋 退出${NC}"
    echo -e "${CYAN}${BOLD}=================================${NC}"
    echo -ne "${CYAN}${BOLD}💕 请选择操作 [1-3]: ${NC}"
    read -n1 choice
    echo

    case "$choice" in
        1)
            start_tavern
            ;;
        2)
            update_tavern
            ;;
        3)
            echo -e "${RED}${BOLD}>> 👋 再见啦爸爸，期待下次见面~${NC}"
            sleep 1
            clear
            exit 0
            ;;
        *)
            echo -e "${RED}${BOLD}>> 😅 输入错误，请重新选择哦~${NC}"
            sleep 1
            ;;
    esac
done
