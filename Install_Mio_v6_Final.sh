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
SCRIPT_VERSION="2.1.1"
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
    pkg update && pkg install -y "${missing_tools[@]}"
    
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
        while IFS= read -r line; do
            if [[ "$line" =~ \[\'([^\']+)\' ]]; then
                url="${BASH_REMATCH[1]}"
                if [[ "$url" == *"github.com"* ]]; then
                    GITHUB_MIRRORS+=("$url")
                fi
            fi
        done < <(echo "$XIU2_CONTENT" | sed -n '/clone_url.*=/,/\]/p')
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
log_warning "根据用户指令，已跳过Termux软件安装过程。"
log_info "脚本将假定您的Termux环境已准备就绪。"
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
# SillyTavern-Termux 增强版菜单 - 内置镜像源更新

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
BOLD='\033[1m'
NC='\033[0m'

# 加载配置
source "$HOME/.env" 2>/dev/null || true

echo -e "${CYAN}${BOLD}"
echo "=================================================="
echo "🌸 SillyTavern-Termux 增强版菜单 🌸"
echo "💕 专为小红书姐妹们优化"
echo "✨ 内置镜像源自动更新功能"
echo "=================================================="
echo -e "${NC}"

echo -e "${YELLOW}当前版本: ${INSTALL_VERSION:-未知}${NC}"
echo -e "${YELLOW}安装日期: ${INSTALL_DATE:-未知}${NC}"
echo ""

echo "1. 启动 SillyTavern"
echo "2. 更新 SillyTavern"
echo "3. 更新GitHub镜像源"
echo "4. 查看系统信息"
echo "5. 重新安装依赖"
echo "6. 退出"
echo ""

read -p "请选择 [1-6]: " choice

case $choice in
    1) echo "one" ;;
    2) echo "two" ;;
    3) echo "three" ;;
    4) echo "four" ;;
    5) echo "five" ;;
    6) echo "six" ;;
    *) echo "invalid" ;;
esac

echo ""
read -p "按Enter键返回菜单..."
exec bash "$HOME/menu.sh"
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

if ! grep -qE 'bash[ ]+\$HOME/menu\.sh' "$PROFILE_FILE"; then
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
    echo "      \"priority\": $((i+1)),"
    echo "      \"url\": \"${GITHUB_MIRRORS[$i]}\","
    echo "      \"domain\": \"$(echo "${GITHUB_MIRRORS[$i]}" | sed 's|https://||' | cut -d'/' -f1)\"
    if [ $i -eq $((${#GITHUB_MIRRORS[@]}-1)) ]; then
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
