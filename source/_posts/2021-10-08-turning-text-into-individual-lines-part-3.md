---
layout: post
date: 2021-10-08 00:00:00
title: "PowerShell 技能连载 - 分割文本行（第 3 部分）"
description: PowerTip of the Day - Turning Text into Individual Lines (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技能中，我们将一大块多行文本拆分为单独的行，并删除了所有空行。

然而，当一行不是真正的空，而是包含空格（空格或制表符）时，它仍然会被输出：

```powershell
# $data is a single string and contains blank lines
$data = @'

Server1


Server2
Cluster4


'@

$data = $data.Trim()

# split in single lines and remove empty lines
$regex = '[\r\n]{1,}'
$array = $data -split $regex

$array.Count

$c = 0
Foreach ($_ in $array)
{
    '{0:d2} {1}' -f $c, $_
    $c++
}
```

在这里，我们在 "Server2" 正上方的行中添加了几个空格（当然，在列表中看不到）。以下是执行结果：

    00 Server1
    01
    02 Server2
    03 Cluster4

由于我们要在任意数量的 CR 和 LF 字符处拆分，因此空格会破坏该模式。

与其将正则表达式变成一个更复杂的野兽，不如为这些事情附加一个简单的 `Where-Object` 来进行精细修饰：

```powershell
# $data is a single string and contains blank lines
$data = @'

Server1


Server2
Cluster4


'@

$data = $data.Trim()

# split in single lines and remove empty lines
$regex = '[\r\n]{1,}'
$array = $data -split $regex |
    Where-Object { [string]::IsNullOrWhiteSpace($_) -eq $false }

$array.Count

$c = 0
Foreach ($_ in $array)
{
    '{0:d2} {1}' -f $c, $_
    $c++
}
```

`[string]::IsNullOrEmpty()` 代表我们所追求的情况，因此符合条件的行被 `Where-Object` 删除。结果就是所需要的理想结果：

    00 Server1
    01 Server2
    02 Cluster4

<!--本文国际来源：[Turning Text into Individual Lines (Part 3)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/turning-text-into-individual-lines-part-3)-->

