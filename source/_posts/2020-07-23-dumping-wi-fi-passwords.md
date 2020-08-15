---
layout: post
date: 2020-07-23 00:00:00
title: "PowerShell 技能连载 - 导出 Wi-Fi 密码"
description: PowerTip of the Day - Dumping Wi-Fi Passwords
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技巧中，我们使用 netsh.exe 转储 Wi-Fi 配置。让我们更进一步，提取缓存的密码：

```powershell
# get cleartext password for each profile
Foreach ($profile in $profiles)
{
      $password = (@(netsh wlan show profile name="$profile" key=clear) -like '*Key Content*' -split ': ')[-1]
      [PSCustomObject]@{
            Profile = $profile
            Password = $password
      }
}
```

这只是一个示例，演示了 PowerShell 如何处理由控制台应用程序（例如 netsh.exe）返回的字符串信息。您也有可能遇到挑战：当 Wi-Fi 配置名称使用特殊字符（例如撇号）时，可能无法通过 netsh.exe 进行检索。

<!--本文国际来源：[Dumping Wi-Fi Passwords](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/dumping-wi-fi-passwords)-->

