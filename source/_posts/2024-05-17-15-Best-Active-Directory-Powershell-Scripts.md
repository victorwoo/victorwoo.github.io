---
layout: post
date: 2024-05-17 00:00:00
title: "PowerShell 技能连载 - 15个最佳的Active Directory Powershell脚本"
description: "15+ Best Active Directory Powershell Scripts"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
我已经整理了一些最佳的Active Directory Powershell脚本，以下内容肯定会为您节省时间和工作。管理域是Active Directory的工作，了解每一个内容都是必须的。Active Directory包括用户、组，可以在Active Directory用户和计算机（ADUC）中进行检查。在域中创建用户或保留用户在域中是Windows管理员的工作。

当我工作多年时，我遇到过许多挑战作为Windows管理员有时候不容易在您的域内创建一组用户或组。这需要自动化以节省时间。如果您喜欢这个类别，还有其他类别可以探索。还有DNS powershell脚本、DHCP powershell脚本和我的自己的powershell存储库。

### 用于Active Directory的有用Powershell命令

获取域中的所有AD用户

```powershell
Get-aduser -properties * -filter *
```

导入Active Directory模块

```powershell
Import-module activedirectory
```

从域中获取所有计算机

```powershell
Get-adcomputer -properties * -filter *
```

通过SAM账户名称禁用AD用户

```powershell
Disable-ADaccount -identity "Name"
```

将数据导出为CSV格式

```powershell
Get-adcomputer -properties * -filter * |export-csv "give path"
```

获取AD组的SAM账户名称

```powershell
Get-ADgroup -identity "provide group name"
```

选择特定用户属性

```powershell
Get-ADUser -properties * -filter *
```

获取域信息

```powershell
Get-ADdomain
```

安装Active Directory角色

```powershell
Install-WindowsFeature AD-Domain-Services
```

获取域控制器列表

```powershell
 Get-ADDomainController
```

## AD用户恢复

从域控制器中恢复已删除的用户。在进行AD清理时，我们有时会删除AD用户，这给我们带来了许多问题。为满足需求提供解决方案如下。

### 工作原理

从域控制器中恢复已删除的用户。在进行AD清理时，我们有时会删除AD用户，这给我们带来了许多问题。为满足需求提供解决方案如下，在Active Directory Powershell脚本中。

### 可能的结果

运行此脚本后，在dsa.msc中搜索该用户应该可以找回而不丢失任何信息。此脚本非常实用，我希望使用它而不是通过GUI操作。

### 下载

您可以从以下链接下载脚本。

