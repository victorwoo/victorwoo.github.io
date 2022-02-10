---
layout: post
date: 2022-01-04 00:00:00
title: "PowerShell 技能连载 - Windows 重启后自动登录"
description: PowerTip of the Day - Auto-Logon After Windows-Reboot
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您的自动化脚本需要重新启动机器，并且您希望在重新启动后自动登录，那么以下是一个快速的脚本，它将登录凭据保存到 Windows 注册表：

```powershell
# ask for logon credentials:
$cred = Get-Credential -Message 'Logon automatically'
$password = $cred.GetNetworkCredential().Password
$username = $cred.UserName

# save logon credentials to registry (WARNING: clear text password used):
$path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty -Path $path -Name AutoAdminLogon -Value 1
Set-ItemProperty -Path $path -Name DefaultPassword -Value $password
Set-ItemProperty -Path $path -Name DefaultUserName -Value $username

# restart machine and automatically log on: (remove -WhatIf to test-drive)
Restart-Computer -WhatIf
```

如果您希望每次计算机启动时自动登录，那么可以使用相同的方法。

显然，此技术可能会增加安全风险：密码以明文的方式写入注册表。请只在合适的地方谨慎使用它。

<!--本文国际来源：[Auto-Logon After Windows-Reboot](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/auto-logon-after-windows-reboot)-->

