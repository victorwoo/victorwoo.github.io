---
layout: post
date: 2021-05-19 00:00:00
title: "PowerShell 技能连载 - 导出不带引号的CSV（和其他转换技巧）"
description: PowerTip of the Day - Exporting CSV without Quotes (and Other Conversion Tricks)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 附带了一堆 `Export-` 和 `ConvertTo-` cmdlet，因此您可以将对象数据序列化为 CSV、JSON、XML和其他格式。很好，但是创建自己的导出功能并不难。

例如，Windows PowerShell 中的 `Export-Csv` 始终对数值添加双引号。如果你不喜欢带双引号的 CSV，就不好办了。 PowerShell 7 已解决此问题，其中包含额外的参数，但创建自己的 `Export-Csv` 函数根本并不难。

这是一个简单的例子：

```powershell
function ConvertTo-MyCsv
{
    param
    (
        [char]
        $Delimiter = ','
    )
    begin
    {
        $init = $false
    }
    process
    {
        # write the headers
        if ($init -eq $false)
        {
            $_.PSObject.Properties.Name -join $Delimiter
            $init = $true
        }

        # write the items
        $_.PSObject.Properties.Value -join $Delimiter
    }
}

$a = Get-Service | ConvertTo-MyCsv
```

这的确是所有的内容了：`ConvertTo-MyCsv` 将对象转换为没有双引号的 CSV，如果需要，甚至可以选择分隔符（默认为 "`,`"）。

要快速检查生成的CSV的完整性，请将其转换回对象：

```powershell
PS> $a | ConvertFrom-CSV | Out-GridView
```

一切都很好，转换生效了。它不比 `ConvertTo-Csv` 慢。

显然，如果任何数据值包含分隔符（这就是为什么 `ConvertTo-Csv` 为它们添加双引号的原因），则转换将失败。但这不是这里的重点。您可以轻松微调函数。更重要的是，PowerShell 中将对象自动转换为文本的艺术。

要将对象转换为 CSV（或任何其他格式），只需访问隐藏的 `PSObject` 属性（可用于任何 PowerShell 对象）。它描述了对象，并提供所有属性名称，值和数据类型。

<!--本文国际来源：[Exporting CSV without Quotes (and Other Conversion Tricks)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/exporting-csv-without-quotes-and-other-conversion-tricks)-->
