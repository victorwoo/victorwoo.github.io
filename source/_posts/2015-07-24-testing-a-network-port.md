---
layout: post
date: 2015-07-24 11:00:00
title: "PowerShell 技能连载 - 测试一个网络端口"
description: PowerTip of the Day - Testing a Network Port
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
这个 `Test-Port` 的测试函数可以通过一个网络端口测试一台远程的机器。它传入一个远程机器名（或 IP 地址），以及可选的端口号和和超时值。

缺省端口号是 5985，改端口用于 PowerShell 远程操作。缺省的超时值是 1000ms（1 秒）。

    #requires -Version 1
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

所以如果您希望知道一台远程计算机是否启用了 PowerShell 远程操作，您只需要运行：

    PS> Test-Port -ComputerName TestServer 
    False

由于缺省的超时值是 1 秒，您最多等待 1 秒就能等到响应。

<!--本文国际来源：[Testing a Network Port](http://community.idera.com/powershell/powertips/b/tips/posts/testing-a-network-port)-->