[AD-User Recover](https://powershellguru.com/wp-content/uploads/2021/03/Wintel-AD-User-Recover-.txt)

## 将服务器添加到域

将服务器添加到域、更改IP地址是一项艰巨任务，并且有时令人沮丧，那么为什么不自动化呢？该脚本无缝运行没有任何故障。这是活动目录Powershell脚本类别中很棒的一个。

### 工作原理

通常情况下，该脚本要求提供首选项1-6, 您想将哪个角色发送到另一个DC. 同样如果使用GUI执行，则是一项艰巨任务, 因此在PowerShell 中非常容易. 在这些脚本中, 如果转移成功，则会收到提示表示角色已成功转移.

### 可能的结果

运行此脚本后, 您将能够将角色从一个DC传输至另一个ad并进行检查. FSMO 角色非常重要，请务必小心操作。

### 下载

您可以通过以下链接下载脚本。

[FSMO Role Transfer](https://powershellguru.com/wp-content/uploads/2021/03/FSMO-Role-Transfer.txt)

## 在 AD 中禁用不活跃用户

禁用 AD 用户是一个月度活动，如果有很多用户，通过 GUI 执行可能会很困难。我为您带来了一段脚本，您可以通过 Powershell 批量禁用用户。

### 工作原理

该脚本将要求输入要禁用的用户标识，并提供一个包含用户信息的表格以进行批量操作，它将使用 Sam 账户进行识别。使用 Powershell 看起来很简单对吧？是的，这非常容易。

### 预期结果

运行此脚本后，您将能够从一个 DC 转移角色到另一个 ad 并且还可以检查。FSMO 角色非常重要，请务必小心操作。

### 下载

您可以从下面下载该脚本。

[Disable Active directory User](https://e37eec5f-8071-43d6-a9d1-0b9ae629dd33.usrfiles.com/ugd/e37eec_cb7781c11d58494297968e9358f666e6.txt)

## 不活跃用户报告

在审核过程中可能需要提供未使用系统或者已经有一段时间没有登录的用户列表，在这种情况下这个脚本就派上了用场并使得事情变得更加简单。

### 工作原理

该脚本获取那些已经有一定时间（比如 90 天）没有登录系统的人员名单，并发送邮件通知我们。请确保正确定义了 SMTP 设置以便接收邮件通知。

### 预期结果

该脚本将展示给你那些已经有指定时间内未登录系统的不活跃用户名单

### 下载

您可以从下面下载该脚本

[AD-InActive Users Report-90 Days](https://powershellguru.com/wp-content/uploads/2021/03/Wintel-AD-InActive-Users-Report-90-Days.-1.txt)

## 获取 AD 计算机详细信息至 CSV 文件中

在审核过程中可能需要提供未使用系统或者已经有一段时间没有登录的计算机列表，在这种情况下这个脚本就派上了用场并使得事情变得更加简单。

### 如何运行

该程序会列出环境中计算机清单并导出到 csv 文件。

### 题外话

我们能够拿到包含计算机清单内容的 csv 文件。

### 下载

您可点击以下链接下载此文件。

[AD computers to csv](https://powershellguru.com/wp-content/uploads/2021/03/AD-computers-to-csv.txt)

## 启动 AD 回收站

当你不想丢失删除用户名信息时启动回收站是必须做的事情。启动回收站优势之处在于我们只需几次点击或执行命令即可轻松恢复任何用户名信息。

### 工作原理

这只是一组命令来启动回收站而无需通过 Windows 设置逐步点击鼠标。此程序易于操作且无任何问题地执行。

### 题外话

运行完毕后, 您可检查是否成功启动回收站也可查看输出显示内容.

### 下载

您可点击以下链接下载此文件.

[Enable Recycle bin](https://powershellguru.com/wp-content/uploads/2021/03/Enable-Recycle-bin.txt)

## 删除 AD 对象

AD 对象既可以是计算机也可以是用户, 此程序为你提供删除环境中某个特定对象及其相关设备功能. 不再需要手工去 GUI 中删除对象.

### 工作原理

该脚本通常使用switch case，以便您可以在用户或计算机删除之间选择正确的选项，并删除选择并在结果屏幕上提供更新。

### 可能的结果

用户或计算机将从域中删除，并可以使用我已经在AD脚本部分中拥有的脚本进行恢复。

### 下载

您可以从以下链接下载脚本。

[AD-object-deletion](https://powershellguru.com/wp-content/uploads/2021/03/AD-object-deletion.txt)

## 创建多个AD组

一次性创建多个AD组。只需在CSV文件中提供详细信息，脚本将获取结果并创建所需的AD组。这是一个很方便查看的实用脚本之一。

### 工作原理

通常情况下，该脚本将从CSV文件中获取输入，并在定义的OU下创建所需的组。

### 可能的结果

无需手动检查即可创建AD组。只需提供所需详细信息即可。

### 下载

您可以从以下链接下载该脚本。

[Create Multiple AD Groups](https://powershellguru.com/wp-content/uploads/2021/03/Create-Multiple-AD-Groups.txt)

## 将AD用户详细信息提取到CSV文件中

提取AD用户详细信息是一个类似于审计过程每月都会执行的操作。了解关于用户每个详情对每个组织来说都很重要。这是一个简单的用于获取有关用户各种详情的脚本。

### 可能的结果

您可以通过检查最后登录日期和其他属性来确定是否需要进行任何清理。

### 下载

您可以从下面下载脚本。

[AD user to csv](https://powershellguru.com/wp-content/uploads/2021/03/AD-user-to-csv.txt)

## AD用户 - 成员 - 创建时间

这是一个在powershellgallery中由一位用户提出的问题，我已经创建了该脚本并要求他测试，结果很成功。

### 工作原理

此脚本将检查用户及其成员资格，并获取用户帐户创建日期。

### 可能的结果

您将能够了解用户属于哪个组以及用户在域中是何时创建的。

### 下载

您可以从下面下载脚本。

[AD-when-created-memberof](https://powershellguru.com/wp-content/uploads/2021/03/AD-when-created-memberof.txt)

## 上次设置密码日期

无法直接从PowerShell中获取上次设置密码日期，我们需要对脚本进行一些更改。如果尝试获取上次设置密码，则会显示1601年的日期。因此，我已经创建了一个用于获取给定samaccount的上次密码日期的脚本。

### 工作原理

该脚本将获取用户最后设置密码属性，并将其修改为正确的日期。可使用txt文档提供用户列表。

### 下载

您可以从下面下载脚本。

[Last password set](https://powershellguru.com/wp-content/uploads/2021/03/Last-password-set.txt)

## OU 单个和批量创建

需要无需任何点击即可创建 OU，我已经为此创建了一个脚本，在其中您可以单独创建或批量创建 OU。

### 工作原理

在 Powershell 中，OU 创建是一个单一命令，但批量创建需要提供输入，这可以通过 CSV 或文本文件提供，并且在此脚本中完成相同操作。

### 可能的结果

如果操作正确，则您将能够在 dsa.msc 中看到已经创建的 OU。

### 下载

您可以从下面下载该脚本。

[create OU](https://powershellguru.com/wp-content/uploads/2021/03/create-OU.zip)

## AD 用户删除 单个和批量

需要无需任何点击即可删除用户，我已经为此创建了一个脚本，在其中您可以单独删除用户或批量删除用户。

### 工作原理

用户删除 是 Powershell 中的一个单一命令，但进行批量删除 需要提供输入，这可以通过 CSV 或文本文件提供，并且在此脚本中完成相同操作。

### 可能的结果

如果操作正确，则你将不能 在 dsa.msc 中看到被删除的用户。

### 下载

您可以从下面下载脚本。

[delete-user-account](https://powershellguru.com/wp-content/uploads/2021/03/delete-user-account.zip)

## AD 复制状态

想要了解域中 AD 的复制状态，这是最适合的脚本。它提供复制状态，如果有任何错误，则会显示相同的内容。

### 工作原理

它类似于 repadmin/replsum，在 HTML 格式中提供相同的结果。

### 可能的结果

如果您的域复制不一致，可以安排此脚本每小时运行，以便检查和故障排除。

### 下载

您可以从下面下载该脚本。

[AD-Replication-status](https://e37eec5f-8071-43d6-a9d1-0b9ae629dd33.usrfiles.com/ugd/e37eec_789b04d1d2424e7aad2e10f3de98b7c7.txt)

## 过期对象报告

想要知道仍然存在于您域中的悬挂对象吗？那么这是一个很好的脚本，可获取并帮助完全创建这些对象。这是 Active Directory Powershell 脚本类别中最有趣的脚本之一。

### 工作原理

它将获取在指定时间范围内未被使用的悬挂对象。

### 可能的结果

如果符合搜索条件，您可以删除过期对象。

### 下载

您可以从下面下载该脚本。

[Stale comp reports](https://powershellguru.com/wp-content/uploads/2021/03/Stale-comp-reports.txt)

## 添加或移除多个用户从多个组

想要知道仍然存在于你领域里但已经不存在了吗？那么这就是一个很好地能够找到并且帮助你完全创建新目标物体。

### 工作原理

它使用 csv 文件读取您的输入并在您的环境中执行，这是一个专门设计的脚本，可以智能地运行并完成您的工作。

### 可能结果

脚本运行后，可能结果是用户将被删除或添加到所需的安全组。如果您有疑问，请直接通过 Facebook 或 Gmail 与我联系，两者都在页脚中提到。

### 下载

您可以从以下链接下载该脚本。

[Multiple user remove from groups](https://powershellguru.com/wp-content/uploads/2021/03/Ad-multiple-user-remove-from-groups.txt)

[Add multiple user to multiple groups](https://powershellguru.com/wp-content/uploads/2021/03/Add-multiple-user-to-multiple-groups.txt)

## 从多台服务器获取 NTP 源

当我们遇到时间同步相关问题时，有时最好检查服务器取时间的来源。这是系统管理员需要进行的一般性练习。因此为此添加了一个脚本。

### 工作原理

它读取服务器列表的输入，并尝试从提供的列表中获取 NTP 源。

### 可能结果

它读取服务器列表的输入，并尝试从提供的列表中获取 NTP 源。

### 下载

您可以从下面下载脚本。

[NTP Source](https://powershellguru.com/wp-content/uploads/2021/03/NTP-Source.txt)

## 比较 AD 组

有时候当您需要比较两个 AD 组并找出其中缺失的一个时，情况可能会变得复杂，因为某些用户被添加到了特定组中。我创建了一个简单的脚本来节省时间，并与您分享。

### 工作原理

该脚本将比较提供的两个组，并显示这两个组之间缺少什么。如果值显示“==”，则表示用户在两个组中都存在；如果显示“=>”或“<=”，则意味着某些用户在其中一个组中缺失。

### 预期结果

使用该脚本，您将知道哪些用户缺失或哪些安全组缺失。

### 下载

您可以从下面下载脚本。

[compare ad groups](https://powershellguru.com/wp-content/uploads/2021/07/compare-ad-groups.txt)

## 镜像 AD 组

曾经想过将相似的用户添加到不同的组中，以便它们互为镜像吗？很容易通过 Powershell 实现，并且可以节省我们宝贵的时间。

### 工作原理

该脚本将从提供的两个 AD 组获取用户列表，如果目标 AD 组中缺少参考AD组成员，则会将该用户添加到目标组中。

### 预期结果

参考和目标AD群体都将具有相同成员。

### 下载

您可以从下面下载腳本.

[Add missing AD group members](https://powershellguru.com/wp-content/uploads/2021/07/Add-missing-AD-group-members.txt)

<!--本文国际来源：[15+ Best Active Directory Powershell Scripts](https://powershellguru.com/active-directory-powershell-scripts/)-->
