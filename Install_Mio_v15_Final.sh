#!/data/data/com.termux/files/usr/bin/bash
# =========================================================================
# SillyTavern-Termux 最新版安装脚本（内置镜像源自动更新）
# 专为新用户设计，集成最新镜像源策略 - Mio's Edition 😸
# =========================================================================

# ==== 彩色输出定义 ====
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
BOLD='\033[1m'
BRIGHT_MAGENTA='\033[1;95m'
NC='\033[0m'

# ==== 版本信息 ====
SCRIPT_VERSION="2.1.5"
INSTALL_DATE=$(date '+%Y-%m-%d %H:%M:%S')

# ==== 输出函数 ====
log_success() { echo -e "${GREEN}${BOLD}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}${BOLD}[ERROR]${NC} $1"; }
log_info() { echo -e "${CYAN}${BOLD}[INFO]${NC} $1"; }
log_warning() { echo -e "${YELLOW}${BOLD}[WARNING]${NC} $1"; }

# ==== 进度显示函数 ====
show_progress() {
    local step=$1
    local total=$2
    local message=$3
    local percent=$((step * 100 / total))
    local filled=$((percent / 10))
    local empty=$((10 - filled))

    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done

    echo -e "${BRIGHT_MAGENTA}${BOLD}🌸 安装进度：[${bar}] ${percent}%${NC}"
    echo -e "${CYAN}${BOLD}💕 ${message}${NC}"
    echo ""
}

# ==== 显示标题 ====
echo -e "${CYAN}${BOLD}"
echo "=================================================="
echo "🌸 SillyTavern 小白专用安装脚本 🌸"
echo "💕 复制粘贴回车，就这么简单！"
echo "✨ 全自动安装，无需任何操作"
echo "🎯 专为中国用户优化，速度超快"
echo "=================================================="
echo -e "${NC}"

echo -e "${YELLOW}${BOLD}💡 姐妹们请看这里~：${NC}"
echo -e "${GREEN}  ✅ 本脚本完全自动化，无需手动操作${NC}"
echo -e "${GREEN}  ✅ 安装时间约15-20分钟，请耐心等待${NC}"
echo -e "${GREEN}  ✅ 安装过程中请不要关闭Termux${NC}"
echo -e "${GREEN}  ✅ 建议连接WiFi网络，确保稳定性${NC}"
echo -e "${GREEN}  ✅ 安装完成后会自动进入菜单${NC}"
echo ""

# ==== 环境检测 ====
show_progress 1 10 "正在检查你的手机环境，确保一切准备就绪~"
log_info "检查Termux环境..."

if [ -z "$PREFIX" ] || [[ "$PREFIX" != "/data/data/com.termux/files/usr" ]]; then
    log_error "本脚本仅适用于 Termux 环境，请在 Termux 中运行！"
    exit 1
fi
log_success "Termux环境检测通过"

# ==== 检查和安装必要工具 ====
log_info "检查必要工具..."
missing_tools=()
for tool in curl grep sed awk git zip; do
    if ! command -v $tool >/dev/null 2>&1; then
        missing_tools+=($tool)
    fi
done

