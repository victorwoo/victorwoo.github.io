---
layout: post
date: 2023-04-25 00:00:40
title: "PowerShell 技能连载 - 重命名属性（简单方法）"
description: PowerTip of the Day - Renaming Properties (Simple)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Select-Object` 不仅可以选择属性，还可以重命名。假设您需要获取一个文件夹中的文件列表，并包含文件大小信息，这行代码就足够了：

```powershell
PS> Get-ChildItem -Path c:\windows -File | Select-Object -Property Length, FullName
}
```

现在你只能看到两个选定的属性“Length”和“FullName”。但是如果您希望此信息以不同的名称显示，例如“Size”和“Path”，该怎么办？

只需通过提交每个属性的哈希表来重命名属性。在每个哈希表内，使用“Name”键来重命名属性，“`Expression = '[OriginalPropertyName]' }`”键保持原始属性内容不变：

```powershell
Get-ChildItem -Path c:\windows -File | Select-Object -Property @{Name='Size';Expression='Length'}, @{Name='Path';Expression='FullName'}
```

这样，您可以轻松地重命名任何对象中的任何属性。
<!--本文国际来源：[Renaming Properties (Simple)](https://blog.idera.com/database-tools/powershell/powertips/renaming-properties-simple/)-->

