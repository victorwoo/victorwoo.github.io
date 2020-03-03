---
layout: post
date: 2020-02-24 00:00:00
title: "PowerShell 技能连载 - 理解 $ErrorView"
description: PowerTip of the Day - Understanding $ErrorView
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当 PowerShell 遇到问题时，它会显示一条相当长的错误消息：

```powershell
PS> 1/0
Attempted to divide by zero.
At line:1 char:1
+ 1/0
+ ~~~
    + CategoryInfo          : NotSpecified: (:) [], RuntimeException
    + FullyQualifiedErrorId : RuntimeException
```

在现实生活中，您通常只需要第一行，而早在 2006 年，PowerShell 团队就添加了一个名为 `$ErrorView` 的首选项变量，该变量可以控制错误消息的显示方式。当将它赋值为“`CategoryView`”时，将大大缩短错误消息：

```powershell
PS> $ErrorView = 'CategoryView'

PS> 1/0
NotSpecified: (:) [], RuntimeException

PS>
```

不过，这并不太好用，因为一行无法体现真正重要的信息，并且您可以将它赋值为“`NormalView`”以返回到默认视图。同时，实用性较差导致多数人从未听说过 `$ErrorView`。

幸运的是，在PowerShell 7（RC1 中引入）中，团队记住并最终解决了该问题。为了不破坏兼容性，他们选择添加第三个选项：`ConciseView`。现在，单行错误消息可以正常工作，并显示典型用户需要知道的所有信息：

```powershell
PS> $ErrorView = ConciseView

PS> 1/0
RuntimeException: Attempted to divide by zero.

PS>
```

作为 PowerShell 开发人员，只需切换回“`NormalView`”即可查看其余的错误消息。或者（甚至更好）运行 `Get-Error -Newest 1` 以获取有关最新错误的详细信息：

```powershell
PS C:\> 1/0
    RuntimeException: Attempted to divide by zero.
    PS C:\> Get-Error -Newest 1

    Exception            :
      Type         : System.Management.Automation.RuntimeException
      ErrorRecord  :
          Exception            :
              Type  : System.Management.Automation.ParentContainsErrorRecordException
              Message : Attempted to divide by zero.
              HResult : -2146233087
          CategoryInfo         : NotSpecified: (:) [], ParentContainsErrorRecordException
          FullyQualifiedErrorId : RuntimeException
          InvocationInfo      :
              ScriptLineNumber : 1
              OffsetInLine    : 1
              HistoryId      : -1
              Line            : 1/0
              PositionMessage : At line:1 char:1
                                 + 1/0
                                 + ~~~
              CommandOrigin  : Internal
          ScriptStackTrace     : at , : line 1
      TargetSite    :
          Name         : Divide
          DeclaringType : System.Management.Automation.IntOps, System.Management.Automation, Version=7.0.0.0,
    Culture=neutral, PublicKeyToken=31bf3856ad364e35
          MemberType  : Method
          Module      : System.Management.Automation.dll
      StackTrace    :
     at System.Management.Automation.IntOps.Divide(Int32 lhs, Int32 rhs)
     at System.Dynamic.UpdateDelegates.UpdateAndExecute2[T0,T1,TRet](CallSite site, T0 arg0, T1 arg1)
     at System.Management.Automation.Interpreter.DynamicInstruction`3.Run(InterpretedFrame frame)
     at System.Management.Automation.Interpreter.EnterTryCatchFinallyInstruction.Run(InterpretedFrame frame)
      Message      : Attempted to divide by zero.
      Data         : System.Collections.ListDictionaryInternal
      InnerException :
          Type    : System.DivideByZeroException
          Message : Attempted to divide by zero.
          HResult : -2147352558 ;
      Source       : System.Management.Automation
      HResult      : -2146233087
    CategoryInfo          : NotSpecified: (:) [], RuntimeException
    FullyQualifiedErrorId : RuntimeException
    InvocationInfo    :
      ScriptLineNumber: 1
      OffsetInLine    : 1
      HistoryId       : -1
      Line            : 1/0
      PositionMessage : At line:1 char:1
                         + 1/0
                         + ~~~
      CommandOrigin  : Internal
    ScriptStackTrace     : at , : line 1
```

<!--本文国际来源：[Understanding $ErrorView](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/understanding-errorview)-->