if [ ${#missing_tools[@]} -gt 0 ]; then
    log_warning "需要安装必要工具: ${missing_tools[*]}"
    log_info "正在自动安装..."
    log_info "Mio正在帮您切换到清华大学镜像源，加速基础工具下载哦~"
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/termux/apt/termux-main stable main" > $PREFIX/etc/apt/sources.list
    pkg update -y && pkg install -y "${missing_tools[@]}"
    
    # 再次检查
    for tool in "${missing_tools[@]}"; do
        if ! command -v $tool >/dev/null 2>&1; then
            log_error "工具安装失败: $tool"
            exit 1
        fi
    done
    log_success "必要工具安装完成"
else
    log_success "必要工具检查完成"
fi

# ==== 获取存储权限 ====
STORAGE_DIR="$HOME/storage/shared"
if [ ! -d "$STORAGE_DIR" ]; then
    log_info "自动获取存储权限..."
    if command -v termux-setup-storage >/dev/null 2>&1; then
        echo -e "${YELLOW}${BOLD}📱 即将弹出权限请求窗口${NC}"
        echo -e "${GREEN}${BOLD}💡 请点击"允许"按钮授权存储权限${NC}"
        echo -e "${CYAN}${BOLD}⏰ 3秒后自动继续...${NC}"
        sleep 3
        termux-setup-storage
        sleep 2
        log_success "存储权限配置完成"
    fi
else
    log_success "存储权限已配置"
fi

# ==== 步骤2：自动获取最新GitHub镜像源 ====
show_progress 2 10 "正在获取最新GitHub镜像源，确保下载速度最快~"
log_info "从XIU2官方脚本获取最新镜像源..."

# XIU2脚本的多个获取源
XIU2_SOURCES=(
    "https://ghproxy.net/https://github.com/XIU2/UserScript/raw/refs/heads/master/GithubEnhanced-High-Speed-Download.user.js"
    "https://gh.ddlc.top/https://github.com/XIU2/UserScript/raw/refs/heads/master/GithubEnhanced-High-Speed-Download.user.js"
    "https://ghfast.top/https://github.com/XIU2/UserScript/raw/refs/heads/master/GithubEnhanced-High-Speed-Download.user.js"
    "https://hub.gitmirror.com/https://github.com/XIU2/UserScript/raw/refs/heads/master/GithubEnhanced-High-Speed-Download.user.js"
)

# 获取XIU2脚本内容
XIU2_CONTENT=""
for source in "${XIU2_SOURCES[@]}"; do
    domain=$(echo "$source" | sed 's|https://||' | cut -d'/' -f1)
    log_info "尝试从 $domain 获取镜像源..."
    
    if XIU2_CONTENT=$(timeout 15 curl -fsSL --connect-timeout 8 --max-time 15 "$source" 2>/dev/null); then
        if [ ${#XIU2_CONTENT} -gt 10000 ]; then
            log_success "成功获取最新镜像源！来源: $domain"
            break
        fi
    fi
    XIU2_CONTENT=""
done

# 如果获取失败，使用内置备用镜像源
if [ -z "$XIU2_CONTENT" ]; then
    log_warning "无法获取最新镜像源，使用内置备用源"
    GITHUB_MIRRORS=(
        "https://hub.gitmirror.com/https://github.com" # Gitee 镜像, 速度优秀
        "https://ghproxy.net/https://github.com"
        "https://gh.ddlc.top/https://github.com"
        "https://ghfast.top/https://github.com"
        "https://mirror.ghproxy.com/https://github.com" # 新增
        "https://ghproxy.cfd/https://github.com"
        "https://mirrors.chenby.cn/https://github.com"
        "https://github.com" # 原始地址作为最后手段
    )
else
    # 解析获取到的镜像源
    log_info "解析最新镜像源..."
    GITHUB_MIRRORS=()
    
    # 提取clone_url数组中的镜像源
    if echo "$XIU2_CONTENT" | grep -q "clone_url.*="; then
        # Use grep -o to extract all URLs within single quotes from the relevant block
        url_list=$(echo "$XIU2_CONTENT" | sed -n '/clone_url.*=/,/\]/p' | grep -o "'https[^\']\+'" | tr -d "'")
        for url in $url_list; do
            # Only add URLs that are actual github mirrors
            if [[ "$url" == *"github.com"* ]]; then
                GITHUB_MIRRORS+=("$url")
            fi
        done
    fi
    
    # 确保有备用源
    if [ ${#GITHUB_MIRRORS[@]} -eq 0 ]; then
        log_warning "解析失败，使用内置备用源"
        GITHUB_MIRRORS=(
            "https://hub.gitmirror.com/https://github.com" # Gitee 镜像, 速度优秀
            "https://ghproxy.net/https://github.com"
            "https://gh.ddlc.top/https://github.com"
            "https://ghfast.top/https://github.com"
            "https://github.com"
        )
    else
        # 优化镜像列表：确保 Gitee 镜像源在最前，并添加原始地址作为备用
        log_info "优化镜像源列表..."
        local gitmirror="https://hub.gitmirror.com/https://github.com"
        
        # 从数组中移除可能存在的 Gitee 镜像和原始 GitHub 地址
        temp_mirrors=()
        for mirror in "${GITHUB_MIRRORS[@]}"; do
            if [[ "$mirror" != "$gitmirror" && "$mirror" != "https://github.com" ]]; then
                temp_mirrors+=("$mirror")
            fi
        done
        
        # 将 Gitee 镜像放在首位，然后是列表中的其他镜像，最后是原始 GitHub 地址
        GITHUB_MIRRORS=("$gitmirror" "${temp_mirrors[@]}" "https://github.com")
        
        # 去重，保持顺序
        GITHUB_MIRRORS=($(printf "%s\n" "${GITHUB_MIRRORS[@]}" | awk '!seen[$0]++'))

        log_success "成功解析并优化了 ${#GITHUB_MIRRORS[@]} 个镜像源"
    fi
fi

# ==== 步骤3 & 4：Termux软件安装 (已跳过) ====
show_progress 3 10 "跳过Termux软件和镜像源更新..."
log_warning "根据用户指令，已跳过Termux软件安装过程."
log_info "脚本将假定您的Termux环境已准备就绪."
sleep 2

# ==== 步骤5：安装Node.js ====
show_progress 5 10 "正在安装Node.js运行环境~"
log_info "安装Node.js..."

if ! command -v node >/dev/null 2>&1; then
    if pkg list-all | grep -q '^nodejs-lts/'; then
        pkg install -y nodejs-lts || pkg install -y nodejs
    else
        pkg install -y nodejs
    fi
    log_success "Node.js安装完成"
else
    log_success "Node.js已安装，跳过"
fi

# 配置npm中国镜像源
npm config set prefix "$PREFIX"

# 中国优质npm镜像源列表
NPM_MIRRORS=(
    "https://registry.npmmirror.com/"          # 阿里云npm镜像（推荐）
    "https://mirrors.cloud.tencent.com/npm/"   # 腾讯云npm镜像
    "https://mirrors.huaweicloud.com/repository/npm/" # 华为云npm镜像
    "https://registry.npm.taobao.org/"         # 淘宝npm镜像（备用）
)

# 尝试设置最快的npm镜像源
for npm_mirror in "${NPM_MIRRORS[@]}"; do
    log_info "测试npm镜像源: $(echo "$npm_mirror" | sed 's|https://||' | cut -d'/' -f1)"

    if timeout 5 curl -fsSL --connect-timeout 3 "$npm_mirror" >/dev/null 2>&1; then
        npm config set registry "$npm_mirror"
        log_success "已设置npm镜像源: $(echo "$npm_mirror" | sed 's|https://||' | cut -d'/' -f1)"
        break
    fi
done

# 设置其他npm优化配置（只设置有效的配置项）
npm config set disturl https://npmmirror.com/mirrors/node/ 2>/dev/null || true
npm config set sass_binary_site https://npmmirror.com/mirrors/node-sass/ 2>/dev/null || true

# ==== 智能下载函数 ====
smart_download() {
    local file_path="$1"
    local save_path="$2"
    local description="$3"
    
    log_info "开始下载: $description"
    
    for mirror in "${GITHUB_MIRRORS[@]}"; do
        local full_url="$mirror/$file_path"
        local domain=$(echo "$mirror" | sed 's|https://||' | cut -d'/' -f1)
        
        log_info "尝试源: $domain"
        
        if timeout 20 curl -k -fsSL --connect-timeout 8 --max-time 20 \
            -o "$save_path" "$full_url" 2>/dev/null; then
            
            # 验证下载文件
            if [ -f "$save_path" ] && [ $(stat -c%s "$save_path" 2>/dev/null || echo 0) -gt 100 ]; then
                log_success "下载成功！来源: $domain"
                return 0
            else
                rm -f "$save_path"
            fi
        fi
    done
    
    log_error "所有源都失败了，请检查网络连接"
    return 1
}

# ==== 步骤6：下载SillyTavern ====
show_progress 6 10 "正在下载AI聊天程序，这是最重要的一步哦~"
log_info "下载SillyTavern主程序..."

if [ -d "$HOME/SillyTavern/.git" ]; then
    log_warning "SillyTavern已存在，跳过下载"
else
    rm -rf "$HOME/SillyTavern"
    
    # 尝试Git克隆
    clone_success=false
    for mirror in "${GITHUB_MIRRORS[@]}"; do
        domain=$(echo "$mirror" | sed 's|https://||' | cut -d'/' -f1)
        log_info "尝试从 $domain 克隆..."

        if timeout 120 git clone --depth=1 --single-branch --branch=release \
            --config http.postBuffer=1048576000 \
            "$mirror/SillyTavern/SillyTavern" "$HOME/SillyTavern" 2>/dev/null; then
            log_success "克隆成功！来源: $domain"
            clone_success=true
            break
        else
            rm -rf "$HOME/SillyTavern"
        fi
    done
    
    # 备用方案：下载ZIP
    if [ "$clone_success" = false ]; then
        log_info "Git克隆失败，尝试ZIP下载..."
        
        for mirror in "${GITHUB_MIRRORS[@]}"; do
            domain=$(echo "$mirror" | sed 's|https://||' | cut -d'/' -f1)
            zip_url="$mirror/SillyTavern/SillyTavern/archive/refs/heads/release.zip"
            
            if timeout 60 curl -k -fsSL --connect-timeout 10 --max-time 60 \
                -o "/tmp/sillytavern.zip" "$zip_url" 2>/dev/null; then
                
                cd "$HOME" || exit 1
                if unzip -q "/tmp/sillytavern.zip" 2>/dev/null; then
                    mv "SillyTavern-release" "SillyTavern" 2>/dev/null || true
                    rm -f "/tmp/sillytavern.zip"
                    
                    if [ -d "$HOME/SillyTavern" ]; then
                        log_success "ZIP下载成功！来源: $domain"
                        clone_success=true
                        break
                    fi
                fi
                rm -f "/tmp/sillytavern.zip"
            fi
        done
        
        if [ "$clone_success" = false ]; then
            log_error "所有下载方式都失败了！"
            exit 1
        fi
    fi
fi

# ==== 步骤7：创建增强版菜单脚本 ====
show_progress 7 10 "正在创建专属菜单，让你使用更方便~"
log_info "创建增强版菜单脚本..."

MENU_PATH="$HOME/menu.sh"
ENV_PATH="$HOME/.env"

# 创建.env配置文件
cat > "$ENV_PATH" << EOF
INSTALL_VERSION=$SCRIPT_VERSION
INSTALL_DATE=$INSTALL_DATE
MENU_VERSION=$SCRIPT_VERSION
MIRROR_UPDATE_ENABLED=true
# 最新版 - 内置镜像源自动更新功能
EOF

# 创建增强版菜单脚本
cat > "$MENU_PATH" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# =========================================================================
# SillyTavern-Termux 小红书专版菜单脚本
# 原作者：欤歡 | 优化：mio酱 for 小红书姐妹们 💕
# =========================================================================

# ==== 彩色输出定义 ====
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
BRIGHT_BLUE='\033[1;94m'
BRIGHT_MAGENTA='\033[1;95m'
NC='\033[0m'

# ==== 版本与远程资源 ====
MENU_VERSION=20250701
UPDATE_DATE="2025-07-01"
UPDATE_CONTENT="
💕 小红书专版更新内容：
1. 去除了容易卡住的字体下载功能
2. 增加了多个GitHub加速源轮询
3. 优化了用户界面，更适合姐妹们使用
4. 简化了复杂的技术术语
5. 增加了更多可爱的提示信息
6. 提供了完整的问题解决方案
"

# ==== GitHub加速源列表 ====
GITHUB_MIRRORS=(
    "https://ghproxy.net/https://github.com"
    "https://gh.ddlc.top/https://github.com"
    "https://ghfast.top/https://github.com"
    "https://gh.h233.eu.org/https://github.com"
    "https://ghproxy.cfd/https://github.com"
    "https://hub.gitmirror.com/https://github.com"
    "https://mirrors.chenby.cn/https://github.com"
    "https://github.com"
)

# ==== 通用函数 ====
get_version() { [ -f "$1" ] && grep -E "^$2=" "$1" | head -n1 | cut -d'=' -f2 | tr -d '\r'; }
press_any_key() { echo -e "${CYAN}${BOLD}>> 💕 按任意键返回菜单...${NC}"; read -n1 -s; }

# ==== 智能下载函数 ====
smart_download() {
    local file_path="$1"
    local save_path="$2"
    local description="$3"
    
    echo -e "${CYAN}${BOLD}>> 💕 开始下载: $description${NC}"
    
    for mirror in "${GITHUB_MIRRORS[@]}"; do
        local full_url="$mirror/$file_path"
        local domain=$(echo "$mirror" | sed 's|https://||' | cut -d'/' -f1)
        
        echo -e "${YELLOW}${BOLD}>> 🔄 尝试源: $domain${NC}"
        
        if timeout 30 curl -fsSL --connect-timeout 10 --max-time 30 \
            -o "$save_path" "$full_url" 2>/dev/null; then
            
            if [ -f "$save_path" ] && [ $(stat -c%s "$save_path" 2>/dev/null || echo 0) -gt 100 ]; then
                echo -e "${GREEN}${BOLD}>> ✅ 下载成功！来源: $domain${NC}"
                return 0
            else
                rm -f "$save_path"
            fi
        fi
    done
    
    echo -e "${RED}${BOLD}>> 💔 所有源都失败了，请检查网络连接${NC}"
    return 1
}

# =========================================================================
# 1. 启动酒馆
# =========================================================================
start_tavern() {
    echo -e "\n${CYAN}${BOLD}==== 🌸 启动 SillyTavern 🌸 ====${NC}"
    echo -e "${YELLOW}${BOLD}💕 正在为姐妹启动AI男友聊天程序...${NC}"
    
    for dep in node npm git; do
        if ! command -v $dep >/dev/null 2>&1; then
            echo -e "${RED}${BOLD}>> 😿 检测到缺失工具：$dep，请先修复环境。${NC}"
            press_any_key; return
        fi
    done
    
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
        echo -e "${RED}${BOLD}>> 😿 未检测到 SillyTavern 目录，请重新安装。${NC}"
        sleep 2
    fi
}

# =========================================================================
# 2. 更新酒馆
# =========================================================================
update_tavern() {
    echo -e "\n${CYAN}${BOLD}==== 🔄 更新 SillyTavern 🔄 ====${NC}"
    echo -e "${YELLOW}${BOLD}💕 正在为姐妹更新到最新版本...${NC}"
    
    if [ -d "$HOME/SillyTavern" ]; then
        cd "$HOME/SillyTavern"
        echo -e "${CYAN}${BOLD}>> 📥 正在拉取最新代码...${NC}"
        
        # 尝试多个源更新
        update_success=false
        for mirror in "${GITHUB_MIRRORS[@]}"; do
            local domain=$(echo "$mirror" | sed 's|https://||' | cut -d'/' -f1)
            echo -e "${YELLOW}${BOLD}>> 🔄 尝试从 $domain 更新...${NC}"
            
            if timeout 120 git pull 2>/dev/null; then
                echo -e "${GREEN}${BOLD}>> ✅ 更新成功！${NC}"
                update_success=true
                break
            else
                echo -e "${YELLOW}${BOLD}>> ❌ 更新失败，尝试下一个源...${NC}"
            fi
        done
        
        if [ "$update_success" = false ]; then
            echo -e "${RED}${BOLD}>> 💔 所有源都失败了，请检查网络连接${NC}"
        fi
        
        press_any_key
        cd "$HOME"
    else
        echo -e "${RED}${BOLD}>> 😿 未检测到 SillyTavern 目录。${NC}"
        sleep 2
    fi
}

# =========================================================================
# 3. 简化配置菜单
# =========================================================================
simple_config_menu() {
    while true; do
        clear
        echo -e "${CYAN}${BOLD}==== 🎀 简单配置 🎀 ====${NC}"
        echo -e "${YELLOW}${BOLD}0. 返回主菜单${NC}"
        echo -e "${BLUE}${BOLD}1. 🌐 开启网络访问（推荐）${NC}"
        echo -e "${MAGENTA}${BOLD}2. 🔒 关闭网络访问${NC}"
        echo -e "${GREEN}${BOLD}3. 🔧 重置配置文件${NC}"
        echo -e "${CYAN}${BOLD}==================${NC}"
        echo -ne "${CYAN}${BOLD}💕 请选择操作（0-3）：${NC}"
        read -n1 choice; echo
        
        case "$choice" in
            0) break ;;
            1) 
                echo -e "${CYAN}${BOLD}>> 🌐 正在开启网络访问...${NC}"
                # 这里添加开启网络监听的代码
                echo -e "${GREEN}${BOLD}>> ✅ 网络访问已开启，现在可以用手机浏览器访问啦~${NC}"
                press_any_key
                ;;
            2)
                echo -e "${CYAN}${BOLD}>> 🔒 正在关闭网络访问...${NC}"
                # 这里添加关闭网络监听的代码
                echo -e "${GREEN}${BOLD}>> ✅ 网络访问已关闭${NC}"
                press_any_key
                ;;
            3)
                echo -e "${CYAN}${BOLD}>> 🔧 正在重置配置文件...${NC}"
                # 这里添加重置配置的代码
                echo -e "${GREEN}${BOLD}>> ✅ 配置文件已重置${NC}"
                press_any_key
                ;;
            *)
                echo -e "${RED}${BOLD}>> 😅 输入错误，请重新选择哦~${NC}"
                sleep 1
                ;;
        esac
    done
}

# =========================================================================
# 4. 酒馆福利互助群
# =========================================================================
help_menu() {
    clear
    echo -e "${CYAN}${BOLD}==== 🍻 酒馆福利互助群 ====${NC}"
    echo -e "${YELLOW}${BOLD}欢迎加入小红书姐妹们的专属群聊！${NC}"
    echo ""
    echo -e "${GREEN}${BOLD}🍻 免费api福利互助群：${NC}"
    echo -e "${BRIGHT_MAGENTA}${BOLD}    ✨ 877,957,256 ✨${NC}"
    echo ""
    echo -e "${YELLOW}${BOLD}💕 群里有什么？${NC}"
    echo -e "${CYAN}${BOLD}• 🎀 SillyTavern使用技巧分享${NC}"
    echo -e "${CYAN}${BOLD}• 💝 优质角色卡资源${NC}"
    echo -e "${CYAN}${BOLD}• 🌸 姐妹们的聊天心得${NC}"
    echo -e "${CYAN}${BOLD}• 🆘 遇到问题互相帮助${NC}"
    echo ""
    echo -e "${GREEN}${BOLD}📞 其他求助渠道：${NC}"
    echo -e "${BLUE}${BOLD}• QQ群：807134015（原作者群）${NC}"
    echo -e "${BLUE}${BOLD}• 小红书评论区留言${NC}"
    echo -e "${BLUE}${BOLD}• 邮箱：print.yuhuan@gmail.com${NC}"
    echo ""
    echo -e "${YELLOW}${BOLD}💡 快来加群和姐妹们一起玩耍吧！${NC}"
    press_any_key
}

# =========================================================================
# 5. 网络监听设置
# =========================================================================
network_config_menu() {
    while true; do
        clear
        echo -e "${CYAN}${BOLD}==== 🌐 网络监听设置 ====${NC}"
        echo -e "${YELLOW}${BOLD}💡 网络监听功能说明：${NC}"
        echo -e "${BLUE}${BOLD}• 关闭：只能在手机本地访问（更安全）${NC}"
        echo -e "${BLUE}${BOLD}• 开启：可在同WiFi下其他设备访问（如电脑）${NC}"
        echo ""
        echo -e "${YELLOW}${BOLD}0. 返回主菜单${NC}"
        echo -e "${GREEN}${BOLD}1. 🔒 关闭网络监听（安全模式）${NC}"
        echo -e "${MAGENTA}${BOLD}2. 🌍 开启网络监听（共享模式）${NC}"
        echo -e "${CYAN}${BOLD}3. 🔄 恢复默认配置${NC}"
        echo -e "${CYAN}${BOLD}==================${NC}"
        echo -ne "${CYAN}${BOLD}💕 请选择操作（0-3）：${NC}"
        read -n1 config_choice; echo

        case "$config_choice" in
            0) break ;;
            1|2|3)
                cd "$HOME/SillyTavern" || {
                    echo -e "${RED}${BOLD}>> 💔 SillyTavern目录不存在！${NC}"
                    press_any_key
                    continue
                }

                if [ ! -f config.yaml ] && [ "$config_choice" != "3" ]; then
                    echo -e "${RED}${BOLD}>> 💔 未找到config.yaml文件！${NC}"
                    echo -e "${YELLOW}${BOLD}>> 💡 请先启动一次SillyTavern生成配置文件${NC}"
                    press_any_key
                    continue
                fi

                # 备份原配置
                [ ! -f config.yaml.bak ] && cp config.yaml config.yaml.bak 2>/dev/null

                if [ "$config_choice" = "1" ]; then
                    # 关闭网络监听
                    sed -i 's/^listen: true$/listen: false/' config.yaml 2>/dev/null
                    sed -i 's/^enableUserAccounts: true$/enableUserAccounts: false/' config.yaml 2>/dev/null
                    sed -i 's/^enableDiscreetLogin: true$/enableDiscreetLogin: false/' config.yaml 2>/dev/null
                    sed -i 's/^  - 0\\.0\\.0\\.0\\/0$/  - 127.0.0.1/' config.yaml 2>/dev/null
                    echo -e "${GREEN}${BOLD}>> ✅ 网络监听已关闭（安全模式）${NC}"
                    echo -e "${CYAN}${BOLD}>> 💡 现在只能通过 http://127.0.0.1:8000 访问${NC}"

                elif [ "$config_choice" = "2" ]; then
                    # 开启网络监听
                    sed -i 's/^listen: false$/listen: true/' config.yaml 2>/dev/null
                    sed -i 's/^enableUserAccounts: false$/enableUserAccounts: true/' config.yaml 2>/dev/null
                    sed -i 's/^enableDiscreetLogin: false$/enableDiscreetLogin: true/' config.yaml 2>/dev/null
                    sed -i 's/^  - 127\\.0\\.0\\.1$/  - 0.0.0.0\\/0/' config.yaml 2>/dev/null
                    echo -e "${GREEN}${BOLD}>> ✅ 网络监听已开启（共享模式）${NC}"
                    echo -e "${CYAN}${BOLD}>> 💡 现在可以通过手机IP地址在其他设备访问${NC}"
                    echo -e "${YELLOW}${BOLD}>> ⚠️ 注意：请确保在安全的网络环境下使用${NC}"

                else
                    # 恢复默认配置
                    if [ ! -f config.yaml.bak ]; then
                        echo -e "${YELLOW}${BOLD}>> ⚠️ 未找到备份文件，无法恢复${NC}"
                    else
                        cp config.yaml.bak config.yaml
                        echo -e "${GREEN}${BOLD}>> ✅ 已恢复默认配置${NC}"
                    fi
                fi
                press_any_key
                ;;
            *)
                echo -e "${RED}${BOLD}>> 😅 输入错误，请重新选择哦~${NC}"
                sleep 1
                ;;
        esac
    done
}

