---
layout: post
date: 2021-04-21 00:00:00
title: "PowerShell 技能连载 - 查找系统路径"
description: PowerTip of the Day - Finding System Paths
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有时，脚本需要知道用户桌面或开始菜单等的路径。这些路径可能会有所不同，尤其是在用户使用 OneDrive 时。要找到当前系统路径，请使用以下代码：

```powershell
PS> [Environment]::GetFolderPath('Desktop')
C:\Users\tobia\OneDrive\Desktop
```

您可以使用 `[System.Environment+SpecialFolder]` 类型中定义的所有常量：

```powershell
PS> [Enum]::GetNames([System.Environment+SpecialFolder])
Desktop
Programs
MyDocuments
Personal
Favorites
Startup
Recent
SendTo
StartMenu
MyMusic
MyVideos
DesktopDirectory
MyComputer
NetworkShortcuts
Fonts
Templates
CommonStartMenu
CommonPrograms
CommonStartup
CommonDesktopDirectory
ApplicationData
PrinterShortcuts
LocalApplicationData
InternetCache
Cookies
History

CommonApplicationData
Windows
System
ProgramFiles
MyPictures
UserProfile
SystemX86
ProgramFilesX86
CommonProgramFiles
CommonProgramFilesX86
CommonTemplates
CommonDocuments
CommonAdminTools
AdminTools
CommonMusic
CommonPictures
CommonVideos
Resources
LocalizedResources
CommonOemLinks
CDBurning
```

如果您知道该路径，并且想知道是否有可以使用的已注册系统路径，请尝试相反的方法并转储所有文件夹常量及其关联的路径：

```powershell
[Enum]::GetNames([System.Environment+SpecialFolder]) |
    ForEach-Object {
    # ...for each, create a new object with the constant, the associated path
    # and the code required to get that path
    [PSCustomObject]@{
        Name = $_
        Path = [Environment]::GetFolderPath($_)
    }
    }
```

结果看起来像这样：

    Name                   Path
    ----                   ----
    Desktop                C:\Users\tobia\OneDrive\Desktop
    Programs               C:\Users\tobia\AppData\Roaming\Microsoft\Windows\Start Menu\Pr...
    MyDocuments            C:\Users\tobia\OneDrive\Dokumente
    Personal               C:\Users\tobia\OneDrive\Dokumente
    Favorites              C:\Users\tobia\Favorites
    Startup                C:\Users\tobia\AppData\Roaming\Microsoft\Windows\Start Menu\Pr...
    Recent                 C:\Users\tobia\AppData\Roaming\Microsoft\Windows\Recent
    SendTo                 C:\Users\tobia\AppData\Roaming\Microsoft\Windows\SendTo
    StartMenu              C:\Users\tobia\AppData\Roaming\Microsoft\Windows\Start Menu
    MyMusic                C:\Users\tobia\Music
    MyVideos               C:\Users\tobia\Videos
    DesktopDirectory       C:\Users\tobia\OneDrive\Desktop
    MyComputer
    NetworkShortcuts       C:\Users\tobia\AppData\Roaming\Microsoft\Windows\Network Short...
    Fonts                  C:\WINDOWS\Fonts
    Templates              C:\Users\tobia\AppData\Roaming\Microsoft\Windows\Templates
    CommonStartMenu        C:\ProgramData\Microsoft\Windows\Start Menu
    CommonPrograms         C:\ProgramData\Microsoft\Windows\Start Menu\Programs
    CommonStartup          C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup
    CommonDesktopDirectory C:\Users\Public\Desktop
    ApplicationData        C:\Users\tobia\AppData\Roaming
    PrinterShortcuts       C:\Users\tobia\AppData\Roaming\Microsoft\Windows\Printer Short...
    LocalApplicationData   C:\Users\tobia\AppData\Local
    InternetCache          C:\Users\tobia\AppData\Local\Microsoft\Windows\INetCache
    Cookies                C:\Users\tobia\AppData\Local\Microsoft\Windows\INetCookies
    History                C:\Users\tobia\AppData\Local\Microsoft\Windows\History
    CommonApplicationData  C:\ProgramData
    Windows                C:\WINDOWS
    System                 C:\WINDOWS\system32
    ProgramFiles           C:\Program Files
    MyPictures             C:\Users\tobia\OneDrive\Bilder
    UserProfile            C:\Users\tobia
    SystemX86              C:\WINDOWS\SysWOW64
    ProgramFilesX86        C:\Program Files (x86)
    CommonProgramFiles     C:\Program Files\Common Files
    CommonProgramFilesX86  C:\Program Files (x86)\Common Files
    CommonTemplates        C:\ProgramData\Microsoft\Windows\Templates
    CommonDocuments        C:\Users\Public\Documents
    CommonAdminTools       C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Administr...
    AdminTools             C:\Users\tobia\AppData\Roaming\Microsoft\Windows\Start Menu\Pr...
    CommonMusic            C:\Users\Public\Music
    CommonPictures         C:\Users\Public\Pictures
    CommonVideos           C:\Users\Public\Videos
    Resources              C:\WINDOWS\resources
    LocalizedResources
    CommonOemLinks
    CDBurning              C:\Users\tobia\AppData\Local\Microsoft\Windows\Burn\Burn   #

<!--本文国际来源：[Finding System Paths](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/finding-system-paths)-->
