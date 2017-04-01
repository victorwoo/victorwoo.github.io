layout: post
title: "获取所有支持管道的 Cmdlet"
date: 2014-10-21 15:05:44
description: List Cmdlets Support Pipeline
categories: powershell
tags: powershell
---
用这段代码可以获取所有支持管道的 PowerShell 命令：

    Get-Command -CommandType Cmdlet | Where-Object {
        $_.Parameters.Values | Where-Object {
            $_.Attributes.ValueFromPipeline
        }
    }
