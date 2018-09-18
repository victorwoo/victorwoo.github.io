---
layout: post
date: 2018-09-14 00:00:00
title: "PowerShell 技能连载 - 查找禁用的 GPO"
description: PowerTip of the Day - Finding Disabled GPOs
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
以下是一行可以转储所有禁用了所有设置的组策略对象的代码：

```powershell
Get-Gpo -All | Where-Object GpoStatus -eq AllSettingsDisabled
```

这个示例需要 Microsoft 免费的 RSAT 工具。

<!--more-->
本文国际来源：[Finding Disabled GPOs](http://community.idera.com/powershell/powertips/b/tips/posts/finding-disabled-gpos)
