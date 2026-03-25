<#
.SYNOPSIS
    网络安全工具批量下载与部署脚本（120种）
.DESCRIPTION
    本脚本用于自动下载并安装120种常用网络安全工具（包括Nmap、Wireshark、Burp Suite等）。
    支持彩色终端显示、真实下载进度条，并生成详细的Markdown文档。
    警告：本脚本仅限授权测试与教育用途，严禁用于非法活动！
.NOTES
    作者：QFYN @~
    版本：3.0
    要求：Windows 10/11 或 Windows Server 2016+，需管理员权限。
#>

# ===================== 声明与法律警告 =====================
Clear-Host
Write-Host @"
╔══════════════════════════════════════════════════════════════════════════╗
║                           ⚠️ 法律与道德警告 ⚠️                            ║
║                                                                          ║
║  本脚本仅可用于：                                                         ║
║    1. 经过明确书面授权的渗透测试                                          ║
║    2. 网络安全教学与研究                                                  ║
║    3. 自身系统的安全评估                                                  ║
║                                                                          ║
║  根据《中华人民共和国刑法》第285、286条及《网络安全法》：                 ║
║    - 未经授权对计算机信息系统进行攻击、侵入属违法行为                     ║
║    - 最高可处七年以下有期徒刑                                            ║
║                                                                          ║
║  使用本脚本即代表您承诺：                                                 ║
║    - 已获得目标所有者的书面授权                                          ║
║    - 愿意承担因违规使用产生的一切法律责任                                 ║
╚══════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Red

$confirmation = Read-Host "请输入 'YES' 以确认您已阅读并接受上述条款"
if ($confirmation -ne "YES") {
    Write-Host "未获得确认，脚本退出。" -ForegroundColor Red
    exit 1
}

# ===================== 权限检查 =====================
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "请以管理员身份运行此脚本！" -ForegroundColor Red
    Write-Host "右键单击PowerShell，选择'以管理员身份运行'。" -ForegroundColor Yellow
    pause
    exit 1
}

# ===================== 配置区域 =====================
$script:ToolDir = "$env:USERPROFILE\Desktop\SecurityTools"
$script:LogFile = "$ToolDir\download_log.txt"
$script:MarkdownFile = "$ToolDir\Tool_List.md"
$script:ToolListFile = "$ToolDir\tool_list.txt"   # 可扩展的列表文件

# 创建目录
if (-not (Test-Path $ToolDir)) {
    New-Item -ItemType Directory -Path $ToolDir -Force | Out-Null
}

# ===================== 工具列表（示例120种，实际可扩展） =====================
# 注：此处列出120种工具的名称、下载源或安装命令。部分使用winget自动安装，部分提供直接下载链接。
# 实际使用时可根据需要修改URL。为保证脚本可用性，这里混合使用winget和直接下载。
# 如果winget不可用，会回退到手动下载。

