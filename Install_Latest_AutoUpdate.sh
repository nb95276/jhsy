#!/data/data/com.termux/files/usr/bin/bash
# =========================================================================
# SillyTavern-Termux 智能测速安装脚本 - v3.0 Mio's Edition 😸
# 启动时自动测试并选用最快镜像源
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
SCRIPT_VERSION="3.0.0"
INSTALL_DATE=$(date '+%Y-%m-%d %H:%M:%S')

# ==== 输出函数 ====
log_success() { echo -e "${GREEN}${BOLD}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}${BOLD}[ERROR]${NC} $1"; }
log_info() { echo -e "${CYAN}${BOLD}[INFO]${NC} $1"; }
log_warning() { echo -e "${YELLOW}${BOLD}[WARNING]${NC} $1"; }

# ==== 显示标题 ====
echo -e "${CYAN}${BOLD}"
echo "=================================================="
echo "🌸 SillyTavern 智能测速安装脚本 🌸"
echo "💕 全自动寻找最快下载通道！"
echo "=================================================="
echo -e "${NC}"

# ==== 步骤1：智能测试GitHub镜像源 ====
log_info "第一步：开始寻找最快的两个下载通道..."

# 定义要测试的镜像源列表
declare -A MIRRORS_TO_TEST=(
    ["hub.gitmirror.com"]="https://hub.gitmirror.com/https://github.com"
    ["ghproxy.net"]="https://ghproxy.net/https://github.com"
    ["gh.ddlc.top"]="https://gh.ddlc.top/https://github.com"
    ["ghfast.top"]="https://ghfast.top/https://github.com"
    ["mirror.ghproxy.com"]="https://mirror.ghproxy.com/https://github.com"
    ["gh.h233.eu.org"]="https://gh.h233.eu.org/https://github.com"
    ["ghproxy.cfd"]="https://ghproxy.cfd/https://github.com"
    ["github.com"]="https://github.com"
)

# 定义测试文件 (使用我们自己仓库里的小文件)
TEST_FILE_URL_PART="nb95276/jhsy/raw/main/PROJECT_INFO.txt"
TEST_TIMEOUT=10 # 10秒超时

# 存储测速结果
declare -A speeds

# 开始测速
for domain in "${!MIRRORS_TO_TEST[@]}"; do
    mirror_url="${MIRRORS_TO_TEST[$domain]}"
    full_test_url="$mirror_url/$TEST_FILE_URL_PART"
    
    echo -ne "${CYAN}  - 正在测试 ${domain}... ${NC}"
    
    # 使用curl的-w参数获取下载速度，超时10秒
    speed=$(curl -fsSL --connect-timeout 5 --max-time $TEST_TIMEOUT -w "%{speed_download}" -o /dev/null "$full_test_url" 2>/dev/null)
    speed_kb=$(awk -v s="$speed" 'BEGIN{printf "%.0f\n", s/1024}')

    if [[ "$speed_kb" -gt 0 ]]; then
        echo -e "${GREEN}速度: ${speed_kb} KB/s${NC}"
        speeds["$mirror_url"]=$speed_kb
    else
        echo -e "${RED}连接失败或超时${NC}"
        speeds["$mirror_url"]=0
    fi
    sleep 0.2
done

# 排序并选出最快的两个
TOP_MIRRORS=()
log_info "测速完成，正在为您挑选冠军和亚军..."

# 使用关联数组和sort进行排序
sorted_mirrors=$(
    for mirror in "${!speeds[@]}"; do
        echo "${speeds[$mirror]} $mirror"
    done | sort -rn
)

