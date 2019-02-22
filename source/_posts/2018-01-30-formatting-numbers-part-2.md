---
layout: post
date: 2018-01-30 00:00:00
title: "PowerShell 技能连载 - 格式化数字（第 2 部分）"
description: PowerTip of the Day - Formatting Numbers (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们介绍了 `Get-DisplayFileSize` 函数，它可以自动将字节数转换成容易阅读的带单位的数字，例如 "KB" 和 "MB"。

使用 `Select-Object` 指令，您可以创建一个带有易读的文件尺寸的文件夹列表：

```powershell
$Length = @{
    Name = "Length"
    Expression = {
        if ($_.PSIsContainer) { return }
        $Number = $_.Length
        $newNumber = $Number
        $unit = 'Bytes,KB,MB,GB,TB,PB,EB,ZB' -split ','
        $i = 0
        while ($newNumber -ge 1KB -and $i -lt $unit.Length)
        {
            $newNumber /= 1KB
            $i++
        }

        if ($i -eq $null) { $decimals = 0 } else { $decimals = 2 }
        $displayText = "'{0,10:N$decimals} {1}'" -f $newNumber, $unit[$i]
        $Number = $Number | Add-Member -MemberType ScriptMethod -Name ToString -Value ([Scriptblock]::Create($displayText)) -Force -PassThru
        return $Number
    }
}


# pretty file sizes
dir $env:windir |
    Select-Object -Property Mode, LastWriteTime, $Length, Name |
    Sort-Object -Property Length
```

请注意计算属性 `Length` 仍然可以用于排序。它仍是字节数据，只是显示的方式改变了。

<!--本文国际来源：[Formatting Numbers (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/formatting-numbers-part-2)-->
