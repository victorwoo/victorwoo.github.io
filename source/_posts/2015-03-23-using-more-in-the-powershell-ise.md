layout: post
date: 2015-03-23 11:00:00
title: "PowerShell 技能连载 - 在 PowerShell ISE 中使用“more”"
description: "PowerTip of the Day - Using “more” in the PowerShell ISE"
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
_适用于 PowerShell ISE_

在 PowerShell 控制台中，您可以将命令通过管道输出到旧式的“`more.com`”命令中，或者更高级一些的 `Out-Host -Paging` 中。这将分页显示数据，每按一个键翻一页：

    PS> Get-Process | more
    PS> Get-Process | Out-Host -Paging                                                    

在 PowerShell ISE 中，这些都不支持。这是因为 ISE 没有控制台，所以没有“可见的行数”概念，只有一个无限的文本缓冲区。

要避免大量的结果刷屏问题，只需要自己创建一个兼容 ISE 的“`more`”命令：

    function Out-More
    {
        param
        (
            $Lines = 10,
            
            [Parameter(ValueFromPipeline=$true)]
            $InputObject
        )
        
        begin
        {
            $counter = 0
        }
        
        process
        {
            $counter++
            if ($counter -ge $Lines)
            {
                $counter = 0
                Write-Host 'Press ENTER to continue' -ForegroundColor Yellow
                Read-Host  
            }
            $InputObject
        }
    } 

将您的结果通过管道输出到 `Out-More`，命令，并使用 `-Lines` 来指定接收到多少行以后暂停：

    PS> Get-Process | Out-More -Lines 4
    
    Handles  NPM(K)    PM(K)      WS(K) VM(M)   CPU(s)     Id ProcessName                                                                       
    -------  ------    -----      ----- -----   ------     -- -----------                                                                       
        100       9     1436       1592    51            6896 adb                                                                               
        307      42    22332      12940   123            1424 AllShareFrameworkDMS                                                              
         42       4     1396       1284    19            1404 AllShareFrameworkManagerDMS                                                       
    Press ENTER to continue  
    
    
         81       7     1004        724    43            1388 armsvc                                                                            
        202      25    50376      55320   234     8,06  13720 chrome                                                                            
       1131      65    68672      93892   361   116,73  13964 chrome                                                                            
        199      24    53008      52700   225     5,56  14768 chrome                                                                            
    Press ENTER to continue  
    
    
        248      26    31348      44984   239    44,31  15404 chrome                                                                            
        173      20    23756      25540   179     1,27  16492 chrome                                                                            
        190      22    36316      39208   207     2,81  16508 chrome                                                                            
        184      23    41800      44212   223     1,77  17244 chrome                                                                            
    Press ENTER to continue

<!--more-->
本文国际来源：[Using “more” in the PowerShell ISE](http://community.idera.com/powershell/powertips/b/tips/posts/using-more-in-the-powershell-ise)
