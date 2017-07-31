---
layout: post
date: 2017-07-28 00:00:00
title: "PowerShell 技能连载 - 简单解析设置文件（第三部分）"
description: PowerTip of the Day - Easy Parsing of Setting Files (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
在前一个技能中我们了解了 `ConvertFrom-StringData` 如何将纯文本的键值对转换为哈希表。还缺少另一个方向的操作：将哈希表转为纯文本。有了它以后，您就拥有了一个将设置和信息保存到文件的小型框架。

我们首先创建一个包含一些数据的哈希表：

```powershell
$test = @{
    Name = 'Tobias'
    ID = 12
    Conf = 'PowerShell Conference EU'
}

$test
```

结果看起来如下：

```powershell
Name                           Value
----                           -----
Conf                           PowerShell Conference EU
Name                           Tobias
ID                             12
```

以下是名为 `ConvertFrom-Hashtable` 的函数，传入一个哈希表，并将它转换为纯文本：

```powershell
filter ConvertFrom-Hashtable
{
    $_.GetEnumerator() |
        ForEach-Object {
        # get hash table key and value
        $value = $_.Value
        $name = $_.Name

        # escape "\" in strings
        if ($value -is [string]) { $value = $value.Replace('\','\\') }

        # compose key-value pair as plain text
        '{0}={1}' -f $Name, $value
        }
}
```

让我们看看哈希表是如何转换的：

```powershell
PS> $test | ConvertFrom-Hashtable
Conf=PowerShell Conference EU
Name=Tobias
ID=12

PS>
```

您可以用 `ConvertFrom-StringData` 转换到另一种形式：

```powershell
PS> $test | ConvertFrom-Hashtable | ConvertFrom-StringData

Name                           Value
----                           -----
Conf                           PowerShell Conference EU
Name                           Tobias
ID                             12



PS>
```

所以基本上，您可以将哈希表保存为纯文本，并在稍后使用它：

```powershell
$test = @{
    Name = 'Tobias'
    ID = 12
    Conf = 'PowerShell Conference EU'
}

$path = "$env:temp\settings.txt"

# save hash table as file
$test | ConvertFrom-Hashtable | Set-Content -Path $path -Encoding UTF8
notepad $path

# read hash table from file
Get-Content -Path $path -Encoding UTF8 |
    ConvertFrom-StringData |
    Out-GridView
```

请注意这种方法对简单的字符串和数字型数据有效。它不能处理复杂数据类型，因为这个转换操作并不能序列化对象。

<!--more-->
本文国际来源：[Easy Parsing of Setting Files (Part 3)](http://community.idera.com/powershell/powertips/b/tips/posts/easy-parsing-of-setting-files-part-3)
