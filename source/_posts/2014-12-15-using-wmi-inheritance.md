---
layout: post
date: 2014-12-15 12:00:00
title: "PowerShell 技能连载 - 使用 WMI 继承"
description: PowerTip of the Day - Using WMI Inheritance
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 所有版本_

WMI 类是彼此继承的，我们可以利用这个特性。例如这行代码：

    PS> Get-WmiObject -Class Win32_Printer 

它将返回通过 WMI 获取到的所有打印机。打印机是从更多的通用类继承的，这段代码可以显示继承树：

    PS> Get-WmiObject -Class Win32_Printer | Select-Object -ExpandProperty __derivation -First 1
    CIM_Printer
    CIM_LogicalDevice
    CIM_LogicalElement
    CIM_ManagedSystemElement 

所以如果您不只是对打印机感兴趣，而是对更多的硬件感兴趣，那么选择更通用的父类，例如 `CIM_LogicalDevice`。这行代码可以获取所有的硬件清单：

    PS> Get-WmiObject -Class CIM_LogicalDevice
    
    Manufacturer        Name                Status                       StatusInfo
    ------------        ----                ------                       ----------
    Realtek             Realtek High Def... OK                                    3
                        Kona                OK                                     
    Intel Corporation   Intel(R) 8 Serie... OK                                     
    Intel Corporation   Intel(R) Wireles...                                        
    Microsoft           Microsoft Kernel...                                        
                        ASIX AX88772B US...                                        
    Microsoft           Virtueller Micro...                                        
    Microsoft           Bluetooth-Gerät ...                                        
    Microsoft           Microsoft-ISATAP...                                        
                        Microsoft-ISATAP...                                        
    Microsoft           Teredo Tunneling...                                        
    Microsoft           Von Microsoft ge...                                        
                        Microsoft-ISATAP...                                        
                        Microsoft-ISATAP...                                        
                        Microsoft-ISATAP...                                        
                        Microsoft-ISATAP...                                        
                        ASIX AX88772B US...                                        
                        Microsoft-ISATAP...                                        
                        Microsoft-ISATAP...                                        
                        Virtueller Micro...                                        
                        Microsoft-ISATAP...                                        
                        Microsoft-ISATAP...                                        
                        Microsoft-ISATAP...                                        
    -Virtual Battery 0- CRB Battery 0   
    (...)        

这段代码将返回有关的类，这样的您就可以清晰地看到 WMI 如何调用您的硬件类型：

     
    PS> Get-WmiObject -Class CIM_LogicalDevice |
      Group-Object -Property __Class -NoElement
    
    Count Name                     
    ----- ----                     
        1 Win32_SoundDevice        
        1 Win32_Battery            
        1 Win32_IDEController      
       20 Win32_NetworkAdapter     
        1 Win32_PortableBattery    
       10 Win32_Printer            
        1 Win32_Processor          
        2 Win32_DiskDrive          
        7 Win32_DiskPartition      
        1 Win32_Fan                
        2 Win32_Keyboard           
        5 Win32_LogicalDisk        
        2 Win32_MappedLogicalDisk  
        1 Win32_MemoryArray        
        2 Win32_MemoryDevice       
        2 Win32_PointingDevice     
        1 Win32_SCSIController     
        2 Win32_USBController      
        6 Win32_USBHub             
        5 Win32_Volume             
        4 Win32_CacheMemory        
        1 Win32_DesktopMonitor     
        1 Win32_VideoController    
        1 Win32_VoltageProbe       
        1 Win32_MotherboardDevice  
        8 Win32_Bus                
      134 Win32_PnPEntity    
    

It basically takes all the instances derived from CIM_LogicalDevice and groups them by “__Class” which is their real class name.
它基本上获取从 `CIM_LogicalDevice` 继承的所有实例并按照“`__Class`”分组。这是它们的真实类名。

<!--本文国际来源：[Using WMI Inheritance](http://community.idera.com/powershell/powertips/b/tips/posts/using-wmi-inheritance)-->
