---
layout: post
title: "PowerShell 技能连载 - 检查 Windows 更新"
date: 2014-05-26 00:00:00
description: PowerTip of the Day - Checking Windows Updates
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
要检查 Windows 中安装的所有更新，有一个 COM 库可以帮您完成这个任务。但是这个库用起来不是很直观，而且也不支持远程。

所以我们设计了一个 PowerShell 函数，叫做 `Get-WindowsUpdate`。它默认情况下获取本地安装的更新，但是您也可以指定一个或多个远程计算机，并且获取它们的更新。

远程操作是借助 PowerShell 远程操作来实现的，所以只有远程计算机的 PowerShell 远程操作启用以后（例如，Windows Server 2012 默认启用 PowerShell 远程操作）才能使用，并且您需要远程计算机上的本地 Administrator 权限。

    function Get-WindowsUpdate
    {
      [CmdletBinding()]
      param
      (
        [String[]]
        $ComputerName,
        $Title = '*',
        $Description = '*',
        $Operation = '*'
      )
      
      $code = {
        param
        (
          $Title,
          $Description
        )
    
    
        $Type = @{
          name='Operation'
          expression={
        
        switch($_.operation)
        {
                1 {'Installed'}
                2 {'Uninstalled'}
                3 {'Other'}
        }
      }
    }
        
        $Session = New-Object -ComObject 'Microsoft.Update.Session'
        $Searcher = $Session.CreateUpdateSearcher()
        $historyCount = $Searcher.GetTotalHistoryCount()
        $Searcher.QueryHistory(0, $historyCount) | 
        Select-Object Title, Description, Date, $Type |
        Where-Object { $_.Title -like $Title } |
        Where-Object { $_.Description -like $Description } |
        Where-Object { $_.Operation -like $Operation }
      }
    
      $null = $PSBoundParameters.Remove('Title')
      $null = $PSBoundParameters.Remove('Description')
      $null = $PSBoundParameters.Remove('Operation')
    
      Invoke-Command -ScriptBlock $code @PSBoundParameters -ArgumentList $Title, $Description
    }

这个函数也支持过滤器，所以要获得所有已安装的 Office 更新，您只需要这样做：

![](/img/2014-05-26-checking-windows-updates-001.png)

<!--more-->
本文国际来源：[Checking Windows Updates](http://community.idera.com/powershell/powertips/b/tips/posts/checking-windows-updates)
