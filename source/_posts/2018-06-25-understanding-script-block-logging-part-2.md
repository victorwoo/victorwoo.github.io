---
layout: post
date: 2018-06-25 00:00:00
title: "PowerShell 技能连载 - 理解脚本块日志（第 2 部分）"
description: PowerTip of the Day - Understanding Script Block Logging (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
这是关于 PowerShell 脚本块日志的迷你系列的第 2 部分。今天，我们将会再次读取脚本块日志的记录。但是这次我们将以更加面向对象的方式读取日志数据：

```powershell
function Get-LoggedCode
{
    # read all raw events
    $logInfo = @{ ProviderName="Microsoft-Windows-PowerShell"; Id = 4104 }
    Get-WinEvent -FilterHashtable $logInfo |
        # take each raw set of data...
        ForEach-Object {
            # create a new object and extract the interesting
            # parts from the raw data to compose a "cooked"
            # object with useful data
            [PSCustomObject]@{
                # when this was logged
                Time = $_.TimeCreated
                # script code that was logged
                Code = $_.Properties[2].Value
                # if code was split into multiple log entries,
                # determine current and total part
                PartCurrent = $_.Properties[0].Value
                PartTotal = $_.Properties[1].Value

                # if total part is 1, code is not fragmented
                IsMultiPart = $_.Properties[1].Value -ne 1
                # path of script file (this is empty for interactive
                # commands)
                Path = $_.Properties[4].Value
                # log level
                # by default, only level "Warning" will be logged
                Level = $_.LevelDisplayName
                # user who executed the code (SID)
                User = $_.UserId
            }
        }
}
```

当您运行这段代码时，您将得到一个新的名为 `Get-LoggedCode` 的命令。当您执行它时，它将返回类似这样的对象：

```powershell
Time        : 25.05.2018 10:57:36
Code        : function Get-LoggedCode
                {
                    # read all raw events
                    $logInfo = @{ ProviderName="Microsoft-Windows-PowerShell"; Id = 4104 }
                    Get-WinEvent -FilterHashtable $logInfo |
                        # take each raw set of data...
                        ForEach-Object {
                            # create a new object and extract the interesting
                            # parts from the raw data to compose a "cooked"
                            # object with useful data:
                            [PSCustomObject]@{
                                # when this was logged:
                                Time = $_.TimeCreated
                                # script code that was logged:
                                Code = $_.Properties[2].Value
                                # if code was split into multiple log entries,
                                # determine current and total part:
                                PartCurrent = $_.Properties[0].Value
                                PartTotal = $_.Properties[1].Value

                                # if total part is 1, code is not fragmented:
                                IsMultiPart = $_.Properties[1].Value -ne 1
                                # path of script file (this is empty for interactive
                                # commands)
                                Path = $_.Properties[4].Value
                                # log level
                                # by default, only level "Warning" will be logged:
                                Level = $_.LevelDisplayName
                                # user who executed the code (SID)
                                User = $_.UserId
                            }
                        }
                }



PartCurrent : 1
PartTotal   : 1
IsMultiPart : False
Path        : D:\sample.ps1
Level       : Warning
User        : S-1-5-21-2012478179-265285931-690539891-1001
```

在我们的代码中，我们添加了 `Select-Object` 来读取整个日志，而不是最后一条日志。这里，我们得到我们刚刚执行的代码。您机器上的执行情况可能有所不同，原因如下：

缺省情况下，脚本快日志只记录“安全相关”（在返回的数据中，级别为 "Warning"）的代码。PowerShell 内部判断哪些代码是和安全相关的。在明天的技能中，我们将会介绍如何启用 "Verbose" 模式。当该模式打开时，所有代码都会被记录，所以日志文件的体积会增长得很快。以下是缺省设置 ("Warning") 日志和详细日志的数量对比（从测试机器中提取）：


```powershell
PS> Get-LoggedCode | Group-Object Level

Count Name                      Group
----- ----                      -----
    549 Verbose                   {@{Time=25.05.2018 10:57:52; Code=prompt;..
    36 Warning                   {@{Time=25.05.2018 10:57:52; Code={...
```

请注意：由于日志的体积非常大，所以长的代码被分成多块。"`IsMultiPart`"、"`PartCurrent`" 和 "`PartTotal`" 属性可以提供这方面的有用信息。

<!--本文国际来源：[Understanding Script Block Logging (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/understanding-script-block-logging-part-2)-->
