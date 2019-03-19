---
wlayout: post
date: 2015-02-02 12:00:00
title: "PowerShell 技能连载 - 凭据混淆器"
description: PowerTip of the Day - Credential Obfuscator
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell ISE 3.0 及以上版本_

虽然一般不建议将密码硬编码在脚本里，但有些情况下已经这么做了。相比于硬编码明文密码，一个最基本的改进是将密码混淆。密码混淆是一种弱的保护方式，但它能确保非掌握 PowerShell 知识的人员轻易地得到密码。

这是段小脚本会询问用户名和密码，然后生成一段混淆脚本来产生凭据对象。

当您运行下面这段脚本生成的脚本，在 `$cred` 变量将会保存一个包含用户名和密码的凭据对象，它可以用于任何带 `-Credential` 参数的 cmdlet。

    $cred = Get-Credential -Message 'Enter Domain\Username and Password'
    $pwd = $cred.Password
    $user = $cred.UserName
    $key = 1..32 | ForEach-Object { Get-Random -Maximum 256 }
    $pwdencrypted = $pwd | ConvertFrom-SecureString -Key $key

    $private:ofs = ' '

    $generatedScript = @()
    $generatedScript += '$password = ''{0}''' -f $pwdencrypted
    $generatedScript += '$key = ''{0}''' -f "$key"

    $generatedScript += '$passwordSecure = ConvertTo-SecureString -String $password -Key ([Byte[]]$key.Split('' ''))'
    $generatedScript += '$cred = New-Object system.Management.Automation.PSCredential(''{0}'', $passwordSecure)' -f $user
    $generatedScript += '$cred'

    $file = $psise.CurrentPowerShellTab.Files.Add()
    $file.Editor.Text = $generatedScript | Out-String
    $file.Editor.SetCaretPosition(1,1)

自动生成的密码脚本看起来类似这样：

    $password = '76492d1116743f0423413b16050a5345MgB8AHMAUQA3AFAAVwB0AGkAUQBUAC8AdwBqADYAUABVAFYAUwB4AEYAYgB4AFEAPQA9AHwAZgA0ADgAOQA4AGYANwA0AGEAMAA0ADUANwA5ADkAMwA5ADkAMwA1ADUANQA0AGYANwA5AGQANwBkAGYAOQBmAGEAYQA3ADMAYgBkADIAOQA3AGMAYQBmADUAMgA3ADEANwA3AGEAYgBmADAAYgA1AGYAYwAyADYAYgAzADkAOAA='
    $key = '187 98 34 82 148 52 13 86 246 2 130 197 217 97 147 98 75 197 149 246 74 35 27 7 211 15 131 93 182 231 171 3'
    $passwordSecure = ConvertTo-SecureString -String $password -Key ([Byte[]]$key.Split(' '))
    $cred = New-Object system.Management.Automation.PSCredential('mickey\mouse', $passwordSecure)
    $cred

<!--本文国际来源：[Credential Obfuscator](http://community.idera.com/powershell/powertips/b/tips/posts/credential-obfuscator)-->
