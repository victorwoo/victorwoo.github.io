---
layout: post
date: 2021-08-17 00:00:00
title: "PowerShell 技能连载 - 处理控制台命令的错误"
description: PowerTip of the Day - Error Handling for Console Commands
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有时，在 PowerShell 脚本中使用控制台应用程序很有用，甚至是必要的。例如，在上一个技能中，我们研究了删除映射网络驱动器的方法，尽管 `Remove-PSDrive` 声称能够执行此操作，但最可靠的方法仍然是使用旧的 net.exe 控制台命令。

让我们快速看看如何检查控制台命令是否成功完成。

让我们尝试通过映射一个新的网络驱动器，然后使用控制台应用程序将其删除。当然，您可以将相同的原则应用于您可能需要在 PowerShell 脚本中运行的任何控制台应用程序：

```powershell
PS> net use z: \\127.0.0.1\c$
The command completed successfully.


PS> net use z: /delete
z: was deleted successfully.

PS> net use z: /delete
net : The network connection could not be found.
At line:1 char:1
+ net use z: /delete
+ ~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (The network con...d not be found.:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError

More help is available by typing NET HELPMSG 2250.
```

创建好映射驱动器，然后再删除。但是，状态消息是本地化的（因此很难将它们与多国环境中的预期值进行比较），并且错误会作为异常出现。

通过使用 `$?`，您可以将输出转换为仅 `$true` 或 `$false`：`$true` 表示命令成功完成，而 `$false` 表示（任何）错误：

```powershell
PS> $null = net use z: \\127.0.0.1\c$; $result = $?; $result
True

PS> $null = net use z: \\127.0.0.1\c$; $result = $?; $result
net : System error 85 has occurred.
At line:1 char:9
+ $null = net use z: \\127.0.0.1\c$; $result = $?; $result
+         ~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (System error 85 has occurred.:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError

The local device name is already in use.
False
```

这要好得多，因为您的脚本随后可以判断 `$result` 并在出现错误时采取适当的步骤或将消息写入日志文件。

但是，如果出现错误，详细的错误信息仍会发送到控制台，并且没有（明显的）方法可以将其删除。即使是成熟的 `try...catch` 错误处理程序也不会响应它们：

```powershell
PS> $null = try { net use z: \\127.0.0.1\c$} catch {}; $result = $?; $result
net : System error 85 has occurred.
At line:1 char:15
+ $null = try { net use z: \\127.0.0.1\c$} catch {}; $result = $?; $res ...
+               ~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (System error 85 has occurred.:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError

The local device name is already in use.
False
```

原因是：控制台应用程序不会抛出 .NET 异常。发生错误时，控制台应用程序仅通过输出流 #2 发出信息。

而这恰好是包装控制台应用程序的解决方案：将所有流重定向到输出流。这段代码映射了一个网络驱动器：第一次调用成功；所有后续调用都失败：

```powershell
PS> $null = net use z: \\127.0.0.1\c$ *>&1; $?
True

PS> $null = net use z: \\127.0.0.1\c$ *>&1; $?
False

PS> $null = net use z: \\127.0.0.1\c$ *>&1; $?
False
```

同样，这会再次删除映射的驱动器，就像在第一次调用成功之前一样，所有剩余的调用都会失败：

```powershell
PS> $null = net use z: /delete *>&1; $result = $?; $result
True

PS> $null = net use z: /delete *>&1; $result = $?; $result
False

PS> $null = net use z: /delete *>&1; $result = $?; $result
False
```

<!--本文国际来源：[Error Handling for Console Commands](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/error-handling-for-console-commands)-->

