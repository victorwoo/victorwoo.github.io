---
layout: post
title: "PowerShell 技能连载 - 设置注册表权限"
date: 2014-05-30 00:00:00
description: PowerTip of the Day - Setting Registry Permissions
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
设置注册表项的权限并不是一件小事。不过通过一些技巧，并不是一件大事。

首先，运行 `REGEDIT` 并创建一个测试项。然后，右击该项并且使用图形界面设置您想要的权限。

然后，运行这段脚本（请将 `-Path` 值设为您刚才定义的注册表项）：

    $path = 'HKCU:\software\prototype'
    $sd = Get-Acl -Path $Path
    $sd.Sddl | clip 

这段代码将从您的注册表项中读取安全信息并将它复制到剪贴板中。

接下来，使用这段脚本为新创建的或已有的注册表项应用相同的安全设置。只需要将这段脚本中的 SDDL 定义替换成您刚创建的值：

    # replace the content of this variable with the SDDL you just created
    $sddl = 'O:BAG:S-1-5-21-1908806615-3936657230-2684137421-1001D:PAI(A;CI;KR;;;BA)(A;CI;KA;;;S-1-5-21-1907506615-3936657230-2684137421-1001)'
    
    $Path = 'HKCU:\software\newkey'
    $null = New-Item -Path $Path -ErrorAction SilentlyContinue
    
    $sd = Get-Acl -Path $Path
    $sd.SetSecurityDescriptorSddlForm($sddl)
    Set-Acl -Path $Path -AclObject $sd

您可能需要以完整 Administrator 权限来运行这段脚本。如您所见，第一段脚本和您的测试注册表项只是用来生成 SDDL 文本。当您得到 SSDL 文本之后，您只需要将它粘贴入第二段脚本中。第二段脚本不再需要用到那个测试注册表项。

<!--本文国际来源：[Setting Registry Permissions](http://community.idera.com/powershell/powertips/b/tips/posts/setting-registry-permissions)-->
