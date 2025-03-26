---
layout: post
date: 2023-03-02 00:00:26
title: "PowerShell 技能连载 - 使用合适的数据类型（第 2 部分）"
description: PowerTip of the Day - Using Appropriate DataTypes (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
第 1 部分中我们介绍了将数据转换为更适合的 .NET 数据类型后数据的可用性如何提高。

如果无法为数据找到现有的数据类型以为其提供结构，也可以创建自己的数据类型。

假设您需要处理名称。这是一个名为 `[TeamMember]` 的自定义数据类型，可以为名称添加结构：

```powershell
class TeamMember
{
    [string]$FirstName
    [string]$LastName


    TeamMember([string]$Name)
    {
        # case correct text
        $newName = [cultureinfo]::InvariantCulture.TextInfo.ToTitleCase($Name)
        # automatically find delimiter character
        $delimiter = $newName.ToCharArray() -match '[,. ]' | Select-Object -First 1

        # no delimiter?
        if ($delimiter.Count -eq 0)
        {
            $this.LastName = $Name
            return
        }

        $array = $newName.Split($delimiter)

        # based on found delimiter
        switch -Regex ($delimiter)
        {
            # dot or space:
            '[.\s]'   {
                        $this.FirstName = $array[0]
                        $this.LastName = $array[1]
                     }
            # comma
            '\,'     {
                        $this.FirstName = $array[1]
                        $this.LastName = $array[0]
                     }
            # invalid
            default  {
                        $this.LastName = $Name
                     }
        }
    }
}
```

运行此代码后，定义了名为 `[TeamMember]` 的新数据类型。现在可以将包含名称的字符串简单地转换为结构化数据类型：

```powershell
PS> [TeamMember]'tobias weltner'

FirstName LastName
--------- --------
Tobias    Weltner



PS> [TeamMember]'tobias.weltner'

FirstName LastName
--------- --------
Tobias    Weltner



PS> [TeamMember]'weltner,tobias'

FirstName LastName
--------- --------
Tobias    Weltner
```

还有个额外的好处，即自动纠正大小写，或者说，您的类可以包含任何您喜欢的魔法。当您后来使用该类型时，您不再需要担心它。

更好的是，当将此类型分配给变量时，它将自动将任何名称转换为新结构，即使在以后的赋值中也是如此：

```powershell
PS> [TeamMember]$name = 'Tobias Weltner'

PS> $name

FirstName LastName
--------- --------
Tobias    Weltner


PS> $name = 'kloVER,kaRL'

PS> $name

FirstName LastName
--------- --------
Karl      Klover
```

自定义类的自动转换的秘密在于其构造函数。当构造函数接受一个 `[string]` 类型的参数时，它可以自动将任何字符串转换为新结构。

类的构造函数和类名相同，并且输入参数为 `[string]`：

```powershell
TeamMember([string]$Name)
    {
        ...
    }
```
<!--本文国际来源：[Using Appropriate DataTypes (Part 2)](https://blog.idera.com/database-tools/powershell/powertips/using-appropriate-datatypes-part-2/)-->