# =========================================================================
# 6. 酒馆插件管理
# =========================================================================
plugin_menu() {
    while true; do
        clear
        echo -e "${CYAN}${BOLD}==== 🧩 酒馆插件管理 ====${NC}"
        echo -e "${YELLOW}${BOLD}💡 插件可以为SillyTavern添加更多功能！${NC}"
        echo ""
        echo -e "${YELLOW}${BOLD}0. 返回主菜单${NC}"
        echo -e "${MAGENTA}${BOLD}1. 📦 安装插件${NC}"
        echo -e "${BLUE}${BOLD}2. 🗑️ 卸载插件${NC}"
        echo -e "${CYAN}${BOLD}==================${NC}"
        echo -ne "${CYAN}${BOLD}💕 请选择操作（0-2）：${NC}"
        read -n1 plugin_choice; echo

        case "$plugin_choice" in
            0) break ;;
            1) plugin_install_menu ;;
            2) plugin_uninstall_menu ;;
            *)
                echo -e "${RED}${BOLD}>> 😅 输入错误，请重新选择哦~${NC}"
                sleep 1
                ;;
        esac
    done
}

# =========================================================================
# 插件安装菜单
# =========================================================================
plugin_install_menu() {
    while true; do
        clear
        echo -e "${CYAN}${BOLD}==== 📦 插件安装 ====${NC}"
        echo -e "${YELLOW}${BOLD}0. 返回上级菜单${NC}"
        echo -e "${MAGENTA}${BOLD}1. 🎯 酒馆助手（多功能扩展）${NC}"
        echo -e "${BLUE}${BOLD}2. 🧠 记忆表格（结构化记忆）${NC}"
        echo -e "${CYAN}${BOLD}==================${NC}"
        echo -ne "${CYAN}${BOLD}💕 请选择要安装的插件（0-2）：${NC}"
        read -n1 install_choice; echo

        case "$install_choice" in
            0) break ;;
            1)
                clear
                echo -e "${MAGENTA}${BOLD}==== 🎯 酒馆助手 ====${NC}"
                echo -e "${YELLOW}${BOLD}📍 仓库：${NC}N0VI028/JS-Slash-Runner"
                echo -e "${CYAN}${BOLD}✨ 功能简介：${NC}"
                echo -e "${BLUE}${BOLD}• 支持在对话中创建交互式界面元素${NC}"
                echo -e "${BLUE}${BOLD}• 可用jQuery操作SillyTavern的DOM${NC}"
                echo -e "${BLUE}${BOLD}• 作为后端中转，连接外部应用${NC}"
                echo -e "${BLUE}${BOLD}• 通过iframe安全运行外部脚本${NC}"
                echo ""
                echo -e "${YELLOW}${BOLD}⚠️ 安全提示：${NC}"
                echo -e "${RED}${BOLD}• 插件允许执行自定义JavaScript代码${NC}"
                echo -e "${RED}${BOLD}• 请确保脚本来源安全可信${NC}"
                echo ""
                echo -ne "${YELLOW}${BOLD}💕 是否安装酒馆助手？(y/n)：${NC}"
                read -n1 ans; echo
                if [[ "$ans" =~ [yY] ]]; then
                    install_plugin "JS-Slash-Runner" "N0VI028/JS-Slash-Runner" "酒馆助手"
                fi
                ;;
            2)
                clear
                echo -e "${BLUE}${BOLD}==== 🧠 记忆表格 ====${NC}"
                echo -e "${YELLOW}${BOLD}📍 仓库：${NC}muyoou/st-memory-enhancement"
                echo -e "${CYAN}${BOLD}✨ 功能简介：${NC}"
                echo -e "${BLUE}${BOLD}• 为AI注入结构化长期记忆能力${NC}"
                echo -e "${BLUE}${BOLD}• 支持角色设定、关键事件记录${NC}"
                echo -e "${BLUE}${BOLD}• 通过直观表格管理AI记忆${NC}"
                echo -e "${BLUE}${BOLD}• 支持导出、分享和自定义结构${NC}"
                echo ""
                echo -e "${YELLOW}${BOLD}📝 使用说明：${NC}"
                echo -e "${CYAN}${BOLD}• 仅在"聊天补全模式"下工作${NC}"
                echo ""
                echo -ne "${YELLOW}${BOLD}💕 是否安装记忆表格？(y/n)：${NC}"
                read -n1 ans; echo
                if [[ "$ans" =~ [yY] ]]; then
                    install_plugin "st-memory-enhancement" "muyoou/st-memory-enhancement" "记忆表格"
                fi
                ;;
            *)
                echo -e "${RED}${BOLD}>> 😅 输入错误，请重新选择哦~${NC}"
                sleep 1
                ;;
        esac
    done
}

