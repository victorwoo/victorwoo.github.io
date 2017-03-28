layout: post
title: "PowerShell 技能连载 - 存储秘密数据"
date: 2014-04-04 00:00:00
description: PowerTip of the Day - Storing Secret Data
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
如果您想以只有您能获取的方式保存敏感数据，您可以使用这个有趣的方法：将明文转换成密文，需要时将密文转换回明文，并将它保存到磁盘中：

    $storage = "$env:temp\secretdata.txt"
    $mysecret = 'Hello, I am safe.'
    
    $mysecret | 
      ConvertTo-SecureString -AsPlainText -Force |
      ConvertFrom-SecureString |
      Out-File -FilePath $storage

当您打开该文件的时候，它读起来像这个样子：

![](/img/2014-04-04-storing-secret-data-001.png)

您的秘密被 Windows 自带的数据保护 API(DPAPI) 用您的身份和机器作为密钥加密。所以只有您（或任何以您的身份运行的进程）可以将该密文解密，而且只能在加密时所用的计算机上解密。

要得到明文，请使用这段代码：

    $storage = "$env:temp\secretdata.txt"
    $secureString = Get-Content -Path $storage | 
      ConvertTo-SecureString
      
    $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToGlobalAllocUnicode($secureString)
    $mysecret = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($ptr) 
    
    $mysecret 

它可以正常使用——您可以获得和加密前一模一样的文本。

现在，以其他人的身份试一下。您会发现其他人无法解密该加密文件。而且您在别的机器上也无法解密。

<!--more-->
本文国际来源：[Storing Secret Data](http://community.idera.com/powershell/powertips/b/tips/posts/storing-secret-data)
