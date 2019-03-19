---
layout: post
title: "PowerShell 技能连载 - 编译二进制 Cmdlet"
date: 2014-05-21 00:00:00
description: PowerTip of the Day - Compiling Binary Cmdlets
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 的函数可以模拟一个真实二进制 cmdlet 的所有特性，但是 PowerShell 函数是 PowerShell 明文的代码，每个人都可以看到它的内容。

如果您是一个开发者并且有兴趣创开发二进制 cmdlet，以下是一个快速的入门。该入门演示如何用纯 PowerShell 创建并编译真正的 cmdlet：

    # C# definition for cmdlet
    $code = @'
    using System;
    using System.Collections.Generic;
    using System.Collections.ObjectModel;
    using System.Linq;
    using System.Text;
    using System.Management.Automation;

    namespace CustomCmdlet
    {
        [Cmdlet("Get", "Magic", SupportsTransactions = false)]
        public class test : PSCmdlet
        {
            private int _Age;

            [Alias(new string[]
            {
                "HowOld", "YourAge"
            }), Parameter(Position = 0,ValueFromPipeline = true)]

            public int Age
            {
                get { return _Age; }
                set { _Age = value; }
            }

            private string _Name;

            [Parameter(Position = 1)]
            public string Name
            {
                get { return _Name; }
                set { _Name = value; }
            }


            protected override void BeginProcessing()
            {
                this.WriteObject("Good morning...");
                base.BeginProcessing();
            }
            protected override void ProcessRecord()
            {
                this.WriteObject("Your name is " + Name + " and your age is " + Age);
                base.ProcessRecord();
            }
            protected override void EndProcessing()
            {
                this.WriteObject("That's it for now.");
                base.EndProcessing();
            }
        }
    }

    '@
    # compile C# code to DLL
    # use a timestamp to create unique file names
    # while testing, when a DLL was imported before, it is in use until PowerShell closes
    # so to do repeated tests, use different DLL file names
    $datetime = Get-Date -Format yyyyMMddHHmmssffff
    $DLLPath = "$env:temp\myCmdlet($datetime).dll"
    Add-Type -TypeDefinition $code -OutputAssembly $DLLPath

    # import a module
    Import-Module -Name $DLLPath -Verbose

现在您可以可以使用新创建的 `Get-Magic` cmdlet。它包含了一个 cmdlet 能实现的所有特性，包括参数、参数别名，甚至支持管道：

![](/img/2014-05-21-compiling-binary-cmdlets-001.png)

请注意例子中主要的 PowerShell 代码只是为了创建并编译 DLL。当 DLL 已经存在时，您需要的只是这行代码（例如，在分发的产品中）：

    Import-Module -Name $DLLPath

要开发复杂的二进制 cmdlet，您可能更希望在 C# 开发环境，例如 Visual Studio 中工作。您所需的只是添加 PowerShell 程序集的引用。PowerShell 程序集的路径可以用这行代码方便地获取到：

![](/img/2014-05-21-compiling-binary-cmdlets-002.png)

它将会把 PowerShell 程序集的路径输出到您的剪贴板中。

请注意只是编译 C# 代码并不会为您的知识资产带来更多的保护，因为它可以被反编译。所以不要用这种方式来“保护”秘密的信息，比如说密码。通过二进制 cmdlet，您可以有机会使用专业的防拷贝软件以及混淆器。额外的保护层并没有纯 PowerShell 代码的版本。

<!--本文国际来源：[Compiling Binary Cmdlets](http://community.idera.com/powershell/powertips/b/tips/posts/compiling-binary-cmdlets)-->