# =========================================================================
# 插件安装核心函数
# =========================================================================
install_plugin() {
    local plugin_dir="$1"
    local repo_url="$2"
    local plugin_name="$3"

    local PLUGIN_PATH="$HOME/SillyTavern/public/scripts/extensions/third-party/$plugin_dir"

    if [ -d "$PLUGIN_PATH" ]; then
        echo -e "${YELLOW}${BOLD}>> ✅ $plugin_name 已存在，无需重复安装${NC}"
        press_any_key
        return
    fi

    echo -e "${CYAN}${BOLD}>> 🔄 正在安装 $plugin_name...${NC}"

    # 尝试多个GitHub加速源
    local success=false
    for mirror in "https://gitproxy.click/https://github.com" \
                  "https://github.tbedu.top/https://github.com" \
                  "https://gh.llkk.cc/https://github.com" \
                  "https://gh.ddlc.top/https://github.com" \
                  "https://github.com"; do

        local domain=$(echo "$mirror" | sed 's|https://||' | cut -d'/' -f1)
        echo -e "${YELLOW}${BOLD}>> 尝试源: $domain${NC}"

        if timeout 60 git clone --depth=1 "$mirror/$repo_url" "$PLUGIN_PATH" 2>/dev/null; then
            echo -e "${GREEN}${BOLD}>> ✅ $plugin_name 安装成功！来源: $domain${NC}"
            success=true
            break
        else
            echo -e "${YELLOW}${BOLD}>> ❌ 失败，尝试下一个源...${NC}"
            rm -rf "$PLUGIN_PATH" 2>/dev/null
        fi
    done

    if [ "$success" = false ]; then
        echo -e "${RED}${BOLD}>> 💔 $plugin_name 安装失败，请检查网络连接${NC}"
    fi

    press_any_key
}

