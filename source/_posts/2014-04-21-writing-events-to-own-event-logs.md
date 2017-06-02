---
layout: post
title: "PowerShell 技能连载 - 将日志写入自定义的事件日志"
date: 2014-04-21 00:00:00
description: PowerTip of the Day - Writing Events to Own Event Logs
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
我们常常需要在脚本运行时记录一些信息。如果将日志信息写入文本文件，那么您需要自己维护和管理它们。您还可以使用 Windows 自带的日志系统，并享受它带来的各种便利性。

要达到这个目的，您只需要初始化一个您自己的日志。这只需要由管理员操作一次。操作方法是以管理员身份启动 PowerShell，然后输入一行代码：

![](/img/2014-04-21-writing-events-to-own-event-logs-001.png)

这样就好了。您现在有了一个可以记录“LogonScript”、“MaintenanceScript”和“Miscellaneous”事件源的日志文件。接下来，您可能只需再进行一些配置，告诉日志系统日志文件的最大容量，以及容量达到最大值的时候需要做什么操作即可：

![](/img/2014-04-21-writing-events-to-own-event-logs-002.png)

现在，您新的日志文件最大可增长到 500MB，并且记录在被新记录覆盖之前可以保持 30 天。

您现在可以关闭您的特权窗口。写日志文件并不需要特殊的权限，并且可以从任何普通的脚本或登录脚本中写入日志。所以打开一个普通的 PowerShell 控制台，然后输入以下代码：

![](/img/2014-04-21-writing-events-to-own-event-logs-003.png)

现在记录事件十分简单了，您可以根据需要选择任意的事件编号或消息。唯一的前提是只能写入已注册的事件源。

使用 `Get-EventLog`，您可以很方便地分析机器中的脚本问题：

![](/img/2014-04-21-writing-events-to-own-event-logs-004.png)

所以，既然您可以方便地使用工业级强度的 Windows 日志系统，何须费劲地将信息记在纯文本文件中呢？

<!--more-->
本文国际来源：[Writing Events to Own Event Logs](http://community.idera.com/powershell/powertips/b/tips/posts/writing-events-to-own-event-logs)
