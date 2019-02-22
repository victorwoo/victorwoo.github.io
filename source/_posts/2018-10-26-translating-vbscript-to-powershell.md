---
layout: post
date: 2018-10-26 00:00:00
title: "PowerShell 技能连载 - 将 VBScript 翻译为 PowerShell"
description: PowerTip of the Day - Translating VBScript to PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
大多数旧的 VBS 脚本可以容易地翻译为 PowerShell。VBS 中关键的命令是 "`CreateObject`"。它能让您操作系统的库。PowerShell 将 "`CreateObject`" 翻译为 "`New-Object -ComObject`"，而对象模型和成员名称保持相同：

当把这段代码保存为扩展名为 ".vbs" 的文本文件后，这段 VBS 脚本就可以发出语音：

```vbscript
Set obj = CreateObject("Sapi.SpVoice")

obj.Speak "Hello World!"
```

对应的 PowerShell 代码类似这样：

```powershell
$obj = New-Object -ComObject "Sapi.SpVoice"
$obj.Speak("Hello World!")
```

只有少量的 VBS 内置成员，例如 `MsgBox` 或 `InputBox`。要翻译这些代码，您需要引入 "`Microsoft.VisualBasic.Interaction`" 类型。以下是调用 `MsgBox` 或 `InputBox` 的 PowerShell 代码：

```powershell
Add-Type -AssemblyName Microsoft.VisualBasic

$result = [Microsoft.VisualBasic.Interaction]::MsgBox("Do you want to restart?", 3, "Question")
$result

$result = [Microsoft.VisualBasic.Interaction]::InputBox("Your name?", $env:username, "Enter Name")
```

以下是支持的 Visual Basic 成员的完整列表：

```powershell
PS> [Microsoft.VisualBasic.Interaction] | Get-Member -Stati


    TypeName: Microsoft.VisualBasic.Interaction

Name            MemberType Definition
----            ---------- ----------
AppActivate     Method     static void AppActivate(int ProcessId), static vo...
Beep            Method     static void Beep()
CallByName      Method     static System.Object CallByName(System.Object Obj...
Choose          Method     static System.Object Choose(double Index, Params ...
Command         Method     static string Command()
CreateObject    Method     static System.Object CreateObject(string ProgId, ...
DeleteSetting   Method     static void DeleteSetting(string AppName, string ...
Environ         Method     static string Environ(int Expression), static str...
Equals          Method     static bool Equals(System.Object objA, System.Obj...
GetAllSettings  Method     static string[,] GetAllSettings(string AppName, s...
GetObject       Method     static System.Object GetObject(string PathName, s...
GetSetting      Method     static string GetSetting(string AppName, string S...
IIf             Method     static System.Object IIf(bool Expression, System....
InputBox        Method     static string InputBox(string Prompt, string Titl...
MsgBox          Method     static Microsoft.VisualBasic.MsgBoxResult MsgBox(...
Partition       Method     static string Partition(long Number, long Start, ...
ReferenceEquals Method     static bool ReferenceEquals(System.Object objA, S...
SaveSetting     Method     static void SaveSetting(string AppName, string Se...
Shell           Method     static int Shell(string PathName, Microsoft.Visua...
Switch          Method     static System.Object Switch(Params System.Object[...



PS>
```

<!--本文国际来源：[Translating VBScript to PowerShell](http://community.idera.com/powershell/powertips/b/tips/posts/translating-vbscript-to-powershell)-->
