---
layout: post
title: "在 PowerShell 脚本中使用 C# 代码"
date: 2013-11-08 00:00:00
description: Using CSharp (C#) code in Powershell scripts
categories: powershell
tags:
- powershell
- csharp
- c#
---
PowerShell 使我们拥有了一门非常强大的脚本语言。许多产品，例如 SharePoint 以 Cmdlet 的形式提供了它们自己的管理扩展。

客户们喜欢脚本语言，是因为它使他们能够编写自己的代码而不需要运行某个编译器，也不需要将可执行程序拷贝到它们的目标计算机中。相对于部署一个脚本，在那些目标计算机中运行一个可执行程序或者在命令行 Shell 中执行一些命令通常需要更复杂的审批过程。

但是从另一方面来说，编写 PowerShell 脚本需要学习一门新的脚本语言并且需要使用他们所熟悉范围之外的工具。作为一个开发者，我喜欢 C# 和 Visual Studio 的智能提示等强大功能。并且，在过去几年内，我用 C# 开发了许多工具——并且我不希望在移植到 PowerShell 的过程中丢弃这些设计好的轮子。

所以如果能在 PowerShell 中复用现有的 C# 代码，而不需要将它以 Cmdlet的形式实现的话，那就十分理想了。

实际上 PowerShell 2.0 提供了一种方式来实现它：使用 `Add-Type` Cmdlet，它能够通过您提供的 C# 源代码在内存中生成一个新的 .NET 程序集，并且可以将该程序集直接用于同一个会话中的 PowerShell 脚本中。

出于演示的目的，我们假设已有以下简单的 C# 代码，作用是获取和设置 SharePoint 中的 Content Deployment 的 `RemoteTimeout` 值：

	using Microsoft.SharePoint.Publishing.Administration; 
	using System; 
	
	namespace StefanG.Tools 
	{ 
	    public static class CDRemoteTimeout  
	    { 
	        public static void Get() 
	        { 
	            ContentDeploymentConfiguration cdconfig = ContentDeploymentConfiguration.GetInstance();
	            Console.WriteLine("Remote Timeout: "+cdconfig.RemoteTimeout); 
	        } 
	
	        public static void Set(int seconds) 
	        { 
	            ContentDeploymentConfiguration cdconfig = ContentDeploymentConfiguration.GetInstance(); 
	            cdconfig.RemoteTimeout = seconds;
	            cdconfig.Update();
	        } 
	    } 
	}

除了引用 .NET 框架之外，这个工具还引用了两个 SharePoint DLL（*Microsoft.SharePoint.dll* 和 *Microsoft.SharePoint.Publishing.dll*），它们用来存取 SharePoint 的对象模型。为了确保 PowerShell 能正确地生成程序集，我们需要为 `Add-Type` Cmdlet 用 `-ReferencedAssemblies` 参数提供引用信息。

为了指定源代码的语言（可以使用 `CSharp`、`CSharpVersion3`、`Visual Basic` 和 `JScript`），您需要使用 `-Language` 参数。缺省值是 `CSharp`。

在我的系统中我有一个 csharptemplate.ps1[csharptemplate.ps1] 文件，我可以快速地复制和修改成我需要的样子来运行我的 C# 代码：

	$Assem = (
	...add referenced assemblies here...
	    ) 
	
	$Source = @" 
	...add C# source code here...
	"@ 
	
	Add-Type -ReferencedAssemblies $Assem -TypeDefinition $Source -Language CSharp

对于上述的 C# 例子，对应的最终 PowerShell 脚本如下：

	$Assem = ( 
	    "Microsoft.SharePoint, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" , 
	    "Microsoft.SharePoint.Publishing, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c"
	    ) 
	
	$Source = @" 
	using Microsoft.SharePoint.Publishing.Administration; 
	using System; 
	
	namespace StefanG.Tools 
	{ 
	    public static class CDRemoteTimeout  
	    { 
	        public static void Get() 
	        { 
	            ContentDeploymentConfiguration cdconfig = ContentDeploymentConfiguration.GetInstance();
	            Console.WriteLine("Remote Timeout: "+cdconfig.RemoteTimeout); 
	        } 
	         
	        public static void Set(int seconds) 
	        { 
	            ContentDeploymentConfiguration cdconfig = ContentDeploymentConfiguration.GetInstance(); 
	            cdconfig.RemoteTimeout = seconds;
	            cdconfig.Update();
	        } 
	    } 
	} 
	"@ 
	
	Add-Type -ReferencedAssemblies $Assem -TypeDefinition $Source -Language CSharp  
	
	[StefanG.Tools.CDRemoteTimeout]::Get()
	[StefanG.Tools.CDRemoteTimeout]::Set(600)

上述例子的最后几行演示了如何在 PowerShell 中调用 C# 方法。

注：文中涉及到的 csharptemplate.ps1 可以在这里[下载][csharptemplate.ps1]。
[csharptemplate.ps1]: /assets/download/csharptemplate.ps1
<!--本文国际来源：[Using CSharp (C#) code in Powershell scripts](http://blogs.technet.com/b/stefan_gossner/archive/2010/05/07/using-csharp-c-code-in-powershell-scripts.aspx)-->
