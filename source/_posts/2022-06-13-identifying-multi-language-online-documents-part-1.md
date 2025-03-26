---
layout: post
date: 2022-06-13 00:00:00
title: "PowerShell 技能连载 - 检测多语言在线文档（第 1 部分）"
description: PowerTip of the Day - Identifying Multi-Language Online Documents (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在之前的技能中，我们介绍了官方的 PowerShell 语言规范，该规范提供了许多不同语言的在线版本。这引出了有关受支持的语言的问题。

通常，多语言在线文档使用相同的URL，只需更改语言 ID 即可。例如，英语和德语版在其语言 ID 上有所不同：

[https://docs.microsoft.com/de-de/powershell/scripting/lang-spec/chapter-01?view=powershell-7.2](https://docs.microsoft.com/de-de/powershell/scripting/lang-spec/chapter-01?view=powershell-7.2)

[https://docs.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-01?view=powershell-7.2](https://docs.microsoft.com/en-us/powershell/scripting/lang-spec/chapter-01?view=powershell-7.2)

为了自动找出所有可用的翻译，我们首先需要一个有可能的语言 ID 列表并构建假想的URL。然后，我们需要一种方法来检查这些 URL 是否真正存在。让我们解决第一部分：

可以这样检索所有可用语言 ID 的列表：

```powershell
[CultureInfo]::GetCultures([Globalization.CultureTypes]::SpecificCultures)
```

这将创建一个哈希表，可轻松查找使用连字符的 ID（因为 Web URL 通常仅使用带有连字符的 ID）：

```powershell
$h = [CultureInfo]::GetCultures([Globalization.CultureTypes]::SpecificCultures) |
Where-Object {$_ -like '*-*' } |
Group-Object -Property Name -AsHashTable
```

现在，我们可以获取可用语言 ID 的列表，我们也可以查找其显示名称：

```powershell
# list all languages:
$h.Keys



PS C:\> $h['de-de'].DisplayName
German (Germany)
```

要获取可能的 URL 的列表，只需遍历所有可用的语言 ID，然后将它们一个接一个地插入 URL 即可。

请注意，我如何将占位符（`{0}`）替换为特定语言的 ID，例如 "en -us"：使用操作符 `-f` 来格式化，然后在循环体中插入语言 ID：

```powershell
$URL = 'https://docs.microsoft.com/{0}/powershell/scripting/lang-spec/chapter-01'

$list = $h.Keys |
    ForEach-Object { $URL -f $_ }

$list
```

我们现在有一个可能的 URL 列表。 在第二部分中，我们将检查此列表以查看实际存在哪些 URL。

<!--本文国际来源：[Identifying Multi-Language Online Documents (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/identifying-multi-language-online-documents-part-1)-->

