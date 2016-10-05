layout: post
date: 2015-07-27 11:00:00
title: "PowerShell 技能连载 - 查找打开了 PowerShell 远程操作功能的计算机"
description: PowerTip of the Day - Finding Computers with PowerShell Remoting
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
在前一个技能中我们演示了如何如何测试一台计算机的端口。在安装了 Microsoft 免费的 RSAT 工具之后，您可以查询您的 Active Directory，并获取所有计算机用户的列表，或指定范围内的所有计算机账户（例如用 `-SearchBase` 限制在一个特定的 OU 中搜索）。

下一步，您可以使用该端口来测试这些计算机是否在线，以及 PowerShell 远程操作端口 5985 是否打开：

    #requires -Version 1 -Modules ActiveDirectory
    function Test-Port
    {
        Param([string]$ComputerName,$port = 5985,$timeout = 1000)
    
        try
        {
            $tcpclient = New-Object -TypeName system.Net.Sockets.TcpClient
            $iar = $tcpclient.BeginConnect($ComputerName,$port,$null,$null)
            $wait = $iar.AsyncWaitHandle.WaitOne($timeout,$false)
            if(!$wait)
            {
                $tcpclient.Close()
                return $false
            }
            else
            {
                # Close the connection and report the error if there is one
    
                $null = $tcpclient.EndConnect($iar)
                $tcpclient.Close()
                return $true
            }
        }
        catch
        {
            $false
        }
    }
    
    Get-ADComputer -Filter * |
    Select-Object -ExpandProperty dnsHostName |
    ForEach-Object {
        Write-Progress -Activity 'Testing Port' -Status $_
    } |
    Where-Object -FilterScript {
        Test-Port -ComputerName $_
    }

<!--more-->
本文国际来源：[Finding Computers with PowerShell Remoting](http://community.idera.com/powershell/powertips/b/tips/posts/finding-computers-with-powershell-remoting)
