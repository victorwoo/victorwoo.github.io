---
layout: post
date: 2019-10-17 00:00:00
title: "PowerShell 技能连载 - 加密文本（第 2 部分）"
description: PowerTip of the Day - Encrypting Text (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
这是我们的加密解密系列的第二部分。在第一部分中您学到了如何在一台计算机中安全地加密文本。现在我们来关注解密部分。

To successfully decrypt text, you must specify the same encoding that was used during encryption. Based on your encryption parameters, you must specify the same password, and based on the -Scope settings, decryption will work only for you and/or only on the same machine where you encrypted the text.

要正确地解密文本，必须指定加密时使用的相同编码。基于您的加密参数，您必须指定相同的密码。并且基于 `-Scope` 设置，解密将只能针对您和/或仅在您加密文本的同一机器上工作。

以下是 `Unprotect-Text` 函数。我们也从上一个技能中复制了 `Protect-Text` 函数，这样您可以方便地使用这两种功能：

```powershell
function Protect-Text
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [String]
        $SecretText,

        [string]
        $Password='',

        [string]
        [ValidateSet('CurrentUser','LocalMachine')]
        $scope = 'CurrentUser',

        [string]
        [ValidateSet('UTF7','UTF8','UTF32','Unicode','ASCII','Default')]
        $Encoding = 'Default',

        [Switch]
        $ReturnByteArray

    )
    begin
    {
        Add-Type -AssemblyName System.Security
        if ([string]::IsNullOrEmpty($Password))
        {
            $optionalEntropy = $null
        }
        else
        {
            $optionalEntropy = [System.Text.Encoding]::$Encoding.GetBytes($Password)
        }
    }
    process
    {
        try
        {
            $userData = [System.Text.Encoding]::$Encoding.GetBytes($SecretText)
            $bytes = [System.Security.Cryptography.ProtectedData]::Protect($userData, $optionalEntropy, $scope)
            if ($ReturnByteArray)
            {
                $bytes
            }
            else
            {
                [Convert]::ToBase64String($bytes)
            }
        }
        catch
        {
            throw "Protect-Text: Unable to protect text. $_"
        }
    }
}



function Unprotect-Text
{
    [CmdletBinding(DefaultParameterSetName='Byte')]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName="Text", Position=0)]
        [string]
        $EncryptedString,

        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName="Byte", Position=0)]
        [Byte[]]
        $EncryptedBytes,

        [string]
        $Password='',

        [string]
        [ValidateSet('CurrentUser','LocalMachine')]
        $scope = 'CurrentUser',

        [string]
        [ValidateSet('UTF7','UTF8','UTF32','Unicode','ASCII','Default')]
        $Encoding = 'Default'

    )
        begin
    {
        Add-Type -AssemblyName System.Security

        if ([string]::IsNullOrEmpty($Password))
        {
            $optionalEntropy = $null
        }
        else
        {
            $optionalEntropy = [System.Text.Encoding]::$Encoding.GetBytes($Password)
        }
    }
    process
    {
        try
        {
            if ($PSCmdlet.ParameterSetName -eq 'Text')
            {
                $inBytes = [Convert]::FromBase64String($EncryptedString)
            }
            else
            {
                $inBytes = $EncryptedBytes
            }
            $bytes = [System.Security.Cryptography.ProtectedData]::Unprotect($inBytes, $optionalEntropy, $scope)
            [System.Text.Encoding]::$Encoding.GetString($bytes)
        }
        catch
        {
            throw "Unprotect-Text: Unable to unprotect your text. Check optional password, and make sure you are using the same encoding that was used during protection."
        }
    }
}
```

以下是如何使用它的示例：

```powershell
$text = "This is my secret"

$a = Protect-Text -SecretText $text -scope CurrentUser -Password zumsel

Unprotect-Text -EncryptedString $a -scope CurrentUser -Password zumsel
```

`Protect-Text` 创建了一个 Base64 编码的字符串，它可以用 `Unprotect-Text` 函数来解密。如果您不希望额外的密码，那么只能使用基于 `-Scope` 的缺省的保护。

要节省空间，您可以使用字节数组来代替 Base64 编码的字符串：

```powershell
$b = Protect-Text -SecretText $text -scope CurrentUser -ReturnByteArray
Unprotect-Text -EncryptedBytes $b -scope CurrentUser
```

<!--本文国际来源：[Encrypting Text (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/encrypting-text-part-2)-->

