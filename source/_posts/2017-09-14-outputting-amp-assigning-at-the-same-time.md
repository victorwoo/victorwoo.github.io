---
layout: post
date: 2017-09-14 00:00:00
title: "PowerShell 技能连载 - 同时输出和赋值"
description: PowerTip of the Day - Outputting and Assigning at the same time
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们介绍了如何记录脚本结果，以及如何使用括号来同时输出和赋值：

```powershell
PS> ($a = Get-Process -Id $pid)

Handles  NPM(K)    PM(K)      WS(K)     CPU(s)     Id  SI ProcessName
-------  ------    -----      -----     ------     --  -- -----------
    1595     102   283200     325444      64,56   6436   1 powershell_ise



PS> $a

Handles  NPM(K)    PM(K)      WS(K)     CPU(s)     Id  SI ProcessName
-------  ------    -----      -----     ------     --  -- -----------
    1595     102   283200     325444      64,75   6436   1 powershell_ise



PS>
```

还可以用 `-OutVariable` 通用参数来实现相同的功能：

```powershell
PS> Get-Process -Id $pid -OutVariable b

Handles  NPM(K)    PM(K)      WS(K)     CPU(s)     Id  SI ProcessName
-------  ------    -----      -----     ------     --  -- -----------
    1731     105   290336     341688      66,66   6436   1 powershell_ise



PS> $b

Handles  NPM(K)    PM(K)      WS(K)     CPU(s)     Id  SI ProcessName
-------  ------    -----      -----     ------     --  -- -----------
    1731     105   290336     341688      66,92   6436   1 powershell_ise



PS>
```

`Tee-Object` 是第三种方法：

```powershell
PS> Get-Process -Id $pid | Tee-Object -Variable c

Handles  NPM(K)    PM(K)      WS(K)     CPU(s)     Id  SI ProcessName
-------  ------    -----      -----     ------     --  -- -----------
    1759     109   292300     343644      71,53   6436   1 powershell_ise



PS> $c

Handles  NPM(K)    PM(K)      WS(K)     CPU(s)     Id  SI ProcessName
-------  ------    -----      -----     ------     --  -- -----------
    1759     109   292300     343644      71,69   6436   1 powershell_ise



PS>
```

以上方法使用了管道，而管道的速度比较慢。如果希望提升性能，那么避免使用管道：

```powershell
PS> Tee-Object -InputObject (Get-Process -Id $pid) -Variable d

Handles  NPM(K)    PM(K)      WS(K)     CPU(s)     Id  SI ProcessName
-------  ------    -----      -----     ------     --  -- -----------
    1761     111   294568     345268      74,31   6436   1 powershell_ise



PS> $d

Handles  NPM(K)    PM(K)      WS(K)     CPU(s)     Id  SI ProcessName
-------  ------    -----      -----     ------     --  -- -----------
    1761     111   294568     345268      74,59   6436   1 powershell_ise



PS>
```

<!--本文国际来源：[Outputting and Assigning at the same time](http://community.idera.com/powershell/powertips/b/tips/posts/outputting-amp-assigning-at-the-same-time)-->
