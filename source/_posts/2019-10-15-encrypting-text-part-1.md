---
layout: post
date: 2019-10-15 00:00:00
title: "PowerShell 技能连载 - 加密文本（第 1 部分）"
description: PowerTip of the Day - Encrypting Text (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
让我们来看看一种在计算机上加密文本的安全方法。以下的 `Protect-Text` 函数接受任意文本，并自动加密，不需要密码。它不使用密码，而是使用您的用户帐户和机器，或者只使用您的机器作为密钥。

如果使用 `-Scope LocalMachine`，任何使用该机器的人都可以解密该文本，但如果该文本泄露给其他人，它无法在其它机器上解密。如果您使用 `-Scope CurrentUser`，只有加密者可以解密，并且只能在加密的机器上解密。这个加密方案很适合保存您的私人密码。

此外，为了提高安全性，可以在顶部添加（可选）密码。当指定了密码时，将应用上述相同的限制，但此外还需要知道密码才能解密文本。

请注意您也可以控制文本解码。请确保加密和解密使用相同的编码。

以下是加密函数：

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
```

结果类似这样：

```powershell
PS> Protect-Text -SecretText 'I am encrypted' -scope LocalMachine
AQAAANCMnd8BFdERjHoAwE/Cl+sBAAAAF8Hpm9A5A0upZysoxLlvgwQAAAACAAAAAAAQZgAAAAEAACAAAACbOsUoDuZJXNkWIzfAABxktVg+Txn7A8Rz
SCvFP7I9YQAAAAAOgAAAAAIAACAAAABz7G7Tpuoje9meLOuugzx1WSoOUfaBtGPM/XZHytjC8hAAAAApt/TDhJ9EqeWEPLIDkd4bQAAAAAN0Q503Pa7X
MxIMOnaO7qd3LKXJa4qhht+jc+Z0HaaV5/md83ipP1vefYAAUXdj8qv4eREeCBSGMqvKjbaOsOg=
```

如果您想了解如何将 Base64 编码的文本转换回原始文本，请看我们的下一个技能！

<!--本文国际来源：[Encrypting Text (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/encrypting-text-part-1)-->

