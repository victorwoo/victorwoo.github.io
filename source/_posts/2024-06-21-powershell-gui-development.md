---
layout: post
date: 2024-06-21 08:00:00
title: "PowerShell 技能连载 - GUI 开发技巧"
description: PowerTip of the Day - PowerShell GUI Development Tips
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 中开发图形用户界面（GUI）是一项重要任务，本文将介绍一些实用的 Windows Forms 和 WPF 开发技巧。

首先，让我们看看基本的 Windows Forms 操作：

```powershell
# 创建 Windows Forms 主窗体函数
function New-WinFormApp {
    param(
        [string]$Title = "PowerShell GUI",
        [int]$Width = 800,
        [int]$Height = 600
    )
    
    try {
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        
        $form = New-Object System.Windows.Forms.Form
        $form.Text = $Title
        $form.Size = New-Object System.Drawing.Size($Width, $Height)
        $form.StartPosition = "CenterScreen"
        
        # 添加菜单栏
        $menuStrip = New-Object System.Windows.Forms.MenuStrip
        $fileMenu = New-Object System.Windows.Forms.ToolStripMenuItem("文件")
        $fileMenu.DropDownItems.Add("新建", $null, { Write-Host "新建" })
        $fileMenu.DropDownItems.Add("打开", $null, { Write-Host "打开" })
        $fileMenu.DropDownItems.Add("保存", $null, { Write-Host "保存" })
        $menuStrip.Items.Add($fileMenu)
        $form.Controls.Add($menuStrip)
        
        # 添加工具栏
        $toolStrip = New-Object System.Windows.Forms.ToolStrip
        $toolStrip.Items.Add("新建", $null, { Write-Host "新建" })
        $toolStrip.Items.Add("打开", $null, { Write-Host "打开" })
        $toolStrip.Items.Add("保存", $null, { Write-Host "保存" })
        $form.Controls.Add($toolStrip)
        
        # 添加状态栏
        $statusStrip = New-Object System.Windows.Forms.StatusStrip
        $statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel("就绪")
        $statusStrip.Items.Add($statusLabel)
        $form.Controls.Add($statusStrip)
        
        return $form
    }
    catch {
        Write-Host "创建窗体失败：$_"
    }
}
```

Windows Forms 控件管理：

```powershell
# 创建 Windows Forms 控件管理函数
function Add-WinFormControls {
    param(
        [System.Windows.Forms.Form]$Form,
        [hashtable]$Controls
    )
    
    try {
        foreach ($control in $Controls.GetEnumerator()) {
            $ctrl = switch ($control.Key) {
                "Button" {
                    New-Object System.Windows.Forms.Button
                }
                "TextBox" {
                    New-Object System.Windows.Forms.TextBox
                }
                "Label" {
                    New-Object System.Windows.Forms.Label
                }
                "ComboBox" {
                    New-Object System.Windows.Forms.ComboBox
                }
                "DataGridView" {
                    New-Object System.Windows.Forms.DataGridView
                }
                "TreeView" {
                    New-Object System.Windows.Forms.TreeView
                }
                "ListView" {
                    New-Object System.Windows.Forms.ListView
                }
                "TabControl" {
                    New-Object System.Windows.Forms.TabControl
                }
                "Panel" {
                    New-Object System.Windows.Forms.Panel
                }
                "GroupBox" {
                    New-Object System.Windows.Forms.GroupBox
                }
                default {
                    throw "不支持的控件类型：$($control.Key)"
                }
            }
            
            # 设置控件属性
            $control.Value.GetEnumerator() | ForEach-Object {
                $ctrl.$($_.Key) = $_.Value
            }
            
            $Form.Controls.Add($ctrl)
        }
        
        Write-Host "控件添加完成"
    }
    catch {
        Write-Host "控件添加失败：$_"
    }
}
```

WPF 应用程序开发：

