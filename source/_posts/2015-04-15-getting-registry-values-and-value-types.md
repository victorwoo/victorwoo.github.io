---
layout: post
date: 2015-04-15 11:00:00
title: "PowerShell 技能连载 - 读取注册表键值和值类型"
description: PowerTip of the Day - Getting Registry Values and Value Types
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
`Get-ItemProperty` 可以方便地读取注册表键值，但是无法获得注册表键值的数据类型。

    Get-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion'

以下是通过 .NET 方法的另一种实现，可以获得所有的信息：

    PS> Get-RegistryValue 'HKLM\Software\Microsoft\Windows NT\CurrentVersion' 
    
    Name                     Type Value                                      
    ----                     ---- -----                                      
    CurrentVersion         String 6.1                                        
    CurrentBuild           String 7601                                       
    SoftwareType           String System                                     
    CurrentType            String Multiprocessor Free                        
    InstallDate             DWord 1326015519                                 
    RegisteredOrganization String                                            
    RegisteredOwner        String Tobias                                     
    SystemRoot             String C:\Windows                                 
    InstallationType       String Client                                     
    EditionID              String Ultimate                                   
    ProductName            String Windows 7 Ultimate                         
    ProductId              String 0042xxx657                    
    DigitalProductId       Binary {164, 0, 0, 0...}                          
    DigitalProductId4      Binary {248, 4, 0, 0...}                          
    CurrentBuildNumber     String 7601                                       
    BuildLab               String 7601.win7sp1_gdr.150202-1526               
    BuildLabEx             String 7601.18741.amd64fre.win7sp1_gdr.150202-1526
    BuildGUID              String f974f16b-3e62-4136-a6fb-64fccddecde3       
    CSDBuildNumber         String 1130                                       
    PathName               String C:\Windows                                 

我们需要开发一个 `Get-RegistryValue` 函数来实现该功能。请注意该函数可传入任意合法的注册表键，并且不需要使用 PowerShell 驱动器号。

    function Get-RegistryValue
    {
        param
        (
            [Parameter(Mandatory = $true)]
            $RegistryKey
        )
    
        $key = Get-Item -Path "Registry::$RegistryKey"
        $key.GetValueNames() |
        ForEach-Object {
            $name = $_
            $rv = 1 | Select-Object -Property Name, Type, Value
            $rv.Name = $name
            $rv.Type = $key.GetValueKind($name)
            $rv.Value = $key.GetValue($name)
            $rv
        }
    }

<!--more-->
本文国际来源：[Getting Registry Values and Value Types](http://community.idera.com/powershell/powertips/b/tips/posts/getting-registry-values-and-value-types)
