<#
.SYNOPSIS
    QFYN Security Tools Auto-Installer
.DESCRIPTION
    一键安装120+网络安全工具，支持中英文界面
    作者: QFYN @~
    版本: 4.0
    警告: 仅限授权测试环境使用！
#>

# ===================== 语言选择 =====================
param(
    [string]$Language = "CN"  # CN = 中文, EN = 英文
)

# 检测系统语言
if ($Language -eq "Auto") {
    $osLang = (Get-Culture).TwoLetterISOLanguageName
    if ($osLang -eq "zh") { $Language = "CN" } else { $Language = "EN" }
}

# ===================== 多语言文本 =====================
$text = @{
    CN = @{
        Warning = @"
╔══════════════════════════════════════════════════════════════════════════╗
║  本工具仅用于授权的网络安全测试、教育及研究                              ║
║  禁止用于非法入侵·仅限授权环境测试·使用者须自行承担一切法律后果          ║
║  未经授权使用可能违反《网络安全法》，最高可处七年以下有期徒刑           ║
╚══════════════════════════════════════════════════════════════════════════╝
"@
        ConfirmMsg = "请输入 '我接受' 以确认您已阅读并接受上述条款"
        ConfirmCode = "我接受"
        NoAdmin = "请以管理员身份运行此脚本！"
        AdminTip = "右键单击PowerShell，选择'以管理员身份运行'"
        StartInstall = "开始安装 {0} 个工具..."
        Installing = "正在安装: {0}"
        ManualInstall = "需要手动安装: {0}"
        Success = "安装完成！"
        Fail = "安装失败"
        AlreadyInstalled = "已安装: {0}"
        Downloading = "正在下载: {0}"
        ConfigPath = "正在配置系统PATH环境变量..."
        PathDone = "PATH配置完成"
        LogFile = "日志文件: {0}"
        ToolList = "工具清单: {0}"
        CreateDir = "创建目录: {0}"
        Skip = "跳过: {0}"
    }
    EN = @{
        Warning = @"
╔══════════════════════════════════════════════════════════════════════════╗
║  This tool is for authorized security testing, education, and research  ║
║  Unauthorized use may violate laws. User assumes all legal liability    ║
╚══════════════════════════════════════════════════════════════════════════╝
"@
        ConfirmMsg = "Enter 'I ACCEPT' to confirm you have read and accept the terms"
        ConfirmCode = "I ACCEPT"
        NoAdmin = "Please run this script as Administrator!"
        AdminTip = "Right-click PowerShell and select 'Run as Administrator'"
        StartInstall = "Installing {0} tools..."
        Installing = "Installing: {0}"
        ManualInstall = "Manual install required: {0}"
        Success = "Installation complete!"
        Fail = "Installation failed"
        AlreadyInstalled = "Already installed: {0}"
        Downloading = "Downloading: {0}"
        ConfigPath = "Configuring system PATH environment variable..."
        PathDone = "PATH configuration complete"
        LogFile = "Log file: {0}"
        ToolList = "Tool list: {0}"
        CreateDir = "Creating directory: {0}"
        Skip = "Skipping: {0}"
    }
}

$lang = $text[$Language]

# ===================== 时区设置 =====================
$targetTimezone = "China Standard Time"
$currentTimezone = (Get-TimeZone).Id
if ($currentTimezone -ne $targetTimezone) {
    try {
        Set-TimeZone -Id $targetTimezone -ErrorAction Stop
        Write-Host "[Timezone] Changed to: $targetTimezone" -ForegroundColor Green
    } catch {
        Write-Host "[Timezone] Failed to change timezone (requires admin)" -ForegroundColor Yellow
    }
}

# ===================== 法律警告 =====================
Clear-Host
Write-Host $lang.Warning -ForegroundColor Red
Write-Host "`n"
Write-Host $lang.ConfirmMsg -ForegroundColor Yellow
$confirmation = Read-Host

if ($confirmation -ne $lang.ConfirmCode) {
    Write-Host "`n[!] $($lang.Skip)" -ForegroundColor Red
    pause
    exit 1
}

# ===================== 权限检查 =====================
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "`n[!] $($lang.NoAdmin)" -ForegroundColor Red
    Write-Host "[!] $($lang.AdminTip)" -ForegroundColor Yellow
    pause
    exit 1
}

# ===================== 配置 =====================
$ToolDir = "$env:USERPROFILE\Desktop\QFYN_Tools"
$LogFile = "$ToolDir\install.log"
$MarkdownFile = "$ToolDir\Tool_List.md"
$StartTime = Get-Date

if (-not (Test-Path $ToolDir)) {
    New-Item -ItemType Directory -Path $ToolDir -Force | Out-Null
    Write-Host "[+] $($lang.CreateDir) $ToolDir" -ForegroundColor Green
}

