---
layout: post
date: 2022-08-02 00:00:00
title: "PowerShell 技能连载 - 记录变量类型"
description: PowerTip of the Day - Logging Variable Types
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
作为调试和质量控制的一部分，您可能需要记录赋值给一个变量的数据。例如，您可能需要找出赋值给指定变量的实际数据类型是什么，以便以后可以以强类型的方式访问变量以增加安全性。

这是一个自定义验证器类，可以用于这类分析。只需先运行下面的代码。除了声明新属性外，它不做任何事情：

```powershell
# create a new custom validation attribute named "LogVariableAttribute":
class IdentifyTypeAttribute  : System.Management.Automation.ValidateArgumentsAttribute
{


  # this gets called whenever a new value is assigned to the variable:

  [void]Validate([object]$value, [System.Management.Automation.EngineIntrinsics]$engineIntrinsics)
  {
    # get the global variable that logs all changes:
    [System.Management.Automation.PSVariable]$variable = Get-Variable "loggedTypes" -Scope global -ErrorAction Ignore
    # if the variable exists and does not contain an ArrayList, delete it:
    if ($variable -ne $null -and $variable.Value -isnot [System.Collections.ArrayList]) { $variable = $null }
    # if the variable does not exist, set up an empty new ArrayList:
    if ($variable -eq $null) { $variable = Set-Variable -Name "loggedTypes" -Value ([System.Collections.ArrayList]@()) -Scope global -PassThru }

    [string]$line = (Get-PSCallStack)[-1].Position.Text
    $pattern = '\$(\w{1,})'
    $match = [regex]::Match($line, $pattern)
    if ($match.success)
    {

      # log the type contained in the variable
      $null = $variable.Value.Add([PSCustomObject]@{
          # use the optional source name that can be defined by the attribute:
          Value = $value.GetType()
          Timestamp = Get-Date
          # use the callstack to find out where the assignment took place:
          Name = [regex]::Match($line, $pattern).Groups[1]
          Position = [regex]::Match($line, $pattern).Groups[1].Index + (Get-PSCallStack)[-1].Position.StartOffset
          Line = (Get-PSCallStack).ScriptLineNumber | Select-Object -Last 1
          Path = (Get-PSCallStack).ScriptName | Select-Object -Last 1
      })

    }
  }
}
```

现在，在您的脚本中，在开始时，通过添加新属性来初始化要跟踪的所有变量：

```powershell
[IdentifyType()]$test = 1
[IdentifyType()]$x = 0

# start using the variables:
for ($x = 1000; $x -lt 3000; $x += 300)
{
  "Frequency $x Hz"
  [Console]::Beep($x, 500)
}

& {
  $test = Get-Date
}


$test = "Hello"
Start-Sleep -Seconds 1
  $test = 1,2,3
```

然后正常运行脚本。结果将记录到全局变量 `$loggedTypes` 中，通过它可以查看所有结果：

```powershell
# looking at the log results:
$loggedTypes | Out-GridView



PS C:\> $loggedTypes


Value     : System.Int32
Timestamp : 04.07.2022 09:42:46
Name      : test
Position  : 17
Line      : 1
Path      :

Value     : System.Int32
Timestamp : 04.07.2022 09:42:46
Name      : x
Position  : 44
Line      : 2
Path      :

Value     : System.Int32
Timestamp : 04.07.2022 09:42:46
Name      : x
Position  : 89
Line      : 5
Path      :

Value     : System.Int32
Timestamp : 04.07.2022 09:42:46
Name      : x
Position  : 113
Line      : 5
Path      :

Value     : System.Int32
Timestamp : 04.07.2022 09:42:47
Name      : x
Position  : 113
Line      : 5
Path      :

Value     : System.Int32
Timestamp : 04.07.2022 09:42:47
Name      : x
Position  : 113
Line      : 5
Path      :

Value     : System.Int32
Timestamp : 04.07.2022 09:42:48
Name      : x
Position  : 113
Line      : 5
Path      :

Value     : System.Int32
Timestamp : 04.07.2022 09:42:48
Name      : x
Position  : 113
Line      : 5
Path      :

Value     : System.Int32
Timestamp : 04.07.2022 09:42:49
Name      : x
Position  : 113
Line      : 5
Path      :

Value     : System.Int32
Timestamp : 04.07.2022 09:42:49
Name      : x
Position  : 113
Line      : 5
Path      :

Value     : System.String
Timestamp : 04.07.2022 09:42:49
Name      : test
Position  : 215
Line      : 16
Path      :

Value     : System.Object[]
Timestamp : 04.07.2022 09:42:50
Name      : test
Position  : 258
Line      : 18
Path      :
```

<!--本文国际来源：[Logging Variable Types](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/logging-variable-types)-->

