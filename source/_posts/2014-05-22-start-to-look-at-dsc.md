layout: post
title: "PowerShell 技能连载 - 开始学习 DSC"
date: 2014-05-22 00:00:00
description: PowerTip of the Day - Start to Look at DSC
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
期望状态配置（DSC）是 PowerShell 4.0 中的一个新特性。通过 DSC，您可以编写简单的配置脚本并且将它们应用到本地或远程的机器上。以下是一个供您入门的示例脚本：

    Configuration MyConfig
    {
      # Parameters are optional
      param ($MachineName)
      # A Configuration block can have one or more Node blocks
      Node $MachineName
      {
        Registry RegistryExample
        {
          Ensure = 'Present' # You can also set Ensure to "Absent"
          Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\ExampleKey'
          ValueName ='TestValue'
          ValueData ='TestData'
        }
      }
    }
    
    MyConfig -MachineName $env:computername -OutputPath c:\dsc
    Start-DscConfiguration -Path c:\dsc -Wait 

配置项“MyConfig”使用了“Registry”资源来确保指定的注册表项存在。您可以在 DSC 脚本中使用更多的资源，例如增加（或删除）本地用户或文件，解压一个 MSI 包或 ZIP 文件，或启动/停止一个服务等等。

运行该配置只会创建一个 MOF 文件。要应用该 MOF 文件，请使用 `Start-DSCConfiguration` cmdlet。请使用 `-Wait` 来等待配置生效。否则，该配置将会在后台以任务的方式完成。

<!--more-->
本文国际来源：[Start to Look at DSC](http://community.idera.com/powershell/powertips/b/tips/posts/start-to-look-at-dsc)