$tools = @(
    # 信息收集
    @{Name="Nmap"; Category="信息收集"; WingetId="Insecure.Nmap"; Url="https://nmap.org/dist/nmap-7.94-setup.exe"; Cmd="nmap"},
    @{Name="Maltego"; Category="信息收集"; WingetId=""; Url="https://www.maltego.com/downloads/"; Cmd="maltego"},
    @{Name="Shodan CLI"; Category="信息收集"; WingetId=""; Url="https://github.com/achillean/shodan-python/releases"; Cmd="shodan"},
    @{Name="Recon-ng"; Category="信息收集"; WingetId=""; Url="https://github.com/lanmaster53/recon-ng"; Cmd="recon-ng"},
    @{Name="theHarvester"; Category="信息收集"; WingetId=""; Url="https://github.com/laramies/theHarvester"; Cmd="theHarvester"},
    @{Name="Dnsrecon"; Category="信息收集"; WingetId=""; Url="https://github.com/darkoperator/dnsrecon"; Cmd="dnsrecon"},
    @{Name="Sublist3r"; Category="信息收集"; WingetId=""; Url="https://github.com/aboul3la/Sublist3r"; Cmd="sublist3r"},
    @{Name="Amass"; Category="信息收集"; WingetId="OWASP.Amass"; Url="https://github.com/OWASP/Amass/releases"; Cmd="amass"},
    @{Name="Masscan"; Category="信息收集"; WingetId=""; Url="https://github.com/robertdavidgraham/masscan/releases"; Cmd="masscan"},
    @{Name="Zmap"; Category="信息收集"; WingetId=""; Url="https://github.com/zmap/zmap/releases"; Cmd="zmap"},
    @{Name="Netdiscover"; Category="信息收集"; WingetId=""; Url="https://github.com/netdiscover/netdiscover"; Cmd="netdiscover"},
    @{Name="Fierce"; Category="信息收集"; WingetId=""; Url="https://github.com/mschwager/fierce"; Cmd="fierce"},
    @{Name="WhatWeb"; Category="信息收集"; WingetId=""; Url="https://github.com/urbanadventurer/WhatWeb"; Cmd="whatweb"},
    @{Name="Wappalyzer"; Category="信息收集"; WingetId=""; Url="https://github.com/AliasIO/Wappalyzer"; Cmd="wappalyzer"},
    @{Name="BuiltWith"; Category="信息收集"; WingetId=""; Url="https://builtwith.com/"; Cmd="builtwith"},

    # 漏洞扫描
    @{Name="Nessus"; Category="漏洞扫描"; WingetId=""; Url="https://www.tenable.com/downloads/nessus"; Cmd="nessus"},
    @{Name="OpenVAS"; Category="漏洞扫描"; WingetId=""; Url="https://www.greenbone.net/en/install_use_gce/"; Cmd="openvas"},
    @{Name="Nexpose"; Category="漏洞扫描"; WingetId=""; Url="https://www.rapid7.com/products/nexpose/"; Cmd="nexpose"},
    @{Name="VulnScanner"; Category="漏洞扫描"; WingetId=""; Url="https://github.com/OWASP/VulnScanner"; Cmd="vulnscanner"},
    @{Name="Nikto"; Category="漏洞扫描"; WingetId=""; Url="https://github.com/sullo/nikto"; Cmd="nikto"},
    @{Name="WPScan"; Category="漏洞扫描"; WingetId=""; Url="https://github.com/wpscanteam/wpscan"; Cmd="wpscan"},
    @{Name="Joomscan"; Category="漏洞扫描"; WingetId=""; Url="https://github.com/rezasp/joomscan"; Cmd="joomscan"},
    @{Name="Droopescan"; Category="漏洞扫描"; WingetId=""; Url="https://github.com/droope/droopescan"; Cmd="droopescan"},
    @{Name="CMSmap"; Category="漏洞扫描"; WingetId=""; Url="https://github.com/Dionach/CMSmap"; Cmd="cmsmap"},
    @{Name="Wfuzz"; Category="漏洞扫描"; WingetId=""; Url="https://github.com/xmendez/wfuzz"; Cmd="wfuzz"},
    @{Name="Dirb"; Category="漏洞扫描"; WingetId=""; Url="https://github.com/v0re/dirb"; Cmd="dirb"},
    @{Name="Gobuster"; Category="漏洞扫描"; WingetId=""; Url="https://github.com/OJ/gobuster"; Cmd="gobuster"},
    @{Name="FFUF"; Category="漏洞扫描"; WingetId=""; Url="https://github.com/ffuf/ffuf"; Cmd="ffuf"},

    # Web应用测试
    @{Name="Burp Suite"; Category="Web应用测试"; WingetId="PortSwigger.BurpSuite.Community"; Url="https://portswigger.net/burp/releases"; Cmd="burpsuite"},
    @{Name="SQLMap"; Category="Web应用测试"; WingetId=""; Url="https://github.com/sqlmapproject/sqlmap"; Cmd="sqlmap"},
    @{Name="Metasploit"; Category="Web应用测试"; WingetId="Rapid7.Metasploit"; Url="https://www.metasploit.com/download"; Cmd="msfconsole"},
    @{Name="OWASP ZAP"; Category="Web应用测试"; WingetId="OWASP.ZAP"; Url="https://www.zaproxy.org/download/"; Cmd="zap"},
    @{Name="W3af"; Category="Web应用测试"; WingetId=""; Url="https://github.com/andresriancho/w3af"; Cmd="w3af"},
    @{Name="Arachni"; Category="Web应用测试"; WingetId=""; Url="https://github.com/Arachni/arachni"; Cmd="arachni"},
    @{Name="BeEF"; Category="Web应用测试"; WingetId=""; Url="https://github.com/beefproject/beef"; Cmd="beef"},
    @{Name="XSSer"; Category="Web应用测试"; WingetId=""; Url="https://github.com/epsylon/xsser"; Cmd="xsser"},
    @{Name="Commix"; Category="Web应用测试"; WingetId=""; Url="https://github.com/commixproject/commix"; Cmd="commix"},
    @{Name="NoSQLMap"; Category="Web应用测试"; WingetId=""; Url="https://github.com/codingo/NoSQLMap"; Cmd="nosqlmap"},
    @{Name="XSStrike"; Category="Web应用测试"; WingetId=""; Url="https://github.com/s0md3v/XSStrike"; Cmd="xsstrike"},
    @{Name="JWT Tool"; Category="Web应用测试"; WingetId=""; Url="https://github.com/ticarpi/jwt_tool"; Cmd="jwt_tool"},

    # 无线与密码
    @{Name="Aircrack-ng"; Category="无线与密码"; WingetId=""; Url="https://www.aircrack-ng.org/downloads.html"; Cmd="aircrack-ng"},
    @{Name="Hashcat"; Category="无线与密码"; WingetId="Hashcat.Hashcat"; Url="https://hashcat.net/hashcat/"; Cmd="hashcat"},
    @{Name="John the Ripper"; Category="无线与密码"; WingetId="OpenWall.John"; Url="https://www.openwall.com/john/"; Cmd="john"},
    @{Name="Hydra"; Category="无线与密码"; WingetId=""; Url="https://github.com/vanhauser-thc/thc-hydra"; Cmd="hydra"},
    @{Name="Medusa"; Category="无线与密码"; WingetId=""; Url="https://github.com/jmk-foofus/medusa"; Cmd="medusa"},
    @{Name="Ncrack"; Category="无线与密码"; WingetId=""; Url="https://nmap.org/ncrack/"; Cmd="ncrack"},
    @{Name="Patator"; Category="无线与密码"; WingetId=""; Url="https://github.com/lanjelot/patator"; Cmd="patator"},
    @{Name="CrackMapExec"; Category="无线与密码"; WingetId=""; Url="https://github.com/byt3bl33d3r/CrackMapExec"; Cmd="cme"},
    @{Name="Responder"; Category="无线与密码"; WingetId=""; Url="https://github.com/SpiderLabs/Responder"; Cmd="responder"},
    @{Name="Impacket"; Category="无线与密码"; WingetId=""; Url="https://github.com/SecureAuthCorp/impacket"; Cmd="impacket"},
    @{Name="Chntpw"; Category="无线与密码"; WingetId=""; Url="https://github.com/TobiSGD/chntpw"; Cmd="chntpw"},
    @{Name="Ophcrack"; Category="无线与密码"; WingetId=""; Url="https://ophcrack.sourceforge.io/"; Cmd="ophcrack"},

    # 防御与监控
    @{Name="Wireshark"; Category="防御与监控"; WingetId="WiresharkFoundation.Wireshark"; Url="https://www.wireshark.org/download.html"; Cmd="wireshark"},
    @{Name="Snort"; Category="防御与监控"; WingetId=""; Url="https://www.snort.org/downloads"; Cmd="snort"},
    @{Name="Suricata"; Category="防御与监控"; WingetId=""; Url="https://suricata.io/download/"; Cmd="suricata"},
    @{Name="Zeek (Bro)"; Category="防御与监控"; WingetId=""; Url="https://zeek.org/download/"; Cmd="zeek"},
    @{Name="OSSEC"; Category="防御与监控"; WingetId=""; Url="https://www.ossec.net/downloads/"; Cmd="ossec"},
    @{Name="Security Onion"; Category="防御与监控"; WingetId=""; Url="https://securityonion.net/"; Cmd="so"},
    @{Name="ELK Stack"; Category="防御与监控"; WingetId=""; Url="https://www.elastic.co/downloads/"; Cmd="elastic"},
    @{Name="Graylog"; Category="防御与监控"; WingetId=""; Url="https://www.graylog.org/downloads"; Cmd="graylog"},
    @{Name="Splunk"; Category="防御与监控"; WingetId=""; Url="https://www.splunk.com/en_us/download.html"; Cmd="splunk"},
    @{Name="OpenVAS (GVM)"; Category="防御与监控"; WingetId=""; Url="https://www.greenbone.net/en/install_use_gce/"; Cmd="gvm"},
    @{Name="Ntopng"; Category="防御与监控"; WingetId=""; Url="https://www.ntop.org/products/ntopng/"; Cmd="ntopng"},
    @{Name="PRTG Network Monitor"; Category="防御与监控"; WingetId=""; Url="https://www.paessler.com/download"; Cmd="prtg"},

    # 渗透框架与综合
    @{Name="Kali Linux (WSL)"; Category="渗透框架"; WingetId="Kali.Linux"; Url="https://www.kali.org/get-kali/"; Cmd="kali"},
    @{Name="Parrot OS (WSL)"; Category="渗透框架"; WingetId=""; Url="https://www.parrotsec.org/download/"; Cmd="parrot"},
    @{Name="BlackArch"; Category="渗透框架"; WingetId=""; Url="https://blackarch.org/downloads.html"; Cmd="blackarch"},
    @{Name="Cobalt Strike"; Category="渗透框架"; WingetId=""; Url="https://www.cobaltstrike.com/download"; Cmd="cobaltstrike"},
    @{Name="Empire"; Category="渗透框架"; WingetId=""; Url="https://github.com/BC-SECURITY/Empire"; Cmd="empire"},
    @{Name="PowerSploit"; Category="渗透框架"; WingetId=""; Url="https://github.com/PowerShellMafia/PowerSploit"; Cmd="powersploit"},
    @{Name="Mimikatz"; Category="渗透框架"; WingetId=""; Url="https://github.com/gentilkiwi/mimikatz"; Cmd="mimikatz"},
    @{Name="BloodHound"; Category="渗透框架"; WingetId=""; Url="https://github.com/BloodHoundAD/BloodHound"; Cmd="bloodhound"},
    @{Name="SharpHound"; Category="渗透框架"; WingetId=""; Url="https://github.com/BloodHoundAD/BloodHound/tree/master/Collectors"; Cmd="sharphound"},
    @{Name="PoshC2"; Category="渗透框架"; WingetId=""; Url="https://github.com/nettitude/PoshC2"; Cmd="poshc2"},
    @{Name="Covenant"; Category="渗透框架"; WingetId=""; Url="https://github.com/cobbr/Covenant"; Cmd="covenant"},
    @{Name="Merlin"; Category="渗透框架"; WingetId=""; Url="https://github.com/Ne0nd0g/merlin"; Cmd="merlin"},

    # 移动与嵌入式
    @{Name="MobSF"; Category="移动安全"; WingetId=""; Url="https://github.com/MobSF/Mobile-Security-Framework-MobSF"; Cmd="mobsf"},
    @{Name="Drozer"; Category="移动安全"; WingetId=""; Url="https://github.com/WithSecureLabs/drozer"; Cmd="drozer"},
    @{Name="Android SDK"; Category="移动安全"; WingetId="Google.AndroidSDK"; Url="https://developer.android.com/studio"; Cmd="adb"},
    @{Name="Burp Mobile Assistant"; Category="移动安全"; WingetId=""; Url="https://portswigger.net/burp/application-mobile-assistant"; Cmd="burp-mobile"},
    @{Name="Objection"; Category="移动安全"; WingetId=""; Url="https://github.com/sensepost/objection"; Cmd="objection"},
    @{Name="Frida"; Category="移动安全"; WingetId=""; Url="https://frida.re/docs/installation/"; Cmd="frida"},
    @{Name="APKTool"; Category="移动安全"; WingetId=""; Url="https://ibotpeaches.github.io/Apktool/"; Cmd="apktool"},
    @{Name="Jadx"; Category="移动安全"; WingetId=""; Url="https://github.com/skylot/jadx"; Cmd="jadx"},
    @{Name="Ghidra"; Category="逆向工程"; WingetId="NationalSecurityAgency.Ghidra"; Url="https://ghidra-sre.org/"; Cmd="ghidra"},
    @{Name="IDA Pro Free"; Category="逆向工程"; WingetId=""; Url="https://hex-rays.com/ida-free/"; Cmd="ida"},

    # 云安全
    @{Name="ScoutSuite"; Category="云安全"; WingetId=""; Url="https://github.com/nccgroup/ScoutSuite"; Cmd="scoutsuite"},
    @{Name="Prowler"; Category="云安全"; WingetId=""; Url="https://github.com/prowler-cloud/prowler"; Cmd="prowler"},
    @{Name="CloudSploit"; Category="云安全"; WingetId=""; Url="https://github.com/aquasecurity/cloudsploit"; Cmd="cloudsploit"},
    @{Name="Kube-hunter"; Category="云安全"; WingetId=""; Url="https://github.com/aquasecurity/kube-hunter"; Cmd="kube-hunter"},
    @{Name="Kube-bench"; Category="云安全"; WingetId=""; Url="https://github.com/aquasecurity/kube-bench"; Cmd="kube-bench"},
    @{Name="Trivy"; Category="云安全"; WingetId=""; Url="https://github.com/aquasecurity/trivy"; Cmd="trivy"},
    @{Name="Clair"; Category="云安全"; WingetId=""; Url="https://github.com/quay/clair"; Cmd="clair"},

    # 取证与内存分析
    @{Name="Volatility"; Category="取证"; WingetId=""; Url="https://www.volatilityfoundation.org/releases"; Cmd="volatility"},
    @{Name="Rekall"; Category="取证"; WingetId=""; Url="https://github.com/google/rekall"; Cmd="rekall"},
    @{Name="Autopsy"; Category="取证"; WingetId=""; Url="https://www.autopsy.com/download/"; Cmd="autopsy"},
    @{Name="Sleuth Kit"; Category="取证"; WingetId=""; Url="https://www.sleuthkit.org/"; Cmd="tsk"},
    @{Name="Foremost"; Category="取证"; WingetId=""; Url="https://github.com/jesparza/foremost"; Cmd="foremost"},
    @{Name="Binwalk"; Category="取证"; WingetId=""; Url="https://github.com/ReFirmLabs/binwalk"; Cmd="binwalk"},
    @{Name="ExifTool"; Category="取证"; WingetId=""; Url="https://exiftool.org/"; Cmd="exiftool"},

    # 社会工程学
    @{Name="SET (Social-Engineer Toolkit)"; Category="社会工程"; WingetId=""; Url="https://github.com/trustedsec/social-engineer-toolkit"; Cmd="setoolkit"},
    @{Name="King Phisher"; Category="社会工程"; WingetId=""; Url="https://github.com/securestate/king-phisher"; Cmd="kingphisher"},
    @{Name="Gophish"; Category="社会工程"; WingetId=""; Url="https://getgophish.com/"; Cmd="gophish"},
    @{Name="Evilginx"; Category="社会工程"; WingetId=""; Url="https://github.com/kgretzky/evilginx2"; Cmd="evilginx"},

    # 物联网与工控
    @{Name="Shodan CLI"; Category="物联网"; WingetId=""; Url="https://github.com/achillean/shodan-python"; Cmd="shodan"},
    @{Name="Censys CLI"; Category="物联网"; WingetId=""; Url="https://github.com/censys/censys-python"; Cmd="censys"},
    @{Name="Zigbee2MQTT"; Category="物联网"; WingetId=""; Url="https://www.zigbee2mqtt.io/"; Cmd="zigbee2mqtt"},
    @{Name="Modbus Poll"; Category="工控"; WingetId=""; Url="https://www.modbustools.com/download.html"; Cmd="modbuspoll"},
    @{Name="S7-1200 Tools"; Category="工控"; WingetId=""; Url="https://github.com/0x90/s7-1200-tools"; Cmd="s7tools"},

    # 其他实用工具
    @{Name="CyberChef"; Category="编解码"; WingetId=""; Url="https://github.com/gchq/CyberChef/releases"; Cmd="cyberchef"},
    @{Name="Dev-Tools"; Category="开发辅助"; WingetId=""; Url="https://github.com/jas502n/Dev-Tools"; Cmd="devtools"},
    @{Name="PowerShell Empire"; Category="后渗透"; WingetId=""; Url="https://github.com/EmpireProject/Empire"; Cmd="empire"},
    @{Name="Nishang"; Category="后渗透"; WingetId=""; Url="https://github.com/samratashok/nishang"; Cmd="nishang"}
)

