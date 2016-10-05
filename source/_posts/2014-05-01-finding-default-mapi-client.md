layout: post
title: "PowerShell 技能连载 - 查找缺省的 MAPI 客户端"
date: 2014-05-01 00:00:00
description: PowerTip of the Day - Finding Default MAPI Client
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
您机器上的 MAPI 客户端就是处理类似“mailto:” URL 的缺省电子邮件客户端。我们设计一个函数来查找是否有 MAPI 客户端，如果有的话，查看具体是哪一个。该函数从 Windows 注册表中获取这项信息：

    function Get-MAPIClient
    {
        function Remove-Argument
        {
          param
          (
            $CommandLine
          )
      
          $divider = ' '
          if ($CommandLine.StartsWith('"')) 
          { 
            $divider = '"'
            $CommandLine = $CommandLine.SubString(1)
          }
      
          $CommandLine.Split($divider)[0]
        } 
      
      $path = 'Registry::HKEY_CLASSES_ROOT\mailto\shell\open\command'
      
      # create new object to return values 
      $returnValue = 1 | Select-Object -Property HasMapiClient, Path, MailTo
      
      $returnValue.hasMAPIClient = Test-Path -Path $path
      
      if ($returnValue.hasMAPIClient)
      {
        $values = Get-ItemProperty -Path $path
        $returnValue.MailTo = $values.'(default)'
        $returnValue.Path = Remove-Argument $returnValue.MailTo 
        if ((Test-Path -Path $returnValue.Path) -eq $false)
        {
          $returnValue.hasMAPIClient = $true
        }
      }
      
      
      $returnValue
    } 
    
    Get-MAPIClient 

以下是使用结果：

![](/img/2014-05-01-finding-default-mapi-client-001.png)

<!--more-->
本文国际来源：[Finding Default MAPI Client](http://community.idera.com/powershell/powertips/b/tips/posts/finding-default-mapi-client)
