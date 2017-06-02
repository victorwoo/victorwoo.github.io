---
layout: post
date: 2017-02-17 00:00:00
title: "PowerShell 技能连载 -用 JSON 缓存凭据"
description: PowerTip of the Day - Caching Credentials Using JSON
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
当您需要将登录凭据缓存到一个文件，通常的做法是用管道将凭据传给 `Export-Clixml` 命令，这将会产生一个很长的 XML 文件。使用 `Import-Clixml` 命令，缓存的凭据可以随时导回脚本中。PowerShell 自动使用用户和机器身份来加密密码（它只能被同一个人在同一台机器上读取）。

可以用 JSON 格式来做同样的事情，并且不会产生更多凌乱的文件。只有对密码加密的部分需要人工完成。

这个例子提示输入登录凭据，然后将它们保存到桌面的 "mycred.json" 文件中，然后在记事本中打开它们，这样您可以查看它的内容并确认密码是加密的：

```powershell
$path = "$home\Desktop\mycred.json"

$cred = Get-Credential
$cred |
  Select Username,@{n="Password"; e={$_.password | ConvertFrom-SecureString}} |
  ConvertTo-Json |
  Set-Content -Path $path -Encoding UTF8


notepad.exe $path

To later reuse the file and import the credential, use this:
$path = "$home\Desktop\mycred.json"

$o = Get-Content -Path $path -Encoding UTF8 -Raw | ConvertFrom-Json
$cred = New-Object -TypeName PSCredential $o.UserName,
  ($o.Password | ConvertTo-SecureString)

# if you entered a valid user credentials, this line
# will start Notepad using the credentials retrieved from
# the JSON file to prove that the credentials are
# working.
Start-Process notepad -Credential $cred
```

回头要使用该文件并导入凭据，请使用这段代码：

```powershell
$path = "$home\Desktop\mycred.json"

$o = Get-Content -Path $path -Encoding UTF8 -Raw | ConvertFrom-Json
$cred = New-Object -TypeName PSCredential $o.UserName,
  ($o.Password | ConvertTo-SecureString)

# if you entered a valid user credentials, this line
# will start Notepad using the credentials retrieved from
# the JSON file to prove that the credentials are
# working.
Start-Process notepad -Credential $cred
```

请注意这个例子将使用存储在 JSON 文件中的凭据来启动记事本的实例。如果您在第一个示例脚本中键入了非法的登录信息，以上操作显然会失败。

也请注意密码事是以加密的方式存储的。加密是以您的账户和机器作为密钥。所以保存的密码是经过安全加密的，但是这里展示的技术只适合同一个人（在同一台机器上）希望下次再使用保存的凭据。一个使用场景是保存再您自己机器上常用的脚本凭据。

<!--more-->
本文国际来源：[Caching Credentials Using JSON](http://community.idera.com/powershell/powertips/b/tips/posts/caching-credentials-using-json)
