---
layout: post
date: 2021-04-29 00:00:00
title: "PowerShell 技能连载 - Linux 如何保护安全字符串（实际未保护）"
description: PowerTip of the Day - How Linux protects SecureStrings (Not)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您在非 Windows 系统上的 PowerShell 中将对象序列化为 XML 时，即通过使用 `Export-CliXml`，所有 SecureString 数据仅被编码，而不被加密。这是根本的区别，也是安全代码一旦移植到非 Windows 操作系统后可能变得不安全的原因。

例如，如果序列化凭据，则结果仅在 Windows 操作系统上是安全的：

```
Get-Credential | Export-Clixml -Path $env:temp\secret.xml
```

在 XML 文件中，您可以看到 `Export-CliXml` 如何更改 SecureString 的表示形式并将其转换为十六进制值的列表。在 Windows 上，SecureString 数据已安全加密，并且只有加密数据的人员（并且正在使用该计算机时）才能读取。在 Linux 和 macOS 上并非如此。由于此处缺少 Windows 加密API，因此仅对 SecureString 进行编码而不是加密。

要在非 Windows 操作系统上解码序列化 XML 内容中的纯文本内容，请尝试如下代码：

```powershell
$secret = '53007500700065007200530065006300720065007400' $bytes = $secret -split '(?<=\G.{2})(?=.)' |ForEach-Object {
    [Convert]::ToByte($_, 16)}
$plain = [Text.Encoding]::Unicode.GetString($bytes)$plain
```

它采用编码字符串，将其分成两对，将十六进制值转换为十进制值，并通过相应的 Unicode 解码器运行结果字节。结果就是原始的密文。

简而言之，请记住，仅在 Windows 操作系统上对序列化的 SecureString 进行安全加密。在 Linux 和 macOS 上，将敏感数据发送到 `Export-CliXml` 不会对其进行保护。

<!--本文国际来源：[How Linux protects SecureStrings (Not)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/how-linux-protects-securestrings-not)-->

