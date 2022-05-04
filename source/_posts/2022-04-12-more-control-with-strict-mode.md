---
layout: post
date: 2022-04-12 00:00:00
title: "PowerShell 技能连载 - More Control with Strict Mode"
description: PowerTip of the Day - More Control with Strict Mode
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有时，PowerShell 可能会出现意外行为。例如，当您输入一个不带引号的 IPv4 地址时，PowerShell 能够正常地接受它，但什么也不做。为什么？

```powershell
PS> 1.2.3.4 
```

在这种情况下，激活“严格模式”可能会有好处，当出现问题时会发出更严格的异常：

```powershell
PS> Set-StrictMode -Version Latest

PS> 1.2.3.4 
The property '3.4' cannot be found on this object. Verify that the property exists.
At line:1 char:1 
```

启用严格模式后，PowerShell 会这样解释输入“1.2.3.4”：获取到浮点数 1.2，然后查询其中的 "3" 属性和其中的 "4" 属性。当然，这些属性是不存在的。禁用严格模式后，PowerShell 不会抱怨不存在的属性，只会返回“什么也没有”。这就是所发生的事情。

启用严格模式还有助于识别代码中的拼写错误。只需确保您在脚本开发机器上专门启用严格模式即可。永远不要将它添加到生产代码中。严格模式只是脚本开发人员的帮手。一旦脚本完成并移交给其他用户，请不要将开发工具留在其中。

`Set-StrictMode` 永远不应该放在您的代码中（并且始终以交互方式输入或作为配置文件脚本的一部分）的原因很简单：其他 PowerShell 脚本开发人员可能故意选择依赖松散的异常，并且当您的脚本强制严格模式，它也适用于从那里使用的所有代码（和模块）。在生产中启用严格模式可能会使运行良好的代码突然产生过多的红色异常。

<!--本文国际来源：[More Control with Strict Mode](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/more-control-with-strict-mode)-->

