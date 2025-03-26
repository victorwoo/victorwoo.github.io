---
layout: post
date: 2022-10-19 00:00:00
title: "PowerShell 技能连载 - 查找 MSI 产品代码（第 2 部分）"
description: PowerTip of the Day - Finding MSI Product Codes (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 Windows 10 及以上版本，查找 MSI 软件包及其产品代码不再需要 WMI 查询。相反，您可以使用 `Get-Package` 来替代：

```powershell
Get-Package |
Select-Object -Property Name, @{
    Name='ProductCode'
    Expression={
        $code = $_.Metadata["ProductCode"]
        if ([string]::IsNullOrWhiteSpace($code) -eq $false)
        {
            $code
        }
        else
        {
            'N/A'
        }
    }
} |
Format-List
```

<!--本文国际来源：[Finding MSI Product Codes (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/finding-msi-product-codes-part-2)-->

