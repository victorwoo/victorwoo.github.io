---
layout: post
date: 2022-05-20 00:00:00
title: "PowerShell 技能连载 - 签名 PowerShell 脚本（第 2 部分）"
description: PowerTip of the Day - Code-Signing PowerShell Scripts (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技能中，我们解释了如何使用 `New-SeftSignedCert` 创建自签名的代码签名证书。今天，我们将使用自签名或公司代码签名证书真实地对 PowerShell 脚本进行数字签名。

为此，请使用您想要的任何 PowerShell 脚本文件。您所需要的只是它的路径。另外，您需要一个在 Windows 证书存储中存储的有效代码签名证书的路径。这是第一部分的快速回顾，以创建自签名证书，以防您没有公司证书：

```powershell
$Subject = 'MyPowerShellCode'
$FriendlyName = 'My Valid PowerShell Code'

# expires 5 years from now:
$ExpirationDate = (Get-Date).AddYears(5)

# store in user personal store:
$certStore = 'Cert:\CurrentUser\my'

# create certificate:
$cert = New-SelfSignedCertificate -Subject $Subject -Type CodeSigningCert -CertStoreLocation $certStore -FriendlyName $FriendlyName -NotAfter $ExpirationDate

$thumbprint = $cert.Thumbprint

$Path = Join-Path -Path $certStore -ChildPath $thumbprint
Write-Warning "Certificate Path: $Path"
```

运行此代码时，您将获得一个自签名的代码签名证书，并且该代码将返回生成证书的路径，即：

    Cert:\CurrentUser\my\F4C1F9978D564E143D554F3679746B3A79E1FF87   

要使用您的证书，请像这样通过 `Get-Item` 读取它（确保修改匹配证书的路径 - 每个证书都有唯一的指纹）：

```powershell
PS> $myCert = Get-Item -Path Cert:\CurrentUser\my\F4C1F9978D564E143D554F3679746B3A79E1FF87   
```

要将数字签名添加到 PowerShell 脚本文件（或其他能够为此问题携带数字签名的文件），请使用 `Set-AuthenticodeSignature`。运行以下演示代码（根据需要调整文件和证书的路径）：

```powershell
# digitally sign this file (adjust path to an existing ps1 file):
$Path = "$env:temp\test.ps1"

# adjust this path to point to a valid code signing certificate:
$CertPath = 'Cert:\CurrentUser\my\F4C1F9978D564E143D554F3679746B3A79E1FF87'

# if it does not exist, create a dummy file
$exists = Test-Path -Path $Path
if ($exists -eq $false)
{
    'Hello World!' | Set-Content -Path $Path -Encoding UTF8
}

# read a code signing certificate to use for signing:
$myCert = Get-Item -Path $CertPath

# add a digital signature to a PS script file:
Set-AuthenticodeSignature -FilePath $Path -Certificate $myCert

# show changes inside script file:
notepad $Path
```

运行此代码时，在 `$Path` 中指定的脚本文件将打开并显示添加到脚本底部的数字签名：

    Hello World!   
    
    # SIG # Begin signature block   
    # MIIFcAYJKoZIhvcNAQcCoIIFYTCCBV0CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB   
    # gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR   
    # AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU4QK+x7NLicgrIdzN+Nvxqbuq   
    # Qv2gggMKMIIDBjCCAe6gAwIBAgIQG5jphqHXvLJFA0oCJTgcpDANBgkqhkiG9w0B   
    ...

恭喜，您刚刚已经对一个 PowerShell 脚本进行了数字签名！我们将在第三部分中探讨这种签名的好处。

<!--本文国际来源：[Code-Signing PowerShell Scripts (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/code-signing-powershell-scripts-part-2)-->

