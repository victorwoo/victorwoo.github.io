---
layout: post
date: 2018-06-07 00:00:00
title: "PowerShell 技能连载 - 使用秘密的 $FormatEnumerationLimit 变量"
description: PowerTip of the Day - Using Secret $FormatEnumerationLimit variable
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Format-List` 缺省以列表的形式显示对象的属性，如果某个属性包含一个数组，该数组将会转换为文本，而且只显示一小部分数组元素。以下是一个例子：

```powershell
PS> Get-Process -Id $Pid | Format-List -Property Name, Modules


Name    : powershell_ise
Modules : {System.Diagnostics.ProcessModule (PowerShell_ISE.exe),
            System.Diagnostics.ProcessModule (ntdll.dll), System.Diagnostics.ProcessModule
            (MSCOREE.DLL), System.Diagnostics.ProcessModule (KERNEL32.dll)...}
```

这行代码获取 PowerShell 的进程，并且显示它的名称和加载的模块。如您所见，输出的结果并没有显示所有加载的模块。

有一个名为 `FormatEnumerationLimit` 的神秘变量，控制 `Format-List` 显示多少个数组元素。

缺省情况下，显示个数限制为 4 个，所以输出结果中最多显示 4 个数组元素。如果将限制值设为 -1，事实上相当于关闭了该限制：

```powershell
PS> $FormatEnumerationLimit
4

PS> $FormatEnumerationLimit = -1

PS> $FormatEnumerationLimit
-1
```

如果您再次运行相同的命令，`Format-List` 将显示所有数组元素：

```powershell
PS> Get-Process -Id $Pid | Format-List -Property Name, Modules


Name    : powershell_ise
Modules : {System.Diagnostics.ProcessModule (PowerShell_ISE.exe),
        System.Diagnostics.ProcessModule (ntdll.dll), System.Diagnostics.ProcessModule
        (MSCOREE.DLL), System.Diagnostics.ProcessModule (KERNEL32.dll),
        System.Diagnostics.ProcessModule (KERNELBASE.dll), System.Diagnostics.ProcessModule
        (ADVAPI32.dll), System.Diagnostics.ProcessModule (msvcrt.dll),
        System.Diagnostics.ProcessModule (sechost.dll), System.Diagnostics.ProcessModule
        (RPCRT4.dll), System.Diagnostics.ProcessModule (mscoreei.dll),
        System.Diagnostics.ProcessModule (SHLWAPI.dll), System.Diagnostics.ProcessModule
        (combase.dll), System.Diagnostics.ProcessModule (ucrtbase.dll),
        System.Diagnostics.ProcessModule (bcryptPrimitives.dll),
        System.Diagnostics.ProcessModule (GDI32.dll), System.Diagnostics.ProcessModule
        (gdi32full.dll), System.Diagnostics.ProcessModule (msvcp_win.dll),
        System.Diagnostics.ProcessModule (USER32.dll), System.Diagnostics.ProcessModule
        (win32u.dll), System.Diagnostics.ProcessModule (IMM32.DLL),
        System.Diagnostics.ProcessModule (kernel.appcore.dll), System.Diagnostics.ProcessModule
        (VERSION.dll), System.Diagnostics.ProcessModule (clr.dll),
        System.Diagnostics.ProcessModule (MSVCR120_CLR0400.dll),
        System.Diagnostics.ProcessModule (mscorlib.ni.dll), System.Diagnostics.ProcessModule
        (ole32.dll), System.Diagnostics.ProcessModule (uxtheme.dll),
        System.Diagnostics.ProcessModule (tiptsf.dll), System.Diagnostics.ProcessModule
        (OLEAUT32.dll), System.Diagnostics.ProcessModule (CRYPTSP.dll),
        System.Diagnostics.ProcessModule (rsaenh.dll), System.Diagnostics.ProcessModule
        (bcrypt.dll), System.Diagnostics.ProcessModule (CRYPTBASE.dll),
(...)
```

<!--本文国际来源：[Using Secret $FormatEnumerationLimit variable](http://community.idera.com/powershell/powertips/b/tips/posts/using-secret-formatenumerationlimit-variable)-->
