---
layout: post
date: 2021-02-04 00:00:00
title: "PowerShell 技能连载 - 使用 GitHub Web Service（第 2 部分）"
description: PowerTip of the Day - Using GitHub Web Services (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技能中，我们研究了组织的 GitHub Web 服务 API。现在，让我们看看如何使用单个 GitHub 帐户。

道格·芬克（Doug Finke）创建了一个名为 "ImportExcel" 的出色的开源 PowerShell 模块，该模块使处理 Excel 文件变得轻而易举：[https://github.com/dfinke/ImportExcel](https://github.com/dfinke/ImportExcel)。他的公共 GitHub 用户名是 dfinke。

要查找他的作品的最新版本以及在何处下载，请尝试以下操作：

```powershell
$username = 'dfinke'
$reponame = 'ImportExcel'
$url = "https://api.github.com/repos/$username/$reponame/releases/latest"
Invoke-RestMethod -UseBasicParsing -Uri $url |
    Select-Object -Property tag_name, published_at, zipball_url, name
```

结果看起来像这样：

    tag_name published_at         zipball_url
    -------- ------------         -----------
    v7.1.0   2020-03-21T00:38:13Z https://api.github.com/repos/dfinke/ImportExcel/zipball/v7.1.0

请注意，下载 URL 将下载 GitHub 上所见的整个软件工程。如果您只想使用他的 PowerShell 模块，请选择发布到 PowerShell Gallery 的即用型 PowerShell 模块：

```powershell
PS> Install-Module -Name ImportExcel -Scope CurrentUser
```

安装模块后，由于 Doug 的出色工作，您现在可以将任何数据通过管道传输到 `Export-Excel`。如果愿意，请创建包含 Doug 模块完整版本历史记录的 Excel 工作表：

```powershell
$username = 'dfinke'
$reponame = 'ImportExcel'
$url = https://api.github.com/repos/$username/$reponame/releases

Invoke-RestMethod -UseBasicParsing -Uri $url |

# workaround needed for any JSON web service result that
# consists of more than one dataset
ForEach-Object { $_ } |

Sort-Object -Property published_at -Descending |
Select-Object -Property published_at, Name, Url, body |
Export-Excel
```

<!--本文国际来源：[Using GitHub Web Services (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-github-web-services-part-2)-->