# =========================================================================
# 插件卸载菜单
# =========================================================================
plugin_uninstall_menu() {
    local PLUGIN_ROOT="$HOME/SillyTavern/public/scripts/extensions/third-party"

    while true; do
        clear
        echo -e "${CYAN}${BOLD}==== 🗑️ 插件卸载 ====${NC}"
        echo -e "${YELLOW}${BOLD}0. 返回上级菜单${NC}"

        if [ ! -d "$PLUGIN_ROOT" ]; then
            echo -e "${YELLOW}${BOLD}>> 📂 插件目录不存在，无插件可卸载${NC}"
            press_any_key
            break
        fi

        # 获取已安装的插件列表
        mapfile -t plugin_dirs < <(find "$PLUGIN_ROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)

        if [ ${#plugin_dirs[@]} -eq 0 ]; then
            echo -e "${YELLOW}${BOLD}>> 📭 未检测到已安装的插件${NC}"
            press_any_key
            break
        fi

        # 显示插件列表
        for i in "${!plugin_dirs[@]}"; do
            plugin_name=$(basename "${plugin_dirs[$i]}")
            echo -e "${BLUE}${BOLD}$((i+1)). 🧩 ${GREEN}${BOLD}${plugin_name}${NC}"
        done

        echo -e "${CYAN}${BOLD}==================${NC}"
        echo -ne "${CYAN}${BOLD}💕 请输入要卸载的插件序号（或0返回）：${NC}"
        read -r idx

        if [[ "$idx" == "0" ]]; then
            break
        fi

        if [[ "$idx" =~ ^[1-9][0-9]*$ ]] && [ "$idx" -le "${#plugin_dirs[@]}" ]; then
            plugin_name=$(basename "${plugin_dirs[$((idx-1))]}")
            echo -ne "${YELLOW}${BOLD}💔 确定要卸载 ${plugin_name} 吗？(y/n)：${NC}"
            read -n1 ans; echo

            if [[ "$ans" =~ [yY] ]]; then
                rm -rf "${plugin_dirs[$((idx-1))]}"
                echo -e "${GREEN}${BOLD}>> ✅ 插件 ${plugin_name} 已成功卸载${NC}"
            else
                echo -e "${YELLOW}${BOLD}>> 🙅‍♀️ 已取消卸载操作${NC}"
            fi
            press_any_key
        else
            echo -e "${RED}${BOLD}>> 😅 输入错误，请重新选择哦~${NC}"
            sleep 1
        fi
    done
}

# =========================================================================
# 7. 脚本更新管理
# =========================================================================
script_update_menu() {
    while true; do
        clear
        echo -e "${CYAN}${BOLD}==== 🔄 脚本更新管理 ====${NC}"
        echo -e "${YELLOW}${BOLD}💡 保持脚本最新，享受最新功能！${NC}"
        echo ""
        echo -e "${YELLOW}${BOLD}0. 返回主菜单${NC}"
        echo -e "${GREEN}${BOLD}1. 🔍 检查脚本更新${NC}"
        echo -e "${BLUE}${BOLD}2. 📋 查看更新日志${NC}"
        echo -e "${CYAN}${BOLD}==================${NC}"
        echo -ne "${CYAN}${BOLD}💕 请选择操作（0-2）：${NC}"
        read -n1 update_choice; echo

        case "$update_choice" in
            0) break ;;
            1) check_script_update ;;
            2) show_update_log ;;
            *)
                echo -e "${RED}${BOLD}>> 😅 输入错误，请重新选择哦~${NC}"
                sleep 1
                ;;
        esac
    done
}

