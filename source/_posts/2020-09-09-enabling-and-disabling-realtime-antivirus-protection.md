---
layout: post
date: 2020-09-09 00:00:00
title: "PowerShell 技能连载 - 启用或禁用实时防病毒保护"
description: PowerTip of the Day - Enabling and Disabling Realtime Antivirus Protection
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您以完全管理员权限运行，则可以使用 PowerShell 启用和禁用实时防病毒保护。当明确需要运行可能会被阻止的合法脚本时，暂时禁用实时防病毒保护有时可能会有所帮助。通常，实时保护很有价值，只有在有充分理由的情况下才应将其禁用。

要禁用实时保护，请运行以下命令：

```powershell
Set-MpPreference -DisableRealtimeMonitoring $true
```

要启用它，请将 `$true` 替换为 `$false`。

<!--本文国际来源：[Enabling and Disabling Realtime Antivirus Protection](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/enabling-and-disabling-realtime-antivirus-protection)-->