# 将最快的两个添加到TOP_MIRRORS数组
while read -r speed mirror; do
    if [[ "$speed" -gt 0 ]] && [[ ${#TOP_MIRRORS[@]} -lt 2 ]]; then
        TOP_MIRRORS+=("$mirror")
    fi
done <<< "$sorted_mirrors"

# 如果可用的镜像少于2个，则添加备用
if [ ${#TOP_MIRRORS[@]} -eq 0 ]; then
    log_warning "所有镜像源都连接失败！"
    log_info "将使用 ghproxy.net 和 hub.gitmirror.com 作为备用方案。"
    TOP_MIRRORS=("https://ghproxy.net/https://github.com" "https://hub.gitmirror.com/https://github.com")
elif [ ${#TOP_MIRRORS[@]} -eq 1 ]; then
    log_warning "只有一个镜像源可用。"
    log_info "额外添加 ghproxy.net 作为备用方案。"
    if [[ "${TOP_MIRRORS[0]}" != "https://ghproxy.net/https://github.com" ]]; then
        TOP_MIRRORS+=("https://ghproxy.net/https://github.com")
    else
        TOP_MIRRORS+=("https://hub.gitmirror.com/https://github.com")
    fi
fi

log_success "已选定最优下载通道："
log_info "1. $(echo "${TOP_MIRRORS[0]}" | sed 's|https://||' | cut -d'/' -f1)"
log_info "2. $(echo "${TOP_MIRRORS[1]}" | sed 's|https://||' | cut -d'/' -f1)"
echo ""

# 后续所有下载都将使用 TOP_MIRRORS
GITHUB_MIRRORS=("${TOP_MIRRORS[@]}")

# ==== 步骤2：安装Node.js (如果需要) ====
log_info "第二步：准备Node.js运行环境..."
if ! command -v node >/dev/null 2>&1; then
    log_info "未检测到Node.js，开始安装..."
    pkg update # 仅在需要安装时更新
    pkg install -y nodejs-lts || pkg install -y nodejs
    log_success "Node.js安装完成"
else
    log_success "Node.js已安装，跳过"
fi

# 配置npm中国镜像源
log_info "配置npm中国镜像源..."
npm config set prefix "$PREFIX"
NPM_MIRRORS=(
    "https://registry.npmmirror.com/"
    "https://mirrors.cloud.tencent.com/npm/"
    "https://mirrors.huaweicloud.com/repository/npm/"
    "https://registry.npm.taobao.org/"
)
for npm_mirror in "${NPM_MIRRORS[@]}"; do
    if timeout 5 curl -fsSL --connect-timeout 3 "$npm_mirror" >/dev/null 2>&1; then
        npm config set registry "$npm_mirror"
        log_success "已设置npm镜像源: $(echo "$npm_mirror" | sed 's|https://||' | cut -d'/' -f1)"
        break
    fi
done
npm config set disturl https://npmmirror.com/mirrors/node/ 2>/dev/null || true
npm config set sass_binary_site https://npmmirror.com/mirrors/node-sass/ 2>/dev/null || true
echo ""

# ==== 步骤3：下载SillyTavern ====
log_info "第三步：使用最优通道下载SillyTavern主程序..."
if [ -d "$HOME/SillyTavern/.git" ]; then
    log_warning "SillyTavern已存在，跳过下载"
else
    rm -rf "$HOME/SillyTavern"
    
    clone_success=false
    for mirror in "${GITHUB_MIRRORS[@]}"; do
        domain=$(echo "$mirror" | sed 's|https://||' | cut -d'/' -f1)
        log_info "尝试从 $domain 克隆..."
        if timeout 120 git clone --depth=1 --single-branch --branch=release "$mirror/SillyTavern/SillyTavern" "$HOME/SillyTavern" 2>/dev/null; then
            log_success "克隆成功！来源: $domain"
            clone_success=true
            break
        else
            rm -rf "$HOME/SillyTavern"
        fi
    done
    
    if [ "$clone_success" = false ]; then
        log_info "Git克隆失败，尝试ZIP下载..."
        for mirror in "${GITHUB_MIRRORS[@]}"; do
            domain=$(echo "$mirror" | sed 's|https://||' | cut -d'/' -f1)
            zip_url="$mirror/SillyTavern/SillyTavern/archive/refs/heads/release.zip"
            if timeout 60 curl -k -fsSL --connect-timeout 10 -o "/tmp/sillytavern.zip" "$zip_url" 2>/dev/null; then
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
            log_error "所有最优下载方式都失败了！请检查网络或稍后重试。"
            exit 1
        fi
    fi
fi
echo ""

# ==== 步骤4：安装SillyTavern依赖 ====
log_info "第四步：安装SillyTavern依赖 (这可能需要5-10分钟)..."
cd "$HOME/SillyTavern" || { log_error "进入SillyTavern目录失败！"; exit 1; }
rm -rf node_modules
if ! npm install --no-audit --no-fund --loglevel=error --no-progress --omit=dev; then
    log_warning "首次安装失败，尝试清理缓存重试..."
    npm cache clean --force 2>/dev/null || true
    rm -rf node_modules package-lock.json 2>/dev/null
    if ! npm install --no-audit --no-fund --loglevel=error --no-progress --omit=dev; then
        log_error "依赖安装失败，请检查网络连接后，运行菜单中的[重新安装依赖]选项"
    else
        log_success "依赖安装成功（重试后）"
    fi
else
    log_success "依赖安装成功"
fi
echo ""

# ==== 步骤5：创建增强版菜单和配置 ====
log_info "第五步：创建菜单和配置文件..."
MENU_PATH="$HOME/menu.sh"
ENV_PATH="$HOME/.env"

cat > "$ENV_PATH" << EOF
INSTALL_VERSION=$SCRIPT_VERSION
INSTALL_DATE=$INSTALL_DATE
MENU_VERSION=$SCRIPT_VERSION
EOF

cat > "$MENU_PATH" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; CYAN='\033[1;36m'; BOLD='\033[1m'; NC='\033[0m'
source "$HOME/.env" 2>/dev/null || true
echo -e "${CYAN}${BOLD}=================================================="
echo "🌸 SillyTavern-Termux 智能菜单 🌸"
echo "=================================================="
echo -e "${YELLOW}版本: ${INSTALL_VERSION:-未知} | 安装日期: ${INSTALL_DATE:-未知}${NC}\n"
echo "1. 🚀 启动 SillyTavern"
echo "2. 🔄 更新 SillyTavern"
echo "3. 🛠️ 重新安装依赖"
echo "4. 📊 查看系统信息"
echo "5. ❌ 退出"
echo ""
read -p "请选择 [1-5]: " choice
case $choice in
    1) cd "$HOME/SillyTavern" && node server.js;;
    2) cd "$HOME/SillyTavern" || exit 1; git pull origin release; npm install --no-audit --no-fund --omit=dev; echo -e "${GREEN}>> ✅ 更新完成！${NC}";;
    3) cd "$HOME/SillyTavern" || exit 1; rm -rf node_modules package-lock.json; npm install --no-audit --no-fund --omit=dev; echo -e "${GREEN}>> ✅ 依赖重新安装完成！${NC}";;
    4) echo "Node: $(node -v 2>/dev/null||echo N/A) | npm: $(npm -v 2>/dev/null||echo N/A) | Git: $(git --version 2>/dev/null||echo N/A)";;
    5) exit 0;;
    *) echo -e "${RED}>> ⚠️ 无效选择${NC}";;
esac
echo ""; read -p "按Enter键返回菜单..."; exec bash "$HOME/menu.sh"
EOF

chmod +x "$MENU_PATH"

PROFILE_FILE="$HOME/.bashrc"
touch "$PROFILE_FILE"
if ! grep -qE 'bash[ ]+\$HOME/menu\.sh' "$PROFILE_FILE"; then
    echo 'bash $HOME/menu.sh' >> "$PROFILE_FILE"
fi
log_success "菜单和自动启动配置完成"
echo ""

# ==== 安装完成 ====
echo -e "${GREEN}${BOLD}🎉🎉🎉 恭喜爸爸！SillyTavern智能安装成功！🎉🎉🎉${NC}"
echo "✨ 现在可以和AI聊天啦！"
echo -e "${YELLOW}>> 1. 按任意键进入菜单"
echo -e ">> 2. 选择"1. 🚀 启动 SillyTavern"
echo -e ">> 3. 在手机浏览器中打开 http://localhost:8000${NC}"
read -p "按任意键进入主菜单开始使用..." -n1 -s
exec bash "$HOME/menu.sh"
