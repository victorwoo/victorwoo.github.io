---
layout: post
date: 2017-06-21 00:00:00
title: "PowerShell 技能连载 - 获取端口分配列表"
description: PowerTip of the Day - Get List of Port Assignments
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
IANA（互联网数字分配机构）维护了一个包含所有已知的端口分配的 CSV 文件。PowerShell 可以为您下载这个列表：

```powershell
$out = "$env:temp\portlist.csv"
$url = 'https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.csv'
$web = Invoke-WebRequest -Uri $url -UseBasicParsing -OutFile $out
Import-Csv -Path $out -Encoding UTF8
```

返回的结果是一个包含所有的端口分配的面向对象格式的列表。接下来您可以使用这个信息例如过滤特定的端口：

```powershell
Import-Csv -Path $out -Encoding UTF8 |
    Where-Object 'transport protocol' -eq 'tcp' |
    Where-Object 'Port Number' -lt 1000
```

<!--本文国际来源：[Get List of Port Assignments](http://community.idera.com/powershell/powertips/b/tips/posts/get-list-of-port-assignments)-->
