---
layout: post
date: 2016-02-16 12:00:00
title: "PowerShell 技能连载 - 谁在监听？（第二部分）"
description: PowerTip of the Day - Who is Listening? (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您的系统是 Windows 8 或 Windows Server 2012 或以上版本，您可以使用 `Get-NetTcpConnection` 来找出哪个网络端口正在使用中，以及谁在监听这些端口。

以下脚本不仅列出正在使用的端口而且列出了正在监听该端口的进程。如果进程是 "svchost"，该脚本还会找出是哪个服务启动了这个进程：

```powershell
#requires -Version 3 -Modules NetTCPIP

$service = @{}
$Process = @{
  Name = 'Name'
  Expression = {
    $id = $_.OwningProcess
    $name = (Get-Process -Id $id).Name 
    if ($name -eq 'svchost')
    {
      if ($service.ContainsKey($id) -eq $false)
      {
        $service.$id = Get-WmiObject -Class win32_Service -Filter "ProcessID=$id" | Select-Object -ExpandProperty Name
      }
      $service.$id -join ','
    }
    else
    {
      $name
    }
  }
}

Get-NetTCPConnection | 
Select-Object -Property LocalPort, OwningProcess, $Process | 
Sort-Object -Property LocalPort, Name -Unique
```

结果类似如下：

    LocalPort OwningProcess Name                                                   
    --------- ------------- ----                                                   
          135           916 RpcEptMapper,RpcSs                                     
          139             4 System                                                 
          445             4 System                                                 
         5354          2480 mDNSResponder                                          
         5985             4 System                                                 
         7680           544 Appinfo,BITS,Browser,CertPropSvc,DoSvc,iphlpsvc,Lanm...
         7779             4 System                                                 
        15292          7364 Adobe Desktop Service                                  
        27015          2456 AppleMobileDeviceService                               
    (...)

<!--本文国际来源：[Who is Listening? (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/who-is-listening-part-2)-->
