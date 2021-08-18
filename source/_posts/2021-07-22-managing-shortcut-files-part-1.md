---
layout: post
date: 2021-07-22 00:00:00
title: "PowerShell 技能连载 - 管理快捷方式文件（第 1 部分）"
description: PowerTip of the Day - Managing Shortcut Files (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 可以创建新的 LNK 文件并在旧 COM 对象的帮助下编辑现有文件。

让我们首先在开始菜单中的任何位置找到所有 LNK 文件：

```powershell
[Environment]::GetFolderPath('StartMenu') | Get-ChildItem -Filter *.lnk -Recurse
```

这样可以获取到在开始菜单中任何位置找到的所有 LNK 文件。

接下来，让我们读取它们并找出它们的目标和隐藏的键盘快捷键（如果有）：

```powershell
[Environment]::GetFolderPath('StartMenu') |
  Get-ChildItem -Filter *.lnk -Recurse |
  ForEach-Object { $scut = New-Object -ComObject WScript.Shell } {
    $scut.CreateShortcut($_.FullName)
  }
```

COM 对象 WScript.Shell 提供了一个名为 `CreateShortcut()` 的方法，当您传入现有 LNK 文件的路径时，您将返回其内部属性。

在我的环境下，这些 LNK 文件看起来类似于：

    FullName         : C:\Users\tobia\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Visual Studio Code\Visual Studio Code.lnk
    Arguments        :
    Description      :
    Hotkey           :
    IconLocation     : ,0
    RelativePath     :
    TargetPath       : C:\Users\tobia\AppData\Local\Programs\Microsoft VS Code\Code.exe
    WindowStyle      : 1
    WorkingDirectory : C:\Users\tobia\AppData\Local\Programs\Microsoft VS Code

    FullName         : C:\Users\tobia\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell (x86).lnk
    Arguments        :
    Description      : Performs object-based (command-line) functions
    Hotkey           :
    IconLocation     : %SystemRoot%\syswow64\WindowsPowerShell\v1.0\powershell.exe,0
    RelativePath     :
    TargetPath       : C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe
    WindowStyle      : 1
    WorkingDirectory : %HOMEDRIVE%%HOMEPATH%

    FullName         : C:\Users\tobia\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell ISE (x86).lnk
    Arguments        :
    Description      : Windows PowerShell Integrated Scripting Environment. Performs object-based (command-line) functions
    Hotkey           :
    IconLocation     : %SystemRoot%\system32\WindowsPowerShell\v1.0\powershell_ise.exe,0
    RelativePath     :
    TargetPath       : C:\WINDOWS\syswow64\WindowsPowerShell\v1.0\PowerShell_ISE.exe
    WindowStyle      : 1
    WorkingDirectory : %HOMEDRIVE%%HOMEPATH%

    FullName         : C:\Users\tobia\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell ISE.lnk
    Arguments        :
    Description      : Windows PowerShell Integrated Scripting Environment. Performs object-based (command-line) functions
    Hotkey           :
    IconLocation     : %SystemRoot%\system32\WindowsPowerShell\v1.0\powershell_ise.exe,0
    RelativePath     :
    TargetPath       : C:\WINDOWS\system32\WindowsPowerShell\v1.0\PowerShell_ISE.exe
    WindowStyle      : 1
    WorkingDirectory : %HOMEDRIVE%%HOMEPATH%

    FullName         : C:\Users\tobia\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell.lnk
    Arguments        :
    Description      : Performs object-based (command-line) functions
    Hotkey           :
    IconLocation     : %SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe,0
    RelativePath     :
    TargetPath       : C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
    WindowStyle      : 1
    WorkingDirectory : %HOMEDRIVE%%HOMEPATH%

    FullName         : C:\Users\tobia\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Zoom\Uninstall Zoom.lnk
    Arguments        : /uninstall
    Description      : Uninstall Zoom
    Hotkey           :
    IconLocation     : C:\Users\tobia\AppData\Roaming\Zoom\bin\Zoom.exe,0
    RelativePath     :
    TargetPath       : C:\Users\tobia\AppData\Roaming\Zoom\uninstall\Installer.exe
    WindowStyle      : 1
    WorkingDirectory :

<!--本文国际来源：[Managing Shortcut Files (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/managing-shortcut-files-part-1)-->

