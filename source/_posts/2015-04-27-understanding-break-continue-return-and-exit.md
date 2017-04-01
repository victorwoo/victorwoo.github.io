layout: post
date: 2015-04-27 11:00:00
title: "PowerShell 技能连载 - 理解 break、continue、return 和 exit 语句"
description: PowerTip of the Day - Understanding break, continue, return, and exit
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
您是否十分熟悉“break”、“continue”、“return”和“exit”的用法？这些是十分有用的语言概念，以下是一个演示它们不同之处的测试函数：

    'Starting'
    
    function Test-Function {
        $fishtank = 1..10
    
        Foreach ($fish in $fishtank)
        {
            if ($fish -eq 7)
            {
                break      # <- abort loop
                #continue  # <- skip just this iteration, but continue loop
                #return    # <- abort code, and continue in caller scope
                #exit      # <- abort code at caller scope 
            }
    
            "fishing fish #$fish"
    
        }
        'Done.'
    }
    
    Test-Function
    
    
    'Script done!'

只需要去掉某个关键词的注释并运行脚本，就可以观察循环的执行结果。

<!--more-->
本文国际来源：[Understanding break, continue, return, and exit](http://community.idera.com/powershell/powertips/b/tips/posts/understanding-break-continue-return-and-exit)
