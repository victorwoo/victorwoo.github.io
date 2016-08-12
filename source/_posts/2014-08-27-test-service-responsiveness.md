layout: post
date: 2014-08-27 11:00:00
title: "PowerShell 技能连载 - 测试服务的响应性"
description: PowerTip of the Day - Test Service Responsiveness
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
_适用于 PowerShell 所有版本_

要测试某个服务是否仍然可响应，可以使用这个聪明的点子。首先，向 WMI 查询您想要检查的服务。WMI 将会开心地返回对应进程的 ID。

接下来，查询该进程。进程对象将会告知您该进程是冻结还是可响应的状态：

    function Test-ServiceResponding($ServiceName)
    {
      $service = Get-WmiObject -Class Win32_Service -Filter "Name='$ServiceName'"
      $processID = $service.processID
      
      $process = Get-Process -Id $processID
      
      $process.Responding
    }
    
这个例子将会检测 Spooler 服务是否可响应：
     
    PS> Test-ServiceResponding -ServiceName Spooler
    True
     
请注意，该示例代码假设服务正在运行。如果您想试试的话，您可以自己检测一下，排除非正在运行的服务。

<!--more-->
本文国际来源：[Test Service Responsiveness](http://powershell.com/cs/blogs/tips/archive/2014/08/27/test-service-responsiveness.aspx)
