layout: post
title: "定时休眠的命令"
date: 2013-08-16 00:00:00
description: scheduling hibernate
categories: powershell
tags:
- geek
- script
- command
---
例如2个小时以后休眠：

    timeout /t 7200 /nobreak & shutdown /h

<!--more-->
注意事项：

1. `shutdown /h /t xxx` 这样的组合是没用的。
2. 注意倒计时过程中不能按 `CTRL+C` 组合键来中止倒计时，否则会立即休眠。正确中止倒计时的方法是直接关闭命令行窗口。
