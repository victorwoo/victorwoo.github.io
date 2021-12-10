---
layout: post
date: 2021-12-01 00:00:00
title: "PowerShell 技能连载 - 禁用摄像头"
description: PowerTip of the Day - Disabling Webcams
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
寻求保护隐私吗？这是一个简短的脚本，用于在您的系统上查找已启用的摄像头，并让您禁用任何不想使用的摄像头：

```powershell
  # find working cameras
$result = Get-PnpDevice -FriendlyName *Camera* -Status OK -ErrorAction Ignore |
  Out-GridView -Title 'Select Camera Device To Disable' -OutputMode Single |
  Disable-PnpDevice -Confirm:$false -Passthru -whatif # remove -WhatIf to actually disable devices)
```

<!--本文国际来源：[Disabling Webcams](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/disabling-webcams)-->

