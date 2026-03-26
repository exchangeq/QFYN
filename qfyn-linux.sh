#!/usr/bin/env bash
#
# ============================================================================
# QFYN Security Tools - Linux 版安装脚本
# 版本: 4.0
# 作者: QFYN @~
# 支持: Ubuntu/Debian, CentOS/RHEL, Fedora, Arch, openSUSE
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

# ===================== 配置 =====================
SCRIPT_VERSION="4.0"
INSTALL_DIR="$HOME/QFYN_Tools"
LOG_FILE="$INSTALL_DIR/install.log"
CONFIG_FILE="$INSTALL_DIR/config.json"
TOOL_LIST_FILE="$INSTALL_DIR/tool_list.md"
START_TIME=$(date +%s)

# ===================== 检测系统 =====================
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_NAME="$NAME"
        OS_VERSION="$VERSION_ID"
    else
        OS_NAME="Linux"
        OS_VERSION="unknown"
    fi

    if command -v apt &>/dev/null; then
        PKG_MANAGER="apt"
        PKG_UPDATE="apt update -y"
        PKG_INSTALL="apt install -y"
        PKG_UPGRADE="apt upgrade -y"
    elif command -v yum &>/dev/null; then
        PKG_MANAGER="yum"
        PKG_UPDATE="yum update -y"
        PKG_INSTALL="yum install -y"
        PKG_UPGRADE="yum upgrade -y"
    elif command -v dnf &>/dev/null; then
        PKG_MANAGER="dnf"
        PKG_UPDATE="dnf update -y"
        PKG_INSTALL="dnf install -y"
        PKG_UPGRADE="dnf upgrade -y"
    elif command -v pacman &>/dev/null; then
        PKG_MANAGER="pacman"
        PKG_UPDATE="pacman -Sy"
        PKG_INSTALL="pacman -S --noconfirm"
        PKG_UPGRADE="pacman -Syu --noconfirm"
    elif command -v zypper &>/dev/null; then
        PKG_MANAGER="zypper"
        PKG_UPDATE="zypper refresh"
        PKG_INSTALL="zypper install -y"
        PKG_UPGRADE="zypper update -y"
    else
        PKG_MANAGER="unknown"
    fi

    echo -e "${GREEN}[✓] 检测到系统: $OS_NAME${NC}"
    echo -e "${GREEN}[✓] 包管理器: $PKG_MANAGER${NC}"
}

# ===================== 多语言 =====================
if [[ "${LANG:-}" == zh_CN* ]] || [[ "${LANG:-}" == zh_TW* ]]; then
    LANG_CN=true
else
    LANG_CN=false
fi

if $LANG_CN; then
    MSG_WARNING="╔══════════════════════════════════════════════════════════════════════════╗
║  本工具仅用于授权的网络安全测试、教育及研究                              ║
║  禁止用于非法入侵·仅限授权环境测试·使用者须自行承担一切法律后果          ║
║  未经授权使用可能违反《网络安全法》，最高可处七年以下有期徒刑           ║
╚══════════════════════════════════════════════════════════════════════════╝"
    MSG_CONFIRM="请输入 [1] 接受 / [2] 退出"
    MSG_CONFIRM_CODE="1"
    MSG_NO_ROOT="请使用 root 或 sudo 权限运行此脚本！"
    MSG_START="开始安装"
    MSG_INSTALLING="正在安装"
    MSG_SUCCESS="安装完成"
    MSG_FAIL="安装失败"
    MSG_ALREADY="已安装"
    MSG_MANUAL="需手动安装"
    MSG_SELECT_CAT="📂 请选择要安装的分类"
    MSG_SELECT_TOOL="🔧 请选择要安装的工具"
    MSG_INSTALL_ALL="📦 安装全部工具"
    MSG_BACK="🔙 返回上级"
    MSG_EXIT="🚪 退出"
    MSG_CONF_PATH="正在配置环境变量..."
    MSG_PATH_DONE="PATH 配置完成"
    MSG_LOG="日志文件"
    MSG_TOOL_LIST="工具清单"
    MSG_CREATE_DIR="创建目录"
