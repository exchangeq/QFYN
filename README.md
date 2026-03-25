# Security Tools Auto-Installer (PowerShell)

⚠️ **法律警告**  
本脚本仅用于授权的网络安全测试、教育及研究。未经授权使用可能违反《网络安全法》，使用者须自行承担法律责任。

## 功能
- 一键下载并安装 Nmap, Burp Suite, SQLMap, Hashcat, Wireshark 等 12+ 安全工具
- 带进度条的自动下载
- 配置系统 PATH 和命令别名

## 使用方法
1. 以管理员身份运行 PowerShell
2. 执行 `.\install_tools.ps1`
3. 输入 `YES` 接受条款
4. 等待下载安装完成

## 工具列表
| 分类 | 工具 |
|------|------|
| 信息收集 | Nmap, Maltego, Shodan CLI |
| 漏洞扫描 | Nessus, OpenVAS |
| Web 应用 | Burp Suite, SQLMap, Metasploit |
| 无线与密码 | Aircrack-ng, Hashcat |
| 防御与监控 | Wireshark, Snort/Suricata |

## 许可证
本项目采用 MIT 许可证，但使用时必须遵守法律警告。