# 补充至120项（当前已列出约110项，可再添加10项简单工具）
$extraTools = @(
    @{Name="Putty"; Category="远程连接"; WingetId="PuTTY.PuTTY"; Url="https://www.putty.org/"; Cmd="putty"},
    @{Name="WinSCP"; Category="文件传输"; WingetId="WinSCP.WinSCP"; Url="https://winscp.net/eng/download.php"; Cmd="winscp"},
    @{Name="Notepad++"; Category="编辑器"; WingetId="Notepad++.Notepad++"; Url="https://notepad-plus-plus.org/downloads/"; Cmd="notepad++"},
    @{Name="Git"; Category="版本控制"; WingetId="Git.Git"; Url="https://git-scm.com/download/win"; Cmd="git"},
    @{Name="Python3"; Category="运行环境"; WingetId="Python.Python.3"; Url="https://www.python.org/downloads/"; Cmd="python"},
    @{Name="Ruby"; Category="运行环境"; WingetId="RubyInstallerTeam.Ruby.3"; Url="https://rubyinstaller.org/downloads/"; Cmd="ruby"},
    @{Name="Node.js"; Category="运行环境"; WingetId="OpenJS.NodeJS"; Url="https://nodejs.org/en/download/"; Cmd="node"},
    @{Name="Visual Studio Code"; Category="编辑器"; WingetId="Microsoft.VisualStudioCode"; Url="https://code.visualstudio.com/download"; Cmd="code"},
    @{Name="Docker Desktop"; Category="容器"; WingetId="Docker.DockerDesktop"; Url="https://www.docker.com/products/docker-desktop/"; Cmd="docker"},
    @{Name="VMware Workstation Player"; Category="虚拟化"; WingetId="VMware.WorkstationPlayer"; Url="https://www.vmware.com/products/workstation-player.html"; Cmd="vmware"}
)
$tools += $extraTools

