---
layout: post
date: 2016-12-07 00:00:00
title: "PowerShell 技能连载 - 安全地对文本加解密"
description: PowerTip of the Day - Safely Encrypting and Decrypting Text
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您加密保密信息时，主要的问题是要寻找一个合适的密钥。一个特别安全的密钥是您的 Windows 身份，它和您的计算机身份绑定。这可以用来在特定的机器上加密敏感的个人信息。

以两个函数演示了如何实现：

```powershell
function Decrypt-Text
{
  
  param
  (
    [String]
    [Parameter(Mandatory,ValueFromPipeline)]
    $EncryptedText
  )
  process
  {
    $secureString = $EncryptedText | ConvertTo-SecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
    [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
  }
}

function Encrypt-Text
{
  
  param
  (
    [String]
    [Parameter(Mandatory,ValueFromPipeline)]
    $Text
  )
  process
  {
     $Text | 
       ConvertTo-SecureString -AsPlainText -Force | 
       ConvertFrom-SecureString
  }
}

'PowerShell Rocks' | Encrypt-Text 
'Hello, World!' | Encrypt-Text | Decrypt-Text
```

您可以将密文安全地保存到文件里。只有您可以读取并解密该文件，而且只能在加密用的电脑上完成。

<!--本文国际来源：[Safely Encrypting and Decrypting Text](http://community.idera.com/powershell/powertips/b/tips/posts/safely-encrypting-and-decrypting-text)-->
