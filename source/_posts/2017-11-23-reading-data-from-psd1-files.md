---
layout: post
date: 2017-11-23 00:00:00
title: "PowerShell 技能连载 - 从 .PSD1 文件中读取数据"
description: PowerTip of the Day - Reading Data from .PSD1 Files
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
一个脚本有多种方法可以保存数据信息。有一种方式特别方便。以下是实现的代码：

```powershell
Import-LocalizedData -BaseDirectory $PSScriptRoot -FileName data.psd1 -BindingVariable Info

$Info
```

请确保将这段代码保存为一个脚本。然后在同一个文件夹中创建另一个文件，并命名为 "data.psd1"，然后增加这段内容：

```powershell
@{
    Name = 'Tobias'
    ID = 12
    Path = 'c:\Windows'
}
```

当两个文件都放在目录下时，运行脚本。它将读取 data.psd1 并将它的内容返回为一个哈希表。请注意 `Import-LocalizedData` 默认情况下并不能将 .psd1 文件作为活动的内容来处理。当 data.psd1 中的哈希表包含命令和变量时，它不可以读取——防止黑客纂改数据文件内容。

如果您在文件夹中添加了子文件夹，并且命名为语言区域性 ID，例如 "de-de" 和 "en-us"，`Import-LocalizedData` 将会自动检测合适的子目录并且从中读取文件（假设您将数据文件的本地化拷贝放在这些文件夹中）。该 cmdlet 将使用 `$PSCulture` 中提供的语言区域设置，或者如果指定了 `-UICulture`，将使用该设置。

<!--本文国际来源：[Reading Data from .PSD1 Files](http://community.idera.com/powershell/powertips/b/tips/posts/reading-data-from-psd1-files)-->