# ===================== 120种工具完整列表 =====================
$tools = @(
    # 信息收集类 (1-15)
    @{Name="Nmap"; Category="信息收集"; WingetId="Insecure.Nmap"; Cmd="nmap"},
    @{Name="Maltego"; Category="信息收集"; WingetId=""; Cmd="maltego"},
    @{Name="Shodan CLI"; Category="信息收集"; WingetId=""; Cmd="shodan"},
    @{Name="Recon-ng"; Category="信息收集"; WingetId=""; Cmd="recon-ng"},
    @{Name="theHarvester"; Category="信息收集"; WingetId=""; Cmd="theharvester"},
    @{Name="Amass"; Category="信息收集"; WingetId="OWASP.Amass"; Cmd="amass"},
    @{Name="Masscan"; Category="信息收集"; WingetId=""; Cmd="masscan"},
    @{Name="Zmap"; Category="信息收集"; WingetId=""; Cmd="zmap"},
    @{Name="Sublist3r"; Category="信息收集"; WingetId=""; Cmd="sublist3r"},
    @{Name="Dnsrecon"; Category="信息收集"; WingetId=""; Cmd="dnsrecon"},
    @{Name="Netdiscover"; Category="信息收集"; WingetId=""; Cmd="netdiscover"},
    @{Name="Fierce"; Category="信息收集"; WingetId=""; Cmd="fierce"},
    @{Name="WhatWeb"; Category="信息收集"; WingetId=""; Cmd="whatweb"},
    @{Name="Wappalyzer"; Category="信息收集"; WingetId=""; Cmd="wappalyzer"},
    @{Name="BuiltWith"; Category="信息收集"; WingetId=""; Cmd="builtwith"},
    # 漏洞扫描类 (16-30)
    @{Name="Nessus"; Category="漏洞扫描"; WingetId=""; Cmd="nessus"},
    @{Name="OpenVAS"; Category="漏洞扫描"; WingetId=""; Cmd="openvas"},
    @{Name="Nexpose"; Category="漏洞扫描"; WingetId=""; Cmd="nexpose"},
    @{Name="Nikto"; Category="漏洞扫描"; WingetId=""; Cmd="nikto"},
    @{Name="WPScan"; Category="漏洞扫描"; WingetId=""; Cmd="wpscan"},
    @{Name="Joomscan"; Category="漏洞扫描"; WingetId=""; Cmd="joomscan"},
    @{Name="CMSmap"; Category="漏洞扫描"; WingetId=""; Cmd="cmsmap"},
    @{Name="Gobuster"; Category="漏洞扫描"; WingetId=""; Cmd="gobuster"},
    @{Name="FFUF"; Category="漏洞扫描"; WingetId=""; Cmd="ffuf"},
    @{Name="Dirb"; Category="漏洞扫描"; WingetId=""; Cmd="dirb"},
    @{Name="Wfuzz"; Category="漏洞扫描"; WingetId=""; Cmd="wfuzz"},
    @{Name="Arachni"; Category="漏洞扫描"; WingetId=""; Cmd="arachni"},
    @{Name="W3af"; Category="漏洞扫描"; WingetId=""; Cmd="w3af"},
    @{Name="VulnScanner"; Category="漏洞扫描"; WingetId=""; Cmd="vulnscanner"},
    @{Name="Droopescan"; Category="漏洞扫描"; WingetId=""; Cmd="droopescan"},
    # Web应用测试类 (31-45)
    @{Name="Burp Suite"; Category="Web测试"; WingetId="PortSwigger.BurpSuite.Community"; Cmd="burpsuite"},
    @{Name="OWASP ZAP"; Category="Web测试"; WingetId="OWASP.ZAP"; Cmd="zap"},
    @{Name="SQLMap"; Category="Web测试"; WingetId=""; Cmd="sqlmap"},
    @{Name="Metasploit"; Category="Web测试"; WingetId="Rapid7.Metasploit"; Cmd="msfconsole"},
    @{Name="BeEF"; Category="Web测试"; WingetId=""; Cmd="beef"},
    @{Name="XSStrike"; Category="Web测试"; WingetId=""; Cmd="xsstrike"},
    @{Name="Commix"; Category="Web测试"; WingetId=""; Cmd="commix"},
    @{Name="NoSQLMap"; Category="Web测试"; WingetId=""; Cmd="nosqlmap"},
    @{Name="XSSer"; Category="Web测试"; WingetId=""; Cmd="xsser"},
    @{Name="JWT Tool"; Category="Web测试"; WingetId=""; Cmd="jwt_tool"},
    @{Name="Postman"; Category="Web测试"; WingetId="Postman.Postman"; Cmd="postman"},
    @{Name="Fiddler"; Category="Web测试"; WingetId="Telerik.Fiddler"; Cmd="fiddler"},
    @{Name="ZAP"; Category="Web测试"; WingetId="OWASP.ZAP"; Cmd="zap"},
    @{Name="Wapiti"; Category="Web测试"; WingetId=""; Cmd="wapiti"},
    @{Name="WPScan"; Category="Web测试"; WingetId=""; Cmd="wpscan"},
    # 无线与密码类 (46-60)
    @{Name="Aircrack-ng"; Category="无线密码"; WingetId=""; Cmd="aircrack-ng"},
    @{Name="Hashcat"; Category="无线密码"; WingetId="Hashcat.Hashcat"; Cmd="hashcat"},
    @{Name="John the Ripper"; Category="无线密码"; WingetId="OpenWall.John"; Cmd="john"},
    @{Name="Hydra"; Category="无线密码"; WingetId=""; Cmd="hydra"},
    @{Name="Medusa"; Category="无线密码"; WingetId=""; Cmd="medusa"},
    @{Name="Ncrack"; Category="无线密码"; WingetId=""; Cmd="ncrack"},
    @{Name="CrackMapExec"; Category="无线密码"; WingetId=""; Cmd="cme"},
    @{Name="Responder"; Category="无线密码"; WingetId=""; Cmd="responder"},
    @{Name="Impacket"; Category="无线密码"; WingetId=""; Cmd="impacket"},
    @{Name="Ophcrack"; Category="无线密码"; WingetId=""; Cmd="ophcrack"},
    @{Name="Kismet"; Category="无线密码"; WingetId=""; Cmd="kismet"},
    @{Name="Reaver"; Category="无线密码"; WingetId=""; Cmd="reaver"},
    @{Name="Wifite"; Category="无线密码"; WingetId=""; Cmd="wifite"},
    @{Name="Patator"; Category="无线密码"; WingetId=""; Cmd="patator"},
    @{Name="Chntpw"; Category="无线密码"; WingetId=""; Cmd="chntpw"},
    # 防御监控类 (61-75)
    @{Name="Wireshark"; Category="防御监控"; WingetId="WiresharkFoundation.Wireshark"; Cmd="wireshark"},
    @{Name="Snort"; Category="防御监控"; WingetId=""; Cmd="snort"},
    @{Name="Suricata"; Category="防御监控"; WingetId=""; Cmd="suricata"},
    @{Name="Zeek"; Category="防御监控"; WingetId=""; Cmd="zeek"},
    @{Name="OSSEC"; Category="防御监控"; WingetId=""; Cmd="ossec"},
    @{Name="ELK Stack"; Category="防御监控"; WingetId=""; Cmd="elastic"},
    @{Name="Graylog"; Category="防御监控"; WingetId=""; Cmd="graylog"},
    @{Name="Splunk"; Category="防御监控"; WingetId=""; Cmd="splunk"},
    @{Name="Ntopng"; Category="防御监控"; WingetId=""; Cmd="ntopng"},
    @{Name="PRTG"; Category="防御监控"; WingetId=""; Cmd="prtg"},
    @{Name="Zabbix"; Category="防御监控"; WingetId=""; Cmd="zabbix"},
    @{Name="Nagios"; Category="防御监控"; WingetId=""; Cmd="nagios"},
    @{Name="Prometheus"; Category="防御监控"; WingetId=""; Cmd="prometheus"},
    @{Name="Grafana"; Category="防御监控"; WingetId="Grafana.Grafana"; Cmd="grafana"},
    @{Name="Security Onion"; Category="防御监控"; WingetId=""; Cmd="so"},
    # 渗透框架类 (76-90)
    @{Name="Metasploit"; Category="渗透框架"; WingetId="Rapid7.Metasploit"; Cmd="msfconsole"},
    @{Name="Cobalt Strike"; Category="渗透框架"; WingetId=""; Cmd="cobaltstrike"},
    @{Name="Empire"; Category="渗透框架"; WingetId=""; Cmd="empire"},
    @{Name="PowerSploit"; Category="渗透框架"; WingetId=""; Cmd="powersploit"},
    @{Name="Mimikatz"; Category="渗透框架"; WingetId=""; Cmd="mimikatz"},
    @{Name="BloodHound"; Category="渗透框架"; WingetId=""; Cmd="bloodhound"},
    @{Name="SharpHound"; Category="渗透框架"; WingetId=""; Cmd="sharphound"},
    @{Name="PoshC2"; Category="渗透框架"; WingetId=""; Cmd="poshc2"},
    @{Name="Covenant"; Category="渗透框架"; WingetId=""; Cmd="covenant"},
    @{Name="Merlin"; Category="渗透框架"; WingetId=""; Cmd="merlin"},
    @{Name="Koadic"; Category="渗透框架"; WingetId=""; Cmd="koadic"},
    @{Name="Pupy"; Category="渗透框架"; WingetId=""; Cmd="pupy"},
    @{Name="Evil-WinRM"; Category="渗透框架"; WingetId=""; Cmd="evil-winrm"},
    @{Name="Seatbelt"; Category="渗透框架"; WingetId=""; Cmd="seatbelt"},
    @{Name="Rubeus"; Category="渗透框架"; WingetId=""; Cmd="rubeus"},
    # 移动逆向类 (91-100)
    @{Name="MobSF"; Category="移动逆向"; WingetId=""; Cmd="mobsf"},
    @{Name="Drozer"; Category="移动逆向"; WingetId=""; Cmd="drozer"},
    @{Name="Android SDK"; Category="移动逆向"; WingetId="Google.AndroidSDK"; Cmd="adb"},
    @{Name="Objection"; Category="移动逆向"; WingetId=""; Cmd="objection"},
    @{Name="Frida"; Category="移动逆向"; WingetId=""; Cmd="frida"},
    @{Name="APKTool"; Category="移动逆向"; WingetId=""; Cmd="apktool"},
    @{Name="Jadx"; Category="移动逆向"; WingetId=""; Cmd="jadx"},
    @{Name="Ghidra"; Category="移动逆向"; WingetId="NationalSecurityAgency.Ghidra"; Cmd="ghidra"},
    @{Name="IDA Pro Free"; Category="移动逆向"; WingetId=""; Cmd="ida"},
    @{Name="x64dbg"; Category="移动逆向"; WingetId="x64dbg.x64dbg"; Cmd="x64dbg"},
    # 云安全类 (101-108)
    @{Name="ScoutSuite"; Category="云安全"; WingetId=""; Cmd="scoutsuite"},
    @{Name="Prowler"; Category="云安全"; WingetId=""; Cmd="prowler"},
    @{Name="CloudSploit"; Category="云安全"; WingetId=""; Cmd="cloudsploit"},
    @{Name="Kube-hunter"; Category="云安全"; WingetId=""; Cmd="kube-hunter"},
    @{Name="Kube-bench"; Category="云安全"; WingetId=""; Cmd="kube-bench"},
    @{Name="Trivy"; Category="云安全"; WingetId="AquaSecurity.Trivy"; Cmd="trivy"},
    @{Name="Clair"; Category="云安全"; WingetId=""; Cmd="clair"},
    @{Name="Docker Bench"; Category="云安全"; WingetId=""; Cmd="docker-bench"},
    # 取证分析类 (109-115)
    @{Name="Volatility"; Category="取证分析"; WingetId=""; Cmd="volatility"},
    @{Name="Rekall"; Category="取证分析"; WingetId=""; Cmd="rekall"},
    @{Name="Autopsy"; Category="取证分析"; WingetId=""; Cmd="autopsy"},
    @{Name="Sleuth Kit"; Category="取证分析"; WingetId=""; Cmd="tsk"},
    @{Name="Foremost"; Category="取证分析"; WingetId=""; Cmd="foremost"},
    @{Name="Binwalk"; Category="取证分析"; WingetId=""; Cmd="binwalk"},
    @{Name="ExifTool"; Category="取证分析"; WingetId="ExifTool.ExifTool"; Cmd="exiftool"},
    # 社会工程类 (116-120)
    @{Name="SET"; Category="社会工程"; WingetId=""; Cmd="setoolkit"},
    @{Name="King Phisher"; Category="社会工程"; WingetId=""; Cmd="kingphisher"},
    @{Name="Gophish"; Category="社会工程"; WingetId=""; Cmd="gophish"},
    @{Name="Evilginx"; Category="社会工程"; WingetId=""; Cmd="evilginx"},
    @{Name="CredSniper"; Category="社会工程"; WingetId=""; Cmd="credsniper"}
)

Write-Host "[+] $($lang.StartInstall -f $tools.Count)" -ForegroundColor Green

# ===================== 安装函数 =====================
$total = $tools.Count
$current = 0

