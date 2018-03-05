---
layout: post
date: 2018-02-23 00:00:00
title: "PowerShell 技能连载 - 强制关闭所有 PowerShell ISE 文档"
description: PowerTip of the Day - Forcefully Close All PowerShell ISE Documents
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
以下是一段强制关闭 PowerShell ISE 中所有打开的文档的代码片段。请注意：它不经提示就关闭所有的文档。它适用于当您搞砸了，并且不准备保存脚本的情况：

```powershell
foreach ($tab in $psise.PowerShellTabs)
{
    $files = $tab.Files
    foreach ($file in $files)
    {
        $files.Remove($file, $true)
    }
}
```

不过，当您运行这段代码时，您会收到一个错误。即便您不使用 PowerShell ISE，这个错误（和它的修复信息）对您来说可能十分有趣。

这段代码枚举出所有打开的文件并且尝试逐个关闭它们。这并不能工作：当您枚举一个数组时，您无法改变这个数组。所以当 PowerShell 关闭一个文档时，这个文件列表就变化了，而这将打断这个循环。

当发生这个错误时，一个简单的办法是先将这个数组拷贝到另一个数组。然后就可以安全地枚举这个副本数组。拷贝一个数组十分简单，只需要将它强制类型转换为 `[Object[]]`。

以下是正确的代码：

```powershell
foreach ($tab in $psise.PowerShellTabs)
{
    $files = $tab.Files
    foreach ($file in [Object[]]$files)
    {
        $files.Remove($file, $true)
    }
}
```

<!--more-->
本文国际来源：[Forcefully Close All PowerShell ISE Documents](http://community.idera.com/powershell/powertips/b/tips/posts/forcefully-close-all-powershell-ise-documents)