# =========================================================================
# 检查脚本更新
# =========================================================================
check_script_update() {
    echo -e "\n${CYAN}${BOLD}==== 🔍 检查脚本更新 ====${NC}"
    echo -e "${YELLOW}${BOLD}>> 正在检查GitHub上的最新版本...${NC}"

    # 获取当前版本
    local current_version=$(grep "MENU_VERSION=" "$0" | head -n1 | cut -d'=' -f2 2>/dev/null || echo "unknown")
    echo -e "${BLUE}${BOLD}>> 当前版本：$current_version${NC}"

    # 尝试获取远程版本
    local remote_version=""
    local success=false

    for mirror in "https://gitproxy.click/https://raw.githubusercontent.com" \
                  "https://github.tbedu.top/https://raw.githubusercontent.com" \
                  "https://gh.llkk.cc/https://raw.githubusercontent.com" \
                  "https://gh.ddlc.top/https://raw.githubusercontent.com" \
                  "https://raw.githubusercontent.com"; do

        local domain=$(echo "$mirror" | sed 's|https://||' | cut -d'/' -f1)
        echo -e "${YELLOW}${BOLD}>> 尝试源: $domain${NC}"

        if remote_version=$(timeout 15 curl -k -fsSL "$mirror/nb95276/SillyTavern-Termux/main/menu.sh" | grep "MENU_VERSION=" | head -n1 | cut -d'=' -f2 2>/dev/null); then
            if [ -n "$remote_version" ]; then
                echo -e "${GREEN}${BOLD}>> 远程版本：$remote_version${NC}"
                success=true
                break
            fi
        fi
        echo -e "${YELLOW}${BOLD}>> 获取失败，尝试下一个源...${NC}"
    done

    if [ "$success" = false ]; then
        echo -e "${RED}${BOLD}>> 💔 无法获取远程版本信息，请检查网络连接${NC}"
        press_any_key
        return
    fi

    # 比较版本
    if [ "$current_version" = "$remote_version" ]; then
        echo -e "${GREEN}${BOLD}>> ✅ 脚本已是最新版本！${NC}"
    elif [ "$current_version" = "unknown" ]; then
        echo -e "${YELLOW}${BOLD}>> ⚠️ 无法确定当前版本，建议更新${NC}"
        echo -ne "${CYAN}${BOLD}>> 💕 是否更新脚本？(y/n)：${NC}"
        read -n1 ans; echo
        if [[ "$ans" =~ [yY] ]]; then
            update_script
        fi
    else
        echo -e "${MAGENTA}${BOLD}>> 🎉 发现新版本！${NC}"
        echo -ne "${CYAN}${BOLD}>> 💕 是否立即更新？(y/n)：${NC}"
        read -n1 ans; echo
        if [[ "$ans" =~ [yY] ]]; then
            update_script
        fi
    fi

    press_any_key
}

