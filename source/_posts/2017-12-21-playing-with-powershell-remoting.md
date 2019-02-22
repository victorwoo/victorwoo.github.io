---
layout: post
date: 2017-12-21 00:00:00
title: "PowerShell 技能连载 - 使用 PowerShell 远程处理"
description: PowerTip of the Day - Playing with PowerShell Remoting
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您想试试 PowerShell 远程处理，您至少需要在目标机器（您希望访问的机器）上启用它。要使用它，您需要目标机器上的本地管理员特权。请用管理员特权打开 PowerShell，并且运行以下代码：

```powershell
#requires -RunAsAdministrator

# manually enable PowerShell remoting
Enable-PSRemoting -SkipNetworkProfileCheck -Force
```

接下来，在另一台能通过网络访问的计算机上，运行运行 PowerShell 远程处理的 "`Ping`" 来测试是否能连上目标机器：

```powershell
# "ping" for PowerShell remoting
# tests anonymously whether you can reach the target
$IPorNameTargetComputer = 'place name or IP address here'
Test-WSMan $IPorNameTargetComputer
```

当目标机器响应时，`Test-WSMan` 返回类似以下的文本。它进行了一个匿名测试，所以如果它失败了，您就知道防火墙或者目标机器的配置有问题。

    wsmid           : http://schemas.dmtf.org/wbem/wsman/identity/1/wsmanidentity.xsd
    ProtocolVersion : http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd
    ProductVendor   : Microsoft Corporation
    ProductVersion  : OS: 0.0.0 SP: 0.0 Stack: 3.0 

在下一个技能中，我们将看看能用 PowerShell 远程处理来做什么，以及如何远程执行脚本。

<!--本文国际来源：[Playing with PowerShell Remoting](http://community.idera.com/powershell/powertips/b/tips/posts/playing-with-powershell-remoting)-->
