---
layout: post
date: 2019-08-06 00:00:00
title: "PowerShell 技能连载 - 接受屏蔽的密码"
description: PowerTip of the Day - Accepting Masked Passwords
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果曾经写过需要接受密码等敏感输入的 PowerShell 函数，请确保允许用户传入 SecureString。如果您通过明文接受密码，则存在很大的风险，即其他人可能在输入密码时看到密码，或者（更糟的是）密码已被记录，稍后可以在转储文件中找到。

下面是一个简单的框架，说明如何实现安全输入：

```powershell
function Enter-Secret
{
    param
    (
        [Parameter(Mandatory)]
        [SecureString]
        $SafeInput
    )

    $PlainText = [Management.Automation.PSCredential]::
    new('x',$SafeInput).GetNetworkCredential().Password

    "User entered $PlainText"

}
```

当用户运行 `Enter-Secret`，可以以屏蔽的方式输入密码。在内部，函数将安全字符串转换为纯文本。这样，秘密密码就永远不可见，也永远不会被记录下来。

从 SecureString 到 String 的转换是通过创建一个临时凭证对象来执行的。凭据对象有一个内置方法 (`GetNetworkCredential()`)，用于将SecureString 转换为字符串。

<!--本文国际来源：[Accepting Masked Passwords](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/accepting-masked-passwords)-->

