layout: post
title: "PowerShell 技能连载 - 添加或重置 NTFS 权限"
date: 2014-05-20 00:00:00
description: PowerTip of the Day - Adding and Resetting NTFS Permissions
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
当您需要为一个文件添加一个新的 NTFS 存取规则，或禁用继承并添加新的规则，以下是一个示例脚本，演示这个技巧并且为您提供一个模板。

这个脚本创建一个测试文件，然后以当前用户的身份定义一个新的存取规则。这个规则包含读取和写入权限。这个新规则被添加到已存在的安全描述符中。另外，将禁用继承。

    # create a sample file to apply security rules to
    $Path = "$env:temp\examplefile.txt"
    $null = New-Item -Path $Path -ItemType File -ErrorAction SilentlyContinue
    
    # use current user or replace with another user name
    $username = "$env:USERDOMAIN\$env:USERNAME"
    
    # define the new access rights
    $colRights = [System.Security.AccessControl.FileSystemRights]'Read, Write' 
    $InheritanceFlag = [System.Security.AccessControl.InheritanceFlags]::None 
    $PropagationFlag = [System.Security.AccessControl.PropagationFlags]::None 
    $objType =[System.Security.AccessControl.AccessControlType]::Allow 
    $objUser = New-Object System.Security.Principal.NTAccount($username) 
    
    # create new access control entry
    $objACE = New-Object System.Security.AccessControl.FileSystemAccessRule `
        ($objUser, $colRights, $InheritanceFlag, $PropagationFlag, $objType) 
    
    # get existing access control list for a file or folder
    $objACL = Get-Acl -Path $Path 
    
    # add rule
    $objACL.AddAccessRule($objACE) 
    
    # disable inheritance (if needed)
    $objACL.SetAccessRuleProtection($true, $false)
    
    # apply changed access control list to file
    Set-Acl -Path $Path -AclObject $objACL
    
    # show file in the File Explorer
    explorer.exe "/SELECT,$Path"
    
执行完成之后，该脚本在文件管理器中打开测试文件，并选中它。您可以右键单击该文件并选择 `属性` > `安全` 来查看新的设置。

要查看有哪些存取权限可用，请在 ISE 编辑器中键入以下这行：

![](/img/2014-05-20-adding-and-resetting-ntfs-permissions-001.png)

这将自动打开上下文菜单并列出所有可用的设置。

<!--more-->
本文国际来源：[Adding and Resetting NTFS Permissions](http://powershell.com/cs/blogs/tips/archive/2014/05/20/adding-and-resetting-ntfs-permissions.aspx)
