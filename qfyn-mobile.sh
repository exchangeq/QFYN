#!/data/data/com.termux/files/usr/bin/bash
#
# ============================================================================
# QFYN Security Tools - 移动端/跨平台安装脚本
# 版本: 4.0-mobile
# 作者: QFYN @~
# 支持: Termux (Android), Linux, macOS, WSL
# 优化: 触屏友好、彩色输出、简洁界面
# 警告: 仅限授权测试环境使用！
# ============================================================================

set -euo pipefail

# ===================== 颜色定义 =====================
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    MAGENTA='\033[0;35m'
    WHITE='\033[1;37m'
    GRAY='\033[0;90m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; CYAN=''; MAGENTA=''; WHITE=''; GRAY=''; BOLD=''; NC=''
fi

# ===================== 检测运行环境 =====================
detect_env() {
    if [[ -d /data/data/com.termux ]] || command -v termux-setup-storage &>/dev/null; then
        ENV="Termux"
        INSTALL_DIR="$HOME/storage/shared/QFYN_Tools"
        PKG_MANAGER="pkg"
        PKG_UPDATE="pkg update -y"
        PKG_INSTALL="pkg install -y"
        PYTHON="python"
        PIP="pip"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        ENV="Linux"
        INSTALL_DIR="$HOME/QFYN_Tools"
        if command -v apt &>/dev/null; then
            PKG_MANAGER="apt"
            PKG_UPDATE="apt update -y"
            PKG_INSTALL="apt install -y"
        elif command -v pkg &>/dev/null; then
            PKG_MANAGER="pkg"
            PKG_UPDATE="pkg update -y"
            PKG_INSTALL="pkg install -y"
        else
            PKG_MANAGER="unknown"
        fi
        PYTHON="python3"
        PIP="pip3"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        ENV="macOS"
        INSTALL_DIR="$HOME/QFYN_Tools"
        if command -v brew &>/dev/null; then
            PKG_MANAGER="brew"
            PKG_UPDATE="brew update"
            PKG_INSTALL="brew install"
        else
            PKG_MANAGER="unknown"
        fi
        PYTHON="python3"
        PIP="pip3"
    elif [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "cygwin"* ]]; then
        ENV="Windows"
        INSTALL_DIR="$USERPROFILE\\Desktop\\QFYN_Tools"
        echo -e "${RED}[!] 请使用 Windows 专用版本 (SecurityTools_Installer.ps1)${NC}"
        exit 1
    else
        ENV="Unknown"
        INSTALL_DIR="$HOME/QFYN_Tools"
        PKG_MANAGER="unknown"
    fi
    
    mkdir -p "$INSTALL_DIR"
    LOG_FILE="$INSTALL_DIR/install.log"
    touch "$LOG_FILE"
}

# ===================== 多语言 =====================
if [[ "${LANG:-}" == zh_CN* ]] || [[ "${LANG:-}" == zh_TW* ]]; then
    LANG_CN=true
else
    LANG_CN=false
fi

if $LANG_CN; then
    MSG_WARNING="╔══════════════════════════════════════════════════════════════════════╗
║  本工具仅用于授权的网络安全测试、教育及研究                              ║
║  禁止用于非法入侵·仅限授权环境测试·使用者须自行承担一切法律后果          ║
║  未经授权使用可能违反《网络安全法》，最高可处七年以下有期徒刑           ║
╚══════════════════════════════════════════════════════════════════════╝"
    MSG_CONFIRM="请输入 [1] 接受 / [2] 退出"
    MSG_NO_ROOT="请确保有安装权限 (Termux 无需 root)"
    MSG_START="开始安装"
    MSG_INSTALLING="安装中"
    MSG_SUCCESS="完成"
    MSG_FAIL="失败"
    MSG_ALREADY="已安装"
    MSG_MANUAL="需手动安装"
    MSG_SELECT_CAT="📂 选择分类"
    MSG_SELECT_TOOL="🔧 选择工具"
    MSG_INSTALL_ALL="📦 安装全部"
    MSG_BACK="🔙 返回"
    MSG_EXIT="🚪 退出"
    MSG_CONFIRM_CODE="1"
else
    MSG_WARNING="╔══════════════════════════════════════════════════════════════════════╗
