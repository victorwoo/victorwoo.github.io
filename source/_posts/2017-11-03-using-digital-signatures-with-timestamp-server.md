---
layout: post
date: 2017-11-03 00:00:00
title: "PowerShell 技能连载 - 结合时间戳服务器使用数字签名"
description: PowerTip of the Day - Using Digital Signatures with Timestamp Server
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
当您对脚本文件签名时，会希望签名保持完整，即便为它签名的证书将来过期了。关键的是证书在签名的时候是合法的。

要确保这一点，您需要一个受信的机构提供的时间戳服务器。通过这种方式，您不仅是对一个脚本签名，而且添加了签名的时间。在证书有效期内，一切没有问题。

我们调整了前一个技能中的代码，并且添加了一个时间戳服务器的 URL。以下代码对用户数据文件中所有未签名的脚本文件增加签名。如果您确定要对您的脚本文件增加签名，请移除 `-WhatIf` 参数：

```powershell
# read in the certificate from a pre-existing PFX file
$cert = Get-PfxCertificate -FilePath "$env:temp\codeSignCert.pfx"

# find all scripts in your user profile...
Get-ChildItem -Path $home\Documents -Filter *.ps1 -Include *.ps1 -Recurse -ErrorAction SilentlyContinue |
# ...that do not have a signature yet...
Where-Object {
  ($_ | Get-AuthenticodeSignature).Status -eq 'NotSigned'
  } |
# and apply one
# (note that we added -WhatIf so no signing occurs. Remove this only if you
# really want to add digital signatures!)
Set-AuthenticodeSignature -Certificate $cert -TimestampServer http://timestamp.digicert.com -WhatIf
```

<!--more-->
本文国际来源：[Using Digital Signatures with Timestamp Server](http://community.idera.com/powershell/powertips/b/tips/posts/using-digital-signatures-with-timestamp-server)
