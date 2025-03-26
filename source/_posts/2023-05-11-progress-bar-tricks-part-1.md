---
layout: post
date: 2023-05-11 00:00:30
title: "PowerShell 技能连载 - 进度条技巧（第 1 部分）"
description: PowerTip of the Day - Progress Bar Tricks (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell自带内置进度条。通常情况下，当脚本完成时，它会自动消失：

```powershell
Write-Progress -Activity 'I am busy' -Status 'Step A'
Start-Sleep -Seconds 2
Write-Progress -Activity 'I am busy' -Status 'Step B'
Start-Sleep -Seconds 2
```

如果您想在脚本仍在运行时关闭进度条，则需要使用“-Completed”开关参数：

```powershell
Write-Progress -Activity 'I am busy' -Status 'Step A'
Start-Sleep -Seconds 2
Write-Progress -Activity 'I am busy' -Status 'Step B'
Start-Sleep -Seconds 2
Write-Progress -Completed -Activity 'I am busy'
Write-Host 'Progress bar closed, script still running.'
Start-Sleep -Seconds 2
```

如您所见，关闭进度条需要同时指定“－Activity”参数，因为它是一个强制性的参数。但是，如果您只想关闭所有可见的进度条，则“－Activity”参数的值并不重要。你可以提交一个空格或数字等任何值（除了null值或空字符串），因为这些都不会被强制性参数接受。

写入以下代码以定义“－ Activity” 参数的默认值：

```powershell
Write-Progress -Activity 'I am busy' -Status 'Step A'
Start-Sleep -Seconds 2
Write-Progress -Activity 'I am busy' -Status 'Step B'
Start-Sleep -Seconds 2
Write-Progress -Completed -Activity ' '
Write-Host 'Progress bar closed, script still running.'
Start-Sleep -Seconds 2
```

写入以下代码以定义 "`-Activity`" 参数的默认值：

```powershell
$PSDefaultParameterValues['Write-Progress:Activity']='xyz'
```

现在，"`Write-progress`" 将接受 "`Completed`" 参数而无需提交 "`Activity`" 参数：

```powershell
Write-Progress -Activity 'I am busy' -Status 'Step A'
Start-Sleep -Seconds 2
Write-Progress -Activity 'I am busy' -Status 'Step B'
Start-Sleep -Seconds 2
Write-Progress -Completed # due to the previously defined new default value, -Activity can now be omitted
Write-Host 'Progress bar closed, script still running.'
Start-Sleep -Seconds 2
```
<!--本文国际来源：[Progress Bar Tricks (Part 1)](https://blog.idera.com/database-tools/powershell/powertips/progress-bar-tricks-part-1/)-->

