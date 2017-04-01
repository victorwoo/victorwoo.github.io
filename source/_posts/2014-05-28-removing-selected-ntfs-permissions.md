layout: post
title: "PowerShell 技能连载 - 移除选定的 NTFS 权限"
date: 2014-05-28 00:00:00
description: PowerTip of the Day - Removing Selected NTFS Permissions
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
您也许需要从 NTFS 权限中移除某些权限。我们假设您希望移除某个用户的所有权限，因为他已经离开了这个部门。

请注意：您当然可以针对每个用户组来维护 NTFS 权限，并且为每个用户设置权限通常不是个好主意。但是，常常需要针对单个用户设置权限，以下示例脚本不仅可以移除这些权限，并且通过一些小修改还能成为查找这些权限的审计工具。

以下是一个简单的示例脚本。通过设置 `$Path` 和 `$Filter`，脚本可以扫描 `$Path` 文件夹以及它的所有子文件夹中所有访问控制项和 `$Filter` 字符串相匹配的项目。它只会处理非继承的访问控制项。

输出结果中将被删除的访问控制项标记为红色；如果所有访问控制项和过滤器都不匹配，则显示绿色。如果脚本没有返回任何东西，那么表示您扫描的文件夹中没有直接的访问控制项。

    $Path = 'C:\somefolder
    $Filter = 'S-1-5-*'
    
    Get-ChildItem -Path C:\Obfuscated -Recurse -ErrorAction SilentlyContinue |
      ForEach-Object {
    
        $acl = Get-Acl -Path $Path 
        $found = $false
        foreach($acc in $acl.access ) 
        { 
            if ($acc.IsInherited -eq $false)
            {
                $value = $acc.IdentityReference.Value 
                if($value -like $Filter) 
                { 
                    Write-Host "Remove $Value from $Path " -ForegroundColor Red
                    $null = $ACL.RemoveAccessRule($acc) 
                    $found = $true
                } 
                else
                {
                  Write-Host "Skipped $Value from $Path " -ForegroundColor Green
                }
            }
        }
        if ($found)
        {
    # uncomment this to actually remove ACEs
    #        Set-Acl -Path $Path -AclObject $acl -ErrorAction Stop      
        }
    }

<!--more-->
本文国际来源：[Removing Selected NTFS Permissions](http://community.idera.com/powershell/powertips/b/tips/posts/removing-selected-ntfs-permissions)