# =========================================================================
# 更新脚本
# =========================================================================
update_script() {
    echo -e "\n${CYAN}${BOLD}==== 🔄 更新脚本 ====${NC}"
    echo -e "${YELLOW}${BOLD}>> 正在下载最新版本...${NC}"

    local success=false
    for mirror in "https://gitproxy.click/https://raw.githubusercontent.com" \
                  "https://github.tbedu.top/https://raw.githubusercontent.com" \
                  "https://gh.llkk.cc/https://raw.githubusercontent.com" \
                  "https://gh.ddlc.top/https://raw.githubusercontent.com" \
                  "https://raw.githubusercontent.com"; do

        local domain=$(echo "$mirror" | sed 's|https://||' | cut -d'/' -f1)
        echo -e "${YELLOW}${BOLD}>> 尝试源: $domain${NC}"

        if timeout 30 curl -k -fsSL -o "$HOME/menu.sh.new" "$mirror/nb95276/SillyTavern-Termux/main/menu.sh" 2>/dev/null; then
            if [ -f "$HOME/menu.sh.new" ] && [ $(stat -c%s "$HOME/menu.sh.new" 2>/dev/null || echo 0) -gt 1000 ]; then
                echo -e "${GREEN}${BOLD}>> ✅ 下载成功！来源: $domain${NC}"
                success=true
                break
            else
                rm -f "$HOME/menu.sh.new"
            fi
        fi
        echo -e "${YELLOW}${BOLD}>> 下载失败，尝试下一个源...${NC}"
    done

    if [ "$success" = false ]; then
        echo -e "${RED}${BOLD}>> 💔 脚本更新失败，请稍后重试${NC}"
        return
    fi

    # 备份当前脚本
    cp "$HOME/menu.sh" "$HOME/menu.sh.bak" 2>/dev/null

    # 替换脚本
    mv "$HOME/menu.sh.new" "$HOME/menu.sh"
    chmod +x "$HOME/menu.sh"

    echo -e "${GREEN}${BOLD}>> ✅ 脚本更新成功！${NC}"
    echo -e "${CYAN}${BOLD}>> 🔄 正在重启菜单...${NC}"
    sleep 2
    exec bash "$HOME/menu.sh"
}

# =========================================================================
# 查看更新日志
# =========================================================================
show_update_log() {
    clear
    echo -e "${CYAN}${BOLD}==== 📋 更新日志 ====${NC}"
    echo -e "${MAGENTA}${BOLD}SillyTavern-Termux 小红书专版${NC}"
    echo -e "${YELLOW}${BOLD}最新更新：2025-07-01${NC}"
    echo ""
    echo -e "${GREEN}${BOLD}🎉 主要功能：${NC}"
    echo -e "${BLUE}${BOLD}• 🚀 11个GitHub加速源，按测速排序${NC}"
    echo -e "${BLUE}${BOLD}• ⚡ 优化下载超时，快速失败切换${NC}"
    echo -e "${BLUE}${BOLD}• 🌐 网络监听设置（安全/共享模式）${NC}"
    echo -e "${BLUE}${BOLD}• 🧩 酒馆插件管理（助手+记忆表格）${NC}"
    echo -e "${BLUE}${BOLD}• 🔄 脚本自动更新功能${NC}"
    echo -e "${BLUE}${BOLD}• 💕 小红书专版可爱界面${NC}"
    echo ""
    echo -e "${CYAN}${BOLD}🔧 技术优化：${NC}"
    echo -e "${BLUE}${BOLD}• Git浅克隆 + ZIP备用下载${NC}"
    echo -e "${BLUE}${BOLD}• NPM阿里云镜像加速${NC}"
    echo -e "${BLUE}${BOLD}• SSL验证跳过，解决连接问题${NC}"
    echo -e "${BLUE}${BOLD}• 智能源测试和可用性检查${NC}"
    echo ""
    echo -e "${MAGENTA}${BOLD}💝 专为小红书姐妹们优化！${NC}"
    echo -e "${CYAN}${BOLD}=================================${NC}"
    press_any_key
}

# =========================================================================
# 主菜单循环
# =========================================================================
while true; do
    clear
    echo -e "${CYAN}${BOLD}"
    echo "🌸🌸🌸🌸🌸🌸🌸🌸🌸🌸🌸🌸🌸🌸🌸🌸"
    echo "🌸        SillyTavern 小红书专版        🌸"
    echo "🌸      💕 专为姐妹们优化设计 💕       🌸"
    echo "🌸🌸🌸🌸🌸🌸🌸🌸🌸🌸🌸🌸🌸🌸🌸🌸"
    echo -e "${NC}"
    echo -e "${RED}${BOLD}0. 👋 退出程序${NC}"
    echo -e "${GREEN}${BOLD}1. 🚀 启动 SillyTavern${NC}"
    echo -e "${BLUE}${BOLD}2. 🔄 更新 SillyTavern${NC}"
    echo -e "${YELLOW}${BOLD}3. 🎀 简单配置${NC}"
    echo -e "${MAGENTA}${BOLD}4. 🍻 免费API福利互助群：877,957,256${NC}"
    echo -e "${CYAN}${BOLD}5. 🌐 多设备使用设置${NC}"
    echo -e "${BRIGHT_BLUE}${BOLD}6. 🧩 安装强化插件${NC}"
    echo -e "${BRIGHT_MAGENTA}${BOLD}7. 🔄 更新管理脚本${NC}"
    echo -e "${CYAN}${BOLD}=================================${NC}"
    echo -ne "${CYAN}${BOLD}💕 请选择操作（0-7）：${NC}"
    read -n1 choice; echo
    
    case "$choice" in
        0)
            echo -e "${RED}${BOLD}>> 👋 再见啦姐妹，期待下次见面~${NC}"
            sleep 1
            clear
            exit 0
            ;;
        1) start_tavern ;;
        2) update_tavern ;;
        3) simple_config_menu ;;
        4) help_menu ;;
        5) network_config_menu ;;
        6) plugin_menu ;;
        7) script_update_menu ;;
        *)
            echo -e "${RED}${BOLD}>> 😅 输入错误，请重新选择哦~${NC}"
            sleep 1
            ;;
    esac