else
    MSG_WARNING="╔══════════════════════════════════════════════════════════════════════════╗
║  This tool is for authorized security testing, education, research  ║
║  Unauthorized use may violate laws. User assumes all liability      ║
╚══════════════════════════════════════════════════════════════════════════╝"
    MSG_CONFIRM="Enter [1] Accept / [2] Exit"
    MSG_CONFIRM_CODE="1"
    MSG_NO_ROOT="Please run this script with root or sudo privileges!"
    MSG_START="Starting installation"
    MSG_INSTALLING="Installing"
    MSG_SUCCESS="Complete"
    MSG_FAIL="Failed"
    MSG_ALREADY="Already installed"
    MSG_MANUAL="Manual install required"
    MSG_SELECT_CAT="📂 Select category to install"
    MSG_SELECT_TOOL="🔧 Select tool to install"
    MSG_INSTALL_ALL="📦 Install All Tools"
    MSG_BACK="🔙 Back"
    MSG_EXIT="🚪 Exit"
    MSG_CONF_PATH="Configuring environment variables..."
    MSG_PATH_DONE="PATH configuration complete"
    MSG_LOG="Log file"
    MSG_TOOL_LIST="Tool list"
    MSG_CREATE_DIR="Creating directory"
fi

# ===================== 工具列表 =====================
declare -A TOOLS

# 信息收集类
TOOLS["nmap"]="信息收集|Nmap|nmap|pkg|网络扫描、端口发现"
TOOLS["masscan"]="信息收集|Masscan|masscan|pkg|极速端口扫描"
TOOLS["amass"]="信息收集|Amass|amass|pkg|子域名枚举"
TOOLS["theharvester"]="信息收集|theHarvester|theharvester|pip|邮箱、子域名收集"
TOOLS["dnsrecon"]="信息收集|DNSrecon|dnsrecon|pip|DNS枚举"
TOOLS["whatweb"]="信息收集|WhatWeb|whatweb|pkg|Web指纹识别"
TOOLS["gobuster"]="信息收集|Gobuster|gobuster|pkg|目录/子域名爆破"
TOOLS["ffuf"]="信息收集|FFUF|ffuf|pkg|快速目录枚举"
TOOLS["sublist3r"]="信息收集|Sublist3r|sublist3r|pip|子域名枚举"
TOOLS["recon-ng"]="信息收集|Recon-ng|recon-ng|pip|信息收集框架"
TOOLS["shodan"]="信息收集|Shodan|shodan|pip|物联网搜索引擎"
TOOLS["metagoofil"]="信息收集|Metagoofil|metagoofil|pip|元数据收集"
TOOLS["theharvester"]="信息收集|theHarvester|theharvester|pip|邮箱收集"
TOOLS["dnsrecon"]="信息收集|DNSrecon|dnsrecon|pip|DNS枚举"
TOOLS["fierce"]="信息收集|Fierce|fierce|git|DNS扫描"

# 漏洞扫描类
TOOLS["nikto"]="漏洞扫描|Nikto|nikto|pkg|Web服务器扫描"
TOOLS["wpscan"]="漏洞扫描|WPScan|wpscan|gem|WordPress扫描"
TOOLS["joomscan"]="漏洞扫描|Joomscan|joomscan|git|Joomla扫描"
TOOLS["sqlmap"]="漏洞扫描|SQLMap|sqlmap|pip|SQL注入检测"
TOOLS["openvas"]="漏洞扫描|OpenVAS|openvas|pkg|漏洞评估系统"
TOOLS["nessus"]="漏洞扫描|Nessus|nessus|manual|专业漏洞扫描"
TOOLS["nexpose"]="漏洞扫描|Nexpose|nexpose|manual|Rapid7漏洞管理"
TOOLS["gvm"]="漏洞扫描|GVM|gvm|pkg|Greenbone漏洞管理"