foreach ($tool in $tools) {
    $current++
    $percent = [math]::Round(($current / $total) * 100, 0)
    Write-Progress -Activity $lang.Installing -Status "$($tool.Name) ($current/$total)" -PercentComplete $percent

    Write-Host "[$percent%] $($lang.Installing -f $tool.Name)" -ForegroundColor Cyan

    if ($tool.WingetId) {
        try {
            $installed = winget list --id $tool.WingetId 2>$null | Select-String $tool.WingetId
            if ($installed) {
                Write-Host "  ✓ $($lang.AlreadyInstalled -f $tool.Name)" -ForegroundColor Green
            } else {
                winget install --id $tool.WingetId --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  ✓ $($tool.Name) $($lang.Success.ToLower())" -ForegroundColor Green
                } else {
                    Write-Host "  ⚠ $($lang.ManualInstall -f $tool.Name)" -ForegroundColor Yellow
                }
            }
        } catch {
            Write-Host "  ⚠ $($lang.ManualInstall -f $tool.Name)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ⚠ $($lang.ManualInstall -f $tool.Name)" -ForegroundColor Yellow
    }
    
    "$(Get-Date) - $($tool.Name) - $($tool.Category)" | Out-File -Append $LogFile
}

Write-Progress -Activity $lang.Installing -Completed

# ===================== 配置 PATH =====================
Write-Host "[*] $($lang.ConfigPath)" -ForegroundColor Cyan

$pathsToAdd = @(
    "C:\Program Files\Nmap",
    "C:\Program Files\Wireshark",
    "C:\Program Files\BurpSuite",
    "$env:USERPROFILE\AppData\Local\Programs\Python\Python311\Scripts",
    "$env:USERPROFILE\AppData\Local\Programs\Python\Python311"
)

$currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
foreach ($path in $pathsToAdd) {
    if (Test-Path $path) {
        if ($currentPath -notlike "*$path*") {
            [Environment]::SetEnvironmentVariable("Path", "$currentPath;$path", "Machine")
            Write-Host "  + Added: $path" -ForegroundColor Green
        }
    }
}
Write-Host "[+] $($lang.PathDone)" -ForegroundColor Green

# ===================== 生成 Markdown 清单 =====================
Write-Host "[*] $($lang.ToolList -f $MarkdownFile)" -ForegroundColor Cyan

$md = @"
# QFYN Security Tools - 完整工具清单

> 生成时间: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
> 工具总数: $total  
> 作者: QFYN @~

| # | 工具名称 | 类别 | 快捷命令 |
|---|---------|------|---------|
"@

$i = 1
foreach ($tool in $tools) {
    $md += "| $i | $($tool.Name) | $($tool.Category) | `$($tool.Cmd) |`n"
    $i++
}

$md | Out-File -FilePath $MarkdownFile -Encoding utf8

# ===================== 完成 =====================
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "[+] $($lang.Success)" -ForegroundColor Green
Write-Host "[+] $($lang.LogFile -f $LogFile)" -ForegroundColor Green
Write-Host "[+] $($lang.ToolList -f $MarkdownFile)" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

pause
# ===================== 120种工具完整列表（续）=====================
# 注意：以上脚本已包含全部120种工具，此部分为验证和补充说明

# 验证工具数量
Write-Host "[*] 验证工具列表..." -ForegroundColor Cyan
$validTools = $tools | Where-Object { $_.Name -and $_.Category }
$actualCount = $validTools.Count

if ($actualCount -eq 120) {
    Write-Host "[✓] 工具列表完整: $actualCount 种工具" -ForegroundColor Green
} else {
    Write-Host "[!] 工具列表数量: $actualCount / 120" -ForegroundColor Yellow
}

# ===================== 生成快速启动脚本 =====================
$quickStart = @"
@echo off
title QFYN Security Tools Quick Launch
color 0A
echo ========================================
echo    QFYN Security Tools v4.0
echo    作者: QFYN @~
echo ========================================
echo.
echo 可用命令:
echo   nmap        - 网络扫描
echo   wireshark   - 流量分析
echo   burpsuite   - Web代理
echo   sqlmap      - SQL注入
echo   hashcat     - 密码破解
echo   metasploit  - 渗透框架
echo.
echo 输入命令名称启动工具
echo ========================================
echo.
cmd /k
"@

$quickStartPath = "$ToolDir\QFYN_Quick_Start.bat"
$quickStart | Out-File -FilePath $quickStartPath -Encoding ascii
Write-Host "[+] 快速启动脚本: $quickStartPath" -ForegroundColor Green

# ===================== 生成环境变量配置脚本 =====================
$envScript = @'
# QFYN Security Tools PATH Configuration
$paths = @(
    "C:\Program Files\Nmap",
    "C:\Program Files\Wireshark",
    "C:\Program Files\BurpSuite",
    "C:\Program Files\OWASP\ZAP",
    "C:\Program Files\Metasploit\bin",
    "C:\Program Files\Hashcat",
    "C:\Program Files\John",
    "$env:USERPROFILE\AppData\Local\Programs\Python\Python311\Scripts",
    "$env:USERPROFILE\AppData\Local\Programs\Python\Python311",
    "C:\tools\sqlmap",
    "C:\tools\hydra",
    "C:\tools\aircrack-ng"
)

$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
foreach ($path in $paths) {
    if (Test-Path $path) {
        if ($currentPath -notlike "*$path*") {
            [Environment]::SetEnvironmentVariable("Path", "$currentPath;$path", "User")
            Write-Host "Added: $path" -ForegroundColor Green
        }
    }
}
Write-Host "PATH configuration complete!" -ForegroundColor Green
'@

$envScriptPath = "$ToolDir\QFYN_Configure_PATH.ps1"
$envScript | Out-File -FilePath $envScriptPath -Encoding utf8
Write-Host "[+] PATH配置脚本: $envScriptPath" -ForegroundColor Green

# ===================== 生成卸载脚本 =====================
$uninstallScript = @'
# QFYN Security Tools Uninstaller
Write-Host "QFYN Security Tools Uninstaller" -ForegroundColor Red
Write-Host "此操作将移除所有已安装的工具" -ForegroundColor Yellow
$confirm = Read-Host "确认卸载? (y/N)"

if ($confirm -eq 'y' -or $confirm -eq 'Y') {
    $tools = @(
        "Insecure.Nmap",
        "WiresharkFoundation.Wireshark",
        "PortSwigger.BurpSuite.Community",
        "OWASP.ZAP",
        "Rapid7.Metasploit",
        "Hashcat.Hashcat",
        "OpenWall.John"
    )
    
    foreach ($tool in $tools) {
        Write-Host "卸载: $tool"
        winget uninstall --id $tool --silent 2>$null
    }
    
    Write-Host "卸载完成！" -ForegroundColor Green
} else {
    Write-Host "取消卸载" -ForegroundColor Yellow
}
pause
'@

$uninstallPath = "$ToolDir\QFYN_Uninstall.ps1"
$uninstallScript | Out-File -FilePath $uninstallPath -Encoding utf8
Write-Host "[+] 卸载脚本: $uninstallPath" -ForegroundColor Green

# ===================== 生成使用说明 =====================
$userGuide = @"
# QFYN Security Tools 使用指南

## 快速开始

1. **以管理员身份运行** `QFYN_Security_Tools_Installer.exe`
2. 输入 `I ACCEPT` 接受法律条款
3. 等待自动安装完成

## 手动安装工具

对于没有 winget ID 的工具，请手动下载：

| 工具 | 下载地址 |
|------|---------|
| Maltego | https://www.maltego.com/downloads/ |
| SQLMap | https://github.com/sqlmapproject/sqlmap |
| Hydra | https://github.com/vanhauser-thc/thc-hydra |
| Aircrack-ng | https://www.aircrack-ng.org/downloads.html |
| Nessus | https://www.tenable.com/downloads/nessus |

## 常用命令

### 信息收集
```bash
nmap -sV 192.168.1.1           # 端口扫描
amass enum -d target.com       # 子域名枚举
shodan host 8.8.8.8            # IP信息查询
```powershell
# ===================== 脚本自更新功能 =====================
$scriptVersion = "4.0"
$repoUrl = "https://raw.githubusercontent.com/exchangeq/QFYN/main/SecurityTools_Installer.ps1"

