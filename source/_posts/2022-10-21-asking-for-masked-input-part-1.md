---
layout: post
date: 2022-10-21 00:00:00
title: "PowerShell 技能连载 - 遮罩输入框（第 1 部分）"
description: PowerTip of the Day - Asking for Masked Input (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
永远不要将纯文本输入框用于保密信息和密码——用户输入的文本可能被记录和利用。请始终使用遮罩输入框。这是用户提示的一种简单方法：

```powershell
# asking secret using masked input box
$secret = Read-Host "Enter secret" -AsSecureString

# internally, get back plain text
$data = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret)
$plain =[Runtime.InteropServices.Marshal]::PtrToStringAuto($data)

Write-Host "You secret: $plain" -ForegroundColor Yellow
```

<!--本文国际来源：[Asking for Masked Input (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/asking-for-masked-input-part-1)-->