# Web应用测试类
TOOLS["burpsuite"]="Web测试|Burp Suite|burpsuite|manual|Web代理抓包"
TOOLS["zap"]="Web测试|OWASP ZAP|zap|pkg|Web安全扫描器"
TOOLS["hydra"]="Web测试|Hydra|hydra|pkg|网络登录爆破"
TOOLS["curl"]="Web测试|curl|curl|pkg|HTTP客户端"
TOOLS["wget"]="Web测试|wget|wget|pkg|下载工具"
TOOLS["ffuf"]="Web测试|FFUF|ffuf|pkg|目录枚举"
TOOLS["gobuster"]="Web测试|Gobuster|gobuster|pkg|目录爆破"
TOOLS["wfuzz"]="Web测试|Wfuzz|wfuzz|pip|Web模糊测试"
TOOLS["xsstrike"]="Web测试|XSStrike|xsstrike|pip|XSS检测"
TOOLS["commix"]="Web测试|Commix|commix|git|命令注入检测"

# 无线与密码类
TOOLS["john"]="无线密码|John the Ripper|john|pkg|密码破解"
TOOLS["hashcat"]="无线密码|Hashcat|hashcat|pkg|GPU加速破解"
TOOLS["aircrack-ng"]="无线密码|Aircrack-ng|aircrack-ng|pkg|无线安全审计"
TOOLS["hydra"]="无线密码|Hydra|hydra|pkg|网络爆破"
TOOLS["medusa"]="无线密码|Medusa|medusa|pkg|并行爆破器"
TOOLS["responder"]="无线密码|Responder|responder|git|LLMNR欺骗"
TOOLS["impacket"]="无线密码|Impacket|impacket|pip|网络协议库"
TOOLS["crackmapexec"]="无线密码|CrackMapExec|crackmapexec|pip|域渗透工具"
TOOLS["kismet"]="无线密码|Kismet|kismet|pkg|无线网络探测器"
TOOLS["reaver"]="无线密码|Reaver|reaver|pkg|WPS破解"
TOOLS["wifite"]="无线密码|Wifite|wifite|pip|自动化无线攻击"

# 防御监控类
TOOLS["tcpdump"]="防御监控|tcpdump|tcpdump|pkg|命令行抓包"
TOOLS["wireshark"]="防御监控|Wireshark|wireshark|pkg|流量分析"
TOOLS["snort"]="防御监控|Snort|snort|pkg|入侵检测"
TOOLS["suricata"]="防御监控|Suricata|suricata|pkg|IDS/IPS"
TOOLS["zeek"]="防御监控|Zeek|zeek|pkg|网络安全监控"
TOOLS["ossec"]="防御监控|OSSEC|ossec|pkg|主机入侵检测"
TOOLS["fail2ban"]="防御监控|Fail2ban|fail2ban|pkg|防暴力破解"
TOOLS["rkhunter"]="防御监控|RKHunter|rkhunter|pkg|Rootkit检测"

# 渗透框架类
TOOLS["metasploit"]="渗透框架|Metasploit|metasploit-framework|pkg|渗透测试框架"
TOOLS["empire"]="渗透框架|Empire|empire|git|后渗透框架"
TOOLS["mimikatz"]="渗透框架|Mimikatz|mimikatz|manual|凭据提取"
TOOLS["bloodhound"]="渗透框架|BloodHound|bloodhound|pip|AD关系分析"
TOOLS["cobaltstrike"]="渗透框架|Cobalt Strike|cobaltstrike|manual|红队平台"

# 移动逆向类
TOOLS["apktool"]="移动逆向|APKTool|apktool|pkg|APK反编译"
TOOLS["jadx"]="移动逆向|Jadx|jadx|pkg|Android反编译"
TOOLS["ghidra"]="移动逆向|Ghidra|ghidra|pkg|逆向工程框架"
TOOLS["frida"]="移动逆向|Frida|frida|pip|动态代码注入"
TOOLS["objection"]="移动逆向|Objection|objection|pip|移动运行时探索"
TOOLS["mobsf"]="移动逆向|MobSF|mobsf|pip|移动安全框架"

