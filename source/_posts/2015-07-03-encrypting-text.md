---
layout: post
date: 2015-07-03 04:00:00
title: "PowerShell 技能连载 - 加密文本"
description: PowerTip of the Day - Encrypting Text
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有很多办法可以加密文本。以下是一个未使用“密钥”的方法，所谓的密钥实际上是您的用户标识符加上机器名。

当您使用 `ConvertTo-TextEncrypted` 命令加密文本时，结果只能由同一个人在同一台机器上使用 `ConvertFrom-TextEncrypted` 命令来解密：

    #requires -Version 2


    function ConvertTo-TextEncrypted
    {
        param([Parameter(ValueFromPipeline = $true)]$Text)

        process
        {
            $Text |
            ConvertTo-SecureString -AsPlainText -Force |
            ConvertFrom-SecureString
        }
    }


    function ConvertFrom-TextEncrypted
    {
        param([Parameter(ValueFromPipeline = $true)]$Text)

        process
        {
            $SecureString = $Text |
            ConvertTo-SecureString

            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
            [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        }
    }

要测试效果，请先使用这行代码：

    PS> "Hello World" | ConvertTo-TextEncrypted | ConvertFrom-TextEncrypted
    Hello World

下一步，得到相同的密文，然后将它保存到一个文件中：

    $Path = "$env:temp\secret.txt"
    'Hello World' | ConvertTo-TextEncrypted | Set-Content -Path $Path

现在，使用这行代码来读取加密的文件，然后对它进行解密：

    $Path = "$env:temp\secret.txt"
    Get-Content -Path $Path | ConvertFrom-TextEncrypted

请注意两个脚本都不包含密码。而实际的密码正是你的用户标识符。当另一个人，或是您在另一台机器上试图解开文件中的密文，将会失败。

这个方法可以用来安全地保存个人密码，这样您就不用每天都输入了。

<!--本文国际来源：[Encrypting Text](http://community.idera.com/powershell/powertips/b/tips/posts/encrypting-text)-->
