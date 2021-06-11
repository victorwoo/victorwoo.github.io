---
layout: post
date: 2021-01-05 00:00:00
title: "PowerShell 技能连载 - 了解 PowerShell 中的 REST Web 服务"
description: PowerTip of the Day - Understanding REST Web Services in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Web 服务类型很多，PowerShell 可以使用 `Invoke-RestMethod` 访问其中的许多服务。这是一个快速入门，可帮助您起步。

这是最简单的形式，Web 服务就是上面带有结构化数据的网页。您可以在浏览器中使用相同的 URL 来查看数据。PowerShell 使用 `Invoke-RestMethod` 检索数据。这为您提供了最新的 PowerShell 团队博客：

```powershell
Invoke-RestMethod -Uri https://blogs.msdn.microsoft.com/powershell/feed/ |
    Select-Object -Property Title, pubDate
```

像上面的那种简单的 REST Web 服务可以接受参数。这些参数可以作为 URL 的一部分提交。这是一个可以接受任何数字并返回有关该数字的部分意义信息的 Web 服务。下次您被邀请参加 25 周年纪念日时，您可能想查询一些有关数字 25 的有趣信息：

```powershell
PS> Invoke-RestMethod http://numbersapi.com/25
25 is the number of cents in a quarter.

PS> Invoke-RestMethod http://numbersapi.com/25
25 is the (critical) number of Florida electoral votes for the 2000 U.S. presidential election.

PS> Invoke-RestMethod http://numbersapi.com/25
25 is the minimum age of candidates for election to the United States House of Representatives.
```

其他 Web 服务通过不可见的 POST 数据传入用户数据（类似于网站上的表单数据）。它们可能还需要会话状态、cookie 和/或登录。

这是最后一个例子：

```powershell
# https://4bes.nl/2020/08/23/calling-a-rest-api-from-powershell/

$Body = @{
    Cook = "Freddy"
    Meal = "PastaConCarne"
}

$Parameters = @{
    Method = "POST"
    Uri =  "https://4besday4.azurewebsites.net/api/AddMeal"
    Body = ($Body | ConvertTo-Json)
    ContentType = "application/json"
}
Invoke-RestMethod @Parameters -SessionVariable cookie
Invoke-RestMethod "https://4besday4.azurewebsites.net/api/AddMeal" -WebSession $cookie
```

哈希表类似于您要发送到 Web 服务的参数。它们将转换为 JSON 格式。由 Web 服务确定接受用户输入的格式。然后，使用 POST方法将数据传输到 Web 服务。

如果您为向指定名字的厨师发送一个请求，则会从 Web 服务中获取一条通知，告知您正在准备食品。确保更改 Cook 和 Meal 的数据。

如您所见，`Invoke-RestMethod` 使用了两次。第一次调用获取会话状态和 cookie，并将其存储在使用 `-SessionVariable` 参数定义的 `$cookie` 变量中。

第二个调用通过 `-WebSession` 参数提交会话状态。这样，Web 服务可以保留每次调用之间的状态并清楚地标识您。

<!--本文国际来源：[Understanding REST Web Services in PowerShell](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/understanding-rest-web-services-in-powershell)-->