║  This tool is for authorized security testing, education, research  ║
║  Unauthorized use may violate laws. User assumes all liability      ║
╚══════════════════════════════════════════════════════════════════════╝"
    MSG_CONFIRM="Enter [1] Accept / [2] Exit"
    MSG_NO_ROOT="Please ensure you have install permissions"
    MSG_START="Starting installation"
    MSG_INSTALLING="Installing"
    MSG_SUCCESS="Complete"
    MSG_FAIL="Failed"
    MSG_ALREADY="Already installed"
    MSG_MANUAL="Manual install required"
    MSG_SELECT_CAT="📂 Select Category"
    MSG_SELECT_TOOL="🔧 Select Tool"
    MSG_INSTALL_ALL="📦 Install All"
    MSG_BACK="🔙 Back"
    MSG_EXIT="🚪 Exit"
    MSG_CONFIRM_CODE="1"
fi

# ===================== 工具列表 =====================
declare -A TOOLS
# 格式: key="分类|显示名|包名|安装命令类型"
# 类型: pkg=系统包, pip=Python包, git=Git克隆, manual=手动

# 信息收集
TOOLS["nmap"]="信息收集|Nmap|nmap|pkg"
TOOLS["masscan"]="信息收集|Masscan|masscan|pkg"
TOOLS["amass"]="信息收集|Amass|amass|pkg"
TOOLS["whatweb"]="信息收集|WhatWeb|whatweb|pkg"
TOOLS["gobuster"]="信息收集|Gobuster|gobuster|pkg"
TOOLS["ffuf"]="信息收集|FFUF|ffuf|pkg"
TOOLS["theharvester"]="信息收集|theHarvester|theharvester|pip"
TOOLS["dnsrecon"]="信息收集|DNSrecon|dnsrecon|pip"

# 漏洞扫描
TOOLS["nikto"]="漏洞扫描|Nikto|nikto|pkg"
TOOLS["wpscan"]="漏洞扫描|WPScan|wpscan|gem"
TOOLS["sqlmap"]="漏洞扫描|SQLMap|sqlmap|pip"

# Web测试
TOOLS["hydra"]="Web测试|Hydra|hydra|pkg"
TOOLS["curl"]="Web测试|curl|curl|pkg"
TOOLS["wget"]="Web测试|wget|wget|pkg"

# 无线密码
TOOLS["john"]="无线密码|John|john|pkg"
TOOLS["hashcat"]="无线密码|Hashcat|hashcat|pkg"
TOOLS["aircrack"]="无线密码|Aircrack-ng|aircrack-ng|pkg"

# 防御监控
TOOLS["tcpdump"]="防御监控|tcpdump|tcpdump|pkg"
TOOLS["wireshark"]="防御监控|Wireshark|wireshark|pkg"

# 渗透框架
TOOLS["metasploit"]="渗透框架|Metasploit|metasploit-framework|pkg"

# 移动逆向
TOOLS["apktool"]="移动逆向|APKTool|apktool|pkg"
TOOLS["jadx"]="移动逆向|Jadx|jadx|pkg"

# 云安全
TOOLS["trivy"]="云安全|Trivy|trivy|pkg"

# 取证分析
TOOLS["binwalk"]="取证分析|Binwalk|binwalk|pip"

# 社会工程
TOOLS["setoolkit"]="社会工程|SET|setoolkit|pip"

# 开发工具
TOOLS["git"]="开发工具|Git|git|pkg"
TOOLS["python"]="开发工具|Python|python|pkg"
TOOLS["nodejs"]="开发工具|Node.js|nodejs|pkg"

# 网络工具
TOOLS["netcat"]="网络工具|Netcat|netcat|pkg"

# 分类列表
CATEGORIES=(
    "信息收集"
    "漏洞扫描"
    "Web测试"
    "无线密码"
    "防御监控"
    "渗透框架"
    "移动逆向"
    "云安全"
    "取证分析"
    "社会工程"
    "开发工具"
    "网络工具"
)

