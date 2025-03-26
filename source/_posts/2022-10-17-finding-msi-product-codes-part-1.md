---
layout: post
date: 2022-10-17 00:00:00
title: "PowerShell 技能连载 - 查找 MSI 产品代码（第 1 部分）"
description: PowerTip of the Day - Finding MSI Product Codes (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您需要已安装的 MSI 软件包及其产品代码列表，则可以使用 WMI 查询信息。以下操作可能需要几秒钟：

```powershell
Get-CimInstance -ClassName Win32_Product |
Select-Object -Property Name, @{Name='ProductCode'; Expression={$_.IdentifyingNumber}}
```

<!--本文国际来源：[Finding MSI Product Codes (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/finding-msi-product-codes-part-1)-->

