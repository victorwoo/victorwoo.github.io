---
layout: post
date: 2019-10-03 00:00:00
title: "PowerShell 技能连载 - 将 SecureString 转换为文本"
description: PowerTip of the Day - Converting SecureString to Text
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
将加密的 SecureString 转换回纯文本非常有用。例如，通过这种方式，您可以使用 PowerShell 的“遮罩输入”特性。只需请求一个 SecureString, PowerShell 就会屏蔽用户输入的显示。接下来，将 SecureString 转换成纯文本，这样就可以在内部使用它来做任何您想做的事情：

```powershell
function Convert-SecureStringToText
{
  param
  (
    [Parameter(Mandatory,ValueFromPipeline)]
    [System.Security.SecureString]
    $Password
  )

  process
  {
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
  }
}

$password = Read-Host -Prompt 'Enter password' -AsSecureString
$plain = Convert-SecureStringToText -Password $password

"You entered: $plain"
```

如果你想知道为什么一开始就可以将 SecureString 转换成纯文本，那么请注意：SecureString 只保护第三方的字符串内容，即“中间人”攻击。它绝不是保护真正输入密码的人。

这也体现了为什么使用凭据有风险。当一个脚本请求凭据时，脚本总是可以获取整个密码：

```powershell
$cred = Get-Credential -UserName $env:USERNAME -Message 'Enter your password'
$plain = Convert-SecureStringToText -Password $cred.Password
"You entered: $plain"
```

实际上，通过凭据对象，要获取输入的密码更容易，因为它有一个内置的方法实现这个功能：

```powershell
$cred = Get-Credential -UserName $env:USERNAME -Message 'Enter your password'
$plain = $cred.GetNetworkCredential().Password
"You entered: $plain"
```

当一个脚本请求凭据时，请确保信任该脚本（的作者）。

<!--本文国际来源：[Converting SecureString to Text](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/converting-securestring-to-text)-->