function Check-ForUpdates {
    Write-Host "[*] 检查更新..." -ForegroundColor Cyan
    try {
        $webContent = Invoke-WebRequest -Uri $repoUrl -TimeoutSec 5 -ErrorAction Stop
        if ($webContent.Content -match '\$scriptVersion = "([\d\.]+)"') {
            $latestVersion = $matches[1]
            if ($latestVersion -gt $scriptVersion) {
                Write-Host "[!] 发现新版本 v$latestVersion (当前 v$scriptVersion)" -ForegroundColor Yellow
                $updateConfirm = Read-Host "是否更新脚本? (y/N)"
                if ($updateConfirm -eq 'y' -or $updateConfirm -eq 'Y') {
                    $newPath = "$PSScriptRoot\SecurityTools_Installer_v$latestVersion.ps1"
                    $webContent.Content | Out-File -FilePath $newPath -Encoding utf8
                    Write-Host "[+] 已下载新版本: $newPath" -ForegroundColor Green
                    Write-Host "[*] 请运行新版本脚本" -ForegroundColor Cyan
                    pause
                    exit
                }
            } else {
                Write-Host "[✓] 已是最新版本 v$scriptVersion" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "[!] 无法检查更新: $_" -ForegroundColor Yellow
    }
}

# ===================== 系统兼容性检查 =====================
function Test-SystemCompatibility {
    Write-Host "[*] 检查系统兼容性..." -ForegroundColor Cyan
    
    $osInfo = Get-CimInstance Win32_OperatingSystem
    $osVersion = [Version]$osInfo.Version
    $isWindows10OrLater = $osVersion.Major -ge 10
    
    if (-not $isWindows10OrLater) {
        Write-Host "[!] 警告: 此脚本需要 Windows 10 或更高版本" -ForegroundColor Yellow
        Write-Host "    当前系统: $($osInfo.Caption)" -ForegroundColor Yellow
    } else {
        Write-Host "[✓] 系统版本: $($osInfo.Caption)" -ForegroundColor Green
    }
    
    $freeSpace = (Get-PSDrive C).Free / 1GB
    if ($freeSpace -lt 10) {
        Write-Host "[!] 警告: C盘剩余空间不足10GB，建议至少20GB" -ForegroundColor Yellow
        Write-Host "    当前剩余: $([math]::Round($freeSpace, 2)) GB" -ForegroundColor Yellow
    } else {
        Write-Host "[✓] 磁盘空间: $([math]::Round($freeSpace, 2)) GB 可用" -ForegroundColor Green
    }
    
    $totalMemory = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB
    if ($totalMemory -lt 4) {
        Write-Host "[!] 警告: 内存不足4GB，建议8GB以上" -ForegroundColor Yellow
        Write-Host "    当前内存: $([math]::Round($totalMemory, 2)) GB" -ForegroundColor Yellow
    } else {
        Write-Host "[✓] 内存: $([math]::Round($totalMemory, 2)) GB" -ForegroundColor Green
    }
}

# ===================== 网络连接测试 =====================
function Test-NetworkConnectivity {
    Write-Host "[*] 测试网络连接..." -ForegroundColor Cyan
    
    $testUrls = @(
        "https://github.com",
        "https://raw.githubusercontent.com",
        "https://api.github.com"
    )
    
    $workingUrls = @()
    foreach ($url in $testUrls) {
        try {
            $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Write-Host "  ✓ $url" -ForegroundColor Green
                $workingUrls += $url
            }
        } catch {
            Write-Host "  ✗ $url - 连接失败" -ForegroundColor Red
        }
    }
    
    if ($workingUrls.Count -eq 0) {
        Write-Host "[!] 错误: 无法连接到互联网，请检查网络设置" -ForegroundColor Red
        pause
        exit 1
    }
    
    # 检查 winget 可用性
    $wingetAvailable = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetAvailable) {
        Write-Host "[✓] winget 可用" -ForegroundColor Green
    } else {
        Write-Host "[!] winget 不可用，部分工具需要手动安装" -ForegroundColor Yellow
        Write-Host "    建议从 Microsoft Store 安装'应用安装程序'" -ForegroundColor Yellow
    }
}

# ===================== 备份现有配置 =====================
function Backup-ExistingConfig {
    $backupDir = "$ToolDir\backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    
    if (Test-Path $ToolDir) {
        Write-Host "[*] 备份现有配置..." -ForegroundColor Cyan
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        
        $filesToBackup = @("install.log", "Tool_List.md", "QFYN_Configure_PATH.ps1")
        foreach ($file in $filesToBackup) {
            $source = Join-Path $ToolDir $file
            if (Test-Path $source) {
                Copy-Item $source -Destination $backupDir -Force
                Write-Host "  + 备份: $file" -ForegroundColor Green
            }
        }
        Write-Host "[+] 备份完成: $backupDir" -ForegroundColor Green
    }
}

# ===================== 并行下载优化 =====================
function Install-ToolsParallel {
    param(
        [array]$ToolList,
        [int]$MaxParallel = 5
    )
    
    Write-Host "[*] 使用并行安装模式 (最多 $MaxParallel 个并发)" -ForegroundColor Cyan
    
    $scriptBlock = {
        param($tool)
        
        $lang = $using:lang
        $toolName = $tool.Name
        $wingetId = $tool.WingetId
        
        if ($wingetId) {
            try {
                $result = winget install --id $wingetId --silent --accept-package-agreements --accept-source-agreements 2>&1
                if ($LASTEXITCODE -eq 0) {
                    return @{Name=$toolName; Status="Success"; Message="$toolName 安装成功"}
                } else {
                    return @{Name=$toolName; Status="Manual"; Message="需要手动安装: $toolName"}
                }
            } catch {
                return @{Name=$toolName; Status="Manual"; Message="需要手动安装: $toolName"}
            }
        } else {
            return @{Name=$toolName; Status="Manual"; Message="需要手动安装: $toolName"}
        }
    }
    
    $results = @()
    $queue = [System.Collections.Queue]::new($ToolList)
    $running = @{}
    $completed = 0
    $total = $ToolList.Count
    
    while ($completed -lt $total) {
        # 启动新任务
        while ($running.Count -lt $MaxParallel -and $queue.Count -gt 0) {
            $tool = $queue.Dequeue()
            $job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $tool
            $running[$job.Id] = @{Job=$job; Tool=$tool.Name}
            Write-Host "[$($completed+1)/$total] 开始安装: $($tool.Name)" -ForegroundColor Cyan
        }
        
        # 检查完成的任务
        $completedJobs = Get-Job | Where-Object { $_.State -eq 'Completed' }
        foreach ($job in $completedJobs) {
            $result = Receive-Job $job
            $results += $result
            Remove-Job $job
            $running.Remove($job.Id)
            $completed++
            
            if ($result.Status -eq "Success") {
                Write-Host "  ✓ $($result.Message)" -ForegroundColor Green
            } else {
                Write-Host "  ⚠ $($result.Message)" -ForegroundColor Yellow
            }
        }
        
        Start-Sleep -Milliseconds 500
    }
    
    return $results
}

# ===================== 生成快捷方式 =====================
function Create-Shortcuts {
    param([string]$DesktopPath = [Environment]::GetFolderPath("Desktop"))
    
    Write-Host "[*] 创建桌面快捷方式..." -ForegroundColor Cyan
    
    $shortcuts = @(
        @{Name="QFYN Quick Start"; Target="$ToolDir\QFYN_Quick_Start.bat"; Icon=""},
        @{Name="QFYN Tool List"; Target="$MarkdownFile"; Icon=""},
        @{Name="QFYN User Guide"; Target="$guidePath"; Icon=""}
    )
    
    $wshShell = New-Object -ComObject WScript.Shell
    
    foreach ($shortcut in $shortcuts) {
        $shortcutPath = Join-Path $DesktopPath "$($shortcut.Name).lnk"
        if (-not (Test-Path $shortcutPath)) {
            $link = $wshShell.CreateShortcut($shortcutPath)
            $link.TargetPath = $shortcut.Target
            $link.Save()
            Write-Host "  + 创建: $($shortcut.Name).lnk" -ForegroundColor Green
        }
    }
}

# ===================== 生成 JSON 配置文件 =====================
$configJson = @{
    version = $scriptVersion
    installDate = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    installPath = $ToolDir
    tools = $tools | Select-Object Name, Category, WingetId, Cmd
    language = $Language
    timezone = (Get-TimeZone).Id
} | ConvertTo-Json -Depth 3

$configPath = "$ToolDir\QFYN_Config.json"
$configJson | Out-File -FilePath $configPath -Encoding utf8
Write-Host "[+] 配置文件: $configPath" -ForegroundColor Green

# ===================== 生成 PowerShell 配置文件 =====================
$profileContent = @"
# QFYN Security Tools Profile
# 自动添加于 $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

# 添加工具路径到 PATH
`$qfynPaths = @(
    "C:\Program Files\Nmap",
    "C:\Program Files\Wireshark",
    "C:\Program Files\BurpSuite",
    "$ToolDir"
)

foreach (`$path in `$qfynPaths) {
    if (Test-Path `$path -and `$env:PATH -notlike "*`$path*") {
        `$env:PATH += ";`$path"
    }
}

# 自定义函数
function Start-QFYNMenu {
    Write-Host "QFYN Security Tools Menu" -ForegroundColor Cyan
    Write-Host "1. Nmap Scan" -ForegroundColor Yellow
    Write-Host "2. Wireshark" -ForegroundColor Yellow
    Write-Host "3. Burp Suite" -ForegroundColor Yellow
    Write-Host "4. SQLMap" -ForegroundColor Yellow
    Write-Host "5. Hashcat" -ForegroundColor Yellow
    Write-Host "6. Quick Start Menu" -ForegroundColor Yellow
    Write-Host "0. Exit" -ForegroundColor Red
    `$choice = Read-Host "选择"
    switch (`$choice) {
        "1" { nmap }
        "2" { wireshark }
        "3" { burpsuite }
        "4" { sqlmap }
        "5" { hashcat }
        "6" { & "$ToolDir\QFYN_Quick_Start.bat" }
        "0" { return }
    }
}