# 云安全类
TOOLS["trivy"]="云安全|Trivy|trivy|pkg|容器漏洞扫描"
TOOLS["kube-hunter"]="云安全|Kube-hunter|kube-hunter|pip|K8s渗透测试"
TOOLS["kube-bench"]="云安全|Kube-bench|kube-bench|git|K8s安全基准"
TOOLS["scoutsuite"]="云安全|ScoutSuite|scoutsuite|pip|云安全审计"
TOOLS["prowler"]="云安全|Prowler|prowler|pip|AWS安全扫描"

# 取证分析类
TOOLS["volatility"]="取证分析|Volatility|volatility|pip|内存取证"
TOOLS["binwalk"]="取证分析|Binwalk|binwalk|pip|固件分析"
TOOLS["foremost"]="取证分析|Foremost|foremost|pkg|文件恢复"
TOOLS["autopsy"]="取证分析|Autopsy|autopsy|manual|数字取证平台"
TOOLS["exiftool"]="取证分析|ExifTool|exiftool|pkg|元数据读取"

# 社会工程类
TOOLS["setoolkit"]="社会工程|SET|setoolkit|pip|社会工程工具包"
TOOLS["gophish"]="社会工程|Gophish|gophish|manual|钓鱼框架"
TOOLS["evilginx"]="社会工程|Evilginx|evilginx|git|高级钓鱼代理"

# 开发工具类
TOOLS["git"]="开发工具|Git|git|pkg|版本控制"
TOOLS["python3"]="开发工具|Python3|python3|pkg|编程语言"
TOOLS["python3-pip"]="开发工具|pip3|python3-pip|pkg|Python包管理"
TOOLS["golang"]="开发工具|Go|golang|pkg|编程语言"
TOOLS["ruby"]="开发工具|Ruby|ruby|pkg|编程语言"
TOOLS["nodejs"]="开发工具|Node.js|nodejs|pkg|JavaScript运行时"

# 网络工具类
TOOLS["netcat"]="网络工具|Netcat|netcat|pkg|网络调试"
TOOLS["socat"]="网络工具|Socat|socat|pkg|网络转发"
TOOLS["proxychains"]="网络工具|Proxychains|proxychains|pkg|代理工具"
TOOLS["tor"]="网络工具|Tor|tor|pkg|匿名网络"
TOOLS["openssl"]="网络工具|OpenSSL|openssl|pkg|加密工具"

# ===================== 分类列表 =====================
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
    echo -e "${GRAY}────────────────────────────────────────────────────────${NC}"
}

print_banner() {
    clear
    echo -e "${RED}$MSG_WARNING${NC}"
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     QFYN Security Tools v$SCRIPT_VERSION - Linux 版              ║${NC}"
    echo -e "${CYAN}║                    作者: QFYN @~                                 ║${NC}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║  系统: $OS_NAME | 包管理器: $PKG_MANAGER${NC}"
    echo -e "${CYAN}║  安装目录: $INSTALL_DIR${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

check_root() {
    if [[ $EUID -ne 0 ]] && [[ "$PKG_MANAGER" != "unknown" ]]; then
        echo -e "${RED}[!] $MSG_NO_ROOT${NC}"
        echo -e "${YELLOW}[*] 请使用: sudo $0${NC}"
        exit 1
    fi
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
    IFS='|' read -r cat name pkg type desc <<< "$data"

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
            eval "$PKG_INSTALL $pkg" &>> "$LOG_FILE"
            ;;
        pip)
            if pip3 show "$pkg" &>/dev/null 2>&1; then
                echo -e "${GREEN}✓ $MSG_ALREADY${NC}"
                return 0
            fi
            pip3 install "$pkg" &>> "$LOG_FILE"
            ;;
        gem)
            if gem list | grep -q "$pkg"; then
                echo -e "${GREEN}✓ $MSG_ALREADY${NC}"
                return 0
            fi
            gem install "$pkg" &>> "$LOG_FILE"
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
        manual)
            echo -e "${YELLOW}⚠ $MSG_MANUAL${NC}"
            return 1
            ;;
        *)
            echo -e "${YELLOW}⚠ $MSG_MANUAL${NC}"
            return 1
            ;;
    esac

    if command -v "$pkg" &>/dev/null || pip3 show "$pkg" &>/dev/null 2>&1; then
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
    echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║  $MSG_SELECT_CAT                                              ║${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    local i=1
    for cat in "${CATEGORIES[@]}"; do
        local count=0
        for k in "${!TOOLS[@]}"; do
            IFS='|' read -r c _ _ _ _ <<< "${TOOLS[$k]}"
            [[ "$c" == "$cat" ]] && ((count++))
        done
        printf "  ${GREEN}%2d)${NC} %-15s ${GRAY}[%d]${NC}\n" "$i" "$cat" "$count"
        ((i++))
    done
    echo -e "  ${GREEN}$i)${NC} $MSG_INSTALL_ALL"
    echo -e "  ${RED}0)${NC} $MSG_EXIT"
    draw_line
}

