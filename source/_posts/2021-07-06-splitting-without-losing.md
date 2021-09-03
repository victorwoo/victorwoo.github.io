---
layout: post
date: 2021-07-06 00:00:00
title: "PowerShell 技能连载 - 拆分而不丢失字符"
description: PowerTip of the Day - Splitting without Losing
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
拆分文本时，通常会丢失拆分字符。这就是为什么这个例子中的反斜杠丢失的原因：

```powershell
PS> 'c:\test\file.txt' -split '\\'
c:
test
file.txt
```

重要提示：请注意 `-split` 运算符需要一个正则表达式。如果你想在反斜杠处拆分，因为反斜杠是正则表达式中的一个特殊字符，你需要对它进行转义。以下调用告诉您需要转义的内容：提交要使用的文字文本。结果是转义的正则表达式文本：

```powershell
PS> [regex]::Escape('\')
\\
```

如果你想拆分而不丢失任何字符，你可以使用所谓的先行断言和后行断言。以下代码在一个反斜杠*后*分割（不删除它）：

```powershell
PS> 'c:\test\file.txt' -split '(?<=\\)'
c:\
test\
file.txt
```

以下代码在每个反斜杠*之前*拆分：

```powershell
PS> 'c:\test\file.txt' -split '(?=\\)'
c:
\test
\file.txt
```

<!--本文国际来源：[Splitting without Losing](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/splitting-without-losing)-->

