layout: post
date: 2016-12-14 00:00:00
title: "PowerShell 技能连载 - 对启用 PIN 的用户使用 PowerShell Remoting"
description: PowerTip of the Day - Using PowerShell Remoting with PIN-enabled Accounts
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
如果您设置了 PIN 用来登录您的电脑，对您自己的机器使用 PowerShell remoting 可能会失败，提示如下奇怪的错误信息：

```
PS C:\>  Invoke-Command { "Hello" } -ComputerName $env:computername 
[DESKTOP-7AAMJLF]  Connecting to remote server DESKTOP-7AAMJLF failed with the following error  message : WinRM cannot process the request. The following error with  errorcode 0x8009030e occurred while using Negotiate authentication: A specified logon session does not exist. It may already have been terminated. 
 Possible causes are:
  -The user name or password specified are  invalid.
  -Kerberos is used when no authentication  method and no user name are specified.
  -Kerberos accepts domain user names, but not  local user names.
  -The Service Principal Name (SPN) for the  remote computer name and port does not exist.
  -The client and remote computers are in  different domains and there is no trust between the two domains.
 After checking for the above issues, try the  following:
  -Check the Event Viewer for events related to  authentication.
  -Change the authentication method; add the  destination computer to the WinRM TrustedHosts configuration setting or use  HTTPS transport.
 Note that computers in the TrustedHosts list  might not be authenticated.
  -For more information about WinRM  configuration, run the following command: winrm help config. For more  information, see the 
about_Remote_Troubleshooting  Help topic.
    + CategoryInfo          : OpenError: (DESKTOP-7AAMJLF:String)  [], PSRemotingTransportException
    + FullyQualifiedErrorId :  1312,PSSessionStateBroken
```

要解决这个问题，您可以有两个选择：

* 设置一个使用密码的用户账户（需要本地管理员权限）。然后，运行 `Invoke-Command` 的时候使用 `-Credential` 参数，然后指定账户和密码。
* 如果您的电脑没有加入域，那么您需要启用 Negotiate 认证来进行 PowerShell remoting 操作。，并且使用机器的 IP 地址而不是计算机名。

<!--more-->
本文国际来源：[Using PowerShell Remoting with PIN-enabled Accounts](http://community.idera.com/powershell/powertips/b/tips/posts/using-powershell-remoting-with-pin-enabled-accounts)
