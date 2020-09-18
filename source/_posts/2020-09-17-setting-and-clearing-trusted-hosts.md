---
layout: post
date: 2020-09-17 00:00:00
title: "PowerShell 技能连载 - 设置和清除信任的主机"
description: PowerTip of the Day - Setting and Clearing Trusted Hosts
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 远程处理在客户端（发出命令并在服务器上进行身份验证的计算机）上维护受信任的 IP 地址和/或计算机名称的列表。此列表对您很重要，因为它控制着您如何对远程计算机进行身份验证。

默认情况下，PowerShell 仅支持 Kerberos 身份验证，因为它最安全，并且可以同时对客户端和服务器进行身份验证。但是，它需要一个 Active Directory，并且不能与 IP 地址一起使用。

```powershell
# execute PowerShell code remotely
Invoke-Command { Get-Service } -ComputerName storage2 -Credential AdminUser
```

在此示例中，AdminUser 必须是在 storage2 上具有适当权限才能访问的域帐户。

通过将 IP 地址和/或计算机名称添加到 TrustedHosts，您也可以使用 NTLM身份验证。这样，您可以使用本地帐户进行身份验证，并使用远程帐户访问独立系统，域外的系统以及通过IP地址指定的系统。

也允许使用通配符，因此当将 TrustedHosts 设置为 "*" 时，任何计算机都可以使用 NTLM 身份验证。但是，这并不太明智，因为现在黑客可以断开服务器并用另一台机器代替它来捕获密码，因为您不会注意到它不再是您要访问的机器。因此，仅对于您知道的位于“信任”的安全环境中的计算机，对 TrustedHosts 进行更改。

仅管理员和 WinRM 服务运行时才能访问 TrustedHosts 列表。启动提升的 PowerShell 环境，并确保 WinRM 服务正在运行：

```powershell
PS> Start-Service -Name WinRM
```

要查看 TrustedHosts 的当前内容，请运行以下命令：

```powershell
PS> Get-ChildItem -Path WSMan:\localhost\Client\TrustedHosts


    WSManConfig: Microsoft.WSMan.Management\WSMan::localhost\Client

Type            Name                           SourceOfValue   Value
----            ----                           -------------   -----
System.String   TrustedHosts
```

默认情况下，列表为空。要重置其内容（即指定IP范围），请使用 `Set-Item`：

```powershell
PS> Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value 192.168.* -Force
```

要添加更多条目，请添加 `-Concatenate` 参数。这将添加一个不同的计算机名称：

```powershell
PS> Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value storage2 -Concatenate -Force
```

现在尝试转储更改的内容。结果是一个逗号分隔的列表，支持通配符：

```powershell
PS> Get-ChildItem -Path WSMan:\localhost\Client\TrustedHosts


    WSManConfig: Microsoft.WSMan.Management\WSMan::localhost\Client

Type            Name                           SourceOfValue   Value
----            ----                           -------------   -----
System.String   TrustedHosts                                   192.168.*,storage2
```

要将 TrustedHosts 还原为默认值并将其清空，请使用 `Clear-Item` 命令：

```powershell
PS> Clear-Item -Path WSMan:\localhost\Client\TrustedHosts -Force
```

<!--本文国际来源：[Setting and Clearing Trusted Hosts](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/setting-and-clearing-trusted-hosts)-->

