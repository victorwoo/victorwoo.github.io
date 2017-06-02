---
layout: post
title: "Visual Studio的PowerShell扩展工具"
date: 2013-09-28 00:00:00
description: PowerShell Tools for Visual Studio - PowerShell integration for Visual Studio
categories: powershell
tags:
- powershell
- visualstudio
- develop
- tool
- ide
- extension
---
Visual Studio的PowerShell扩展工具为Visual Studio 2012和2013 RC增加了PowerShell语言支持。

本工具目前为BETA版。

下载地址：[Visual Studio工具库][1]
开源项目：[GitHub][2]

必须条件：

* Visual Studio 2012或2013 RC
* PowerShell 3.0
	* Windows 8和Server 2012已自带
	* Windows 8或Server 2012以下的系统需要[Windows Management Framework 3.0][3]

编辑器扩展
=========

语法高亮、智能感知和代码折叠
-------------------------
![Syntax highlighting, IntelliSense and code folding](/img/2013-09-28-powershell-tools-for-visual-studio-001.png)

方法导航
-------
![Function navigation](/img/2013-09-28-powershell-tools-for-visual-studio-002.png)

调试器扩展
=========

脚本输出
-------
![Script Output](/img/2013-09-28-powershell-tools-for-visual-studio-003.png)

断点支持
-------
![Breakpoint Support](/img/2013-09-28-powershell-tools-for-visual-studio-004.png)

本地变量支持
-----------
![Locals Support](/img/2013-09-28-powershell-tools-for-visual-studio-005.png)

调用堆栈支持
-----------
![Stack Frame Support](/img/2013-09-28-powershell-tools-for-visual-studio-006.png)

工程系统支持
===========
![Project System Support](/img/2013-09-28-powershell-tools-for-visual-studio-007.png)

[1]: http://visualstudiogallery.msdn.microsoft.com/c9eb3ba8-0c59-4944-9a62-6eee37294597 "PowerShell Tools for Visual Studio"
[2]: https://github.com/adamdriscoll/poshtools "poshtools"
[3]: http://www.microsoft.com/en-us/download/details.aspx?id=34595 "Windows Management Framework 3.0"
