---
layout: post
title: "PowerShell 技能连载 - 使用加密文件系统（EFS）来保护密码"
date: 2014-04-03 00:00:00
description: PowerTip of the Day - Using Encrypting File System (EFS) to Protect Passwords
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您必须在脚本中以硬编码的方式包含密码和其它隐私信息（正常情况下应避免使用），那么您还可以通过 EFS（加密文件系统）的方式来保障安全性。加密的脚本只能被加密者读取（和执行），所以只有您在自己的机器上能运行该脚本。

一下是加密一个 PowerShell 脚本的简单方法：

    # create some sample script
    # replace path with some real-world existing script if you want
    # and remove the line that creates the script
    $path = "$env:temp\test.ps1"
    "Write-Host 'I run only for my master.'" > $path
    
    $file = Get-Item -Path $path
    $file.Encrypt() 

当您运行这段脚本时，它将在您的临时文件夹中创建一个用 EFS 加密的新的 PowerShell 脚本（如果您见到一条错误提示信息，那么很有可能您机器上的 EFS 不可用或者被禁用了）。

加密之后，该文件在 Windows 资源管理器中呈现绿色，并且只有您能够运行它。别人无法看见源代码。

请注意在许多企业环境中，EFS 系统是通过恢复密钥部署的。指定的维护人员可以通过主密钥解密文件。如果没有主密钥，一旦您丢失了您的 EFS 证书，就连您也无法查看或运行加密的脚本。

<!--本文国际来源：[Using Encrypting File System (EFS) to Protect Passwords](http://community.idera.com/powershell/powertips/b/tips/posts/using-encrypting-file-system-efs-to-protect-passwords)-->