Write-Host "QFYN Security Tools loaded!" -ForegroundColor Green
Write-Host "Type 'Start-QFYNMenu' to open the menu" -ForegroundColor Cyan
"@

$profilePath = [System.IO.Path]::Combine($env:USERPROFILE, "Documents", "WindowsPowerShell", "Microsoft.PowerShell_profile.ps1")
$profileDir = Split-Path $profilePath -Parent
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

if (Test-Path $profilePath) {
    $existingContent = Get-Content $profilePath -Raw
    if ($existingContent -notlike "*QFYN Security Tools*") {
        Add-Content -Path $profilePath -Value "`n$profileContent"
        Write-Host "[+] 已添加到 PowerShell 配置文件" -ForegroundColor Green
    }
} else {
    $profileContent | Out-File -FilePath $profilePath -Encoding utf8
    Write-Host "[+] 创建 PowerShell 配置文件" -ForegroundColor Green
}

# ===================== 执行主流程 =====================
# 检查更新（可选，注释掉以加快速度）
# Check-ForUpdates

# 系统兼容性检查
Test-SystemCompatibility

# 网络连接测试
Test-NetworkConnectivity

# 备份现有配置
Backup-ExistingConfig

# 显示安装信息
Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  QFYN Security Tools v$scriptVersion" -ForegroundColor Magenta
Write-Host "  作者: QFYN @~" -ForegroundColor Magenta
Write-Host "  语言: $(if ($Language -eq 'CN') { '中文' } else { 'English' })" -ForegroundColor Magenta
Write-Host "  时区: $(Get-TimeZone).DisplayName" -ForegroundColor Magenta
Write-Host "  工具总数: $($tools.Count)" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta

Write-Host "`n[*] 开始安装 $($tools.Count) 个工具..." -ForegroundColor Cyan
Write-Host "[*] 预计时间: 15-30 分钟 (取决于网速)" -ForegroundColor Cyan
Write-Host ""

# 选择安装模式
Write-Host "选择安装模式:" -ForegroundColor Yellow
Write-Host "  1. 串行安装 (稳定，适合网络较差)" -ForegroundColor White
Write-Host "  2. 并行安装 (快速，需要稳定网络)" -ForegroundColor White
$modeChoice = Read-Host "请选择 (1/2，默认1)"

if ($modeChoice -eq "2") {
    # 并行安装
    $wingetTools = $tools | Where-Object { $_.WingetId } | Select-Object -First 50
    $results = Install-ToolsParallel -ToolList $wingetTools -MaxParallel 5
} else {
    # 串行安装（原有逻辑）
    $total = $tools.Count
    $current = 0
    
    foreach ($tool in $tools) {
        $current++
        $percent = [math]::Round(($current / $total) * 100, 0)
        Write-Progress -Activity $lang.Installing -Status "$($tool.Name) ($current/$total)" -PercentComplete $percent
        
        Write-Host "[$percent%] $($lang.Installing -f $tool.Name)" -ForegroundColor Cyan
        
        if ($tool.WingetId) {
            try {
                $installed = winget list --id $tool.WingetId 2>$null | Select-String $tool.WingetId
                if ($installed) {
                    Write-Host "  ✓ $($lang.AlreadyInstalled -f $tool.Name)" -ForegroundColor Green
                } else {
                    winget install --id $tool.WingetId --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "  ✓ $($tool.Name) $($lang.Success.ToLower())" -ForegroundColor Green
                    } else {
                        Write-Host "  ⚠ $($lang.ManualInstall -f $tool.Name)" -ForegroundColor Yellow
                    }
                }
            } catch {
                Write-Host "  ⚠ $($lang.ManualInstall -f $tool.Name)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  ⚠ $($lang.ManualInstall -f $tool.Name)" -ForegroundColor Yellow
        }
        
        "$(Get-Date) - $($tool.Name) - $($tool.Category)" | Out-File -Append $LogFile
    }
    
    Write-Progress -Activity $lang.Installing -Completed
}

# ===================== 配置 PATH =====================
Write-Host "[*] $($lang.ConfigPath)" -ForegroundColor Cyan

$pathsToAdd = @(
    "C:\Program Files\Nmap",
    "C:\Program Files\Wireshark",
    "C:\Program Files\BurpSuite",
    "C:\Program Files\OWASP\ZAP",
    "C:\Program Files\Metasploit\bin",
    "C:\Program Files\Hashcat",
    "C:\Program Files\John",
    "$env:USERPROFILE\AppData\Local\Programs\Python\Python311\Scripts",
    "$env:USERPROFILE\AppData\Local\Programs\Python\Python311",
    "$env:USERPROFILE\AppData\Local\Microsoft\WindowsApps",
    "$ToolDir"
)

$currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
foreach ($path in $pathsToAdd) {
    if (Test-Path $path) {
        if ($currentPath -notlike "*$path*") {
            [Environment]::SetEnvironmentVariable("Path", "$currentPath;$path", "Machine")
            Write-Host "  + Added: $path" -ForegroundColor Green
        }
    }
}
Write-Host "[+] $($lang.PathDone)" -ForegroundColor Green

# ===================== 生成所有辅助文件 =====================
# 这些函数已在前面定义，此处调用
Create-Shortcuts

# 打开安装目录
Write-Host "[*] 打开安装目录..." -ForegroundColor Cyan
Start-Process explorer.exe $ToolDir

# ===================== 完成 =====================
$endTime = Get-Date
$duration = $endTime - $StartTime

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "[+] $($lang.Success)" -ForegroundColor Green
Write-Host "[+] 安装用时: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor Green
Write-Host "[+] 安装目录: $ToolDir" -ForegroundColor Green
Write-Host "[+] 日志文件: $LogFile" -ForegroundColor Green
Write-Host "[+] 工具清单: $MarkdownFile" -ForegroundColor Green
Write-Host "[+] 快速启动: $quickStartPath" -ForegroundColor Green
Write-Host "[+] 配置文件: $configPath" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# 提示重启 PowerShell
Write-Host "`n[*] 提示: 请重启 PowerShell 或运行以下命令使 PATH 生效:" -ForegroundColor Yellow
Write-Host "    `$env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')" -ForegroundColor White

# 等待用户按任意键退出
Write-Host "`n按任意键退出..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
# ===================== 脚本自更新功能 =====================
$scriptVersion = "4.0"
$repoUrl = "https://raw.githubusercontent.com/exchangeq/QFYN/main/SecurityTools_Installer.ps1"

function Check-ForUpdates {
    Write-Host "[*] 检查更新..." -ForegroundColor Cyan
    try {
        $webContent = Invoke-WebRequest -Uri $repoUrl -TimeoutSec 5 -ErrorAction Stop
        if ($webContent.Content -match '\$scriptVersion = "([\d\.]+)"') {
            $latestVersion = $matches[1]
            if ($latestVersion -gt $scriptVersion) {
                Write-Host "[!] 发现新版本 v$latestVersion (当前 v$scriptVersion)" -ForegroundColor Yellow
                $updateConfirm = Read-Host "是否更新脚本? (y/N)"
                if ($updateConfirm -eq 'y' -or $updateConfirm -eq 'Y') {
                    $newPath = "$PSScriptRoot\SecurityTools_Installer_v$latestVersion.ps1"
                    $webContent.Content | Out-File -FilePath $newPath -Encoding utf8
                    Write-Host "[+] 已下载新版本: $newPath" -ForegroundColor Green
                    Write-Host "[*] 请运行新版本脚本" -ForegroundColor Cyan
                    pause
                    exit
                }
            } else {
                Write-Host "[✓] 已是最新版本 v$scriptVersion" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "[!] 无法检查更新: $_" -ForegroundColor Yellow
    }
}

# ===================== 系统兼容性检查 =====================
function Test-SystemCompatibility {
    Write-Host "[*] 检查系统兼容性..." -ForegroundColor Cyan
    
    $osInfo = Get-CimInstance Win32_OperatingSystem
    $osVersion = [Version]$osInfo.Version
    $isWindows10OrLater = $osVersion.Major -ge 10
    
    if (-not $isWindows10OrLater) {
        Write-Host "[!] 警告: 此脚本需要 Windows 10 或更高版本" -ForegroundColor Yellow
        Write-Host "    当前系统: $($osInfo.Caption)" -ForegroundColor Yellow
    } else {
        Write-Host "[✓] 系统版本: $($osInfo.Caption)" -ForegroundColor Green
    }
    
    $freeSpace = (Get-PSDrive C).Free / 1GB
    if ($freeSpace -lt 10) {
        Write-Host "[!] 警告: C盘剩余空间不足10GB，建议至少20GB" -ForegroundColor Yellow
        Write-Host "    当前剩余: $([math]::Round($freeSpace, 2)) GB" -ForegroundColor Yellow
    } else {
        Write-Host "[✓] 磁盘空间: $([math]::Round($freeSpace, 2)) GB 可用" -ForegroundColor Green
    }
    
    $totalMemory = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB
    if ($totalMemory -lt 4) {
        Write-Host "[!] 警告: 内存不足4GB，建议8GB以上" -ForegroundColor Yellow
        Write-Host "    当前内存: $([math]::Round($totalMemory, 2)) GB" -ForegroundColor Yellow
    } else {
        Write-Host "[✓] 内存: $([math]::Round($totalMemory, 2)) GB" -ForegroundColor Green
    }
}

# ===================== 网络连接测试 =====================
function Test-NetworkConnectivity {
    Write-Host "[*] 测试网络连接..." -ForegroundColor Cyan
    
    $testUrls = @(
        "https://github.com",
        "https://raw.githubusercontent.com",
        "https://api.github.com"
    )
    
    $workingUrls = @()
    foreach ($url in $testUrls) {
        try {
            $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Write-Host "  ✓ $url" -ForegroundColor Green
                $workingUrls += $url
            }
        } catch {
            Write-Host "  ✗ $url - 连接失败" -ForegroundColor Red
        }
    }
    
    if ($workingUrls.Count -eq 0) {
        Write-Host "[!] 错误: 无法连接到互联网，请检查网络设置" -ForegroundColor Red
        pause
        exit 1
    }
    
    # 检查 winget 可用性
    $wingetAvailable = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetAvailable) {
        Write-Host "[✓] winget 可用" -ForegroundColor Green
    } else {
        Write-Host "[!] winget 不可用，部分工具需要手动安装" -ForegroundColor Yellow
        Write-Host "    建议从 Microsoft Store 安装'应用安装程序'" -ForegroundColor Yellow
    }
}

