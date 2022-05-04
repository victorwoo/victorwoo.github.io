---
layout: post
date: 2022-04-20 00:00:00
title: "PowerShell 技能连载 - 利用 WMI（第 3 部分）"
description: PowerTip of the Day - Leveraging WMI (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
新的 `Get-CimInstance` cmdlet 允许您在本地查询 WMI，并且（有限）支持远程查询：您可以指定 `-ComputerName` 参数，但不能使用替代凭据。

这是因为 `Get-CimInstance` 使用单独的网络会话进行远程访问，这为您提供了更多选择。例如，一旦您建立了一个网络会话，您就可以将它用于多个查询。以下是远程查询 WMI 信息的方法——从建立网络会话开始：

```powershell
# establish network session
$credential = Get-Credential -Message 'Your logon details'
$computername = '127.0.0.1'  # one or more comma-separated IP addresses or computer names
                                # note that IP addresses only work with NTFS authentication. 
                                # using computer names in AD is more secure (Kerberos)

$options = New-CimSessionOption -Protocol Wsman -UICulture en-us # optional
$session = New-CimSession -SessionOption $option -Credential $credential -ComputerName $computername

# output live session
$session
```

结果是一个或多个会话，每台指定计算机一个：

    Id           : 1
    Name         : CimSession1
    InstanceId   : e7790bc5-6b0d-4920-a6b9-d7b9676aae74
    ComputerName : 127.0.0.1
    Protocol     : WSMAN  

当您在 Active Directory 之外使用 IP 地址或计算机时，请确保您已在客户端计算机（而不是服务器）上启用了 NTFS 身份验证。以下代码激活 NTFS 身份验证并需要本地管理员权限：

```powershell
PS> Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value * -Force  
```

设置网络会话后，可以将其用于多个 WMI 查询：

```powershell
Get-CimInstance -ClassName Win32_BIOS -CimSession $session
Get-CimInstance -ClassName Win32_StartupCommand -CimSession $session 
```

完成后，永远不要忘记关闭网络会话，这样它就不会在服务器上驻留很长时间：

```powershell
Remove-CimSession -CimSession $session
```

<!--本文国际来源：[Leveraging WMI (Part 3)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/leveraging-wmi-part-3)-->

