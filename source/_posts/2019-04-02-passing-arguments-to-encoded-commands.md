---
layout: post
date: 2019-04-02 00:00:00
title: "PowerShell 技能连载 - 向编码的命令传递参数"
description: PowerTip of the Day - Passing Arguments to Encoded Commands
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
对 PowerShell 代码编码是一种在 PowerShell 环境之外运行 PowerShell 代码的方法，例如在批处理文件中。以下是一些读取 PowerShell 代码，对它编码，并且通过命令行执行它的示例代码：

```powershell
$command = {
Get-Service |
    Where-Object Status -eq Running |
    Out-GridView -Title 'Pick a service that you want to stop' -PassThru |
    Stop-Service
}

$bytes = [System.Text.Encoding]::Unicode.GetBytes($command)
$encodedCommand = [Convert]::ToBase64String($bytes)
"powershell.exe -noprofile -encodedcommand $encodedCommand" | clip
```

当执行这段代码之后，您会发现剪贴板里有 PowerShell 命令。代码类似这样：

```powershell
powershell.exe -noprofile -encodedcommand DQAKAEcAZQB0AC0AUwBlAHIAdgBpAGMAZQAgAHwAIAANAAoAIAAgACAAIABXAGgAZQByAGUALQBPAGIAagBlAGMAdAAgAFMAdABhAHQAdQBzACAALQBlAHEAIABSAHUAbgBuAGkAbgBnACAAfAAgAA0ACgAgACAAIAAgAE8AdQB0AC0ARwByAGkAZABWAGkAZQB3ACAALQBUAGkAdABsAGUAIAAnAFAAaQBjAGsAIABhACAAcwBlAHIAdgBpAGMAZQAgAHQAaABhAHQAIAB5AG8AdQAgAHcAYQBuAHQAIAB0AG8AIABzAHQAbwBwACcAIAAtAFAAYQBzAHMAVABoAHIAdQAgAHwAIAANAAoAIAAgACAAIABTAHQAbwBwAC0AUwBlAHIAdgBpAGMAZQANAAoA
```

当您打开一个新的 `cmd.exe` 窗口，您可以将这段代码粘贴到控制台并且执行纯的 PowerShell 代码。您可以在任何有足够空间容纳整行代码的地方执行编码过的命令。因为长度限制，编码过的命令在快捷方式文件（.lnk 文件）以及开始菜单中的运行对话框中工作不正常。

还有一个额外的限制：无法传递参数到编码过的命令。除非使用一个很酷的技能。首先，在代码中加入一个 `param()` 块，然后使该参数成为必选。然后，从一个外部的 PowerShell 通过管道将参数传递进去。

以下是一个示例：

```powershell
$command = {
param
(
    [Parameter(Mandatory)]
    [string]
    $FirstName,

    [Parameter(Mandatory)]
    [string]
    $LastName
)
"Hello, your first name is $FirstName and your last name is $lastname!"
}

$bytes = [System.Text.Encoding]::Unicode.GetBytes($command)
$encodedCommand = [Convert]::ToBase64String($bytes)
"powershell.exe -noprofile -command 'Tobias', 'Weltner' | powershell -noprofile -encodedcommand $encodedCommand" | clip
```

命令看起来类似这样：

```powershell
powershell.exe -noprofile -command 'Tom', 'Tester' | powershell -noprofile -encodedcommand DQAKAHAAYQByAGEAbQANAAoAKAANAAoAIAAgACAAIABbAFAAYQByAGEAbQBlAHQAZQByACgATQBhAG4AZABhAHQAbwByAHkAKQBdAA0ACgAgACAAIAAgAFsAcwB0AHIAaQBuAGcAXQANAAoAIAAgACAAIAAkAEYAaQByAHMAdABOAGEAbQBlACwADQAKAA0ACgAgACAAIAAgAFsAUABhAHIAYQBtAGUAdABlAHIAKABNAGEAbgBkAGEAdABvAHIAeQApAF0ADQAKACAAIAAgACAAWwBzAHQAcgBpAG4AZwBdAA0ACgAgACAAIAAgACQATABhAHMAdABOAGEAbQBlAA0ACgApAA0ACgAiAEgAZQBsAGwAbwAsACAAeQBvAHUAcgAgAGYAaQByAHMAdAAgAG4AYQBtAGUAIABpAHMAIAAkAEYAaQByAHMAdABOAGEAbQBlACAAYQBuAGQAIAB5AG8AdQByACAAbABhAHMAdAAgAG4AYQBtAGUAIABpAHMAIAAkAGwAYQBzAHQAbgBhAG0AZQAhACIADQAKAA==
```

当您运行这段代码，参数 "Tom" 和 "Tester" 将通过管道传递给执行编码过命令的 PowerShell。由于参数是必选的，所以管道的元素会传递给提示符，并且被编码的命令处理。

<!--本文国际来源：[Passing Arguments to Encoded Commands](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/passing-arguments-to-encoded-commands)-->

