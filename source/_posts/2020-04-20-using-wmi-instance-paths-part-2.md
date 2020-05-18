---
layout: post
date: 2020-04-20 00:00:00
title: "PowerShell 技能连载 - 使用 WMI 实例路径（第 2 部分）"
description: PowerTip of the Day - Using WMI Instance Paths (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技能中，我们演示了了新的 `Get-CimInstance` 命令缺少 `Get-WmiObject` 能够返回的重要的 "`__Path`" 属性。现在让我们将此属性添加回 `Get-CimInstance` 中。

`Get-CimInstance` 返回的每个实例的类型均为 `[Microsoft.Management.Infrastructure.CimInstance]` 类型，因此可以用 `Update-TypeData` 向该类型添加新属性：

```powershell
$code = {
    # get key properties
    $keys = $this.psbase.CimClass.CimClassProperties.Where{$_.Qualifiers.Name -eq 'Key'}.Name
    $pairs = foreach($key in $keys)
    {
    '{0}="{1}"' -f $key, $this.$key
    }
    # add server name
    $path = '\\{0}\{1}:{2}.{3}' -f $this.CimSystemProperties.ServerName.ToUpper(),
    # add namespace
    $this.CimSystemProperties.Namespace.Replace("/","\"),
    # add class
    $this.CimSystemProperties.ClassName,
    # add key properties
    ($pairs -join ',')

    return $path
}

Update-TypeData -TypeName Microsoft.Management.Infrastructure.CimInstance -MemberType ScriptProperty -MemberName __Path -Value $code -Force
```

运行此代码后，所有 CIM 实例都将再次具有 `__Path` 属性。它略有不同，因为“新的” `__Path` 属性引用了所有键值。对于我们测试的所有用例，这都没有什么不同：

```powershell
PS> $old = Get-WmiObject -Class Win32_BIOS

PS> $new = Get-CimInstance -ClassName Win32_BIOS


PS> $old.__PATH
\\DESKTOP-8DVNI43\root\cimv2:Win32_BIOS.Name="1.0.13",SoftwareElementID="1.0.13",SoftwareElementState=3,TargetOperatingSystem=0,Version="DELL   - 20170001"

PS> $new.__Path
\\DESKTOP-8DVNI43\root\cimv2:Win32_BIOS.Name="1.0.13",SoftwareElementID="1.0.13",SoftwareElementState="3",TargetOperatingSystem="0",Version="DELL   - 20170001"


PS> [wmi]($old.__Path)

SMBIOSBIOSVersion : 1.0.13
Manufacturer      : Dell Inc.
Name              : 1.0.13
SerialNumber      : 4ZKM0Z2
Version           : DELL   - 20170001

PS> [wmi]($new.__Path)

SMBIOSBIOSVersion : 1.0.13
Manufacturer      : Dell Inc.
Name              : 1.0.13
SerialNumber      : 4ZKM0Z2
Version           : DELL   - 20170001
```

<!--本文国际来源：[Using WMI Instance Paths (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-wmi-instance-paths-part-2)-->