# ===================== 辅助函数 =====================
log() {
    echo -e "${2:-$WHITE}[$(date '+%H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

draw_line() {
    echo -e "${GRAY}────────────────────────────────────────${NC}"
}

print_banner() {
    clear
    echo -e "${RED}$MSG_WARNING${NC}"
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     QFYN Security Tools v4.0 - 移动端适配版           ║${NC}"
    echo -e "${CYAN}║              作者: QFYN @~                            ║${NC}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║  环境: $ENV | 包管理器: $PKG_MANAGER${NC}"
    echo -e "${CYAN}║  安装目录: $INSTALL_DIR${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

confirm_legal() {
    echo -e "${YELLOW}$MSG_CONFIRM${NC}"
    echo -e "${GREEN}[1] 接受${NC}  ${RED}[2] 退出${NC}"
    read -r choice
    if [[ "$choice" != "$MSG_CONFIRM_CODE" ]]; then
        echo -e "${RED}[!] 已退出${NC}"
        exit 0
    fi
}

install_tool() {
    local key="$1"
    local data="${TOOLS[$key]}"
    IFS='|' read -r cat name pkg type <<< "$data"
    
    echo -ne "  $MSG_INSTALLING: $name... "
    
    case $type in
        pkg)
            if command -v "$pkg" &>/dev/null; then
                echo -e "${GREEN}✓ $MSG_ALREADY${NC}"
                return 0
            fi
            if [[ "$PKG_MANAGER" == "unknown" ]]; then
                echo -e "${YELLOW}⚠ $MSG_MANUAL${NC}"
                return 1
            fi
            $PKG_INSTALL "$pkg" &>> "$LOG_FILE"
            ;;
        pip)
            if $PIP show "$pkg" &>/dev/null; then
                echo -e "${GREEN}✓ $MSG_ALREADY${NC}"
                return 0
            fi
            $PIP install "$pkg" &>> "$LOG_FILE"
            ;;
        git)
            local git_path="$INSTALL_DIR/$name"
            if [[ -d "$git_path" ]]; then
                echo -e "${GREEN}✓ $MSG_ALREADY${NC}"
                return 0
            fi
            git clone --depth 1 "https://github.com/$pkg/$pkg.git" "$git_path" &>> "$LOG_FILE"
            echo "export PATH=\"\$PATH:$git_path\"" >> "$HOME/.bashrc"
            ;;
        gem)
            if command -v "$pkg" &>/dev/null; then
                echo -e "${GREEN}✓ $MSG_ALREADY${NC}"
                return 0
            fi
            gem install "$pkg" &>> "$LOG_FILE"
            ;;
        *)
            echo -e "${YELLOW}⚠ $MSG_MANUAL${NC}"
            return 1
            ;;
    esac
    
    if command -v "$pkg" &>/dev/null || $PIP show "$pkg" &>/dev/null 2>&1; then
        echo -e "${GREEN}✓ $MSG_SUCCESS${NC}"
        return 0
    else
        echo -e "${RED}✗ $MSG_FAIL${NC}"
        return 1
    fi
}

# ===================== 菜单系统 =====================
show_category_menu() {
    echo ""
    echo -e "${MAGENTA}$MSG_SELECT_CAT${NC}"
    draw_line
    
    local i=1
    for cat in "${CATEGORIES[@]}"; do
        # 统计该分类工具数
        local count=0
        for k in "${!TOOLS[@]}"; do
            IFS='|' read -r c _ _ _ <<< "${TOOLS[$k]}"
            [[ "$c" == "$cat" ]] && ((count++))
        done
        echo -e "  ${GREEN}$i)${NC} $cat ${GRAY}[$count]${NC}"
        ((i++))
    done
    echo -e "  ${GREEN}$i)${NC} $MSG_INSTALL_ALL"
    echo -e "  ${RED}0)${NC} $MSG_EXIT"
    draw_line
}

show_tools_menu() {
    local category="$1"
    echo ""
    echo -e "${CYAN}$MSG_SELECT_TOOL - $category${NC}"
    draw_line
    
    local tools_list=()
    local i=1
    for key in "${!TOOLS[@]}"; do
        IFS='|' read -r cat name _ _ <<< "${TOOLS[$key]}"
        if [[ "$cat" == "$category" ]]; then
            tools_list+=("$key|$name")
            echo -e "  ${GREEN}$i)${NC} $name"
            ((i++))
        fi
    done
    echo -e "  ${GREEN}$i)${NC} $MSG_INSTALL_ALL"
    echo -e "  ${YELLOW}b)${NC} $MSG_BACK"
    echo -e "  ${RED}0)${NC} $MSG_EXIT"
    draw_line
    
    # 返回列表供选择
    for t in "${tools_list[@]}"; do
        echo "$t"
    done
    echo "SEPARATOR"
    echo "$i"
}