# ===================== 辅助函数 =====================
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Download-Tool {
    param(
        [string]$Name,
        [string]$Url,
        [string]$WingetId,
        [string]$Category
    )
    $destPath = Join-Path $ToolDir "$Name-Installer.exe"
    Write-ColorOutput "[$Category] 正在处理: $Name" "Cyan"

    # 优先尝试 winget 安装
    if ($WingetId) {
        Write-ColorOutput "  尝试使用 winget 安装..." "Yellow"
        try {
            winget install --id $WingetId --exact --silent --accept-package-agreements --accept-source-agreements
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "  安装成功 (winget)" "Green"
                return
            } else {
                Write-ColorOutput "  winget 安装失败，回退到手动下载" "Red"
            }
        } catch {
            Write-ColorOutput "  winget 不可用或安装失败，回退到手动下载" "Red"
        }
    }

    # 手动下载
    if ($Url -and $Url -notlike "*github.com*") {
        Write-ColorOutput "  下载地址: $Url" "Gray"
        try {
            # 使用 Invoke-WebRequest 下载，显示进度
            $progressPreference = 'Continue'
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($Url, $destPath)
            Write-ColorOutput "  下载完成: $destPath" "Green"
            # 记录日志
            "$(Get-Date) - 下载完成: $Name" | Out-File -Append $script:LogFile
        } catch {
            Write-ColorOutput "  下载失败: $_" "Red"
            "$(Get-Date) - 下载失败: $Name - $_" | Out-File -Append $script:LogFile
        }
    } elseif ($Url -like "*github.com*") {
        # GitHub 仓库通常需要获取 release 最新版本，这里简化处理，提示用户手动下载
        Write-ColorOutput "  请手动从 $Url 下载最新版本，并放入 $ToolDir 目录" "Yellow"
        "$(Get-Date) - 需手动下载: $Name - $Url" | Out-File -Append $script:LogFile
    } else {
        Write-ColorOutput "  未提供有效下载链接或 winget ID，请手动安装" "Red"
        "$(Get-Date) - 缺少安装信息: $Name" | Out-File -Append $script:LogFile
    }
}

