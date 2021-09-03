---
layout: post
date: 2021-07-08 00:00:00
title: "PowerShell 技能连载 - 生日派对的琐事"
description: PowerTip of the Day - Trivia Facts for Birthday Parties
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
假设您受邀参加一位朋友的 37 岁生日。你可以在生日贺卡上放什么？试试这个：

```powershell
PS> Invoke-RestMethod -Uri http://numbersapi.com/37 -UseBasicParsing
37 is the number of plays William Shakespeare is thought to have written (counting Henry IV as three parts).
```

只需将 URL 中的数字替换为您需要的任何实际数字。这是一个很好的例子，说明使用 PowerShell 使用 REST Web 服务是多么容易。

`Invoke-RestMethod` 始终是更聪明的选择。有时示例使用 `Invoke-WebRequest` 代替。对于后者，您需要从接收到的值中手动提取信息并将其转换为正确的格式。这就是 `Invoke-RestMethod` 自动做的：

```powershell
PS> (Invoke-WebRequest -Uri http://numbersapi.com/37 -UseBasicParsing).Content
37 is the cost in cents of the Whopper Sandwich when Burger King first introduced it in 1957.
```

<!--本文国际来源：[Trivia Facts for Birthday Parties](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/trivia-facts-for-birthday-parties)-->

