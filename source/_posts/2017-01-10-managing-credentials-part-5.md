layout: post
date: 2017-01-10 00:00:00
title: "PowerShell 技能连载 - 管理凭据（第五部分）"
description: PowerTip of the Day - Managing Credentials (Part 5)
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
当 PowerShell 自动加密一个安全字符串时，它使用您的身份作为密钥。只有您可以解密该安全字符串。而如果您想用一个共享的密码来加密一段安全字符串，会怎么样呢？

以下是一个经典的做法，用密码来加密：

```powershell
# $secretKey MUST be of length 8 or 16
# anyone who knows the secret can decrypt the password 
$secretKey = 'mysecretmysecret'
$password = 'myPassword'

$SecureString = ConvertTo-SecureString -String $password -AsPlainText -Force
$RandomSecureString = ConvertTo-SecureString -String $secretKey -AsPlainText -Force
$encryptedPassword = ConvertFrom-SecureString -SecureString $SecureString -SecureKey $RandomSecureString
$encryptedPassword
```

该密钥 (`$secretKey`) 必须是 8 或 16 个字符的文本。任何知道密钥的人都可以解密（这就是为何 secretKey 不应该是脚本的一部分，而下面的脚本下方加入了硬编码的密钥是为了延时解密的过程。最好以交互的方式输入密钥）：

```powershell
# this is the key to your secret
$secretKey = 'mysecretmysecret'
# this is the encrypted secret as produced by the former code
$encryptedPassword = '76492d1116743f0423413b16050a5345MgB8AEMARQAxAFgAdwBmAHcARQBvAGUAKwBOAGoAYgBzAE4AUgBnAHoARABSAHcAPQA9AHwANQA3ADYAMABjAGYAYQAwAGMANgBkADQAYQBiADYAOAAyAGYAZAA5AGYAMwA5AGYAYQBjADcANQA5ADIAYwAzADkAMAA2ADQANwA1ADcAMQA3ADMAMwBmAGMAMwBlADIAZQBjADcANgAzAGQAYQA1AGIAZABjADYAMgA2AGQANAA='

$RandomSecureString = ConvertTo-SecureString -String $secretKey -AsPlainText -Force
$securestring = $encryptedPassword | ConvertTo-SecureString -SecureKey $RandomSecureString
# Result is a secure string
$SecureString
```

结果是一个安全字符串，您可以用它来构建一个完整的凭据：

```powershell
$credential = New-Object -TypeName PSCredential('yourcompany\youruser', $SecureString)
$credential
```

您也可以再次检查密码明文：


    PS C:\Users\tobwe> $credential.GetNetworkCredential().Password
    myPassword

请注意安全字符串的所有者（创建它的人）总是可以取回明文形式的密码。这并不是一个安全问题。创建安全字符串的人在过去的时刻已经知道了密码。安全字符串保护第三方的敏感数据，并将它以其他用户无法接触到的形式保存到内存中。

密钥和对称加密算法的问题是您需要分发密钥，而密钥需要被保护，它既可以用来加密也可以用来解密。

在 PowerShell 5 中有一个简单得多的方法：`Protect-CMSMessage` 和 `Unprotect-CMSMessage`，它们使用数字证书和非对称加密。通过这种方法，加密安全信息的一方无需知道解密的密钥，反之亦然。加密的一方只需要制定谁（哪个证书）可用来解密保密信息。

<!--more-->
本文国际来源：[Managing Credentials (Part 5)](http://community.idera.com/powershell/powertips/b/tips/posts/managing-credentials-part-5)
