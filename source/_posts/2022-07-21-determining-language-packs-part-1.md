---
layout: post
date: 2022-07-21 00:00:00
title: "PowerShell 技能连载 - 确定语言包（第 1 部分）"
description: PowerTip of the Day - Determining Language Packs (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
假设您需要查找 Windows 计算机已安装的语言包。在这个三部分的系列中，我们使用 PowerShell 的功能来解决此问题。

在第一部分中，我们只是尝试通过寻找可以利用的原生非 PowerShell 命令来解决问题。

事实证明，命令 `dism.exe` 可以为您找到该信息。但是，与许多二进制控制台命令一样，结果是 (a)本地化的，(b)字符串数据，(c)通常需要管理员特权。

如果我们别无选择，作为管理员，您可以运行以下代码：

```powershell
DISM.exe /Online /Get-Intl /English
```

接下来，您可以使用 PowerShell 功能过滤和解析信息，直到找到所需的内容为止。

例如，使用 `Select-String` 仅选择那些对您的任务有趣的行：

```powershell
DISM.exe /Online /Get-Intl /English |
    Select-String -SimpleMatch 'Installed language(s)'
```

结果看起来像这样：

    Installed language(s): de-DE
    Installed language(s): en-US
    Installed language(s): fr-FR

接下来，使用 PowerShell 管道机制处理每个结果并提取您真正需要的信息：

```powershell
DISM.exe /Online /Get-Intl /English |
    Select-String -SimpleMatch 'Installed language(s)' |
    ForEach-Object { $_.Line.Split(':')[-1].Trim() }
```

在这里，每次取出一行，然后由冒号分隔，然后取出最后一部分（右）部分，删除所有空格。这很麻烦，但最后能够获取原生字符串的数据的结果。

实际上，`Select-String` 支持正则表达方式。因此，如果您了解正则表达式，则可以立即查询所需的信息：

```powershell
DISM.exe /Online /Get-Intl /English |
    Select-String -Pattern 'Installed language\(s\):\s(.*?)$' |
    ForEach-Object { $_.Matches[0].Groups[1].Value }
```

请注意，在代码示例中如何使用 `-Pattern` 参数并忽略 `-SimplePattern` 参数，从而告诉 `Select-String` 我们正在使用完整的正则表达式。现在，搜索模式使用 "`\`" 来转义所有特殊字符，并定义一组括号来定义我们要寻找的值，位于搜索文本之后和行末的 "`$`" 之后）。


然后，`Select-String` 在其属性 "`Matches`" 中返回正则表达式匹配，因此我们可以从这里以面向对象的方式访问发现的匹配和组。我们正在寻找的信息是在第一个匹配项中（每行，index 为 0），在第二组中（索引号 0 代表整个匹配，索引号 1 是第一个括号内的匹配项）。

如果这个操作对你来说太低级了，请期待下一个技能！

<!--本文国际来源：[Determining Language Packs (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/determining-language-packs-part-1)-->