# ===================== 备份现有配置 =====================
function Backup-ExistingConfig {
    $backupDir = "$ToolDir\backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    
    if (Test-Path $ToolDir) {
        Write-Host "[*] 备份现有配置..." -ForegroundColor Cyan
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        
        $filesToBackup = @("install.log", "Tool_List.md", "QFYN_Configure_PATH.ps1")
        foreach ($file in $filesToBackup) {
            $source = Join-Path $ToolDir $file
            if (Test-Path $source) {
                Copy-Item $source -Destination $backupDir -Force
                Write-Host "  + 备份: $file" -ForegroundColor Green
            }
        }
        Write-Host "[+] 备份完成: $backupDir" -ForegroundColor Green
    }
}

# ===================== 并行下载优化 =====================
function Install-ToolsParallel {
    param(
        [array]$ToolList,
        [int]$MaxParallel = 5
    )
    
    Write-Host "[*] 使用并行安装模式 (最多 $MaxParallel 个并发)" -ForegroundColor Cyan
    
    $scriptBlock = {
        param($tool)
        
        $lang = $using:lang
        $toolName = $tool.Name
        $wingetId = $tool.WingetId
        
        if ($wingetId) {
            try {
                $result = winget install --id $wingetId --silent --accept-package-agreements --accept-source-agreements 2>&1
                if ($LASTEXITCODE -eq 0) {
                    return @{Name=$toolName; Status="Success"; Message="$toolName 安装成功"}
                } else {
                    return @{Name=$toolName; Status="Manual"; Message="需要手动安装: $toolName"}
                }
            } catch {
                return @{Name=$toolName; Status="Manual"; Message="需要手动安装: $toolName"}
            }
        } else {
            return @{Name=$toolName; Status="Manual"; Message="需要手动安装: $toolName"}
        }
    }
    
    $results = @()
    $queue = [System.Collections.Queue]::new($ToolList)
    $running = @{}
    $completed = 0
    $total = $ToolList.Count
    
    while ($completed -lt $total) {
        # 启动新任务
        while ($running.Count -lt $MaxParallel -and $queue.Count -gt 0) {
            $tool = $queue.Dequeue()
            $job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $tool
            $running[$job.Id] = @{Job=$job; Tool=$tool.Name}
            Write-Host "[$($completed+1)/$total] 开始安装: $($tool.Name)" -ForegroundColor Cyan
        }
        
        # 检查完成的任务
        $completedJobs = Get-Job | Where-Object { $_.State -eq 'Completed' }
        foreach ($job in $completedJobs) {
            $result = Receive-Job $job
            $results += $result
            Remove-Job $job
            $running.Remove($job.Id)
            $completed++
            
            if ($result.Status -eq "Success") {
                Write-Host "  ✓ $($result.Message)" -ForegroundColor Green
            } else {
                Write-Host "  ⚠ $($result.Message)" -ForegroundColor Yellow
            }
        }
        
        Start-Sleep -Milliseconds 500
    }
    
    return $results
}

# ===================== 生成快捷方式 =====================
function Create-Shortcuts {
    param([string]$DesktopPath = [Environment]::GetFolderPath("Desktop"))
    
    Write-Host "[*] 创建桌面快捷方式..." -ForegroundColor Cyan
    
    $shortcuts = @(
        @{Name="QFYN Quick Start"; Target="$ToolDir\QFYN_Quick_Start.bat"; Icon=""},
        @{Name="QFYN Tool List"; Target="$MarkdownFile"; Icon=""},
        @{Name="QFYN User Guide"; Target="$guidePath"; Icon=""}
    )
    
    $wshShell = New-Object -ComObject WScript.Shell
    
    foreach ($shortcut in $shortcuts) {
        $shortcutPath = Join-Path $DesktopPath "$($shortcut.Name).lnk"
        if (-not (Test-Path $shortcutPath)) {
            $link = $wshShell.CreateShortcut($shortcutPath)
            $link.TargetPath = $shortcut.Target
            $link.Save()
            Write-Host "  + 创建: $($shortcut.Name).lnk" -ForegroundColor Green
        }
    }
}

# ===================== 生成 JSON 配置文件 =====================
$configJson = @{
    version = $scriptVersion
    installDate = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    installPath = $ToolDir
    tools = $tools | Select-Object Name, Category, WingetId, Cmd
    language = $Language
    timezone = (Get-TimeZone).Id
} | ConvertTo-Json -Depth 3

$configPath = "$ToolDir\QFYN_Config.json"
$configJson | Out-File -FilePath $configPath -Encoding utf8
Write-Host "[+] 配置文件: $configPath" -ForegroundColor Green

# ===================== 生成 PowerShell 配置文件 =====================
$profileContent = @"
# QFYN Security Tools Profile
# 自动添加于 $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

# 添加工具路径到 PATH
`$qfynPaths = @(
    "C:\Program Files\Nmap",
    "C:\Program Files\Wireshark",
    "C:\Program Files\BurpSuite",
    "$ToolDir"
)

foreach (`$path in `$qfynPaths) {
    if (Test-Path `$path -and `$env:PATH -notlike "*`$path*") {
        `$env:PATH += ";`$path"
    }
}

# 自定义函数
function Start-QFYNMenu {
    Write-Host "QFYN Security Tools Menu" -ForegroundColor Cyan
    Write-Host "1. Nmap Scan" -ForegroundColor Yellow
    Write-Host "2. Wireshark" -ForegroundColor Yellow
    Write-Host "3. Burp Suite" -ForegroundColor Yellow
    Write-Host "4. SQLMap" -ForegroundColor Yellow
    Write-Host "5. Hashcat" -ForegroundColor Yellow
    Write-Host "6. Quick Start Menu" -ForegroundColor Yellow
    Write-Host "0. Exit" -ForegroundColor Red
    `$choice = Read-Host "选择"
    switch (`$choice) {
        "1" { nmap }
        "2" { wireshark }
        "3" { burpsuite }
        "4" { sqlmap }
        "5" { hashcat }
        "6" { & "$ToolDir\QFYN_Quick_Start.bat" }
        "0" { return }
    }
}

Write-Host "QFYN Security Tools loaded!" -ForegroundColor Green
Write-Host "Type 'Start-QFYNMenu' to open the menu" -ForegroundColor Cyan
"@

$profilePath = [System.IO.Path]::Combine($env:USERPROFILE, "Documents", "WindowsPowerShell", "Microsoft.PowerShell_profile.ps1")
$profileDir = Split-Path $profilePath -Parent
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

if (Test-Path $profilePath) {
    $existingContent = Get-Content $profilePath -Raw
    if ($existingContent -notlike "*QFYN Security Tools*") {
        Add-Content -Path $profilePath -Value "`n$profileContent"
        Write-Host "[+] 已添加到 PowerShell 配置文件" -ForegroundColor Green
    }
} else {
    $profileContent | Out-File -FilePath $profilePath -Encoding utf8
    Write-Host "[+] 创建 PowerShell 配置文件" -ForegroundColor Green
}

# ===================== 执行主流程 =====================
# 检查更新（可选，注释掉以加快速度）
# Check-ForUpdates

# 系统兼容性检查
Test-SystemCompatibility

# 网络连接测试
Test-NetworkConnectivity

# 备份现有配置
Backup-ExistingConfig

# 显示安装信息
Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  QFYN Security Tools v$scriptVersion" -ForegroundColor Magenta
Write-Host "  作者: QFYN @~" -ForegroundColor Magenta
Write-Host "  语言: $(if ($Language -eq 'CN') { '中文' } else { 'English' })" -ForegroundColor Magenta
Write-Host "  时区: $(Get-TimeZone).DisplayName" -ForegroundColor Magenta
Write-Host "  工具总数: $($tools.Count)" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta

