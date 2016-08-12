layout: post
date: 2016-02-16 12:00:00
title: "PowerShell 技能连载 - ___"
description: PowerTip of the Day - Who is Listening? (Part 2)
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
If you run at least Windows 8 or Windows Server 2012, you can use Get-NetTcpConnection to find out which network ports are in use, and who is listening on these ports.

The script below not only lists the ports in use but also the processes that do the listening. If the process is "svchost", the script finds out the names of the services that are run by this process:

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
    

The result may look similar to this:

      
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

<!--more-->
本文国际来源：[Who is Listening? (Part 2)](http://powershell.com/cs/blogs/tips/archive/2016/02/16/who-is-listening-part-2.aspx)
