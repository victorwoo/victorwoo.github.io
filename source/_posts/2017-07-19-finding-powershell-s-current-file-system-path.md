---
layout: post
date: 2017-07-19 00:00:00
title: "PowerShell 技能连载 - 查看 PowerShell 当前的文件系统路径"
description: "PowerTip of the Day - Finding PowerShell’s Current File System Path"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
To find out the path your PowerShell is currently using, simply run Get-Location:
要查看 PowerShell 的当前路径，只要用 `Get-Location` 命令即可：
     
```powershell
    PS> Get-Location
    
    Path          
    ----          
    C:\Users\tobwe
```

然而，当前路径不一定指向一个文件系统位置。如果您将位置指向注册表，例如这样：

```powershell     
    PS> cd hkcu:\ 
    
    PS> Get-Location
    
    Path  
    ----  
    HKCU:\
```

如果您想知道 PowerShell 当前使用的文件系统路径，而不管当前使用什么 provider，请使用以下代码：

```powershell     
    PS> $ExecutionContext.SessionState.Path
    
    CurrentLocation CurrentFileSystemLocation
    --------------- -------------------------
    HKCU:\          C:\Users\tobwe           
    
    
    
    PS> $ExecutionContext.SessionState.Path.CurrentFileSystemLocation
    
    Path          
    ----          
    C:\Users\tobwe 
    
    
    PS> Get-Location 
    
    Path  
    ----  
    HKCU:\
```

`CurrentFileSystemLocation` 总是返回文件系统的当前位置，这可能和 `Get-Location` 返回的不一样。

<!--本文国际来源：[Finding PowerShell’s Current File System Path](http://community.idera.com/powershell/powertips/b/tips/posts/finding-powershell-s-current-file-system-path)-->
