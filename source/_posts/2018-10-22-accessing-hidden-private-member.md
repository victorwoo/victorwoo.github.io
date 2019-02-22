---
layout: post
date: 2018-10-22 00:00:00
title: "PowerShell 技能连载 - 存取隐藏（私有）成员"
description: PowerTip of the Day - Accessing Hidden (Private) Member
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
对象和类型中包括方法和属性等成员，但只有少数是公开可见和可使用的。还有许多隐藏（私有）的成员。在生产系统上使用这些成员是不明智的，当它们更新版本的时候，您并不会得到通知，所以可能会工作不正常。所以对于高级的 PowerShell 开发者来说是一个很好奇的地方。

有一个免费的 PowerShell 模块名为 `ImpliedReflection`，能将私有的成员变为可见，甚至在 PowerShell ISE 和 Visual Studio Code 的 IntelliSense 中，而且您可以运行那些成员。

例如，以下公有的类型只暴露了一个公有的方法，您可以用它来构造 PowerShell 的模块路径。

```powershell
PS> [System.Management.Automation.ModuleIntrinsics]::GetModulePath

OverloadDefinitions
-------------------
static string GetModulePath(string currentProcessModulePath, string hklmMachineModulePath, string
hkcuUserModulePath)




PS> [System.Management.Automation.ModuleIntrinsics] | Get-Member -Static


    TypeName: System.Management.Automation.ModuleIntrinsics

Name            MemberType Definition
----            ---------- ----------
Equals          Method     static bool Equals(System.Object objA, System.Object objB)
GetModulePath   Method     static string GetModulePath(string currentProcessModulePath, string hklmMa...
ReferenceEquals Method     static bool ReferenceEquals(System.Object objA, System.Object objB)
```

现在我们像这样安装 `ImpliedReflection`：

```powershell
Install-Module -Name ImpliedReflection -Scope CurrentUser
```

当该模块安装以后，您需要先允许该扩展：

```powershell
PS> Enable-ImpliedReflection -Force
```

现在，当您重新访问该类型并查看它的成员时，仍然只显示其公有成员。只有当您交互式输出该类型时，该扩展才起作用：

```powershell
PS> [System.Management.Automation.ModuleIntrinsics] | Get-Member -Static


    TypeName: System.Management.Automation.ModuleIntrinsics

Name            MemberType Definition
----            ---------- ----------
Equals          Method     static bool Equals(System.Object objA, System.Object objB)
GetModulePath   Method     static string GetModulePath(string currentProcessModulePath, string hklmMa...
ReferenceEquals Method     static bool ReferenceEquals(System.Object objA, System.Object objB)



PS> [System.Management.Automation.ModuleIntrinsics]

IsPublic IsSerial Name                                     BaseType
-------- -------- ----                                     --------
True     False    ModuleIntrinsics                         System.Object



PS> [System.Management.Automation.ModuleIntrinsics] | Get-Member -Static


    TypeName: System.Management.Automation.ModuleIntrinsics

Name                           MemberType Definition
----                           ---------- ----------
AddToPath                      Method     static string AddToPath(string basePath, string pathToAdd, ...
CombineSystemModulePaths       Method     static string CombineSystemModulePaths()
Equals                         Method     static bool Equals(System.Object objA, System.Object objB)
ExportModuleMembers            Method     static void ExportModuleMembers(System.Management.Automatio...
GetDscModulePath               Method     static string GetDscModulePath()
GetExpandedEnvironmentVariable Method     static string GetExpandedEnvironmentVariable(string name, S...
GetManifestGuid                Method     static guid GetManifestGuid(string manifestPath)
GetManifestModuleVersion       Method     static version GetManifestModuleVersion(string manifestPath)
GetModuleName                  Method     static string GetModuleName(string path)
GetModulePath                  Method     static string GetModulePath(string currentProcessModulePath...
GetPersonalModulePath          Method     static string GetPersonalModulePath()
GetSystemwideModulePath        Method     static string GetSystemwideModulePath()
IsModuleMatchingModuleSpec     Method     static bool IsModuleMatchingModuleSpec(psmoduleinfo moduleI...
IsPowerShellModuleExtension    Method     static bool IsPowerShellModuleExtension(string extension)
NewAliasInfo                   Method     static System.Management.Automation.AliasInfo NewAliasInfo(...
PathContainsSubstring          Method     static int PathContainsSubstring(string pathToScan, string ...
PatternContainsWildcard        Method     static bool PatternContainsWildcard(System.Collections.Gene...
ProcessOneModulePath           Method     static string ProcessOneModulePath(System.Management.Automa...
ReferenceEquals                Method     static bool ReferenceEquals(System.Object objA, System.Obje...
RemoveNestedModuleFunctions    Method     static void RemoveNestedModuleFunctions(psmoduleinfo module)
SetModulePath                  Method     static string SetModulePath()
SortAndRemoveDuplicates        Method     static void SortAndRemoveDuplicates[T](System.Collections.G...
_ctor                          Method     static System.Management.Automation.ModuleIntrinsics _ctor(...
MaxModuleNestingDepth          Property   static int MaxModuleNestingDepth {get;}
PSModuleExtensions             Property   static string[] PSModuleExtensions {get;set;}
PSModuleProcessableExtensions  Property   static string[] PSModuleProcessableExtensions {get;set;}
SystemWideModulePath           Property   static string SystemWideModulePath {get;set;}
Tracer                         Property   static System.Management.Automation.PSTraceSource Tracer {g...
```

现在您可以使用私有的成员了，好像它们是公有的一样：

```powershell
PS> [System.Management.Automation.ModuleIntrinsics]::GetPersonalModulePath()
C:\Users\tobwe\Documents\WindowsPowerShell\Modules

PS> [System.Management.Automation.ModuleIntrinsics]::SystemWideModulePath
c:\windows\system32\windowspowershell\v1.0\Modules
```

再次强调，这仅仅适用于希望更深入了解对象和类型内部的工作机制的高级用户。`ImpliedReflection` 模块用于操作私有成员。在生产环境下，您需要十分谨慎地操作私有成员。

<!--本文国际来源：[Accessing Hidden (Private) Member](http://community.idera.com/powershell/powertips/b/tips/posts/accessing-hidden-private-member)-->
