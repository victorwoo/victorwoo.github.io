---
layout: post
title: "PowerShell 技能连载 - 获取数据库连接字符串"
date: 2014-06-05 00:00:00
description: PowerTip of the Day - Getting Database Connection String
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
您是否疑惑过一个数据库的连接字符串到底长什么样？当您从控制面板中创建一个数据源时，一个向导将指引您完成整个创建过程。以下是一个利用这个向导并获取生成的连接字符串的方法。

请注意该向导的选择要依赖于您机器上所安装的数据库驱动。

    function Get-ConnectionString
    {

      $Path = Join-Path -Path $env:TEMP -ChildPath 'dummy.udl'

      $null = New-Item -Path $Path -ItemType File -Force

      $CommandArg = """$env:CommonProgramFiles\System\OLE DB\oledb32.dll"",OpenDSLFile "  + $Path


      Start-Process -FilePath Rundll32.exe -Argument $CommandArg -Wait
      $ConnectionString = Get-Content -Path $Path | Select-Object -Last 1
      $ConnectionString | clip.exe
      Write-Warning 'Connection String is also available from clipboard'
      $ConnectionString

    }

当您调用 `Get-ConnectionString` 方法时，将会创建一个临时的 udl 文件，并且用控制面板向导打开它。您可以通过向导完成配置。配置完成之后，PowerShell 将会检测临时文件并且返回连接字符串。

它的工作原理是 `Get-Process` 函数带了 `-Wait` 参数，它能够挂起脚本的执行，直到向导退出。在向导退出以后，脚本就可以安全地访问 udl 文件了。

<!--本文国际来源：[Getting Database Connection String](http://community.idera.com/powershell/powertips/b/tips/posts/getting-database-connection-string)-->
