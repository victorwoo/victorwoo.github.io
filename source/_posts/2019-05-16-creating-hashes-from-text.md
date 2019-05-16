---
layout: post
date: 2019-05-16 00:00:00
title: "PowerShell 技能连载 - 从文本创建哈希"
description: PowerTip of the Day - Creating Hashes from Text
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
哈希是一种唯一确定一段文本而不用暴露原始文本的棒法。哈希被用来确定文本、查找重复的文件内容，以及验证密码。PowerShell 5 以及更高版本甚至提供了一个 cmdlet 来计算文件的哈希值：`Get-FileHash`。

然而，`Get-FileHash` 不能计算字符串的哈希。没有必要只是为了计算哈希值而将字符串保存到文件。您可以使用所谓的内存流来代替。以下是一段从任何字符串计算哈希值的代码片段：

```powershell
$Text = 'this is the text that you want to convert into a hash'

$stream = [IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($Text))
$hash = Get-FileHash -InputStream $stream -Algorithm SHA1
$stream.Close()
$stream.Dispose()

$hash
```

使用完成后别忘了关闭并释放内存流，防止内存泄漏并释放所有资源。

<!--本文国际来源：[Creating Hashes from Text](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/creating-hashes-from-text)-->

