---
title: "PowerShell 模块开发流程"
date: 2014-07-16 23:56:19
description: PowerShell module develop workflow
categories: powershell
tags: powershell
---
我们希望使用 ISE 编辑器开发 PowerShell 的 .psm1 模块时，能够享受和开发 .ps1 脚本一样的体验：

- 能够在 ISE 中按 `F5` 键运行并观察执行效果。
- 能够在 ISE 中设置断点并进行调试。
- 编辑脚本并保存后，能够使修改处即时生效。

如果直接用 ISE 打开 .psm1 模块文件，是无法直接运行的。我和*史瑞克*朋友探讨了这个问题，现将他的经验整理如下：

- 先直接以 .ps1 的方式开发和调试（将模块代码和测试代码写在同一个 .ps1 文件中）。
    + 注意在这种方式下，`Export-Member` 是不能用的，可以暂时注释掉。
    + 基本开发、调试完以后，将 .ps1 后缀改为 .psm1，并取消 `Export-Member` 的注释。
- 同时打开 .psm1 和 .ps1（前者是可复用的模块，后者是最终的应用脚本），即可在 .psm1 中设置断点进行调试。

请注意，如果将模块文件放在 `%PSModulePath%` 目录下，宿主只会在启动时自动加载一次模块的内容。如果在宿主启动之后编辑了 .psm1 文件，那么已经启动的宿主是不会感知到的，仍然执行的是旧的模块文件代码。

如果要让 .psm1 中的更改即时生效，需要在 .ps1 脚本的头部加上这段代码，显式加载模块：

    if (gmo Test-Module) { rmo Test-Module }
    ipmo Test-Module

    Test-Module # 实际的业务

这样，每次重新运行 .ps1 脚本时，都会重新加载新的 .psm1 文件。待调试完之后，可以把头两行注释掉。
