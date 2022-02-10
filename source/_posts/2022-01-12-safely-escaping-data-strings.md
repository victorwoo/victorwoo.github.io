---
layout: post
date: 2022-01-12 00:00:00
title: "PowerShell 技能连载 - 安全地转义数据字符串"
description: PowerTip of the Day - Safely Escaping Data Strings
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
通常，您使用像 `EscapeUriString()` 这样的方法来安全地转义要追加到 URL 的字符串数据（如我们之前的技能中所指出的）。

但是，这可能会导致头疼的情况，因为 `EscapeUriString()` 专门设计用于转义包括域名部分的完整URL，而不仅仅是您的参数。这就是为什么它可能损坏您要发送给其他人的数据，即莫尔斯 Web Service。尝试运行以下代码：

```powershell
$url = "https://api.funtranslations.com/translate/morse.json?text=One&Two"

$Escaped = [Uri]::EscapeUriString($url)

$result = Invoke-RestMethod -Uri $url
$result.contents
```

返回的结果可以看出问题：

    translated text translation
    ---------- ---- -----------
    --- -. .   One  morse

即使您将文本 "One&Two" 发送给 WebService，它也仅会返回 "One" 的摩尔斯代码。当您查看 `$Escaped` 的内容时，就能发现原因：

```powershell
PS C:\> $escaped
https://api.funtranslations.com/translate/morse.json?text=One&Two
```

`EscapeUriString` 没有将 & 字符转义——因为 & 是URL的有效部分，它用于分割参数。实质上，WebService 接收了两个参数，因为它只支持一个，所以它丢弃了第二个参数。

虽然 `EscapeUriString()` 能很方便快速转义完整的网址，但它具有严重的缺点。要解决此问题，请务必确保将 base URL 和数据参数分开。您可以使用 `EscapeDataString()`，来代替 `EscapeUriString()` 来确保*所有*特殊字符被正确转义：

```powershell
$Text = 'One&Two'
$Escaped = [Uri]::EscapeDataString($Text)
$baseurl = "https://api.funtranslations.com/translate/morse.json?text="
$url = $baseurl + $Escaped

$resultok = Invoke-RestMethod -Uri $url
$resultok.contents
```

现在结果是正确的（用于演示的 WebService 确实具有速率限制，因此如果您过于频繁调用它，将需要等待一小时来验证）：

这是因为 `$escaped` 现在转义了所有特殊字符，包括 ＆ 符号：

```powershell
PS> $escaped
One%26Two
```

此外，您还有一张“返程票：`UnescapeDataString()`，它能将转义后的数据恢复正常：

```powershell
# escape special characters
$text = 'This is a text with [special] characters!'

$escaped = [Uri]::EscapeDataString($text)
$escaped

# unescape escaped strings
$unescaped = [Uri]::UnescapeDataString($escaped)
$unescaped
```

结果如下所示：

    This%20is%20a%20text%20with%20%5Bspecial%5D%20characters%21
    This is a text with [special] characters!

<!--本文国际来源：[Safely Escaping Data Strings](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/safely-escaping-data-strings)-->

