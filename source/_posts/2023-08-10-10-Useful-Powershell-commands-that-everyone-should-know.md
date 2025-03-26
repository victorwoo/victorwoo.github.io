---
layout: post
date: 2023-08-10 00:00:00
title: "PowerShell 技能连载 - 10个每个人都应该知道的有用PowerShell命令"
description: "10 Useful Powershell commands that everyone should know"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
许多开发人员喜爱PowerShell，而且理由充分：它增强了Windows命令提示符，在那里我们中的许多人花费大量时间。然而，它确实有一个学习曲线，但一旦掌握了基本指令，对你来说将是生产力的绝佳工具。

Cmdlets 是 PowerShell 功能能力背后的驱动力。开发人员应该知道数十个关键命令，这些命令涵盖从改进通用 Windows 体验到对开发工作有用的指令。此列表编制为刚开始使用者提供便于参考的工具。

## Get-Help

对于任何使用 PowerShell 的人来说，Get-Help 命令至关重要，因为它提供即时访问所需信息以运行和操作所有可用命令。

以下是示例。

```plaintext
Get-Help [[-Name] <String>] [-Path <String>] [-Category <String[]>] [-Component <String[]>]
[-Functionality <String[]>] [-Role <String[]>] [-Examples] [<CommonParameters>]
```

## Get-Command

Get-Command 是一个方便的参考 cmdlet，它显示当前会话中可访问的所有命令。

```powershell
get-command
```

输出内容类似这样:

```plaintext
CommandType     Name                            Definition
-----------     ----                            ----------
Cmdlet          Add-Content                     Add-Content [-Path] <String[...
Cmdlet          Add-History                     Add-History [[-InputObject] ...
Cmdlet          Add-Member                      Add-Member [-MemberType]
```

## Set-ExecutionPolicy

为防止恶意脚本在PowerShell环境中运行，微软默认禁用了脚本。然而，开发人员希望能够构建和运行脚本，因此Set-ExecutionPolicy命令允许您调整PowerShell脚本的安全级别。您可以选择四种不同的安全级别：

**Restricted**: 这是默认的安全级别，阻止执行PowerShell脚本。在这个安全级别下只能交互式输入命令。

**All Signed**: 只有由可靠发布者签名的脚本才能运行在这个安全级别。

**Remote Signed**: 任何在本地生成的PowerShell脚本都可以在这个安全级别下运行。远程开发的脚本只有经过认可发布者签名后才被允许运行。

**Unrestricted**: 如其名称所示，无限制的安全级别从执行策略中移除所有限制，允许所有脚本运行。

## Get-ExecutionPolicy

类似地，在陌生环境工作时，该命令可以快速显示当前执行策略：

## Get-Service

了解系统上已安装哪些服务也是很有益处的。通过以下命令，您可以快速获取这些数据：

```powershell
Get-Service
```

输出结果可能类似如下:

```plaintext
Status   Name               DisplayName
------   ----               -----------
Running  AarSvc_4f948d3     Agent Activation Runtime_4f948d3
Running  AdobeARMservice    Adobe Acrobat Update Service
Stopped  AJRouter           AllJoyn Router Service
Stopped  ALG                Application Layer Gateway Service
Running  AMD Crash Defen... AMD Crash Defender Service
Running  AMD External Ev... AMD External Events Utility
```

如果您需要知道某个特定服务是否已安装，请在命令中添加“-Name”开关和服务的名称，Windows 将显示该服务的状态。还可以使用过滤功能返回当前安装的服务的指定子集。

## Get-EventLog

PowerShell 中的 Get-EventLog 命令可真正解析计算机事件日志。有许多可用选项。要阅读特定日志，请使用“-Log”开关后跟日志文件名。例如，要查看应用程序日志，请执行以下命令：

```powershell
Get-EventLog -Log "Application"
```

Get-Eventlog 的其他参数是：

- \-Verbose
- \-Debug
- \-ErrorAction
- \-ErrorVariable
- \-WarningAction
- \-WarningVariable
- \-OutBuffer
- \-OutVariable

## Get-Process

通常很方便能够快速获得当前正在运行的所有进程的列表，就像获取可用服务列表一样。

这些信息可以通过 `Get-Process` 命令获得。

```powershell
Get-Process
```

输出类似这样：

```plaintext
Handles  NPM(K)    PM(K)      WS(K)     CPU(s)     Id  SI ProcessName
-------  ------    -----      -----     ------     --  -- -----------
    206      13     2696       4320       0.38  13684   6 AdobeIPCBroker
    110       8     2008       4224              3816   0 amdfendrsr
    371      16     5996      12548              2528   0 AppHelperCap
    502      29    20728      14560       1.64   9688   6 ApplicationFrameHost
    124       8     1556       2204              5372   0 armsvc
```

## Stop-Process

Stop-Process 可用于终止已冻结或不再响应的进程。如果不确定是什么导致了延迟，可以使用 Get-Process 快速发现问题进程。在获得名称或进程 ID 后，可以使用 Stop-Process 停止一个进程。以下是相同操作的示例：

```powershell
Stop-Process -processname armsvc
```

## Clear-History

如果您希望删除所有命令历史记录条目怎么办？使用 Clear-History cmdlet 很简单。它也可以用来仅删除特定的命令。例如，以下命令将删除以“help”开头或以“command”结尾的命令：

```powershell
Clear-History -Command *help*, *command
```

## ConvertTo-html

如果您需要提取数据以供报告或分发给他人，ConvertTo-HTML 是一种快速简便的方法。要使用它，请将另一个命令的输出传递给 ConvertTo-HTML 命令，并使用 -Property 开关指定您希望在 HTML 文件中包含哪些输出属性。您还需要为文件命名。

例如，以下代码创建了一个列出当前控制台中 PowerShell 命令的 HTML 页面：

```powershell
get-commad | convertto-html > command.htm
```

## 结论

以下 cmdlet 是我在日常工作中经常使用的一些特别提及，也被许多 PowerShell 开发人员广泛使用。请在评论部分告诉我这篇文章中遗漏了什么，以便我们可以在接下来的文章中涵盖它。