# ===================== 主流程 =====================
Write-ColorOutput "==============================================" "Magenta"
Write-ColorOutput "开始下载 120 种安全工具，请耐心等待..." "Magenta"
Write-ColorOutput "下载目录: $ToolDir" "Magenta"
Write-ColorOutput "==============================================" "Magenta"

$total = $tools.Count
$current = 0
foreach ($tool in $tools) {
    $current++
    Write-Progress -Activity "下载工具" -Status "正在处理: $($tool.Name)" -PercentComplete (($current / $total) * 100) -CurrentOperation "($current/$total)"
    Download-Tool -Name $tool.Name -Url $tool.Url -WingetId $tool.WingetId -Category $tool.Category
    Start-Sleep -Milliseconds 500   # 避免请求过快
}
Write-Progress -Activity "下载工具" -Completed

Write-ColorOutput "所有工具处理完成！" "Green"
Write-ColorOutput "详细日志保存在: $LogFile" "Green"

# ===================== 生成 Markdown 文档 =====================
Write-ColorOutput "正在生成工具清单 Markdown 文档..." "Cyan"
$mdContent = @"
# 网络安全工具清单（120种）

> 生成时间：$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
> 下载目录：`$ToolDir`

## 快速命令索引

| 类别 | 工具名称 | 快捷命令 | 安装方式 |
|------|----------|----------|----------|
"@

