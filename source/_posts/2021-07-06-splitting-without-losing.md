---
layout: post
date: 2021-07-06 00:00:00
title: "PowerShell 技能连载 - Splitting without Losing"
标题：《PowerShell 技能连载 - 分裂而不失落》
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
When you split texts, you typically lose the splitting character. That’s why the backslash in this example is lost:
拆分文本时，通常会丢失拆分字符。这就是为什么这个例子中的反斜杠丢失的原因：

```powershell
PS> 'c:\test\file.txt' -split '\\'
c:
test
file.txt
```

IMPORTANT: Note that the -split operator expects a regular expression. If you want to split at backslashes, since a backslash is a special character in regex, you need to escape it. The following call tells you what you need to escape: submit the literal text you want to use. The result is the escaped regex text:
重要提示：请注意 -split 运算符需要一个正则表达式。如果你想在反斜杠处拆分，因为反斜杠是正则表达式中的一个特殊字符，你需要对它进行转义。以下调用告诉您需要转义的内容：提交要使用的文字文本。结果是转义的正则表达式文本：

```powershell
PS> [regex]::Escape('\')
\\
```

If you want to split without losing anything, you can use so-called look-aheads and look-behinds. This splits *after* a backslash (without removing it):
如果你想分裂而不丢失任何东西，你可以使用所谓的前瞻和后视。这在*后*一个反斜杠分割（不删除它）：

```powershell
PS> 'c:\test\file.txt' -split '(?<=\\)'
c:\
test\
file.txt
```

And this splits *before* each backslash:
这在*之前*每个反斜杠拆分：

```powershell
PS> 'c:\test\file.txt' -split '(?=\\)'
c:
\test
\file.txt
```

<!--本文国际来源：[Splitting without Losing](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/splitting-without-losing)-->

