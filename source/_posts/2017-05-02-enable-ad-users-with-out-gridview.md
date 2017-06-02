---
layout: post
date: 2017-05-02 00:00:00
title: "PowerShell 技能连载 - 用 Out-GridView 启用 AD 用户"
description: PowerTip of the Day - Enable AD Users with Out-GridView
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
有些时候在 PowerShell 中只需要几行代码就可以创造出很有用的支持工具。以下是一个显示所有禁用的 AD 用户的例子。您可以选择一个（或按住 CTRL 键选择多个），然后点击 OK，这些用户将会被启用：

```powershell
#requires -Version 3.0 -Modules ActiveDirectory
Search-ADAccount -AccountDisabled |
  Out-GridView -Title 'Who should be enabled?' -OutputMode Multiple |
  # remove -WhatIf to actually enable accounts
  Enable-ADAccount -WhatIf
```

<!--more-->
本文国际来源：[Enable AD Users with Out-GridView](http://community.idera.com/powershell/powertips/b/tips/posts/enable-ad-users-with-out-gridview)
