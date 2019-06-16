---
layout: post
date: 2019-06-03 00:00:00
title: "PowerShell 技能连载 - 使用代理服务器的缺省凭据"
description: PowerTip of the Day - Using Default Credentials for Proxy
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您的公司使用一个需要身份认证的代理服务器，PowerShell 可能有时候无法访问 Internet。您可能需要通知代理服务器使用凭据缓存中的缺省凭据：

```powershell
[System.Net.WebRequest]::DefaultWebProxy.Credentials=[System.Net.CredentialCache]::DefaultCredentials
```

<!--本文国际来源：[Using Default Credentials for Proxy](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-default-credentials-for-proxy)-->

