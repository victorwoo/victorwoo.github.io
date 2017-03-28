layout: post
date: 2016-01-06 12:00:00
title: "PowerShell 技能连载 - 理解 PowerShell 的流"
description: PowerTip of the Day - Understanding PowerShell Streams
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
PowerShell 提供七种不同的流，可以用来输出信息。流可以帮助筛选信息，因为流可以不输出。实际上一些流默认是不输出的。以下是一个名为 `Test-Stream` 的示例函数。它运行后会将信息发送给所有七种流。

请注意：`Write-Information` 是 PowerShell 5.0 新加入的。如果您想在早期的 PowerShell 版本中运行，请移除调用 `Write-Information` 的语句！

```powershell
function Test-Stream
{
  #region These are all the same and define return values
  'Return Value 1'
  echo 'Return Value 2'
  'Return Value 3' | Write-Output
  #endregion

  Write-Verbose 'Additional Information'
  Write-Debug 'Developer Information'
  Write-Host 'Mandatory User Information'
  Write-Warning 'Warning Information'
  Write-Error 'Error Information'

  # new in PowerShell 5.0
  Write-Information 'Auxiliary Information' 
}
```

这应该是您运行 `Test-Stream` 能看到的结果：

```shell
    PS C:\> Test-Stream
    Return Value 1
    Return Value 2
    Return Value 3
    Mandatory User  Information
    WARNING: Warning  Information
    Test-Stream : Error  Information
    At line:1 char:1
    + Test-Stream
    + ~~~~~~~~~~~
        + CategoryInfo          : NotSpecified: (:) [Write-Error],  WriteErrorException
        + FullyQualifiedErrorId : Microsoft.PowerShell.Commands.WriteErrorException,Test-Stream 
     
    PS C:\> $result =  Test-Stream
    Mandatory User  Information
    WARNING: Warning  Information
    Test-Stream : Error  Information
    At line:1 char:1
    + Test-Stream
    + ~~~~~~~~~~~
        + CategoryInfo          : NotSpecified: (:) [Write-Error],  WriteErrorException
        + FullyQualifiedErrorId :  Microsoft.PowerShell.Commands.WriteErrorException,Test-Stream 
     
    PS C:\> $result
    Return Value 1
    Return Value 2
    Return Value 3
     
    PS C:\>
```

如您所见，`echo` 和 `Write-Output` 工作起来效果相同，而且实际上它们确实是相同的（因为`echo` 是 `Write-Output` 的别名）。它们定义了一个或多个返回值。它们可以赋值给一个变量。同理，这个规则适用于函数留下的未赋值的变量：它们也被送到 `Write-Output` 流中。

`Write-Host` 直接将输出送到控制台，所以它一定可见。这个 Cmdlet 只能用于向用户传递信息的场景。

其他的流是静默的。要查看其它流的输出，您首先需要打开它们：

```powershell
$VerbosePreference = 'Continue'
$DebugPreference = 'Continue'
$InformationPreference = 'Continue'
```

当打开之后，`Test-Stream` 将输出这样的信息：

```shell
PS C:\> Test-Stream
Return Value 1
Return Value 2
Return Value 3
VERBOSE: Additional Information
DEBUG: Developer Information
Mandatory User Information
Auxiliary Information 
```

要恢复缺省值，请复位 preference 变量：

```powershell
$VerbosePreference = 'SilentlyContinue'
$DebugPreference = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'
```


如果在函数中加入了通用参数，您就可以在调用函数时使用使用 `-Verbose` 和 `-Debug` 开关。`Test-CommonParameter` 演示了如何添加通用参数支持。

```powershell
function Test-CommonParameter
{
    [CmdletBinding()]
    param()
    
    "VerbosePreference = $VerbosePreference"
    "DebugPreference = $DebugPreference"
}
```

当运行 `Test-CommonParameter` 时，您将立即明白 `-Verbose` 和 `Debug` 通用参数是如何工作的：它们只是改变了本地 preference 变量：

```powershell
PS C:\> Test-CommonParameter
VerbosePreference = SilentlyContinue
DebugPreference = SilentlyContinue

PS C:\> Test-CommonParameters -Debug -Verbose
VerbosePreference = Continue
DebugPreference = Inquire
```

<!--more-->
本文国际来源：[Understanding PowerShell Streams](http://community.idera.com/powershell/powertips/b/tips/posts/understanding-powershell-streams)