Write-Host "`n[*] 开始安装 $($tools.Count) 个工具..." -ForegroundColor Cyan
Write-Host "[*] 预计时间: 15-30 分钟 (取决于网速)" -ForegroundColor Cyan
Write-Host ""

# 选择安装模式
Write-Host "选择安装模式:" -ForegroundColor Yellow
Write-Host "  1. 串行安装 (稳定，适合网络较差)" -ForegroundColor White
Write-Host "  2. 并行安装 (快速，需要稳定网络)" -ForegroundColor White
$modeChoice = Read-Host "请选择 (1/2，默认1)"

if ($modeChoice -eq "2") {
    # 并行安装
    $wingetTools = $tools | Where-Object { $_.WingetId } | Select-Object -First 50
    $results = Install-ToolsParallel -ToolList $wingetTools -MaxParallel 5
} else {
    # 串行安装（原有逻辑）
    $total = $tools.Count
    $current = 0
    
    foreach ($tool in $tools) {
        $current++
        $percent = [math]::Round(($current / $total) * 100, 0)
        Write-Progress -Activity $lang.Installing -Status "$($tool.Name) ($current/$total)" -PercentComplete $percent
        
        Write-Host "[$percent%] $($lang.Installing -f $tool.Name)" -ForegroundColor Cyan
        
        if ($tool.WingetId) {
            try {
                $installed = winget list --id $tool.WingetId 2>$null | Select-String $tool.WingetId
                if ($installed) {
                    Write-Host "  ✓ $($lang.AlreadyInstalled -f $tool.Name)" -ForegroundColor Green
                } else {
                    winget install --id $tool.WingetId --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "  ✓ $($tool.Name) $($lang.Success.ToLower())" -ForegroundColor Green
                    } else {
                        Write-Host "  ⚠ $($lang.ManualInstall -f $tool.Name)" -ForegroundColor Yellow
                    }
                }
            } catch {
                Write-Host "  ⚠ $($lang.ManualInstall -f $tool.Name)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  ⚠ $($lang.ManualInstall -f $tool.Name)" -ForegroundColor Yellow
        }
        
        "$(Get-Date) - $($tool.Name) - $($tool.Category)" | Out-File -Append $LogFile
    }
    
    Write-Progress -Activity $lang.Installing -Completed
}

# ===================== 配置 PATH =====================
Write-Host "[*] $($lang.ConfigPath)" -ForegroundColor Cyan

$pathsToAdd = @(
    "C:\Program Files\Nmap",
    "C:\Program Files\Wireshark",
    "C:\Program Files\BurpSuite",
    "C:\Program Files\OWASP\ZAP",
    "C:\Program Files\Metasploit\bin",
    "C:\Program Files\Hashcat",
    "C:\Program Files\John",
    "$env:USERPROFILE\AppData\Local\Programs\Python\Python311\Scripts",
    "$env:USERPROFILE\AppData\Local\Programs\Python\Python311",
    "$env:USERPROFILE\AppData\Local\Microsoft\WindowsApps",
    "$ToolDir"
)

$currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
foreach ($path in $pathsToAdd) {
    if (Test-Path $path) {
        if ($currentPath -notlike "*$path*") {
            [Environment]::SetEnvironmentVariable("Path", "$currentPath;$path", "Machine")
            Write-Host "  + Added: $path" -ForegroundColor Green
        }
    }
}
Write-Host "[+] $($lang.PathDone)" -ForegroundColor Green

# ===================== 生成所有辅助文件 =====================
# 这些函数已在前面定义，此处调用
Create-Shortcuts

# 打开安装目录
Write-Host "[*] 打开安装目录..." -ForegroundColor Cyan
Start-Process explorer.exe $ToolDir

# ===================== 完成 =====================
$endTime = Get-Date
$duration = $endTime - $StartTime

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "[+] $($lang.Success)" -ForegroundColor Green
Write-Host "[+] 安装用时: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor Green
Write-Host "[+] 安装目录: $ToolDir" -ForegroundColor Green
Write-Host "[+] 日志文件: $LogFile" -ForegroundColor Green
Write-Host "[+] 工具清单: $MarkdownFile" -ForegroundColor Green
Write-Host "[+] 快速启动: $quickStartPath" -ForegroundColor Green
Write-Host "[+] 配置文件: $configPath" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# 提示重启 PowerShell
Write-Host "`n[*] 提示: 请重启 PowerShell 或运行以下命令使 PATH 生效:" -ForegroundColor Yellow
Write-Host "    `$env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')" -ForegroundColor White

# 等待用户按任意键退出
Write-Host "`n按任意键退出..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
```powershell
# ===================== 工具验证与健康检查 =====================
function Test-ToolHealth {
    Write-Host "[*] 验证已安装工具..." -ForegroundColor Cyan
    
    $healthReport = @()
    $installedCount = 0
    
    foreach ($tool in $tools) {
        if ($tool.WingetId) {
            $cmd = $tool.Cmd
            $checkPath = @()
            
            # 常见安装路径
            $possiblePaths = @(
                "C:\Program Files\$($tool.Name)",
                "C:\Program Files (x86)\$($tool.Name)",
                "$env:USERPROFILE\AppData\Local\Programs\$($tool.Name)",
                "$env:USERPROFILE\AppData\Local\$($tool.Name)"
            )
            
            # 检查命令是否存在
            $cmdExists = Get-Command $cmd -ErrorAction SilentlyContinue
            $pathExists = $possiblePaths | Where-Object { Test-Path $_ } | Select-Object -First 1
            
            if ($cmdExists -or $pathExists) {
                $status = "✓"
                $statusText = "已安装"
                $installedCount++
            } else {
                $status = "⚠"
                $statusText = "未检测到"
            }
            
            $healthReport += [PSCustomObject]@{
                状态 = $status
                工具 = $tool.Name
                类别 = $tool.Category
                状态文本 = $statusText
                命令 = $cmd
            }
        }
    }
    
    # 显示健康报告摘要
    $healthReport | Group-Object 状态文本 | ForEach-Object {
        $color = if ($_.Name -eq "已安装") { "Green" } else { "Yellow" }
        Write-Host "  $($_.Name): $($_.Count) 个工具" -ForegroundColor $color
    }
    
    # 保存详细报告
    $healthReport | Export-Csv -Path "$ToolDir\health_report.csv" -NoTypeInformation -Encoding UTF8
    Write-Host "[+] 健康报告已保存: $ToolDir\health_report.csv" -ForegroundColor Green
    
    return $installedCount
}

# ===================== 生成 Docker 部署脚本 =====================
function Generate-DockerScript {
    $dockerContent = @'
# QFYN Security Tools Dockerfile
# 用于在容器中运行安全工具

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 安装基础工具
RUN apt-get update && apt-get install -y \
    nmap \
    wireshark \
    curl \
    wget \
    git \
    python3 \
    python3-pip \
    hydra \
    john \
    aircrack-ng \
    nikto \
    sqlmap \
    && rm -rf /var/lib/apt/lists/*

# 安装 Python 工具
RUN pip3 install requests beautifulsoup4 scapy shodan

# 创建工作目录
WORKDIR /tools

# 克隆额外工具
RUN git clone https://github.com/sqlmapproject/sqlmap.git && \
    git clone https://github.com/vanhauser-thc/thc-hydra.git && \
    git clone https://github.com/danielmiessler/SecLists.git

# 设置环境变量
ENV PATH="/tools/sqlmap:$PATH"

# 入口点
CMD ["/bin/bash"]
'@

    $dockerPath = "$ToolDir\Dockerfile"
    $dockerContent | Out-File -FilePath $dockerPath -Encoding utf8
    Write-Host "[+] Dockerfile 已生成: $dockerPath" -ForegroundColor Green
    
    $dockerBuildCmd = @"
# 构建 Docker 镜像
docker build -t qfyn-security-tools -f "$ToolDir\Dockerfile" .

# 运行容器
docker run -it --rm qfyn-security-tools
"@
    
    $dockerCmdPath = "$ToolDir\docker_commands.txt"
    $dockerBuildCmd | Out-File -FilePath $dockerCmdPath -Encoding utf8
    Write-Host "[+] Docker 命令: $dockerCmdPath" -ForegroundColor Green
}

# ===================== 生成 WSL 配置脚本 =====================
function Generate-WSLConfig {
    $wslContent = @'
# QFYN Security Tools - WSL 配置脚本
# 在 WSL (Ubuntu) 中运行此脚本安装工具

#!/bin/bash

echo "========================================"
echo "QFYN Security Tools - WSL 安装脚本"
echo "========================================"

# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装基础工具
sudo apt install -y \
    nmap \
    wireshark \
    tshark \
    curl \
    wget \
    git \
    python3 \
    python3-pip \
    hydra \
    john \
    aircrack-ng \
    nikto \
    sqlmap \
    gobuster \
    ffuf \
    whatweb \
    dnsrecon \
    theharvester \
    metasploit-framework

# 安装 Python 工具
pip3 install requests beautifulsoup4 scapy shodan

# 克隆工具仓库
cd ~
git clone https://github.com/sqlmapproject/sqlmap.git
git clone https://github.com/vanhauser-thc/thc-hydra.git
git clone https://github.com/danielmiessler/SecLists.git
git clone https://github.com/rebootuser/LinEnum.git
git clone https://github.com/carlospolop/PEASS-ng.git

# 配置 PATH
echo 'export PATH="$PATH:~/sqlmap"' >> ~/.bashrc

echo "========================================"
echo "安装完成！请重启终端"
echo "========================================"
'@

    $wslPath = "$ToolDir\wsl_install.sh"
    $wslContent | Out-File -FilePath $wslPath -Encoding utf8
    Write-Host "[+] WSL 安装脚本: $wslPath" -ForegroundColor Green
}

# ===================== 生成 PowerShell 别名配置文件 =====================
function Generate-PSAlias {
    $aliasContent = @"
# QFYN Security Tools - PowerShell 别名
# 添加到您的 PowerShell profile 以启用快捷命令

# 信息收集别名
Set-Alias -Name nmap -Value "C:\Program Files\Nmap\nmap.exe" -ErrorAction SilentlyContinue
Set-Alias -Name amass -Value "C:\Program Files\amass\amass.exe" -ErrorAction SilentlyContinue

# Web 测试别名
Set-Alias -Name sqlmap -Value "C:\tools\sqlmap\sqlmap.py" -ErrorAction SilentlyContinue
Set-Alias -Name burp -Value "C:\Program Files\BurpSuite\BurpSuite.exe" -ErrorAction SilentlyContinue

# 密码工具别名
Set-Alias -Name hashcat -Value "C:\Program Files\hashcat\hashcat.exe" -ErrorAction SilentlyContinue
Set-Alias -Name john -Value "C:\Program Files\John\john.exe" -ErrorAction SilentlyContinue

# 网络工具别名
Set-Alias -Name wireshark -Value "C:\Program Files\Wireshark\Wireshark.exe" -ErrorAction SilentlyContinue
Set-Alias -Name tshark -Value "C:\Program Files\Wireshark\tshark.exe" -ErrorAction SilentlyContinue

function qfyn-menu {
    Write-Host "QFYN Security Tools Menu" -ForegroundColor Cyan
    Write-Host "1. Nmap Scan" -ForegroundColor Yellow
    Write-Host "2. Wireshark" -ForegroundColor Yellow
    Write-Host "3. Burp Suite" -ForegroundColor Yellow
    Write-Host "4. SQLMap" -ForegroundColor Yellow
    Write-Host "5. Hashcat" -ForegroundColor Yellow
    Write-Host "6. John the Ripper" -ForegroundColor Yellow
    Write-Host "7. Hydra" -ForegroundColor Yellow
    Write-Host "8. Metasploit" -ForegroundColor Yellow
    Write-Host "0. Exit" -ForegroundColor Red
    
    $choice = Read-Host "选择"
    switch ($choice) {
        "1" { nmap }
        "2" { wireshark }
        "3" { burp }
        "4" { sqlmap }
        "5" { hashcat }
        "6" { john }
        "7" { hydra }
        "8" { msfconsole }
        "0" { return }
    }
}

Write-Host "QFYN Security Tools aliases loaded!" -ForegroundColor Green
Write-Host "Type 'qfyn-menu' to open the menu" -ForegroundColor Cyan
"@

    $aliasPath = "$ToolDir\qfyn_aliases.ps1"
    $aliasContent | Out-File -FilePath $aliasPath -Encoding utf8
    Write-Host "[+] PowerShell 别名脚本: $aliasPath" -ForegroundColor Green
}

# ===================== 生成 README 更新 =====================
function Update-README {
    $readmeContent = @"
# 🔐 QFYN Security Tools

> 一键安装 120+ 网络安全工具 | Windows PowerShell | 开源免费

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)]()
[![Version](https://img.shields.io/badge/version-$scriptVersion-green.svg)]()
[![Tools](https://img.shields.io/badge/tools-120%2B-orange.svg)]()

---

## ⚠️ 法律警告

```

