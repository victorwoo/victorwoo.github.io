layout: post
date: 2015-01-06 12:00:00
title: "PowerShell 技能连载 - 创建 NTFS 安全报告"
description: PowerTip of the Day - Creating NTFS Security Report
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
_适用于 PowerShell 所有版本_

如果您希望审计您文件系统中的 NTFS 权限，以下是您起步的建议。

这个脚本递归扫描 Windows 目录和子目录。只要将 `$Path` 替换为其它路径就可以扫描您文件系统的其它路径。

    $Path = 'C:\Windows'
    
    Get-ChildItem -Path $Path -Recurse -Directory -ErrorAction SilentlyContinue |
      ForEach-Object {
        $result = $_ | Select-Object -Property FullName, ExplicitePermissions, Count, Preview
        $result.ExplicitePermissions = (Get-Acl -Path $_.FullName -ErrorAction SilentlyContinue).Access | 
          Where-Object { $_.isInherited -eq $false }
        $result.Count = $result.ExplicitePermissions.Count
        $result.Preview = $result.ExplicitePermissions.IdentityReference -join ','
        if ($result.ExplicitePermissions.Count -gt 0)
        {
          $result
        }
      } | Out-GridView

该脚本读取每个子文件夹的安全描述符并查找非继承的安全控制项。如果找到了，那么就加这个信息加入文件夹对象。

结果将输出到一个网格视图窗口。如果您移除掉 `Out-GridView`，那么您会得到类似如下的信息：

    PS> G:\
    
    FullName                   ExplicitePermissions                          Count Preview                   
    --------                   --------------------                          ----- -------                   
    C:\windows\addins          {System.Security.Access...                        9 CREATOR OWNER,NT AUTHOR...
    C:\windows\AppPatch        {System.Security.Access...                        9 CREATOR OWNER,NT AUTHOR...
    C:\windows\Boot            {System.Security.Access...                        8 NT AUTHORITY\SYSTEM,NT ...
    C:\windows\Branding        {System.Security.Access...                        9 CREATOR OWNER,NT AUTHOR...
    C:\windows\Cursors         {System.Security.Access...                        9 CREATOR OWNER,NT AUTHOR...
    C:\windows\de-DE           {System.Security.Access...                        9 CREATOR OWNER,NT AUTHOR...
    C:\windows\diagnostics     {System.Security.Access...                        8 NT AUTHORITY\SYSTEM,NT ...
    C:\windows\Downloaded P... {System.Security.Access...                       11 CREATOR OWNER,NT AUTHOR...

您可以将这个例子作为更深入的工具的基础。例如，您可以将缺省受信任者（例如“CREATOR”，或“SYSTEM”）加入一个列表，并从结果中排除这个列表。

<!--more-->
本文国际来源：[Creating NTFS Security Report](http://community.idera.com/powershell/powertips/b/tips/posts/creating-ntfs-security-report)
