---
layout: post
title: "PowerShell 技能连载 - 竖排的网格视图"
date: 2013-09-13 00:00:00
description: PowerTip of the Day - Vertical Grid View
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
效果图：

![属性窗口](/img/2013-09-13-vertical-grid-view-001.png)

您总是可以将多个对象通过管道输出到 `Out-GridView` 并且得到一个美观的窗口，窗口中含有一个表格，表格中的每一行对应对象所有属性。当您需要显示很多对象的时候这种做法十分有效。

如果您只是希望显示单个对象的所有属性，那么显示为一个竖排的表格则更为美观。实际上您可以通过名为 `PropertyGrid` 的控件来实现。以下是相应的方法：

	Function Show-Object
	{
	    param
	    (
	        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
	        [Object]
	        $InputObject,

	        $Title
	    )

	    Add-Type -AssemblyName system.Windows.Forms
	    Add-Type -AssemblyName system.Drawing

	    if (!$Title) { $Title = "$InputObject" }
	    $Form = New-Object "System.Windows.Forms.Form"
	    $Form.Size = New-Object System.Drawing.Size @(600,600)
	    $PropertyGrid = New-Object System.Windows.Forms.PropertyGrid
	    $PropertyGrid.Dock = [System.Windows.Forms.DockStyle]::Fill
	    $Form.Text = $Title
	    $PropertyGrid.SelectedObject = $InputObject
	    $PropertyGrid.PropertySort = 'Alphabetical'
	    $Form.Controls.Add($PropertyGrid)
	    $Form.TopMost = $true
	    $null = $Form.ShowDialog()
	}

现在，您可以将任何对象通过管道输出至 `Show-Object`，它将显示一个竖排的属性网格（`PropertyGrid`）。更有趣的是，所有可写的对象都被加粗，并且您的的确确可以在网格中修改这些值（注意，改变值有可能很危险）。并且许多对象，当您选择一个属性，将在状态条上显示详细的描述信息：

	Get-Process -id $pid | Show-Object
	$host | Show-Object
	Get-Item -Path $pshome\powershell.exe | Show-Object


<!--本文国际来源：[Vertical Grid View](http://community.idera.com/powershell/powertips/b/tips/posts/vertical-grid-view)-->
