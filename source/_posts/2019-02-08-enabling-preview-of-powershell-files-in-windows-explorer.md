---
layout: post
date: 2019-02-08 00:00:00
title: "PowerShell 技能连载 - 在资源管理器中启用预览 PowerShell 文件"
description: PowerTip of the Day - Enabling Preview of PowerShell Files in Windows Explorer
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
当您在 Windows 的资源管理器中打开预览窗格查看 PowerShell 脚本时，缺省情况下看不到脚本文件的代码预览。预览窗格是空白的。

要启用预览，只需要使用以下函数：

```powershell
function Enable-PowerShellFilePreview
{
    [CmdletBinding()]
    param
    (
        [string]
        $Font = 'Courier New',
        
        [int]
        $FontSize = 60
    )
    
    # set the font and size (also applies to Notepad)
    $path = "HKCU:\Software\Microsoft\Notepad"
    Set-ItemProperty -Path $path -Name lfFaceName -Value $Font
    Set-ItemProperty -Path $path -Name iPointSize -Value $FontSize
    
    # enable the preview of PowerShell files
    $path = 'HKCU:\Software\Classes\.ps1'
    $exists = Test-Path -Path $path
    if (!$exists){
        $null = New-Item -Path $Path
    }
    $path = 'HKCU:\Software\Classes\.psd1'
    $exists = Test-Path -Path $path
    if (!$exists){
        $null = New-Item -Path $Path
    }
    
    $path = 'HKCU:\Software\Classes\.psm1'
    $exists = Test-Path -Path $path
    if (!$exists){
        $null = New-Item -Path $Path
    }

    
    Get-Item HKCU:\Software\Classes\* -Include .ps1,.psm1,.psd1 | Set-ItemProperty -Name PerceivedType -Value text
}
```

运行这个函数后，使用这个命令：

```powershell
PS> Enable-PowerShellFilePreview
```

如果您喜欢的话，还可以改变预览的字体系列和字号。请注意该设置和记事本共享：

```powershell
PS> Enable-PowerShellFilePreview -Font Consolas -FontSize 100
```

不需要重启系统就可以生效。只需要确保 Windows 资源管理器的预览窗格可见，并选取一个 PowerShell 文件。

<!--more-->
本文国际来源：[Enabling Preview of PowerShell Files in Windows Explorer](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/enabling-preview-of-powershell-files-in-windows-explorer)
