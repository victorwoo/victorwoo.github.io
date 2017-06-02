---
layout: post
title: "PowerShell 技能连载 - 通过F12键跳转到函数定义"
date: 2013-09-12 00:00:00
description: PowerTip of the Day - Go to Function Definition on F12
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
如果您将要编写又长又复杂，有很多函数的PowerShell代码，那么这篇文章对您有所帮助。在其它开发环境中，当您将光标停在一个函数上，并按下F12键，编辑器将跳转到函数的定义处。而PowerShell ISE并不会那么做。

然而，您可以为ISE增加这个功能。以下代码将在 `AddOns` 菜单处增加一个新的 `Find Definition` 命令，并且为其绑定键盘的 `F12` 热键。

下一次您在一大段脚本中点击某个函数，ISE将直接导航到该函数的定义处（当函数在脚本内定义时）。

	function Find-Definition {
	    $e = $psISE.CurrentFile.Editor
	    $Column = $e.CaretColumn
	    $Line = $e.CaretLine
	    
	    $AST = [Management.Automation.Language.Parser]::ParseInput($e.Text,[ref]$null,[ref]$null)
	    $AST.Find({param($ast)
	            ($ast -is [System.Management.Automation.Language.CommandAst]) -and
	            (($ast.Extent.StartLineNumber -lt $Line -and $ast.Extent.EndLineNumber -gt $line) -or
	            ($ast.Extent.StartLineNumber -eq $Line -and $ast.Extent.StartColumnNumber -le $Column) -or
	            ($ast.Extent.EndLineNumber -eq $Line -and $ast.Extent.EndColumnNumber -ge $Column))}, $true) |
	            Select-Object -ExpandProperty CommandElements |
	            ForEach-Object {
	                $name = $_.Value  
	                $AST.Find({param($ast)
	                        ($ast -is [System.Management.Automation.Language.FunctionDefinitionAst]) -and
	                        ($ast.Name -eq $name)}, $true) |
	                        Select-Object -Last 1 |
	                        ForEach-Object {
	                            $e.SetCaretPosition($_.Extent.StartLineNumber,$_.Extent.StartColumnNumber)
	                    }
	            }
	}

	$psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add("Goto Definition",{Find-Definition},'F12') 

<!--more-->

本文国际来源：[Go to Function Definition on F12](http://community.idera.com/powershell/powertips/b/tips/posts/go-to-function-definition-on-f12)
