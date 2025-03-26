---
layout: post
date: 2023-03-06 00:00:15
title: "PowerShell 技能连载 - 存储任何加密的文本"
description: PowerTip of the Day - Storing Any Text Encrypted
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
假设您的脚本需要敏感输入，例如数据库的连接字符串或其他文本信息。

管理此类机密信息的一种方法是将它们存储为 `[SecureString]`，并安全地序列化此信息到 XML。以下是此部分的操作：

```powershell
$Path = "$env:temp\safeconnectionstring.test"


[ordered]@{
    Con1 = 'secret1' | ConvertTo-SecureString -AsPlainText -Force
    Con2 = 'secret2' | ConvertTo-SecureString -AsPlainText -Force
    Con3 = 'secret3' | ConvertTo-SecureString -AsPlainText -Force
} | Export-Clixml -Path $Path
```

它将三段机密信息存储到一个哈希表中，将其转换为安全字符串，然后安全地将它们导出到 XML。机密的关键是运行此脚本的用户和机器，因此只有此人（在同一台计算机上）才能稍后读取信息。

如果您不想将机密信息存储在任何地方，您还可以交互式地输入它们：

```powershell
$Path = "$env:temp\safeconnectionstring.test"


[ordered]@{
    Con1 = Read-Host -Prompt Secret1 -AsSecureString
    Con2 = Read-Host -Prompt Secret1 -AsSecureString
    Con3 = Read-Host -Prompt Secret1 -AsSecureString
} | Export-Clixml -Path $Path
```

Now, when it is time to use the secrets, you need a way to convert secure strings back to plain text. This is what this script does:
现在，当需要使用这些机密信息时，您需要一种将安全字符串转换回纯文本的方法。此脚本的操作：

```powershell
$hash = Import-Clixml -Path $Path
# important: MUST cast $keys to [string[]] or else you cannot modify the hash
# in the loop:
[string[]]$keys = $hash.Keys
$keys | ForEach-Object {
    $hash[$_] = [PSCredential]::new('xyz', $hash[$_]).GetNetworkCredential().Password
}
```

结果(`$hash`)是一个哈希表，其中包含以纯文本形式保存的机密信息，因此在此示例中，您可以通过三个键“con1”、“con2”和“con3”访问这三个机密信息：

```powershell
PS> $hash.Con1
secret1

PS> $hash.Con2
secret2

PS> $hash.Con3
secret3
```
<!--本文国际来源：[Storing Any Text Encrypted](https://blog.idera.com/database-tools/powershell/powertips/storing-any-text-encrypted/)-->

