---
layout: post
date: 2020-01-29 00:00:00
title: "PowerShell 技能连载 - 下载 PowerShell 语言参考（或任意文件）"
description: PowerTip of the Day - Downloading PowerShell Language Reference (or any file)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Invoke-WebRequest` 可以轻松下载文件。下面的代码下载由 PowerShell Magazine 发布的PowerShell语言参考，并使用关联的程序将其打开：

```
$url = "https://download.microsoft.com/download/4/3/1/43113f44-548b-4dea-b471-0c2c8578fbf8/powershell_langref_v4.pdf"

# get desktop path
$desktop = [Environment]::GetFolderPath('Desktop')
$destination = "$desktop\langref.pdf"

# enable TLS1.2 for HTTPS connections
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12

# download PDF file
Invoke-WebRequest -Uri $url -OutFile $destination -UseBasicParsing
# open downloaded file in associated program
Invoke-Item -Path $destination
```

请注意这段代码如何启用 TLS 1.2。是否需要该协议取决于您的连接类型和防火墙。在以上示例中，并不是必须的。对于其它下载链接，可能是必须的。

<!--本文国际来源：[Downloading PowerShell Language Reference (or any file)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/downloading-powershell-language-reference-or-any-file)-->

