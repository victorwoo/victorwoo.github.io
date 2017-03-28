layout: post
date: 2015-03-12 11:00:00
title: "PowerShell 技能连载 - 展开对象数据结构"
description: PowerTip of the Day - Unfolding Object Data Structure
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
_适用于 PowerShell 3.0 及以上版本_

对象有可能包含嵌套的属性，您所关心的数据可能在一个对象中的“某个地方”。

要显示某个对象的所有属性和展开后的子属性，可将它转换为 JSON。这能很好地以文本的方式展现嵌套的属性。

这个例子获取当前的 PowerShell 进程，然后将它转化为 JSON，然后将文本输出到剪贴板。然后就可以将内容粘贴到任意的文本编辑器：

    Get-Process -Id $pid  | ConvertTo-Json | clip.exe

要控制递归的深度，请使用 `ConvertTo-Json` 命令的 `-Depth` 参数。缺省值是 2（所以最多显示 2 层递归深度的内容）。

<!--more-->
本文国际来源：[Unfolding Object Data Structure](http://community.idera.com/powershell/powertips/b/tips/posts/unfolding-object-data-structure)
