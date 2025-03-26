---
layout: post
date: 2022-05-12 00:00:00
title: "PowerShell 技能连载 - 清理硬盘（第 2 部分）"
description: PowerTip of the Day - Cleaning Hard Drive (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一篇文章中，我们介绍了 Windows 工具 cleanmgr 及其参数 `/sageset` 和 `/sagerun`，您可以用它们来定义和运行自动硬盘清理。

今天，我们将研究如何自定义 `cleanmgr.exe` 执行的实际清理任务。

此工具将所有配置存储在 Windows 注册表的这个位置：

    HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches

在下面，您可以找到 `cleanmgr` 可以执行的每项清理任务的关键。在上一个技能中，我们定义了这样的自定义清理任务（请记住，使用提升的管理员权限执行它）：

```powershell
PS> cleanmgr.exe /sageset:5388
```

这行命令打开一个对话框窗口，您可以在其中检查应绑定到已提交 ID 5388 的清理任务。

关闭对话框后，可以在 Windows 注册表中找到这些设置：

```powershell
# the ID you picked when saving the options:
$id = 5388

# the name of the reg value that stores your choices:
$flag = "StateFlags$id"

# the location where user choices are stored:
$path = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\*"

# get all subkeys where your user choice was enabled:
Get-Item -Path $path |
    Where-Object { $_.Property -contains $flag }  # contains your registry value (StateFlags5388)
    Where-Object { $_.GetValue($flag) -gt 0 }     # your registry value contains a number greater than 0
```

执行结果准确列出了您先前在选择对话框中检查的清理器模块：

    Name                           Property
    ----                           --------
    Active Setup Temp Folders      (default)      : {C0E13E61-0CC6-11d1-BBB6-0060978B2AE6}
                                   Autorun        : 1
                                   Description    : These files should no longer be needed. They were originally
                                                    created by a setup program that is no longer running.
                                   FileList       : *.tmp
                                   Flags          : {124, 0, 0, 0}
                                   Folder         : C:\Windows\msdownld.tmp|?:\msdownld.tmp
                                   LastAccess     : {2, 0, 0, 0}
                                   Priority       : 50
                                   StateFlags0001 : 2
                                   StateFlags0003 : 2
                                   StateFlags0033 : 0
                                   StateFlags6254 : 0
                                   StateFlags5388 : 2
    BranchCache                    (default)      : {DE661907-527D-4d6a-B6A6-EBC7F88D9B95}
                                   StateFlags0001 : 0
                                   StateFlags0003 : 0
                                   StateFlags0033 : 0
                                   StateFlags6254 : 0
                                   StateFlags5388 : 2
    D3D Shader Cache               (default)      : {D8D133CD-3F26-402F-86DA-90B710751C2C}
                                   Autorun        : 1
                                   ReserveIDHint  : 2
                                   StateFlags0001 : 0
                                   StateFlags0003 : 0
                                   StateFlags0033 : 0
                                   StateFlags6254 : 0
                                   StateFlags5388 : 2
    Delivery Optimization Files    (default)      : {4057C1AD-A51F-40BB-B960-22888CEB9812}
                                   Autorun        : 0
                                   Description    : @C:\WINDOWS\system32\domgmt.dll,-104
                                   Display        : @C:\WINDOWS\system32\domgmt.dll,-103
                                   Flags          : 128
                                   ReserveIDHint  : 2
                                   StateFlags0001 : 0
                                   StateFlags0003 : 0
                                   StateFlags0033 : 0
                                   StateFlags6254 : 0
                                   StateFlags5388 : 2
    Diagnostic Data Viewer         (default)        : {C0E13E61-0CC6-11d1-BBB6-0060978B2AE6}
    database files                 Autorun          : 0
                                   CleanupString    : rundll32.exe utcutil.dll,DiskCleanupEnd
                                   Description      : @C:\WINDOWS\system32\utcutil.dll,-302
                                   Display          : @C:\WINDOWS\system32\utcutil.dll,-301
                                   FileList         : *.*
                                   Flags            : 573
                                   Folder           : C:\ProgramData\Microsoft\Diagnosis\EventTranscript\
                                   IconPath         : C:\WINDOWS\system32\utcutil.dll,0
                                   PreCleanupString : rundll32.exe utcutil.dll,DiskCleanupStart
                                   Priority         : 100
                                   StateFlags0001   : 0
                                   StateFlags0003   : 0
                                   StateFlags0033   : 0
                                   StateFlags6254   : 0
                                   StateFlags5388   : 2
    Downloaded Program Files       (default)          : {8369AB20-56C9-11D0-94E8-00AA0059CE02}
                                   AdvancedButtonText : @C:\Windows\System32\occache.dll,-1072
                                   Autorun            : 1
                                   Description        : @C:\Windows\System32\occache.dll,-1071
                                   Display            : @C:\Windows\System32\occache.dll,-1070
                                   Priority           : {100, 0, 0, 0}
                                   StateFlags0001     : 2
                                   StateFlags0003     : 2
                                   StateFlags0033     : 0
                                   StateFlags6254     : 2
                                   StateFlags5388     : 2
    Internet Cache Files           (default)          : {9B0EFD60-F7B0-11D0-BAEF-00C04FC308C9}
                                   AdvancedButtonText : &View Files
                                   Autorun            : 1
                                   Description        : The Temporary Internet Files folder contains Web pages stored
                                                        on your hard disk for quick viewing.
                                                        Your personalized settings for Web pages will be left intact.
                                   Display            : Temporary Internet Files
                                   Priority           : 100
                                   StateFlags0001     : 2
                                   StateFlags0003     : 2
                                   StateFlags0033     : 0
                                   StateFlags6254     : 2
                                   StateFlags5388     : 2
    Language Pack                  (default)      : {191D5A6B-43B9-477A-BB22-656BF91228AB}
                                   Autorun        : 1
                                   StateFlags0001 : 0
                                   StateFlags0003 : 0
                                   StateFlags0033 : 0
                                   StateFlags6254 : 0
                                   StateFlags5388 : 2
    Old ChkDsk Files               (default)      : {C0E13E61-0CC6-11d1-BBB6-0060978B2AE6}
                                   Autorun        : 1
                                   FileList       : *.CHK
                                   Flags          : 288
                                   Folder         : ?:\FOUND.000|?:\FOUND.001|?:\FOUND.002|?:\FOUND.003|?:\FOUND.004|
                                                    ?:\FOUND.005|?:\FOUND.006|?:\FOUND.007|?:\FOUND.008|?:\FOUND.009
                                   IconPath       : C:\WINDOWS\System32\DATACLEN.DLL,3
                                   Priority       : 50
                                   PropertyBag    : {60F6E464-4DEF-11d2-B2D9-00C04F8EEC8C}
                                   StateFlags0001 : 2
                                   StateFlags0003 : 2
                                   StateFlags0033 : 0
                                   StateFlags6254 : 2
                                   StateFlags5388 : 2
    Recycle Bin                    (default)      : {5ef4af3a-f726-11d0-b8a2-00c04fc309a4}
                                   PluginType     : 2
                                   StateFlags0001 : 2
                                   StateFlags0003 : 0
                                   StateFlags0033 : 0
                                   StateFlags6254 : 0
                                   StateFlags5388 : 2

每个清理器模块在 "(default)" 中具有唯一的GUID。 如您所见，GUID "{C0E13E61-0CC6-11d1-BBB6-0060978B2AE6}" 用于许多清理模块。这是一个通用的文件删除模块，您可以轻松地在自己的文件清理器模块中使用。只需在注册表键 `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches` 中添加新的子键，使用上面提到的 GUID，然后配置该清理器应找到并删除的文件。您可能需要查看现有的清理器，例如 regedit.exe 中的 "Old ChkDsk Files"，以找出定义要删除文件的注册表值的名称。

<!--本文国际来源：[Cleaning Hard Drive (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/cleaning-hard-drive-part-2)-->

