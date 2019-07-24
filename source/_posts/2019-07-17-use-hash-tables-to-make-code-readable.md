---
layout: post
date: 2019-07-17 00:00:00
title: "PowerShell 技能连载 - 用哈希表提高代码可读性"
description: PowerTip of the Day - Use Hash Tables to Make Code Readable
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
也许你在过去偶然见过这样的代码：

```powershell
$shell = New-Object -ComObject WScript.Shell
$value = $shell.Popup('Restart Computer?', 5, 'Important', 36)

"Choice: $value"
```

这段代码打开一个对话框，询问用户是否可以重启计算机。弹出对话框有一个内置超时设置，因此即使在无人值守的情况下运行，代码也不会停止。

但是，由于 PowerShell 使用的是一种旧的 COM 方法，它是由加密的 ID 来控制。用户无法理解 "36" 表示一个带有 YesNo 按钮和问号的对话框。那么如何转义返回的值呢？

哈希表可以以一种简单的方法来包装代码数字，并使代码更具可读性。请看：

```powershell
$timeoutSeconds = 5
$title = 'Important'
$message = 'Restart Computer?'

$buttons = @{
  OK               = 0
  OkCancel         = 1
  AbortRetryIgnore = 2
  YesNoCancel      = 3
  YesNo            = 4
  RetryCancel      = 5
}

$icon = @{
  Stop        = 16
  Question    = 32
  Exclamation = 48
  Information = 64
}

$clickedButton = @{
  -1 = 'Timeout'
  1  = 'OK'
  2  = 'Cancel'
  3  = 'Abort'
  4  = 'Retry'
  5  = 'Ignore'
  6  = 'Yes'
  7  = 'No'
}

$shell = New-Object -ComObject WScript.Shell
$value = $shell.Popup($message, $timeoutSeconds, $title, $buttons.YesNo + $icon.Question)

"Raw result: $value"
"Cooked result: " + $clickedButton.$value

Switch ($clickedButton.$value)
{
  'Yes'    { 'restarting' }
  'No'     { 'aborted' }
  'Timeout'{ 'you did not make a choice' }
}
```

多亏了哈希表，代码使用 `$buttons.YesNo + $icon.Question` 而不是指定 "36"，而且一旦运行了代码(这样就定义了哈希表)，甚至可以获得可用选项的智能感知。

同样，通过使用原始返回值作为哈希表的键，可以轻松地将返回代码转换为人类可读的格式。通过这种方式，您可以使用 switch 语句并为用户单击的按钮分配脚本块，而不必知道单个按钮代码。

<!--本文国际来源：[Use Hash Tables to Make Code Readable](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/use-hash-tables-to-make-code-readable)-->

