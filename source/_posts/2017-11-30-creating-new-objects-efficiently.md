---
layout: post
date: 2017-11-30 00:00:00
title: "PowerShell 技能连载 - 高效创建新的对象"
description: PowerTip of the Day - Creating New Objects Efficiently
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
多数时候，大部分新对象都是静态数据，以属性的方式表示。一个特别有效的创建新的包含新属性的对象是将哈希表转换为对象——我们早些时候转换过：

```powershell
$conf = [PSCustomObject]@{
    Name = 'Tobias'
    Conf = 'psconf.eu'
    Url = 'http://psconf.eu'
}
```

输出的结果是一个简单的对象，没有任何特别的方法：

```powershell
PS C:\> $conf

Name   Conf      Url
----   ----      ---
Tobias psconf.eu http://psconf.eu
```

要增加方法，请在随后使用 `Add-Member` 修饰该对象。这行代码增加一个新的 `Register()` 方法：

```powershell
$object |
    Add-Member -MemberType ScriptMethod -Name Register -Value { Start-Process -FilePath $this.url }
```

请注意脚本块代码如何通过 `Register()` 方法来存取 `$this`：`$this` 变量代表对象自身，所以即便您晚些时候才决定改变 "`Url`" 属性，`Register()` 方法将仍然可以工作。

当您运行 `Register()` 方法，该对象打开 "`Url`" 属性指定的 URL：

```powershell
PS C:\> $conf.Register()
```

<!--本文国际来源：[Creating New Objects Efficiently](http://community.idera.com/powershell/powertips/b/tips/posts/creating-new-objects-efficiently)-->
