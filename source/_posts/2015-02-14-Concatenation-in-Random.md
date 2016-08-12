layout: post
title: "随机抽奖中的粘连现象"
date: 2015-02-14 11:22:56
description: "Concatenation in Random"
categories: [C#]
tags: [C#]
---
现象
----
公司年会中的抽奖环节，是用一个计算机程序来随机抽取中奖姓名，嘉宾喊一声停，屏幕上就出现五个姓名。不过每抽取一次，大屏幕上显示的姓名往往是按部门粘连在一块的。也就是同一个部门连续出现 3-4 个中奖人。

重现
----

这种现象是怎么产生的呢？从程序上，可以想象到一种可能性。我们用 C# 写一个随机数生成器，并假设录入数据的时候，是按部门录入的：

```C#
internal class Generator
{
    private readonly IList<string> candidateList;
    private Random random = new Random();

    internal Generator(string[] candidates)
    {
        candidateList = new List<string>(candidates);
    }

    internal string Pick()
    {
        var random = new Random(); // 会导致粘连
        //var random = this.random; // 不会粘连

        int index = random.Next(candidateList.Count);
        Debug.Write(index + ", ");
        Thread.Sleep(5); // 延时，模拟计算机性能差的情况。
                          // 设为 5 时，有很多“粘连”的数据。
                          // 设为 15 时，“粘连”现象就消失了！

        string choosen = candidateList[index];
        candidateList.Remove(choosen);
        return choosen;
    }
}
```

在 `Pick()` 方法中，采用 `var random = new Random();`，则生成的中奖名单如下：

![](/img/2015-02-14-Concatenation-in-Random-001.png)

从 Debug 窗口中可以观察到，每一轮（5 个）抽取的序号中实际上有许多是重复的或者是相邻的。而这一轮和下一轮之间的序号并不相邻。

    3, 3, 3, 3, 3, 35, 35, 35, 34, 34, 14, 14, 13, 13, 13, 16, 15, 15, 15, 15, 60, 59, 58, 57, 57, 42, 41, 41, 40, 40, 8, 8, 7, 7, 7, 32, 32, 31, 31, 30, 12, 12, 11, 11, 11, 

而且，调节 `Thread.Sleep(x);` 中的延时值，模拟计算机性能的快慢，可以改变结果粘连的程度！当延时小于 5 毫秒时，粘连现象十分明显；当延时大于 15 时，粘连现象基本消失。

消除粘连
--------
计算机性能是不可控制的，那么应当如何产生正确的随机数呢？正确的做法是，在一系列随机数生成的过程中，应该自始至终用同一个随机数发生器，而不是每生成一个随机数就临时创建一个随机数发生器。

所以在 `Pick()` 方法里 `var random = new Random();` 的写法是不正确的。应该采用生存周期更长的 `var random = this.random;` 写法。代码修改后粘连现象消失了：

![](/img/2015-02-14-Concatenation-in-Random-002.png)

结论
----
造成粘连现象的本质原因如下：

随机数的生成是从种子值开始。 如果反复使用同一个种子，就会生成相同的数字系列。 产生不同序列的一种方法是使种子值与时间相关，从而对于 Random 的每个新实例，都会产生不同的系列。 默认情况下，Random 类的无参数构造函数使用系统时钟生成其种子值，而参数化构造函数可根据当前时间的计时周期数采用 Int32 值。 但是，因为时钟的分辨率有限，所以，如果使用无参数构造函数连续创建不同的 Random 对象，就会创建生成相同随机数序列的随机数生成器。

在一轮中，每次抽号抽取的是相同的随机数序列的第一个元素，所以结果很有可能是相同的。由于中奖的号码从列表中移走，所以很可能连续抽到相邻部门的姓名。

注意，虽然结果有些不符合常理，但是对于个人来说，中奖概率还是均等的。

完整的代码如下：
<!--more-->

```c#
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Text;
using System.Threading;

namespace Lottery
{
    internal class Generator
    {
        private readonly IList<string> candidateList;
        private Random random = new Random();

        internal Generator(string[] candidates)
        {
            candidateList = new List<string>(candidates);
        }

        internal string Pick()
        {
            var random = new Random(); // 会导致粘连
            //var random = this.random; // 不会粘连

            int index = random.Next(candidateList.Count);
            Debug.Write(index + ", ");
            Thread.Sleep(5); // 延时，模拟电脑性能差的情况。
                              // 设为 5 时，有很多“粘连”的数据。
                              // 设为 15 时，“粘连”现象就消失了！

            string choosen = candidateList[index];
            candidateList.Remove(choosen);
            return choosen;
        }
    }

    internal class Program
    {
        private static void Main(string[] args)
        {
            string[] candidates =
            {
                "公司领导-宋江", "公司领导-卢俊义", "公司领导-吴用", "公司领导-公孙胜", "公司领导-关胜", "公司领导-林冲", "公司领导-秦明",
                "公司领导-呼延灼", "市场部-花荣", "市场部-柴进", "市场部-李应", "市场部-朱仝", "市场部-鲁智深", "测试中心-武松", "测试中心-董平", "测试中心-张清",
                "测试中心-杨志", "测试中心-徐宁", "测试中心-索超", "测试中心-戴宗", "测试中心-刘唐", "财务部-李逵", "财务部-史进", "财务部-穆弘", "财务部-雷横", "财务部-李俊",
                "财务部-阮小二", "财务部-张横", "品质管理部-阮小五", "品质管理部-张顺", "品质管理部-阮小七", "品质管理部-杨雄", "品质管理部-石秀", "品质管理部-解珍",
                "人力资源部-解宝", "人力资源部-燕青", "人力资源部-朱武", "人力资源部-黄信", "人力资源部-孙立", "人力资源部-宣赞", "人力资源部-郝思文", "系统支持部-韩滔",
                "系统支持部-彭玘", "系统支持部-单廷珪", "系统支持部-魏定国", "系统支持部-萧让", "信息中心-裴宣", "信息中心-欧鹏", "信息中心-邓飞", "信息中心-燕顺", "信息中心-杨林",
                "信息中心-凌振", "信息中心-蒋敬", "研发一部-吕方", "研发一部-郭盛", "研发一部-安道全", "研发一部-皇甫端", "研发一部-王英", "研发一部-扈三娘", "研发一部-鲍旭",
                "研发一部-樊瑞", "研发二部-孔明", "研发二部-孔亮", "研发二部-项充", "研发二部-李衮", "研发二部-金大坚", "研发二部-马麟", "研发二部-童威", "研发三部-童猛",
                "研发三部-孟康", "研发三部-侯健", "研发三部-陈达", "研发三部-杨春", "研发三部-郑天寿", "研发三部-陶宗旺", "研发三部-宋清", "研发三部-乐和", "研发三部-龚旺",
                "研发三部-丁得孙", "研发四部-穆春", "研发四部-曹正", "研发四部-宋万", "研发四部-杜迁", "研发四部-薛永", "研发四部-施恩", "研发四部-李忠", "研发四部-周通",
                "研发四部-汤隆", "研发四部-杜兴", "研发四部-邹渊", "研发五部-邹润", "研发五部-朱贵", "研发五部-朱富", "研发五部-蔡福", "研发五部-蔡庆", "研发五部-李立",
                "研发五部-李云", "研发五部-焦挺", "研发六部-石勇", "研发六部-孙新", "研发六部-顾大嫂", "研发六部-张青", "研发六部-孙二娘", "研发六部-王定六", "研发六部-郁保四",
                "研发六部-白胜", "研发六部-时迁", "研发六部-段景住"
            };
            var generator = new Generator(candidates);

            Console.WindowWidth = 100;
            while (Console.ReadKey().Key != ConsoleKey.Escape)
            {
                var sb = new StringBuilder();
                for (int i = 0; i < 5; i++)
                {
                    var choosen = generator.Pick();
                    sb.Append(choosen);
                    sb.Append('\t');
                }
                Console.WriteLine(sb.ToString().TrimEnd());
            }
        }
    }
}
```

您也可以在[这里](/download/Lottery.cs)下载完整的代码。
