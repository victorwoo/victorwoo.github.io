---
layout: post
date: 2020-04-02 00:00:00
title: "PowerShell 技能连载 - 谨慎使用某些命令"
description: PowerTip of the Day - Be Careful with Some Commands
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
以下是在 PowerShell 脚本中经常发现的三个命令，您应该注意这些命令，因为它们可能会产生严重的副作用：

## exit

"`exit`" 实际上不是命令，而是语言的一部分。它会立即退出PowerShell，您可以选择提交一个数字，该数字将成为调用者可以获取到的 "error level"。

仅当您确实要退出 PowerShell 时才使用 "`exit`"。不要在旨在由其他人调用的函数或脚本中使用它。您可以试试：在函数下方运行时，它输出“ A”，然后退出。但是，您的 PowerShell 环境也将关闭。

```powershell
function test
{
    "A"
    exit
    "B"
}
```

如果只想“退出”部分代码而不退出整个 PowerShell 环境，请改用 "`return`"：

```powershell
function test
{
    "A"
    return
    "B"
}
```

## Set-StrictMode -Version Latest

此命令使 PowerShell 的行为更加严格，即当您读取变量或调用实际上不存在的方法时抛出异常。在默认模式下，PowerShell 将仅返回 `$null`。

对于专业的 PowerShell 用户，在编写脚本代码时启用严格模式是个好主意，因为 PowerShell 会强制您编写更简洁的代码。但是，切勿将此命令添加到生产代码中！

一方面，这没有任何意义：您的生产代码已完成，因此启用严格检查不会改变任何事情。更糟糕的是：您在生产机器上强加了自己的首选项，这可能会导致意外的（和不必要的）异常。假设您的代码调用了其他代码或使用了其他模块中的命令，并且它们的作者使用了 PowerShell 的懒惰模式。现在，当您的代码启用严格模式时，将相同的严格规则应用于从您的代码中调用的所有代码。

即使在测试过程中效果很好，您也不知道其他作者何时更新他们的代码，而导致出现问题。

如果在代码中找到 "`Set-StrictMode`" 调用，只需删除它们即可。如果您喜欢严格模式，请改为在您的个人 PowerShell 配置文件中启用它，或者在需要时手动将其启用。

## Invoke-Expression

该命令采用任何字符串，并像执行 PowerShell 命令一样执行它。尽管这是非常强大的功能，有时甚至是绝对必要的，但它带来了类似所谓“SQL注入”安全问题的所有风险。请看以下代码：

```powershell
# get user input
$Path = Read-Host -Prompt 'Enter path to find .log files'

# compose command
$code = "Get-ChildItem -Path $Path -Recurse -Filter *.log -ErrorAction SilentlyContinue"

# invoke command
Invoke-Expression -Command $code
```

运行此代码时，系统会要求您提供路径，并在输入例如 "`C:\Windows`" 时看到日志文件列表。但是，执行的代码直接取决于用户输入的内容。当您再次运行代码时，请尝试以下操作：`$(Get-Service | Out-GridView; c:\Windows)`

这次，PowerShell 首先列出所有服务，并将它们输出到网格视图窗口。您使用 "`$()`" “注入”了代码。

尽可能避免使用 `Invoke-Expression`，当然，上面的示例是有意构造的。您可以将用户输入直接提交给适当的命令参数，而不是编写字符串命令：

```powershell
# get user input
$Path = Read-Host -Prompt 'Enter path to find .log files'

# invoke command
Get-ChildItem -Path $Path -Recurse -Filter *.log -ErrorAction SilentlyContinue
```

如果必须使用 `Invoke-Expression`，请格外小心，验证任何用户输入，并确保用户无法注入代码。

<!--本文国际来源：[Be Careful with Some Commands](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/be-careful-with-some-commands)-->