show_tools_menu() {
    local category="$1"
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  $MSG_SELECT_TOOL - $category                                 ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    local tools_list=()
    local i=1
    for key in "${!TOOLS[@]}"; do
        IFS='|' read -r cat name pkg type desc <<< "${TOOLS[$key]}"
        if [[ "$cat" == "$category" ]]; then
            tools_list+=("$key|$name|$desc")
            printf "  ${GREEN}%2d)${NC} %-20s ${GRAY}%s${NC}\n" "$i" "$name" "$desc"
            ((i++))
        fi
    done
    echo -e "  ${GREEN}$i)${NC} $MSG_INSTALL_ALL"
    echo -e "  ${YELLOW}b)${NC} $MSG_BACK"
    echo -e "  ${RED}0)${NC} $MSG_EXIT"
    draw_line

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
        IFS='|' read -r cat _ _ _ _ <<< "${TOOLS[$key]}"
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
        printf "\r[$current/$total] "
        if install_tool "$key"; then
            ((installed++))
        fi
    done
    echo ""
    log "$MSG_INSTALL_ALL: $installed/$total $MSG_SUCCESS" "$GREEN"
}

# ===================== 配置 PATH =====================
configure_path() {
    echo ""
    log "$MSG_CONF_PATH" "$CYAN"

    local paths_to_add=(
        "$INSTALL_DIR"
        "/usr/local/bin"
        "$HOME/.local/bin"
    )

    for path in "${paths_to_add[@]}"; do
        if [[ -d "$path" ]] && [[ ":$PATH:" != *":$path:"* ]]; then
            echo "export PATH=\"\$PATH:$path\"" >> "$HOME/.bashrc"
            echo -e "  + Added: $path" | tee -a "$LOG_FILE"
        fi
    done

    log "$MSG_PATH_DONE" "$GREEN"
}

