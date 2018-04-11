---
layout: post
date: 2018-04-04 00:00:00
title: "PowerShell 技能连载 - 信任下载的文件"
description: PowerTip of the Day - Trusting Downloaded Scripts
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
通过 Internet 下载的脚本，很有可能被恶意软件感染过，或者源头是法非的数据来源。数字签名可以增加一个额外的信任和保护层。

作为示例，我们将测试官方的 "Chocolatey" 安装脚本，它的下载地址在这里：

    https://chocolatey.org/install.ps1
    

当您在浏览器中打开这个 URL 时，您将会看到一个十分长的 PowerShell 脚本，您现在需要十分谨慎地检查每一行代码，在运行它之前确保它是完整的，并且不会作恶。

幸运的是，在脚本的尾部您会发现一个非常长的注释块。这是一个数字签名。要检查是否能够信任该脚本，以及它是否未被篡改过，您需要将该代码保存到一个文件中。然后，您可以验证签名：

```powershell
# save script to file
$url = 'https://chocolatey.org/install.ps1'
$outPath = "$env:temp\installChocolatey.ps1"
Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $outPath

# test signature
Get-AuthenticodeSignature -FilePath $outPath
```

结果看起来类似这样：

        Directory: C:\Users\tobwe\AppData\Local\Temp
    
    
    SignerCertificate                         Status         Path                       
    -----------------                         ------         ----                       
    493018BA27EAA09B895BC5660E77F694B84877C7  Valid          installChocolatey.ps1


如果 "Status" 列报告 "Valid"，那么说明：

* 这个文件未被篡改过，是原始的内容
* 该文件是由 "SignerCertificate" 报告的证书创建的

当然您不能理解 "493018BA27EAA09B895BC5660E77F694B84877C7" 是谁，但您可以确定 Windows 认为该证书是可信任的，，所以您可以十分安全地运行这个脚本（如果您想了解 493018BA27EAA09B895BC5660E77F694B84877C7 到底是谁，请看明天的技能）。

以下是 "Status" 其它可能的情况：


* HashMismatch：文件内容被修改。这种情况高度可疑。
* Unknown：签名的证书不被信任。任何人都有可能签名了这个文件。这个签名对您没有任何意义。
* NotSigned：该脚本没有签名。

如果 `Status` 的值不是 `Valid`，那么该签名对您没有任何意义，在运行之前必须人工检查和测试代码。


如果 `Status` 的值是 `Valid`，那么您可以明确地确定创建脚本的人，而且您可以安全地认为它没有被其他人改过。不过，一个合法的签名并不是完全地保证，说明该脚本是无害的。

<!--more-->
本文国际来源：[Trusting Downloaded Scripts](http://community.idera.com/powershell/powertips/b/tips/posts/trusting-downloaded-scripts)
