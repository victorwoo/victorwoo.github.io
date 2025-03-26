---
layout: post
date: 2025-02-06 08:00:00
title: "PowerShell 技能连载 - 对象属性操作"
description: PowerTip of the Day - PowerShell Object Properties
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---

## 属性操作基础

```powershell
# 动态添加属性
$process = Get-Process -Id $PID
$process | Add-Member -MemberType NoteProperty -Name 'HostName' -Value $env:COMPUTERNAME

# 属性选择器
Get-Service | Select-Object -Property Name,Status,@{Name='Uptime';Expression={(Get-Date) - $_.StartTime}}
```

## 应用场景
1. **动态数据增强**：
```powershell
Get-ChildItem | ForEach-Object {
    $_ | Add-Member -MemberType ScriptProperty -Name SizeMB -Value { [math]::Round($this.Length/1MB,2) }
}
```

2. **自定义输出视图**：
```powershell
$diskInfo = Get-CimInstance Win32_LogicalDisk
$diskInfo | Select-Object DeviceID,VolumeName,
    @{Name='Total(GB)';Expression={$_.Size/1GB -as [int]}},
    @{Name='Free(%)';Expression={($_.FreeSpace/$_.Size).ToString("P")}}
```

## 最佳实践
1. 使用PSObject包装原生对象
```powershell
$rawObject = Get-WmiObject Win32_Processor
$customObj = [PSCustomObject]@{
    Name = $rawObject.Name
    Cores = $rawObject.NumberOfCores
    Speed = "$($rawObject.MaxClockSpeed)MHz"
}
```

2. 扩展方法实现属性验证
```powershell
class SecureProcess {
    [ValidatePattern("^\w+$")]
    [string]$ProcessName

    [ValidateRange(1,100)]
    [int]$Priority
}
```

3. 利用属性集提升效率
```powershell
Update-TypeData -TypeName System.IO.FileInfo -MemberType ScriptProperty 
    -MemberName Owner -Value { (Get-Acl $this.FullName).Owner }
```