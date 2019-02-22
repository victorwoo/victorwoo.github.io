---
layout: post
date: 2018-12-28 00:00:00
title: "PowerShell 技能连载 - 查看 Windows 通用唯一识别码 (UUID)"
description: PowerTip of the Day - Finding Windows Universal Unique Identifier (UUID)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
每个 Windows 的安装都有一个唯一的 UUID，您可以用它来区分机器。计算机名可能会改变，但 UUID 不会。

```powershell
PS> (Get-CimInstance -Class Win32_ComputerSystemProduct).UUID
4C4C4544-004C-4710-8051-C4C04F443732
```

In reality, the UUID is just a GUID (Globally Unique Identifier), which comes in different formats:
实际中，UUID 只是一个 GUID（全局唯一标识符），它的格式有所不同：

```powershell
$uuid = (Get-CimInstance -Class Win32_ComputerSystemProduct).UUID
[Guid]$guid = $uuid

"d","n","p","b","x" |
  ForEach-Object {
    '$guid.ToString("{0}") = {1}' -f $_, $guid.ToString($_)
  }
```

以下是执行结果：

    $guid.ToString("d")= 4c4c4544-004c-4710-8051-c4c04f443732
    $guid.ToString("n")= 4c4c4544004c47108051c4c04f443732
    $guid.ToString("p")= (4c4c4544-004c-4710-8051-c4c04f443732)
    $guid.ToString("b")= {4c4c4544-004c-4710-8051-c4c04f443732}
    $guid.ToString("x")= {0x4c4c4544,0x004c,0x4710,{0x80,0x51,0xc4,0xc0,0x4f,0x44,0x37,0x32}}

如果您希望为某个想标记的东西创建一个新的 UUID（或 GUID），例如临时文件名，那么可以用 PowerShell 5 新带来的 `New-Guid` 命令：

```powershell
PS> New-Guid

Guid
----
16750457-9a7e-4510-96ab-f9eef7273f3e
```

它实质上是在后台调用了这个 .NET 方法：

```powershell
PS> [Guid]::NewGuid()

Guid
----
  6cb3cb1a-b094-425b-8ccb-e74c2034884f
```

<!--本文国际来源：[Finding Windows Universal Unique Identifier (UUID)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/finding-windows-universal-unique-identifier-uuid)-->
