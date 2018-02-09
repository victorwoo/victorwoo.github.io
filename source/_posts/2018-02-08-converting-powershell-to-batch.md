---
layout: post
date: 2018-02-08 00:00:00
title: "PowerShell 技能连载 - 将 PowerShell 脚本转换为批处理"
description: PowerTip of the Day - Converting PowerShell to Batch
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
以下是一个有趣的 PowerShell 脚本，名为 `Convert-PowerShellToBatch`。将 PowerShell 脚本的路径作为参数传给它，或者将 `Get-ChildItem` 的执行结果用管道传给它，来批量执行多个脚本。

该函数为每个脚本创建一个批处理文件。当您双击批处理文件时，将执行 PowerShell 代码。

```powershell
function Convert-PowerShellToBatch
{
    param
    (
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]
        [Alias("FullName")]
        $Path
    )

    process
    {
        $encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes((Get-Content -Path $Path -Raw -Encoding UTF8)))
        $newPath = [Io.Path]::ChangeExtension($Path, ".bat")
        "@echo off`npowershell.exe -NoExit -encodedCommand $encoded" | Set-Content -Path $newPath -Encoding Ascii
    }
}

Get-ChildItem -Path C:\path\to\powershell\scripts -Filter *.ps1 |
    Convert-PowerShellToBatch
```

当您查看某个生成的脚本文件时，您会发现 PowerShell 代码被转换为 BASE64 编码的字符串。所以这种转换适用于许多真实世界的需求：

* 双击执行一个批处理文件来运行 PowerShell 代码更方便。
* 没有经验的用户更不容易受诱惑去改动脚本，因为它经过 BASE64 编码。

申明：BASE64 并不是加密。将 BASE64 编码的文本转换为可读的明文是很简单的事。所以这里用的技术不适合用来隐藏秘密，例如密码。

<!--more-->
本文国际来源：[Converting PowerShell to Batch](http://community.idera.com/powershell/powertips/b/tips/posts/converting-powershell-to-batch)
