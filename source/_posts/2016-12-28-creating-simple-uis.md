layout: post
date: 2016-12-27 16:00:00
title: "PowerShell 技能连载 - 创建简单的 UI"
description: PowerTip of the Day - Creating Simple UIs
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
函数和 cmdlet 参数是 PowerShell 提供的基础功能，这些文本界面可以轻松地转换成图形界面。

如果您想发送一条消息，您可以使用 `Send-MailMessage` 并通过文本参数的方式提交细节信息。或者，您可以创建一个图形界面，并将它命名为 `Send-MailMessageUI`：

```powershell
#requires -Version 3.0   

function  Send-MailMessageUI   
{   
  Show-Command  -Name  Send-MailMessage   
}   
​    
Send-MailMessageUI
```

现在，您可以运行 `Send-MailMessageUI`，所有参数都将变成文本框和复选框。甚至不会脚本开发的人现在也能填写这个表单，然后点击“运行”来执行命令。

<!--more-->
本文国际来源：[Creating Simple UIs](http://community.idera.com/powershell/powertips/b/tips/posts/creating-simple-uis)
