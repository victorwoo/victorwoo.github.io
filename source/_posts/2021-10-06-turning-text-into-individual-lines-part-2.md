---
layout: post
date: 2021-10-06 00:00:00
title: "PowerShell 技能连载 - 分割文本行（第 2 部分）"
description: PowerTip of the Day - Turning Text into Individual Lines (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
假设您的脚本获取文本输入数据，并且您需要将文本拆分为单独的行。在上一个技能中，我们建议了一些正则表达式来完成这项工作。但是如果输入文本包含空行怎么办？

```powershell
# $data is a single string and contains blank lines
$data = @'

Server1


Server2
Cluster4


'@

# split in single lines and remove empty lines
$regex = '[\r\n]{1,}'
```

如您所见，我们使用的正则表达式会自动处理文本中间的空白行，但文本开头或结尾的空白行会保留。

    00
    01 Server1
    02 Server2
    03 Cluster4
    04

那是因为我们在任意数量的新行处分割，所以我们也在文本的开头和结尾处分割。我们实际上是自己生成了这两个剩余的空白行。

为了避免这些空行，我们必须确保文本的开头和结尾没有换行符。这就是 `Trim()` 可以做的事情：

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



00 Server1
01 Server2
02 Cluster4
```

<!--本文国际来源：[Turning Text into Individual Lines (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/turning-text-into-individual-lines-part-2)-->

