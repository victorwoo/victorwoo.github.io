---
layout: post
date: 2021-10-04 00:00:00
title: "PowerShell 技能连载 - 分割文本行（第 1 部分）"
description: PowerTip of the Day - Turning Text into Individual Lines (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有时，您需要逐行处理多行文本。下面是一个多行字符串的示例：

```powershell
# working with 1-dimensional input

# $data is a single string
$data = @'
Server1
Server2
Cluster4
'@

$data.GetType().FullName
$data.Count
```

将文本拆分为单独的行的一种有效方法是使用带有正则表达式的 `-split` 运算符，该表达式可以处理各种依赖于平台的行终止符：

```powershell
# split the string in individual lines
# $array is an array with individual lines now

$regex = '[\r\n]{1,}'
$array = $data -split $regex

$array.GetType().FullName
$array.Count

$array
```

以下是您在脚本中遇到的 `$regex` 中的正则表达式的一些替代方案：

| 分隔用的正则表达式    | 说明                                                                                                           |
|--------------|--------------------------------------------------------------------------------------------------------------|
| /r           | 类似于“回车”(ASCII 13)。如果操作系统不是用该字符作为换行符，则分割将会失败。如果操作系统使用该字符加上“换行”(ASCII 10)，那么多出来的不可见的换行符会破坏字符串。                 |
| /n           | 类似上面的情况，只是相反。                                                                                                |
| [\r\n]+      | 与上面的示例代码相同。如果有一个或多个字符，PowerShell 会在两个字符处拆分。这样，CR、LF 或 CRLF、LFCR 在拆分时都被删除。但是，多个连续的新行也将全部删除：CRCRCR 或 CRLFCRLF。 |
| (\r\n|\r|\n) | 这将正确拆分单个换行符，而不管特定操作系统使用哪些字符。连续的空白行保持不变。                                                                      |

如果您从文本文件中读取文本，`Get-Content` 会自动将文本拆分为行。要将整个文本内容作为单个字符串读取，则需要添加 `-Raw` 参数。

<!--本文国际来源：[Turning Text into Individual Lines (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/turning-text-into-individual-lines-part-1)-->