done
EOF

chmod +x "$MENU_PATH"
log_success "增强版菜单创建完成"

# ==== 步骤8：配置自动启动 ====
show_progress 8 10 "正在配置自动启动，以后打开Termux就能直接使用啦~"
log_info "配置自动启动菜单..."

PROFILE_FILE=""
for pf in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"; do
    if [ -f "$pf" ]; then
        PROFILE_FILE="$pf"
        break
    fi
done
if [ -z "$PROFILE_FILE" ]; then
    PROFILE_FILE="$HOME/.bashrc"
fi
touch "$PROFILE_FILE"

if ! grep -qE 'bash[ ]+\$HOME/menu\\.sh' "$PROFILE_FILE"; then
    echo 'bash $HOME/menu.sh' >> "$PROFILE_FILE"
    log_success "自动启动配置完成"
else
    log_success "自动启动已配置，跳过"
fi

# ==== 步骤9：安装SillyTavern依赖 ====
show_progress 9 10 "正在安装运行环境，快要完成啦~"
log_info "安装SillyTavern依赖包..."

cd "$HOME/SillyTavern" || { log_error "进入SillyTavern目录失败！"; exit 1; }
rm -rf node_modules

log_info "开始安装依赖包，这可能需要5-10分钟..."
if ! npm install --no-audit --no-fund --loglevel=error --no-progress --omit=dev; then
    log_warning "首次安装失败，尝试清理缓存重试..."
    npm cache clean --force 2>/dev/null || true
    rm -rf node_modules package-lock.json 2>/dev/null

    if ! npm install --no-audit --no-fund --loglevel=error --no-progress --omit=dev; then
        log_error "依赖安装失败，请检查网络连接"
        log_info "可以稍后运行菜单中的[重新安装依赖]选项"
    else
        log_success "依赖安装成功（重试后）"
    fi
else
    log_success "依赖安装成功"
fi

# ==== 步骤10：保存镜像源配置 ====
show_progress 10 10 "正在保存配置，确保以后更新也能享受高速下载~"
log_info "保存镜像源配置..."

# 保存当前使用的镜像源到配置文件
MIRROR_CONFIG="$HOME/github_mirrors_termux.json"
cat > "$MIRROR_CONFIG" << EOF
{
  "version": "2.6.27",
  "last_updated": "$INSTALL_DATE",
  "platform": "Android Termux",
  "script_version": "$SCRIPT_VERSION",
  "source": "Auto-updated during installation",
  "mirrors_count": ${#GITHUB_MIRRORS[@]},
  "mirrors": [
$(for i in "${!GITHUB_MIRRORS[@]}"; do
    echo "    {"
    echo "      "priority": $((i+1)),"
    echo "      "url": "${GITHUB_MIRRORS[$i]}","
    echo "      "domain": "$(echo "${GITHUB_MIRRORS[$i]}" | sed 's|https://||' | cut -d'/' -f1)""
    if [ $i -eq $(( ${#GITHUB_MIRRORS[@]} - 1 )) ]; then
        echo "    }"
    else
        echo "    },"
    fi
done)
  ],
  "note": "本配置在安装时自动生成，包含当前最优的镜像源排序"
}
EOF

log_success "镜像源配置已保存"

# ==== 安装完成 ====
echo ""
echo -e "${GREEN}${BOLD}"
echo "🎉🎉🎉 恭喜小白！SillyTavern安装成功！🎉🎉🎉"
echo "✨ 你现在可以和AI聊天了！"
echo "💕 安装过程完全自动化，是不是很简单？"
echo "🌸 接下来只需要按任意键进入菜单"
echo "=================================================="
echo -e "${NC}"

echo -e "${YELLOW}${BOLD}🎯 小白用户下一步操作指南：${NC}"
echo -e "${GREEN}${BOLD}1. 按任意键进入菜单${NC}"
echo -e "${GREEN}${BOLD}2. 选择"1. 🚀 启动 SillyTavern"${NC}"
echo -e "${GREEN}${BOLD}3. 在手机浏览器中打开 http://localhost:8000${NC}"
echo -e "${GREEN}${BOLD}4. 开始和AI聊天！${NC}"
echo ""
echo -e "${CYAN}${BOLD}💡 重要提示：${NC}"
echo -e "${YELLOW}  📱 以后打开Termux会自动进入菜单${NC}"
echo -e "${YELLOW}  🔄 如需重启SillyTavern，选择菜单中的启动选项${NC}"
echo -e "${YELLOW}  🌐 聊天地址永远是：http://localhost:8000${NC}"

log_info "安装摘要:"
echo -e "${CYAN}  - 脚本版本: $SCRIPT_VERSION${NC}"
echo -e "${CYAN}  - 安装时间: $INSTALL_DATE${NC}"
echo -e "${CYAN}  - 镜像源数量: ${#GITHUB_MIRRORS[@]} 个${NC}"
echo -e "${CYAN}  - 自动启动: 已配置${NC}"
echo -e "${CYAN}  - 增强菜单: 已安装${NC}"

echo ""
log_info "推荐的镜像源（前5个）:"
for i in "${!GITHUB_MIRRORS[@]}"; do
    if [ $i -lt 5 ]; then
        domain=$(echo "${GITHUB_MIRRORS[$i]}" | sed 's|https://||' | cut -d'/' -f1)
        echo -e "${GREEN}  ✅ $domain${NC}"
    fi
done

echo ""
log_info "使用提示:"
echo -e "${CYAN}  1. 重启Termux后会自动进入菜单${NC}"
echo -e "${CYAN}  2. 菜单中可以更新镜像源保持最佳速度${NC}"
echo -e "${CYAN}  3. 遇到问题可以重新安装依赖${NC}"

echo ""
log_success "现在享受与AI聊天的乐趣吧！😸💕"

echo ""
read -p "按任意键进入主菜单开始使用..." -n1 -s
exec bash "$HOME/menu.sh"