```powershell
# 创建 WPF 应用程序函数
function New-WPFApp {
    param(
        [string]$Title = "PowerShell WPF",
        [int]$Width = 800,
        [int]$Height = 600
    )
    
    try {
        Add-Type -AssemblyName PresentationFramework
        Add-Type -AssemblyName PresentationCore
        Add-Type -AssemblyName WindowsBase
        
        $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="$Title" Height="$Height" Width="$Width" WindowStartupLocation="CenterScreen">
    <DockPanel>
        <Menu DockPanel.Dock="Top">
            <MenuItem Header="文件">
                <MenuItem Header="新建" Click="New_Click"/>
                <MenuItem Header="打开" Click="Open_Click"/>
                <MenuItem Header="保存" Click="Save_Click"/>
            </MenuItem>
        </Menu>
        <ToolBar DockPanel.Dock="Top">
            <Button Content="新建" Click="New_Click"/>
            <Button Content="打开" Click="Open_Click"/>
            <Button Content="保存" Click="Save_Click"/>
        </ToolBar>
        <StatusBar DockPanel.Dock="Bottom">
            <TextBlock Text="就绪"/>
        </StatusBar>
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>
            <StackPanel Grid.Row="0" Margin="10">
                <TextBox x:Name="InputTextBox" Margin="0,5"/>
                <Button Content="确定" Click="OK_Click" Margin="0,5"/>
            </StackPanel>
            <ListView Grid.Row="1" x:Name="ItemListView" Margin="10"/>
        </Grid>
    </DockPanel>
</Window>
"@
        
        $reader = [System.Xml.XmlNodeReader]::new([xml]$xaml)
        $window = [Windows.Markup.XamlReader]::Load($reader)
        
        # 添加事件处理程序
        $window.Add_Loaded({
            Write-Host "窗口已加载"
        })
        
        $window.Add_Closing({
            Write-Host "窗口正在关闭"
        })
        
        return $window
    }
    catch {
        Write-Host "创建 WPF 窗口失败：$_"
    }
}
```

WPF 数据绑定：

```powershell
# 创建 WPF 数据绑定函数
function Set-WPFDataBinding {
    param(
        [System.Windows.Window]$Window,
        [hashtable]$Bindings
    )
    
    try {
        foreach ($binding in $Bindings.GetEnumerator()) {
            $element = $Window.FindName($binding.Key)
            if ($element) {
                $binding.Value.GetEnumerator() | ForEach-Object {
                    $property = $_.Key
                    $value = $_.Value
                    
                    if ($value -is [scriptblock]) {
                        # 绑定事件处理程序
                        $element.Add_$property($value)
                    }
                    else {
                        # 绑定属性
                        $element.SetValue([System.Windows.Controls.Control]::$property, $value)
                    }
                }
            }
        }
        
        Write-Host "数据绑定完成"
    }
    catch {
        Write-Host "数据绑定失败：$_"
    }
}
```

GUI 主题和样式：

```powershell
# 创建 GUI 主题和样式函数
function Set-GUITheme {
    param(
        [System.Windows.Forms.Form]$Form,
        [ValidateSet("Light", "Dark", "Blue")]
        [string]$Theme
    )
    
    try {
        $colors = switch ($Theme) {
            "Light" {
                @{
                    Background = [System.Drawing.Color]::White
                    Foreground = [System.Drawing.Color]::Black
                    ControlBackground = [System.Drawing.Color]::White
                    ControlForeground = [System.Drawing.Color]::Black
                    Border = [System.Drawing.Color]::Gray
                }
            }
            "Dark" {
                @{
                    Background = [System.Drawing.Color]::FromArgb(32, 32, 32)
                    Foreground = [System.Drawing.Color]::White
                    ControlBackground = [System.Drawing.Color]::FromArgb(45, 45, 45)
                    ControlForeground = [System.Drawing.Color]::White
                    Border = [System.Drawing.Color]::Gray
                }
            }
            "Blue" {
                @{
                    Background = [System.Drawing.Color]::FromArgb(240, 240, 255)
                    Foreground = [System.Drawing.Color]::FromArgb(0, 0, 128)
                    ControlBackground = [System.Drawing.Color]::White
                    ControlForeground = [System.Drawing.Color]::FromArgb(0, 0, 128)
                    Border = [System.Drawing.Color]::FromArgb(0, 0, 255)
                }
            }
        }
        
        # 应用主题
        $Form.BackColor = $colors.Background
        $Form.ForeColor = $colors.Foreground
        
        foreach ($control in $Form.Controls) {
            $control.BackColor = $colors.ControlBackground
            $control.ForeColor = $colors.ControlForeground
            if ($control -is [System.Windows.Forms.Control]) {
                $control.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
                $control.FlatAppearance.BorderColor = $colors.Border
            }
        }
        
        Write-Host "主题应用完成"
    }
    catch {
        Write-Host "主题应用失败：$_"
    }
}
```

这些技巧将帮助您更有效地开发 PowerShell GUI 应用程序。记住，在开发 GUI 时，始终要注意用户体验和界面响应性。同时，建议使用适当的错误处理和日志记录机制来跟踪应用程序的运行状态。 