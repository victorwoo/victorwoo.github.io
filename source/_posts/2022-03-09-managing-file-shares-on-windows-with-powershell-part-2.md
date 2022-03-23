---
layout: post
date: 2022-03-09 00:00:00
title: "PowerShell 技能连载 - 在 Windows 中用 PowerShell 来管理文件共享（第 2 部分）"
description: PowerTip of the Day - Managing File Shares on Windows with PowerShell (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技能中，我们介绍了 Windows 附带的 "SmbShare" PowerShell 模块，使您能够管理文件共享。我们学习了代表您在网络上共享的本地文件夹的 "SmbShare" 名词。今天我们来看看 "SbmMapping" 这个名词。

"SmbMapping" 名词从另一端查看共享：它表示您映射为本地驱动器的远程共享。`Get-SmbMapping` 列出您已映射的所有网络驱动器：

```powershell
PS> Get-SmbMapping

Status       Local Path Remote Path
------       ---------- -----------
Disconnected Z:         \\127.0.0.1\c$
OK           Y:         \\storage3\scanning
```

"`New-SmbMapping`" 添加更多网络驱动器并将驱动器号映射到远程共享文件夹。这是一个映射网络驱动器并以纯文本形式提交登录凭据的示例：

```powershell
PS> New-SmbMapping -LocalPath y: -RemotePath \\storage3\scanning -UserName Freddy -Password topSecret123

Status Local Path Remote Path
------ ---------- -----------
OK     y:         \\storage3\scanning
```

与往常一样，查看 cmdlet 文档可以更好地了解整个工作原理：

```powershell
PS> Get-Help -Name New-SmbMapping -Online
```

这将在您的默认浏览器中打开一个文档页面，您可以检查可用参数并查看其他示例。

例如，您会发现 `-Persistent` 开关参数。它确定网络驱动器是永久可用且永久可用，还是仅用于当前会话。`-SaveCredentials` 将缓存输入的登录凭据，以便下次访问远程共享时不再需要密码。

<!--本文国际来源：[Managing File Shares on Windows with PowerShell (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/managing-file-shares-on-windows-with-powershell-part-2)-->

