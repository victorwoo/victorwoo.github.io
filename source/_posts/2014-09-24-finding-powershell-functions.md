layout: post
date: 2014-09-24 11:00:00
title: "PowerShell 技能连载 - 查找 PowerShell 函数"
description: 'PowerTip of the Day - Finding PowerShell Functions '
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
_适用于 PowerShell 3.0 或更高版本_

要快速扫描您的 PowerShell 脚本仓库并在其中查找某个函数，请使用以下过滤器：

    filter Find-Function
    {
       $path = $_.FullName
       $lastwrite = $_.LastWriteTime
       $text = Get-Content -Path $path
       
       if ($text.Length -gt 0)
       {
          
          $token = $null
          $errors = $null
          $ast = [System.Management.Automation.Language.Parser]::ParseInput($text, [ref] $token, [ref] $errors)
          $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) |
          Select-Object -Property Name, Path, LastWriteTime |
          ForEach-Object {
             $_.Path = $path
             $_.LastWriteTime = $lastwrite
             $_
          }
       }
    } 

以下是扫描您的用户配置文件中所有定义了函数的 PowerShell 脚本的方法：

  PS> dir $home -Filter *.ps1 -Recurse -Exclude *.ps1xml | Find-Function 
  
      Name                       Path                       LastWriteTime            
      ----                       ----                       -------------            
      Inject-LogonCredentials    C:\Users\Tobias\Desktop... 06.01.2014 02:43:00      
      Test-Command               C:\Users\Tobias\Desktop... 06.03.2014 10:17:02      
      Test                       C:\Users\Tobias\Desktop... 30.01.2014 09:32:20      
      Get-WebPictureOriginal     C:\Users\Tobias\Desktop... 11.12.2013 11:37:53      
      Get-ConnectionString       C:\Users\Tobias\Documen... 23.05.2014 10:49:09      
      Convert-SID2User           C:\Users\Tobias\Documen... 23.05.2014 15:33:06      
      Lock-Screen                C:\Users\Tobias\Documen... 19.03.2014 12:51:54      
      Show-OpenFileDialog        C:\Users\Tobias\Documen... 16.05.2014 13:42:16      
      Show-UniversalData         C:\Users\Tobias\Documen... 16.05.2014 13:23:20      
      Start-TimebombMemory       C:\Users\Tobias\Documen... 23.05.2014 09:12:28      
      Stop-TimebombMemory        C:\Users\Tobias\Documen... 23.05.2014 09:12:28      
      (...)
      

只需要将结果通过管道输出到 `Out-GridView` 就能查看完整的信息。

<!--more-->
本文国际来源：[Finding PowerShell Functions ](http://community.idera.com/powershell/powertips/b/tips/posts/finding-powershell-functions)