╔══════════════════════════════════════════════════════════════════════════╗
║  本工具仅用于授权的网络安全测试、教育及研究                              ║
║  禁止用于非法入侵·仅限授权环境测试·使用者须自行承担一切法律后果          ║
║  未经授权使用可能违反《网络安全法》，最高可处七年以下有期徒刑           ║
╚══════════════════════════════════════════════════════════════════════════╝

```

---

## 🚀 快速开始

### 下载安装

```powershell
# 方法1: 直接下载脚本
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/exchangeq/QFYN/main/SecurityTools_Installer.ps1" -OutFile "QFYN.ps1"

# 方法2: 克隆仓库
git clone https://github.com/exchangeq/QFYN.git

# 以管理员身份运行 PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\SecurityTools_Installer.ps1
```

使用说明

1. 以管理员身份运行 安装程序
2. 输入 I ACCEPT 接受法律条款
3. 等待自动安装完成（15-30分钟）
4. 重启 PowerShell 使 PATH 生效

---

📦 包含工具（120种）

分类 数量 代表工具
🔍 信息收集 15 Nmap, Maltego, Shodan, Amass
🚨 漏洞扫描 15 Nessus, OpenVAS, Nikto, WPScan
🌐 Web测试 15 Burp Suite, SQLMap, ZAP, Metasploit
🔑 密码破解 15 Hashcat, John, Hydra, Aircrack-ng
🛡️ 防御监控 15 Wireshark, Snort, Suricata, ELK
💣 渗透框架 15 Empire, Mimikatz, BloodHound
📱 移动逆向 10 MobSF, Ghidra, Frida, APKTool
☁️ 云安全 8 Trivy, ScoutSuite, Prowler
🔬 取证分析 7 Volatility, Autopsy, Binwalk
🎭 社会工程 5 SET, Gophish, Evilginx

---

📁 安装后生成的文件

```
QFYN_Tools/
├── Tool_List.md              # 完整工具清单
├── QFYN_Quick_Start.bat      # 快速启动菜单
├── QFYN_Commands.bat         # 命令启动器
├── QFYN_Report.html          # HTML 安装报告
├── QFYN_Config.json          # 配置文件
├── qfyn_aliases.ps1          # PowerShell 别名
├── wsl_install.sh            # WSL 安装脚本
├── Dockerfile                # Docker 部署文件
├── health_report.csv         # 工具健康报告
└── install.log               # 安装日志
```

---

🛠️ 常用命令

```bash
# 信息收集
nmap -sV 192.168.1.1           # 端口扫描
amass enum -d target.com       # 子域名枚举

# Web安全测试
sqlmap -u "http://target.com?id=1"  # SQL注入
burpsuite                              # 启动 Burp Suite

# 密码破解
hashcat -m 0 hash.txt rockyou.txt     # 哈希破解
hydra -l root -P pass.txt ssh://192.168.1.1  # SSH爆破

# 流量分析
wireshark                              # 启动 Wireshark
tshark -i eth0 -w capture.pcap        # 命令行抓包
```

---

🔧 系统要求

项目 要求
操作系统 Windows 10/11 (64位)
权限 管理员权限
内存 建议 8GB+
磁盘 至少 20GB 可用空间
PowerShell 5.1 或更高版本

---

❓ 常见问题

Q: 提示"无法加载脚本"？

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Q: winget 不可用？

从 Microsoft Store 安装"应用安装程序"

Q: 如何更新工具？

```powershell
winget upgrade --all
# 或重新运行安装脚本
```

---

📜 许可证

MIT License - 详见 LICENSE

---

📞 联系方式

· GitHub: exchangeq/QFYN
· 问题反馈: Issues

---

QFYN @~ | Security Tools v$scriptVersion | 开源·免费·安全研究
"@

}

===================== 执行所有功能 =====================

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  生成辅助文件和配置..." -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta

工具健康检查

$installedCount = Test-ToolHealth

生成 Docker 脚本

Generate-DockerScript

生成 WSL 配置

Generate-WSLConfig

生成 PowerShell 别名

Generate-PSAlias

更新 README

Update-README

===================== 最终统计 =====================

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "  QFYN Security Tools v$scriptVersion - 安装完成" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "📊 统计信息:" -ForegroundColor Cyan
Write-Host "  总工具数: $($tools.Count) 种" -ForegroundColor White
Write-Host "  已检测到: $installedCount 种" -ForegroundColor White
Write-Host "  安装目录: $ToolDir" -ForegroundColor White
Write-Host "  安装用时: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor White
Write-Host ""
Write-Host "📁 生成的文件:" -ForegroundColor Cyan
Get-ChildItem $ToolDir -File | ForEach-Object {
Write-Host "  📄 $($.Name) ($([math]::Round($.Length/1KB, 1)) KB)" -ForegroundColor Gray
}
Write-Host ""
Write-Host "🚀 快速启动:" -ForegroundColor Cyan
Write-Host "  运行: $ToolDir\QFYN_Quick_Start.bat" -ForegroundColor Yellow
Write-Host "  查看报告: $ToolDir\QFYN_Report.html" -ForegroundColor Yellow
Write-Host "  重启 PowerShell 使所有命令生效" -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================" -ForegroundColor Green

播放完成提示音

等待退出

Write-Host "`n按任意键退出..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

```