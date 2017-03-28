layout: post
date: 2016-09-07 00:00:00
title: "PowerShell 技能连载 - 检查（本地和远程的）硬盘容量"
description: PowerTip of the Day - Checking Hard Drive Size (Local and Remote)
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
WMI 可以提供硬盘的容量和剩余空间。PowerShell 会用返回这样的友好信息：

```powershell
PS C:\> # local
PS C:\> Get-HardDriveSize

DriveLetter Free(GB) Size(GB) Percent
----------- -------- -------- -------
C:             823,7    942,3    87,4


PS C:\> # remote
PS C:\> Get-HardDriveSize -ComputerName server2 -Credential server2\Tobias

DriveLetter Free(GB) Size(GB) Percent
----------- -------- -------- -------
C:              87,3    436,9      20
D:               5,3       25    21,3
```

以下是代码：

```powershell
function Get-HardDriveSize
{
  param
  (
    $ComputerName,

    $Credential
  )

  # get calculated properties:
  $prop1 = @{
    Name = 'DriveLetter'
    Expression = { $_.DeviceID }
  }

  $prop2 = @{
    Name = 'Free(GB)'
    Expression = { [Math]::Round(($_.FreeSpace / 1GB),1) }
  }

  $prop3 = @{
    Name = 'Size(GB)'
    Expression = { [Math]::Round(($_.Size / 1GB),1) }
  }

  $prop4 = @{
    Name = 'Percent'
    Expression = { [Math]::Round(($_.Freespace * 100 / $_.Size),1) }
  }

  # get all hard drives
  Get-CimInstance -ClassName Win32_LogicalDisk @PSBoundParameters -Filter "DriveType=3" | 
  Select-Object -Property $prop1, $prop2, $prop3, $prop4
}
```

<!--more-->
本文国际来源：[Checking Hard Drive Size (Local and Remote)](http://community.idera.com/powershell/powertips/b/tips/posts/checking-hard-drive-size-local-and-remote)
