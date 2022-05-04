---
layout: post
date: 2022-04-22 00:00:00
title: "PowerShell 技能连载 - 利用 WMI（第 4 部分）"
description: PowerTip of the Day - Leveraging WMI (Part 4)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
成功利用 WMI 的秘诀是知道代表您需求的类名。在上一个技能中，我们解释了如何使用 IntelliSense 向 `Get-CimInstance` 询问可用的类名。不过，您也可以以编程方式执行相同的操作。下面是转储默认命名空间 root\cimv2 的所有有效 WMI 类名称的代码：

```powershell
Get-CimClass | Select-Object -ExpandProperty CimClassName | Sort-Object
```

要检查给定的类名是否真的代表您要查找的内容，请执行一下测试查询。例如，要获取 Win32_OperatingSystem 的所有实例，请运行以下命令：

```powershell
PS> Get-CimInstance -ClassName Win32_OperatingSystem

SystemDirectory     Organization BuildNumber RegisteredUser SerialNumber            Version   
---------------     ------------ ----------- -------------- ------------            -------   
C:\WINDOWS\system32 psconf.eu    19042       Zumsel         12345-12345-12345-AAOEM 10.0.19042   
```

一些 WMI 类名是显而易见的，但其他则不是。要查看在任何给定类名中找到的属性，请尝试以下操作：

```powershell
Get-CimClass | 
    Select-Object -Property CimClassName, @{
    N='Properties'
    E={$_.CimClassProperties -join ','}
    } | 
    Out-GridView -PassThru
```

结果是一个显示 WMI 类名称及其属性名称的网格视图窗口。现在您可以使用网格视图窗口顶部的文本框过滤器来过滤任何关键字。仅列出在 WMI 类名称或其属性之一中包含您的关键字的行。

选择您感兴趣的类，然后单击左下角的“确定”将信息输出到控制台。接下来，您可以使用 `Get-CimInstance` 来测试查询您找到的 WMI 类名称。

<!--本文国际来源：[Leveraging WMI (Part 4)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/leveraging-wmi-part-4)-->

