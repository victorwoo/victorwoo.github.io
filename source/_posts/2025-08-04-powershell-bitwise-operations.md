---
layout: post
date: 2025-08-04 08:00:00
updated: 2025-08-04 08:00:00
title: "PowerShell 技能连载 - 位运算与标志管理"
description: PowerTip of the Day - Bitwise Operations and Flag Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- bitwise
- flags
- enum
---

_适用于 PowerShell 5.1 及以上版本_

位运算在脚本语言中往往被忽视，但在 Windows 管理中却无处不在——文件权限标志、注册表标志位、枚举类型的组合值、网络子网掩码计算。理解位运算不仅能读懂系统底层的标志值，还能编写更高效的状态管理代码。PowerShell 支持 `-band`（与）、`-bor`（或）、`-bxor`（异或）、`-bnot`（取反）等位运算符。

本文将讲解 PowerShell 中的位运算技巧和实际应用场景。

<!-- more -->

## 位运算基础

```powershell
# 位运算符
$a = 0b1100  # 12
$b = 0b1010  # 10

Write-Host "a = $a (二进制：$(ConvertTo-Binary $a))"
Write-Host "b = $b (二进制：$(ConvertTo-Binary $b))"
Write-Host "a -band b = $($a -band $b)  # 与运算（都是1才为1）"
Write-Host "a -bor b  = $($a -bor $b)   # 或运算（任一是1就为1）"
Write-Host "a -bxor b = $($a -bxor $b)  # 异或（不同为1）"
Write-Host "-bnot a   = $(-bnot $a)     # 取反"

# 辅助函数：显示二进制
function ConvertTo-Binary {
    param([int]$Value, [int]$Bits = 8)
    [Convert]::ToString($Value -band ([math]::Pow(2, $Bits) - 1), 2).PadLeft($Bits, '0')
}

# 移位运算
$val = 1
Write-Host "`n移位运算：" -ForegroundColor Cyan
Write-Host "1 -shl 0 = $($val -shl 0) = $(ConvertTo-Binary ($val -shl 0))"
Write-Host "1 -shl 1 = $($val -shl 1) = $(ConvertTo-Binary ($val -shl 1))"
Write-Host "1 -shl 2 = $($val -shl 2) = $(ConvertTo-Binary ($val -shl 2))"
Write-Host "1 -shl 3 = $($val -shl 3) = $(ConvertTo-Binary ($val -shl 3))"

# 检查特定位是否设置
function Test-BitFlag {
    param([int]$Value, [int]$Flag)
    return ($Value -band $Flag) -eq $Flag
}

$permissions = 6  # 二进制 110 = Read(4) + Write(2)
Write-Host "`n权限值 $permissions：" -ForegroundColor Cyan
Write-Host "  Read  (4)：$(Test-BitFlag $permissions 4)"
Write-Host "  Write (2)：$(Test-BitFlag $permissions 2)"
Write-Host "  Execute(1)：$(Test-BitFlag $permissions 1)"
```

执行结果示例：

```
a -band b = 8  # 与运算
a -bor b  = 14  # 或运算
a -bxor b = 6  # 异或
1 -shl 0 = 1 = 00000001
1 -shl 1 = 2 = 00000010
1 -shl 2 = 4 = 00000100
1 -shl 3 = 8 = 00001000

权限值 6：
  Read  (4)：True
  Write (2)：True
  Execute(1)：False
```

## 枚举标志位

```powershell
# 使用 [Flags] 属性创建位标志枚举
Add-Type -TypeDefinition @"
using System;

[Flags]
public enum FilePermissions {
    None    = 0,
    Read    = 1,
    Write   = 2,
    Execute = 4,
    Delete  = 8,
    All     = Read | Write | Execute | Delete
}
"@

# 组合标志
$perms = [FilePermissions]::Read -bor [FilePermissions]::Write
Write-Host "权限：$perms"
Write-Host "是否包含 Read：$($perms -band [FilePermissions]::Read)"
Write-Host "是否包含 Delete：$($perms -band [FilePermissions]::Delete)"

# 添加和移除标志
$perms = $perms -bor [FilePermissions]::Execute
Write-Host "添加 Execute：$perms"

$perms = $perms -band (-bnot [FilePermissions]::Write)
Write-Host "移除 Write：$perms"

# 使用 HasFlag 方法
$fullPerms = [FilePermissions]::All
Write-Host "`nAll 权限检查：" -ForegroundColor Cyan
Write-Host "  HasFlag Read：$($fullPerms.HasFlag([FilePermissions]::Read))"
Write-Host "  HasFlag Delete：$($fullPerms.HasFlag([FilePermissions]::Delete))"

# 服务启动类型标志
Add-Type -TypeDefinition @"
using System;

[Flags]
public enum ServiceCapabilities {
    None          = 0,
    CanStop       = 1,
    CanPause      = 2,
    CanShutdown   = 4,
    SupportsChange = 8
}
"@

$svcCaps = [ServiceCapabilities]::CanStop -bor [ServiceCapabilities]::CanShutdown
Write-Host "`n服务能力：$svcCaps"
Write-Host "可停止：$($svcCaps.HasFlag([ServiceCapabilities]::CanStop))"
Write-Host "可暂停：$($svcCaps.HasFlag([ServiceCapabilities]::CanPause))"
```

执行结果示例：

```
权限：Read, Write
是否包含 Read：Read
是否包含 Delete：0
添加 Execute：Read, Write, Execute
移除 Write：Read, Execute

