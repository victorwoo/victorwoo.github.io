---
layout: post
date: 2021-11-29 00:00:00
title: "PowerShell 技能连载 - 使用 SOAP Webservice"
description: PowerTip of the Day - Using SOAP Webservices
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
尽管 SOAP 尚未广泛用于公共的 Webservice（通常使用更简单的 REST 服务），但在内部，许多公司确实将 SOAP 用于他们的 Webservice。

PowerShell 具有出色的 SOAP 支持，因此您无需大量复杂的代码即可连接和使用 SOAP Webservice。这是少数剩余的免费公共 SOAP Webservice 之一（将德语“bankleitzahl”翻译成银行详细信息）：

```powershell
$o = New-WebServiceProxy -Uri http://www.thomas-bayer.com/axis2/services/BLZService?wsdl
$o.getBank('25050180')
```

如您所见，要开始使用 SOAP Webservice，您需要 Webservice 提供的 WSDL URL。此网页以 XML 格式返回整个接口定义，`New-WebServiceProxy` 根据此信息创建包装 SOAP 数据类型所需的所有代码。

一旦您可以访问（任何）SOAP Webservice，您就可以使用以下代码来检查其方法：

```powershell
$o = New-WebServiceProxy -Uri http://www.thomas-bayer.com/axis2/services/BLZService?wsdl

# common methods
$blacklist = 'CreateObjRef', 'Dispose', 'Equals', 'GetHashCode', 'GetLifetimeService', 'InitializeLifetimeService', 'ToString', 'GetType'

# exclude async and common methods
$o | Get-Member -MemberType *method |
Where-Object Name -notlike '*Async*' |
Where-Object Name -notlike 'Begin*' |
Where-Object Name -notlike 'End*' |
Where-Object { $_.Name -notin $blacklist }
```

<!--本文国际来源：[Using SOAP Webservices](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-soap-webservices)-->