foreach ($tool in $tools) {
    $installMethod = if ($tool.WingetId) { "winget" } else { "手动下载" }
    $mdContent += "| $($tool.Category) | $($tool.Name) | `$($tool.Cmd)` | $installMethod |`n"
}

$mdContent += @"

## 使用说明

1. 所有通过 winget 安装的工具已自动安装到系统。
2. 手动下载的工具安装包存放在 `$ToolDir` 目录，请根据提示手动安装。
3. 对于 GitHub 项目，请访问其 Releases 页面下载最新版。
4. 部分工具需要配置环境变量或依赖库，请参考官方文档。
5. **法律警告**：本工具仅限授权测试使用，滥用将承担法律责任。

## 常见问题

- **winget 不可用**：请安装 [App Installer](https://www.microsoft.com/store/productId/9NBLGGH4NNS1) 或更新 Windows。
- **下载失败**：请检查网络连接，或尝试使用代理。
- **需要管理员权限**：部分工具安装需要管理员权限，请确保脚本以管理员身份运行。

## 更新日志

- v2.0 (2025-03-26): 支持120种工具，添加 winget 自动安装，优化进度显示。
"@

$mdContent | Out-File -FilePath $MarkdownFile -Encoding utf8
Write-ColorOutput "Markdown 文档已生成: $MarkdownFile" "Green"

# ===================== 显示快捷命令 =====================
Write-ColorOutput "==============================================" "Magenta"
Write-ColorOutput "快捷命令列表（部分）" "Magenta"
Write-ColorOutput "==============================================" "Magenta"
$tools | Select-Object -First 20 | ForEach-Object {
    Write-ColorOutput "  $($_.Cmd) - $($_.Name)" "Yellow"
}
Write-ColorOutput "...（共 $total 种工具，完整列表请查看 Markdown 文档）" "Gray"

pause