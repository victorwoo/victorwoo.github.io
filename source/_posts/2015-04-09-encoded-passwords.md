---
layout: post
date: 2015-04-09 11:00:00
title: "PowerShell 技能连载 - 对密码加密"
description: PowerTip of the Day - Encoded Passwords
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您确实需要在脚本中保存一个凭据对象，以下是将一个安全字符串转换为加密文本的方法：

    $password = Read-Host -Prompt 'Enter Password' -AsSecureString
    $encrypted = $password | ConvertFrom-SecureString
    $encrypted | clip.exe
    $encrypted

当运行这段代码时，会要求您输入密码。接下来密码会被转换为一系列字符并存入剪贴板中。加密的密钥是您的身份标识加上您的机器标识，所以只能用相同机器的相同用户对密码解密。

下一步，用这段代码可以将您的密码密文转换为凭据对象：

    $secret = '01000000d08c9ddf0115d1118c7a00c04fc297eb01000000d4a6c6bfcbbb75418de6e9672d85e73600...996f8365c8c82ea61f94927d3e3b14000000c6aecec683717376f0fb18519f326f6ac9cd89dc'
    $username = 'test\user'

    $password = $secret | ConvertTo-SecureString

    $credential = New-Object -TypeName System.Management.Automation.PSCredential($username, $password)

    # example call
    Start-Process notepad -Credential $credential -WorkingDirectory c:\

将加密的密码字符串写入脚本中，然后使用指定的用户名来验证身份。

现在，`$cred` 中保存的凭据对象可以在任何支持 `-Credential` 参数的 cmdlet 或函数中使用了。

<!--本文国际来源：[Encoded Passwords](http://community.idera.com/powershell/powertips/b/tips/posts/encoded-passwords)-->
