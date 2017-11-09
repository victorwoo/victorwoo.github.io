---
layout: post
date: 2017-11-01 00:00:00
title: "PowerShell 技能连载 - 从 PFX 文件加载证书"
description: PowerTip of the Day - Loading Certificates from PFX Files
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
在前一个技能中我们演示了如何使用 `New-SelfSignedCertificate` 来创建新的代码签名证书，并且将它们存储为一个 PFX 文件。今天让我们来看看如何加载一个 PFX 文件。

假设您的 PFX 文件存放在 `$env:temp\codeSignCert.pfx`。以下是读取该文件的代码：

```powershell
$cert = Get-PfxCertificate -FilePath "$env:temp\codeSignCert.pfx"
```

这段代码执行时，将会提示输入密码。这个密码是您创建证书时输入的密码，并且它保护这个文件不被滥用。

当命令成功执行以后，可以从 `$cert` 变量获取证书详细信息：

```powershell
PS C:\> $cert

Thumbprint                                Subject
----------                                -------
5D8A325641CC583F882B439833961AE9BCDEC946  CN=SecurityDepartment



PS C:\> $cert | Select-Object -Property *


EnhancedKeyUsageList     : {Code Signing (1.3.6.1.5.5.7.3.3)}
DnsNameList              : {SecurityDepartment}
SendAsTrustedIssuer      : False
EnrollmentPolicyEndPoint : Microsoft.CertificateServices.Commands.EnrollmentEndPointProperty
EnrollmentServerEndPoint : Microsoft.CertificateServices.Commands.EnrollmentEndPointProperty
PolicyId                 :
Archived                 : False
Extensions               : {System.Security.Cryptography.Oid, System.Security.Cryptography.Oid, System.Security.Cryptography.Oid}
FriendlyName             : IT Sec Department
IssuerName               : System.Security.Cryptography.X509Certificates.X500DistinguishedName
NotAfter                 : 9/29/2022 12:57:28 AM
NotBefore                : 9/29/2017 12:47:28 AM
HasPrivateKey            : True
PrivateKey               : System.Security.Cryptography.RSACryptoServiceProvider
PublicKey                : System.Security.Cryptography.X509Certificates.PublicKey
RawData                  : {48, 130, 3, 10...}
SerialNumber             : 45C8C7871DC392A44AD1ADD28FFDFAC7
SubjectName              : System.Security.Cryptography.X509Certificates.X500DistinguishedName
SignatureAlgorithm       : System.Security.Cryptography.Oid
Thumbprint               : 5D8A325641CC583F882B439833961AE9BCDEC946
Version                  : 3
Handle                   : 2832940980736
Issuer                   : CN=SecurityDepartment
Subject                  : CN=SecurityDepartment
```

证书对象包含了一系列方法：

```powershell
PS C:\> $cert | Get-Member -MemberType *Method


    TypeName: System.Security.Cryptography.X509Certificates.X509Certificate2

Name                            MemberType Definition
----                            ---------- ----------
Dispose                         Method     void Dispose(), void IDisposable.Dispose()
Equals                          Method     bool Equals(System.Object obj), bool Equals(X509Certificate other)
Export                          Method     byte[] Export(System.Security.Cryptography.X509Certificates.X509ContentType contentType), byte[] Export(System.Sec...
GetCertHash                     Method     byte[] GetCertHash()
GetCertHashString               Method     string GetCertHashString()
GetEffectiveDateString          Method     string GetEffectiveDateString()
GetExpirationDateString         Method     string GetExpirationDateString()
GetFormat                       Method     string GetFormat()
GetHashCode                     Method     int GetHashCode()
GetIssuerName                   Method     string GetIssuerName()
GetKeyAlgorithm                 Method     string GetKeyAlgorithm()
GetKeyAlgorithmParameters       Method     byte[] GetKeyAlgorithmParameters()
GetKeyAlgorithmParametersString Method     string GetKeyAlgorithmParametersString()
GetName                         Method     string GetName()
GetNameInfo                     Method     string GetNameInfo(System.Security.Cryptography.X509Certificates.X509NameType nameType, bool forIssuer)
GetObjectData                   Method     void ISerializable.GetObjectData(System.Runtime.Serialization.SerializationInfo info, System.Runtime.Serialization...
GetPublicKey                    Method     byte[] GetPublicKey()
GetPublicKeyString              Method     string GetPublicKeyString()
GetRawCertData                  Method     byte[] GetRawCertData()
GetRawCertDataString            Method     string GetRawCertDataString()
GetSerialNumber                 Method     byte[] GetSerialNumber()
GetSerialNumberString           Method     string GetSerialNumberString()
GetType                         Method     type GetType()
Import                          Method     void Import(byte[] rawData), void Import(byte[] rawData, string password, System.Security.Cryptography.X509Certifi...
OnDeserialization               Method     void IDeserializationCallback.OnDeserialization(System.Object sender)
Reset                           Method     void Reset()
ToString                        Method     string ToString(), string ToString(bool verbose)
Verify                          Method     bool Verify()
```

例如，如果您想验证证书是否合法，只需要调用 `Verify()` 方法。结果是一个布尔值，`$false` 代表证书不被 Windows 信任。

明天，我们将会使用证书对 PowerShell 脚本进行数字签名。

<!--more-->
本文国际来源：[Loading Certificates from PFX Files](http://community.idera.com/powershell/powertips/b/tips/posts/loading-certificates-from-pfx-files)
