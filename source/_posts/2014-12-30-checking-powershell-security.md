---
layout: post
date: 2014-12-30 12:00:00
title: "PowerShell 技能连载 - 检查 PowerShell 安全性"
description: PowerTip of the Day - Checking PowerShell Security
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 2.0 及以上版本_

这段代码在指定的驱动器里查找所有 PowerShell 脚本，然后检查这些脚本是否有合法的数字签名，并汇报哪些脚本没有签名，或签名非法：

    Get-ChildItem C:\ -Filter *.ps1 -Recurse |
      Where-Object { $_.Extension -eq '.ps1' } |
      Get-AuthenticodeSignature |
      Where-Object { $_.Status -ne 'Valid' }

“好吧”，也许您会辩论，“可是我们没有签名证书或 PKI”。这不是问题。数字签名只和信任有关。所以即便是用免费的自签名证书也可以信任。您只需要声明信任谁即可。

相对于依赖需要昂贵的官方代码签名的 Windows “根证书认证”，在您的内部安全审计中，您可以使用类似这样的自制方案：

    $whitelist = @('D3037720F7E5CF2A9DBA855B65D98C2FE1387AD9',
                   '6262A18EC19996DD521F7BDEAA0E079544B84241')

    Get-ChildItem y:\Advanced -Filter *.ps1 -Recurse |
      Where-Object { $_.Extension -eq '.ps1' } |
      Get-AuthenticodeSignature |
      Select-Object -ExpandProperty SignerCertificate |
      Where-Object { $whitelist -notcontains $_.Thumbprint -or $_.Status -eq 'HashMismatch'  }

只需要将任何您信任的证书的唯一的证书指纹添加到白名单中。该证书是否是自签名的并不重要。白名单是最重要的，并且它是您私人的“吊销列表”：如果您不再信任某个证书，或某个证书丢失了，只需要将它的指纹从您的白名单中移除即可。

生成的报告包括所有未使用您的白名单中的证书合法地签名的脚本。如果某个脚本使用白名单中的一个证书签过名，但是后来改变过，它也会出现在报告中。

<!--本文国际来源：[Checking PowerShell Security](http://community.idera.com/powershell/powertips/b/tips/posts/checking-powershell-security)-->
