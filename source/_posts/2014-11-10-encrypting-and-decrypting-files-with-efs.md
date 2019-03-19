---
layout: post
date: 2014-11-10 12:00:00
title: "PowerShell 技能连载 - 用 EFS 加解密文件"
description: PowerTip of the Day - Encrypting and Decrypting Files with EFS
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 所有版本_

假设您的系统启用了 EFS (Encrypting File System)，并且您想将文件保存到一个 NTFS 盘中，那么以下是加密以及确保只有您可以读取该文件的方法：

    (Get-Item -Path 'C:\path..to..some..file.txt').Encrypt()

如果加密成功，那么在 explorer.exe 中将会显示为绿色而不是平常的黑色。用 `Decrypt()` 代替 `Encrypt()` 来撤销加密。

请注意需要事先设置了 EFS，并且您的公司可能需要一个集中存放的备份加密秘钥。

<!--本文国际来源：[Encrypting and Decrypting Files with EFS](http://community.idera.com/powershell/powertips/b/tips/posts/encrypting-and-decrypting-files-with-efs)-->
