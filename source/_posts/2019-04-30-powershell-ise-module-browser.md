---
layout: post
date: 2019-04-30 00:00:00
title: "PowerShell 技能连载 - PowerShell ISE 模块浏览器"
description: PowerTip of the Day - PowerShell ISE Module Browser
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您在使用内置的 PowerShell ISE，您也许发现 "Module Browser Add-on" 很有用。它十分古老了，是 2015 年发布的，然而您可以方便滴从 PowerShell Gallery 中下载安装它：

```powershell
PS C:\> Install-Module ISEModuleBrowserAddOn -Repository PSGallery -Scope CurrentUser
```

当这个模块安装好，您就可以这样将它加载到 PowerShell ISE 中：

```powershell
PS C:\> Import-Module -Name ISEModuleBrowserAddon -Verbose
```

这将在 PowerShell 的右侧打开一个新的 Add-on 面板，其中有三个类别：Gallery，Favorites，以及 My Collection。

"Gallery" 将您连接到在线的 PowerShell Gallery，最初创建该库是为了帮助更容易地发现 PowerShell Gallery 中的在线内容。不过这部分看上去不能工作了。

不过当您点击 "My Collection" 时，将会获取到所有模块，并且当您双击列表中的一个模块时，可以获取模块中的内容，例如包含的命令。您也可以讲一个模块标注为 "Favorite"（它就会出现在 "Favorites" 列表中），卸载一个模块，或通过模块列表底部的按钮打开它。

通过顶部的 "New Module" 按钮，您可以创建一个新的空白 PowerShell 模块：一个向导将引导您完成采集元数据并将建有关文件的所有步骤。

<!--本文国际来源：[PowerShell ISE Module Browser](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/powershell-ise-module-browser)-->

