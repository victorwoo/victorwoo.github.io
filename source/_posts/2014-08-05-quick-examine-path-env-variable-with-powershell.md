---
layout: post
title: 用 PowerShell 快速查看 PATH 环境变量
date: 2014-08-05 14:24:24
description: Quick examine path env variable with PowerShell
categories: powershell
tags:
- powershell
- geek
---
我们常常需要查看 `PATH` 环境变量里是否有我们需要的路径。通常的做法是：

1. 依次打开 系统属性 / 高级 / 环境变量。
2. 分别在“用户变量”和“系统变量”列表框中双击 PATH 条目。
3. 在“变量值”窄小的文本框中检视 PATH 变量的值。
4. 往往不得不把变量值复制粘贴到记事本中，再利用搜索功能来查找。

利用 PowerShell，可以告别以上笨拙的步骤：

    PS > (type env:path) -split ';'

这样就可以看到一个完美分割过的列表了。当然，利用 PowerShell 强大的查询功能，还可以进一步节省眼力。例如我们要查询所有包含“_bin_”的路径：

    PS > (type env:path) -split ';' | sls bin
    
    C:\PROGRAM FILES (X86)\JAVA\JDK1.7.0_45\JRE\BIN
    C:\PROGRAM FILES (X86)\INTEL\OPENCL SDK\2.0\BIN\X86
    C:\PROGRAM FILES (X86)\INTEL\OPENCL SDK\2.0\BIN\X64
    C:\PROGRAM FILES\MICROSOFT SQL SERVER\110\TOOLS\BINN\
    D:\greensoft\UnxUtils\usr\local\wbin\
    C:\Program Files\Microsoft SQL Server\120\Tools\Binn\
    C:\Program Files\TortoiseGit\bin
    C:\Chocolatey\bin
    c:\Program Files\MongoDB 2.6 Standard\bin