# ===================== 生成辅助文件 =====================
generate_files() {
    # 生成快速启动脚本
    cat > "$INSTALL_DIR/quick_start.sh" << 'EOF'
#!/bin/bash
echo "========================================"
echo "  QFYN Security Tools - Quick Start"
echo "========================================"
echo ""
echo "可用命令:"
echo "  nmap        - 网络扫描"
echo "  sqlmap      - SQL注入检测"
echo "  hydra       - 网络登录爆破"
echo "  john        - 密码破解"
echo "  wireshark   - 流量分析"
echo "  metasploit  - 渗透框架"
echo "  gobuster    - 目录爆破"
echo "  ffuf        - 快速目录枚举"
echo ""
echo "输入命令名称启动工具"
echo "========================================"
read -p "命令: " cmd
eval "$cmd"
EOF
    chmod +x "$INSTALL_DIR/quick_start.sh"

    # 生成工具清单
    cat > "$TOOL_LIST_FILE" << EOF
# QFYN Security Tools - 完整工具清单

> 生成时间: $(date '+%Y-%m-%d %H:%M:%S')
> 工具总数: ${#TOOLS[@]}
> 系统: $OS_NAME
> 作者: QFYN @~

| # | 工具名称 | 分类 | 功能说明 |
|---|---------|------|---------|
EOF

    local i=1
    for key in $(echo "${!TOOLS[@]}" | tr ' ' '\n' | sort); do
        IFS='|' read -r cat name _ _ desc <<< "${TOOLS[$key]}"
        echo "| $i | $name | $cat | $desc |" >> "$TOOL_LIST_FILE"
        ((i++))
    done

    # 生成 JSON 配置
    cat > "$CONFIG_FILE" << EOF
{
    "version": "$SCRIPT_VERSION",
    "install_date": "$(date '+%Y-%m-%d %H:%M:%S')",
    "os": "$OS_NAME",
    "package_manager": "$PKG_MANAGER",
    "install_dir": "$INSTALL_DIR",
    "tools_count": ${#TOOLS[@]}
}
EOF

    log "[+] 快速启动: $INSTALL_DIR/quick_start.sh" "$GREEN"
    log "[+] 工具清单: $TOOL_LIST_FILE" "$GREEN"
    log "[+] 配置文件: $CONFIG_FILE" "$GREEN"
}

# ===================== 健康检查 =====================
health_check() {
    echo ""
    log "验证已安装工具..." "$CYAN"

    local installed=0
    local total=0

    for key in "${!TOOLS[@]}"; do
        IFS='|' read -r cat name pkg type _ <<< "${TOOLS[$key]}"
        if [[ "$type" == "pkg" || "$type" == "pip" || "$type" == "gem" ]]; then
            ((total++))
            if command -v "$pkg" &>/dev/null || pip3 show "$pkg" &>/dev/null 2>&1; then
                ((installed++))
            fi
        fi
    done

    echo -e "  已检测到: $installed / $total 个工具" | tee -a "$LOG_FILE"
    echo -e "  详细报告: $INSTALL_DIR/health_report.txt" | tee -a "$LOG_FILE"

    cat > "$INSTALL_DIR/health_report.txt" << EOF
QFYN Security Tools - 健康报告
生成时间: $(date '+%Y-%m-%d %H:%M:%S')
已安装: $installed / $total
EOF
}

# ===================== 主程序 =====================
main() {
    detect_os
    check_root
    print_banner
    confirm_legal

    mkdir -p "$INSTALL_DIR"
    touch "$LOG_FILE"

    log "$MSG_CREATE_DIR: $INSTALL_DIR" "$GREEN"

    # 更新包管理器
    if [[ "$PKG_MANAGER" != "unknown" ]]; then
        log "更新包管理器..." "$CYAN"
        eval "$PKG_UPDATE" &>> "$LOG_FILE" || true
    fi

    # 安装基础依赖
    log "安装基础依赖..." "$CYAN"
    case $PKG_MANAGER in
        apt|yum|dnf|pacman|zypper)
            $PKG_INSTALL git curl wget python3 python3-pip &>> "$LOG_FILE" || true
            ;;
        *)
            log "请手动安装: git, curl, wget, python3" "$YELLOW"
            ;;
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

    configure_path
    generate_files
    health_check

    # 完成统计
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))

    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✅ $MSG_SUCCESS                                              ║${NC}"
    echo -e "${GREEN}╠════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║  安装用时: $duration 秒${NC}"
    echo -e "${GREEN}║  安装目录: $INSTALL_DIR${NC}"
    echo -e "${GREEN}║  日志文件: $LOG_FILE${NC}"
    echo -e "${GREEN}║  工具清单: $TOOL_LIST_FILE${NC}"
    echo -e "${GREEN}║  快速启动: $INSTALL_DIR/quick_start.sh${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}[*] 提示: 请运行 'source ~/.bashrc' 或重启终端使 PATH 生效${NC}"
}

# ===================== 启动 =====================
main "$@"