install_by_category() {
    local category="$1"
    echo ""
    log "$MSG_START $category..." "$CYAN"
    
    local total=0 installed=0
    for key in "${!TOOLS[@]}"; do
        IFS='|' read -r cat _ _ _ <<< "${TOOLS[$key]}"
        if [[ "$cat" == "$category" ]]; then
            ((total++))
            if install_tool "$key"; then
                ((installed++))
            fi
        fi
    done
    log "$category: $installed/$total $MSG_SUCCESS" "$GREEN"
}

install_all() {
    echo ""
    log "$MSG_START $MSG_INSTALL_ALL..." "$CYAN"
    
    local total=${#TOOLS[@]}
    local current=0
    local installed=0
    
    for key in "${!TOOLS[@]}"; do
        ((current++))
        echo -ne "\r[$current/$total] "
        if install_tool "$key"; then
            ((installed++))
        fi
    done
    echo ""
    log "$MSG_INSTALL_ALL: $installed/$total $MSG_SUCCESS" "$GREEN"
}

# ===================== 生成辅助文件 =====================
generate_files() {
    # 生成快速启动脚本
    cat > "$INSTALL_DIR/quick.sh" << 'EOF'
#!/bin/bash
echo "========================================"
echo "  QFYN Security Tools - Quick Start"
echo "========================================"
echo ""
echo "可用命令:"
echo "  nmap      - 网络扫描"
echo "  sqlmap    - SQL注入"
echo "  hydra     - 密码爆破"
echo "  john      - 密码破解"
echo "  tcpdump   - 抓包分析"
echo ""
echo "输入命令启动:"
read -p "> " cmd
eval "$cmd"
EOF
    chmod +x "$INSTALL_DIR/quick.sh"
    
    # 生成工具清单
    cat > "$INSTALL_DIR/README.md" << EOF
# QFYN Security Tools - 工具清单

> 环境: $ENV | 安装时间: $(date '+%Y-%m-%d %H:%M:%S')

| 工具 | 分类 | 说明 |
|------|------|------|
EOF
    for key in "${!TOOLS[@]}"; do
        IFS='|' read -r cat name _ _ <<< "${TOOLS[$key]}"
        echo "| $name | $cat | - |" >> "$INSTALL_DIR/README.md"
    done
    
    log "[+] 快速启动: $INSTALL_DIR/quick.sh" "$GREEN"
    log "[+] 工具清单: $INSTALL_DIR/README.md" "$GREEN"
}

# ===================== 主程序 =====================
main() {
    detect_env
    print_banner
    confirm_legal
    
    # 更新包管理器
    if [[ "$PKG_MANAGER" != "unknown" ]]; then
        log "更新包管理器..." "$CYAN"
        eval "$PKG_UPDATE" &>> "$LOG_FILE" || true
    fi
    
    # 安装基础工具
    log "安装基础依赖..." "$CYAN"
    case $PKG_MANAGER in
        pkg) $PKG_INSTALL git curl wget python &>> "$LOG_FILE" ;;
        apt) $PKG_INSTALL git curl wget python3 python3-pip &>> "$LOG_FILE" ;;
        brew) brew install git curl wget python3 &>> "$LOG_FILE" ;;
    esac
    
    # 主循环
    while true; do
        print_banner
        show_category_menu
        
        read -r choice
        total_cats=${#CATEGORIES[@]}
        
        if [[ "$choice" == "0" ]]; then
            echo -e "${GREEN}[+] $MSG_EXIT${NC}"
            break
        elif [[ "$choice" -ge 1 && "$choice" -le $total_cats ]]; then
            category="${CATEGORIES[$((choice-1))]}"
            install_by_category "$category"
            echo -e "${YELLOW}按回车继续...${NC}"
            read -r
        elif [[ "$choice" -eq $((total_cats+1)) ]]; then
            install_all
            echo -e "${YELLOW}按回车继续...${NC}"
            read -r
        else
            echo -e "${RED}[!] 无效选择${NC}"
            sleep 1
        fi
    done
    
    generate_files
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✅ $MSG_SUCCESS                                      ║${NC}"
    echo -e "${GREEN}╠════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║  安装目录: $INSTALL_DIR${NC}"
    echo -e "${GREEN}║  快速启动: bash $INSTALL_DIR/quick.sh${NC}"
    echo -e "${GREEN}║  日志文件: $LOG_FILE${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}[*] 提示: 重启终端或运行 'source ~/.bashrc' 使命令生效${NC}"
}

# ===================== 启动 =====================
main "$@"