All 权限检查：
  HasFlag Read：True
  HasFlag Delete：True

服务能力：CanStop, CanShutdown
可停止：True
可暂停：False
```

## 网络子网计算

```powershell
# 子网掩码计算
function Get-SubnetInfo {
    param([Parameter(Mandatory)][string]$CIDR)

    $parts = $CIDR -split '/'
    $ip = [System.Net.IPAddress]::Parse($parts[0])
    $prefixLength = [int]$parts[1]

    # 计算子网掩码
    $maskBytes = New-Object byte[] 4
    for ($i = 0; $i -lt 4; $i++) {
        if ($prefixLength -ge 8) {
            $maskBytes[$i] = 255
            $prefixLength -= 8
        } elseif ($prefixLength -gt 0) {
            $maskBytes[$i] = 256 - [math]::Pow(2, 8 - $prefixLength)
            $prefixLength = 0
        }
    }

    $mask = [System.Net.IPAddress]::new($maskBytes)

    # 网络地址
    $ipBytes = $ip.GetAddressBytes()
    $networkBytes = New-Object byte[] 4
    for ($i = 0; $i -lt 4; $i++) {
        $networkBytes[$i] = $ipBytes[$i] -band $maskBytes[$i]
    }
    $network = [System.Net.IPAddress]::new($networkBytes)

    # 广播地址
    $broadcastBytes = New-Object byte[] 4
    $wildcardBytes = New-Object byte[] 4
    for ($i = 0; $i -lt 4; $i++) {
        $wildcardBytes[$i] = 255 -bxor $maskBytes[$i]
        $broadcastBytes[$i] = $networkBytes[$i] -bor $wildcardBytes[$i]
    }
    $broadcast = [System.Net.IPAddress]::new($broadcastBytes)

    # 主机数量
    $hostBits = 32 - [int]$parts[1]
    $totalHosts = [math]::Pow(2, $hostBits)
    $usableHosts = $totalHosts - 2

    return [PSCustomObject]@{
        CIDR        = $CIDR
        Network     = $network.ToString()
        Mask        = $mask.ToString()
        Broadcast   = $broadcast.ToString()
        TotalHosts  = $totalHosts
        UsableHosts = $usableHosts
    }
}

# 子网计算示例
$subnets = @("192.168.1.0/24", "10.0.0.0/16", "172.16.0.0/28")
foreach ($subnet in $subnets) {
    $info = Get-SubnetInfo -CIDR $subnet
    Write-Host "$($info.CIDR) => 网络：$($info.Network) 掩码：$($info.Mask) 广播：$($info.Broadcast) 可用主机：$($info.UsableHosts)" -ForegroundColor Cyan
}
```

执行结果示例：

```
192.168.1.0/24 => 网络：192.168.1.0 掩码：255.255.255.0 广播：192.168.1.255 可用主机：254
10.0.0.0/16 => 网络：10.0.0.0 掩码：255.255.0.0 广播：10.0.255.255 可用主机：65534
172.16.0.0/28 => 网络：172.16.0.0 掩码：255.255.255.240 广播：172.16.0.15 可用主机：14
```

## 文件属性标志

```powershell
# 读取和设置文件属性（位标志）
$file = "C:\Windows\notepad.exe"
$attrs = [System.IO.File]::GetAttributes($file)
Write-Host "notepad.exe 属性：$attrs" -ForegroundColor Cyan

# 检查特定属性
if ($attrs -band [System.IO.FileAttributes]::ReadOnly) {
    Write-Host "  只读：是"
} else {
    Write-Host "  只读：否"
}

if ($attrs -band [System.IO.FileAttributes]::System) {
    Write-Host "  系统：是"
}

if ($attrs -band [System.IO.FileAttributes]::Hidden) {
    Write-Host "  隐藏：是"
}

# 设置文件属性
$testFile = "C:\Temp\test.txt"
Set-Content $testFile -Value "test" -Force

# 添加只读和隐藏属性
$attrs = [System.IO.FileAttributes]::ReadOnly -bor [System.IO.FileAttributes]::Hidden
[System.IO.File]::SetAttributes($testFile, $attrs)
Write-Host "`n已设置属性：$([System.IO.File]::GetAttributes($testFile))"

# 移除只读属性
$attrs = [System.IO.File]::GetAttributes($testFile)
$attrs = $attrs -band (-bnot [System.IO.FileAttributes]::ReadOnly)
[System.IO.File]::SetAttributes($testFile, $attrs)
Write-Host "移除只读后：$([System.IO.File]::GetAttributes($testFile))"

# 清理
Remove-Item $testFile -Force
```

执行结果示例：

```
notepad.exe 属性：ReadOnly, System
  只读：是
  系统：是

已设置属性：ReadOnly, Hidden
移除只读后：Hidden
```

## 注意事项

1. **负数位运算**：`-bnot` 对有符号整数产生负数结果，注意使用无符号类型或正确处理
2. **枚举格式**：`[Flags]` 枚举的 `ToString()` 会自动显示组合名称（如 "Read, Write"）
3. **移位限制**：PowerShell 的移位范围是 0-31（32 位），超过范围结果未定义
4. **权限掩码**：Linux 文件权限（755、644）就是经典的八进制位标志表示
5. **性能优势**：位运算检查多个标志比多次字符串比较更高效
6. **可读性**：位运算代码不易读，添加清晰的注释说明每一位的含义
