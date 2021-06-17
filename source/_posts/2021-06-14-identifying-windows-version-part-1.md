---
layout: post
date: 2021-06-14 00:00:00
title: "PowerShell 技能连载 - 检测 Windows 版本（第 1 部分）"
description: PowerTip of the Day - Identifying Windows Version (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
可以从 Windows 注册表轻松读取当前的 Windows 版本：

```powershell
PS> Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' | Select-Object -Property ReleaseId, DisplayVersion

ReleaseId DisplayVersion
--------- --------------
2009      20H2
```

请注意，不推荐使用 `ReleaseId` 中显示的信息。新的 Windows 10 版本改为使用 `DisplayVersion` 属性。要正确识别 Windows 10 版本，请确保使用 `DisplayVersion` 而不是 `ReleaseId`。

在上面的示例中，您可以看到 Windows 10 报告了许多不同版本的相同 ReleaseId (2009)。例如，`DisplayVersion` 20H1 也使用 ReleaseId 2009。

微软宣布 `ReleaseId` 已弃用，不能再用于正确识别 Windows 10 版本。这对于脚本以及 WSUS、WAC 等工具可能很重要。例如，像 `Get-WindowsImage` 这样的 cmdlet 现在很难识别正确的 Windows 10 版本。

<!--本文国际来源：[Identifying Windows Version (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/identifying-windows-version-part-1)-->

