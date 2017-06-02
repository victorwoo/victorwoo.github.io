---
layout: post
title: Excel 列号和数字互相转换
date: 2014-08-05 17:08:51
description: Conversion between number and excel column
categories: 
- powershell
- office
tags:
- powershell
- geek
- excel
---
Excel 的列号是采用“A”、“B”……“Z”、“AA”、“AB”……的方式编号。但是我们在自动化操作中，往往希望用数字作为列号。我们可以用 PowerShell 来实现 Excel 的列号和数字之间的互相转换。

## 需求归纳

Excel 列号 -> 数字

    A   1
    AB  28
    AC  29

数字 -> Excel 列号

    1   A
    2   B
    24  Y
    26  Z
    27  AA
    28  AB

# 算法分析

* Excel 列号 -> 数字
    - 用 ASCII 编码对输入的字符串解码，得到一个数字型数组。
    - 用 26 进制对数组进行处理（逐位 *= 26，然后累加）。
* 数字 -> Excel 列号
    - 用 26 进制对数字进行处理（不断地 /= 26，取余数），得到数字型数组。
    - 将数字型数组顺序颠倒。
    - 用 ASCII 编码对数字型数组编码，得到 Excel 风格的列号。

# 源代码

转换函数：

    function ConvertFrom-ExcelColumn ($column) {
        $result = 0
        $ids = [System.Text.Encoding]::ASCII.GetBytes($column) | foreach {
            $result = $result * 26 + $_ - 64
        }
        return $result
    }
    
    function ConvertTo-ExcelColumn ($number) {
        $ids = while ($number -gt 0) {
            ($number - 1) % 26 + 1 + 64
            $number = [math]::Truncate(($number - 1) / 26)
        }
    
        [array]::Reverse($ids)
        return [System.Text.Encoding]::ASCII.GetString([array]$ids)
    }

测试代码：
    
    echo "A`t$(ConvertFrom-ExcelColumn A)"
    echo "AB`t$(ConvertFrom-ExcelColumn AB)"
    echo "AC`t$(ConvertFrom-ExcelColumn AC)"
    
    echo ''
    
    @(1..2) + @(25..28) | foreach {
        echo "$_`t$(ConvertTo-ExcelColumn $_)"
    }

执行结果：

    A   1
    AB  28
    AC  29
    
    1   A
    2   B
    25  Y
    26  Z
    27  AA
    28  AB

您也可以在[这里](/download/ExcelColumn.ps1)下载完整的脚本。
