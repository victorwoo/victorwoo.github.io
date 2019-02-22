---
layout: post
date: 2018-05-29 00:00:00
title: "PowerShell 技能连载 - PowerShell 陈列架 dba 工具 – 数据库专家 PowerShell 扩展"
description: "PowerTip of the Day - PowerShell Gallery dbatools – PowerShell Extension for Database Professionals"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们解释了如何获取 PowerShellGet 并在您的 PowerShell 版本中运行。现在我们来看看 PowerShell 陈列架能够如何方便地扩展 PowerShell 功能。

PowerShell 是一个多用途的自动化语言，而且世界各地的数据库专家已经开始开发一个名为 "dbatools" 的 PowerShell 扩展，它可以从 PowerShell 陈列架免费地下载：

```powershell
PS> Install-Module dbatools -Scope CurrentUser -Force
```

当安装完之后，PowerShell 现在拥有了大量新的数据库相关的命令：

```powershell
PS> Get-Command -Module dbatools

CommandType     Name                                               Version    Sou
                                                                                rce
-----------     ----                                               -------    ---
Alias           Attach-DbaDatabase                                 0.9.332    dba
Alias           Backup-DbaDatabaseCertificate                      0.9.332    dba
Alias           Connect-DbaSqlServer                               0.9.332    dba
Alias           Copy-SqlAgentCategory                              0.9.332    dba
Alias           Copy-SqlAlert                                      0.9.332    dba
Alias           Copy-SqlAudit                                      0.9.332    dba
Alias           Copy-SqlAuditSpecification                         0.9.332    dba
Alias           Copy-SqlBackupDevice                               0.9.332    dba
Alias           Copy-SqlCentralManagementServer                    0.9.332    dba
Alias           Copy-SqlCredential                                 0.9.332    dba
Alias           Copy-SqlCustomError                                0.9.332    dba
Alias           Copy-SqlDatabase                                   0.9.332    dba
Alias           Copy-SqlDatabaseAssembly                           0.9.332    dba
Alias           Copy-SqlDatabaseMail                               0.9.332    dba
Alias           Copy-SqlDataCollector                              0.9.332    dba
Alias           Copy-SqlEndpoint                                   0.9.332    dba
Alias           Copy-SqlExtendedEvent                              0.9.332    dba
Alias           Copy-SqlJob                                        0.9.332    dba
Alias           Copy-SqlJobServer                                  0.9.332    dba
Alias           Copy-SqlLinkedServer                               0.9.332    dba
Alias           Copy-SqlLogin                                      0.9.332    dba
Alias           Copy-SqlOperator                                   0.9.332    dba
Alias           Copy-SqlPolicyManagement                           0.9.332    dba
Alias           Copy-SqlProxyAccount                               0.9.332    dba
Alias           Copy-SqlResourceGovernor                           0.9.332    dba
Alias           Copy-SqlServerAgent                                0.9.332    dba
Alias           Copy-SqlServerTrigger                              0.9.332    dba
Alias           Copy-SqlSharedSchedule                             0.9.332    dba
Alias           Copy-SqlSpConfigure                                0.9.332    dba
Alias           Copy-SqlSsisCatalog                                0.9.332    dba 
...
```

这个模块的文档齐备，所以您可以使用 `Get-Help` 查看每个命令的细节和示例代码。同样地，当您用您喜欢的搜索引擎搜索 "PowerShell + dbatools"，可以找到一个有许多示例和教程的，充满活力的社区。

<!--本文国际来源：[PowerShell Gallery dbatools – PowerShell Extension for Database Professionals](http://community.idera.com/powershell/powertips/b/tips/posts/powershell-gallery-dbatools-powershell-extension-for-database-professionals)-->
