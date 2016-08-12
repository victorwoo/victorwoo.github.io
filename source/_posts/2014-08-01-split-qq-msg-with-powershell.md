layout: post
date: 2014-08-01 16:42:00
title: "用 PowerShell 批量分割 QQ 聊天记录"
description: Split QQ Message with PowerShell
categories:
- powershell
- text
tags:
- powershell
- text
- geek
---
纯文本文件有诸多的好处：

- 通用
- 易于管理
- 易于搜索
- 易于迁移

接下来我们用 PoewrShell 来处理 QQ 的聊天记录。目的是将所有的聊天记录按照“组名/对象名.txt”来分别保存每个好友、每个 QQ 群等的聊天记录。

我现在用的是 QQ 6.1 (11905) 版本。依次打开 QQ / 工具 / 消息管理器，点击右上角的倒三角按钮可以看到“导出全部消息记录”菜单项。我们在接下来的对话框里的保存类型中选择“文本文件(*.txt,不支持导入)”，并用默认的“全部消息记录.txt”文件名保存。保存之后的文件内容大概是如下格式：

    消息记录（此消息记录为文本格式，不支持重新导入）
    
    ================================================================
    消息分组:我的好友
    ================================================================
    消息对象:Victor.Woo
    ================================================================
    
    2010-01-06 16:57:28 Victor.Woo
    http://pic4.nipic.com/20090728/1684061_175750076_2.jpg
    
    2010-05-27 12:29:35 Victor.Woo
    6块钱包月55
    8000/月
    中心端，用户端
    
    ================================================================
    消息分组:技术.关注
    ================================================================
    消息对象:*PowerShell技术交流
    ================================================================
    
    2013-06-23 15:52:32 此消彼长，云过有痕<qq_g@163.com>
    http://yun.baidu.com/buy/center?tag=4#FAQ02
    
    百度亮了，自己找亮点
    
    2013-06-23 18:42:35 Victor.Woo<victorwoo@gmail.com>
    [表情]

观察它的规律：

- 以 `================================================================` 作为每一段的元数据开始。
- 接下来依次是消息分组、分隔符、消息对象。
- 以 `================================================================` 作为元数据的结束。
- 元数据之后，是正文部分，直到下一个元数据开始。
- 文件头部还有两行无关内容。
- 文件尺寸巨大，不适合整体用正则表达式来提取，只能一行一行解析。

我们的目标是生成 _我的好友/Victor.Woo.txt_ 和 _技术.关注/.PowerShell技术交流.txt_

根据这个规律，我们可以用类似“状态机”的思想来设计 PowerShell 脚本。在遍历源文件的所有行时，用一个 `$status` 变量来表示当前的状态，各个状态的含义如下：

|状态|含义|
|-|-|
|INIT|初始状态|
|ENTER_BLOCK|进入一个元数据块|
|ENTER_GROUP|“消息分组”解析完成|
|ENTER_SPLITTER|元数据中间的分隔符解析完成|
|ENTER_TARGET|“消息对象”解析完成|
|LEAVE_BLOCK|元数据块解析完成|
|CONTENT|当前行是正文内容|

然后用一个 `switch` 语句让 `$status` 变量在这些状态之间来回跳转，就能解析出一个一个独立的消息文件了。完整代码如下：
<!--more-->

    function Get-Status($status, $textLine, $lineNumber, $block) {
        $splitter = '================================================================'
        switch ($status) {
            'INIT' {
                if ($textLine -eq $splitter) {
                    $status = 'ENTER_BLOCK'
                }
            }
            'ENTER_BLOCK' {
                if ($textLine -cmatch '消息分组:(.*)') {
                  $block.Group = $matches[1]
                    $block.Target = $null
                    $status = 'ENTER_GROUP'
                    break
                } else {
                  Write-Error "[$lineNumber] [$status] $textLine"
                    exit
                }
            }
            'ENTER_GROUP' {
                if ($textLine -eq $splitter) {
                    $status = 'ENTER_SPLITTER'
                    break
                } else {
                    Write-Error "[$lineNumber] [$status] $textLine"
                    exit
                }
            }
            'ENTER_SPLITTER' {
                if ($textLine -cmatch '消息对象:(.*)') {
                  $block.Target = $matches[1]
                    $status = 'ENTER_TARGET'
                    break
                } else {
                  Write-Error "[$lineNumber] [$status] $textLine"
                    exit
                }
            }
            'ENTER_TARGET' {
                if ($textLine -eq $splitter) {
                    $status = 'LEAVE_BLOCK'
                    break
                } else {
                    Write-Error "[$lineNumber] [$status] $textLine"
                    exit
                }
            }
            'LEAVE_BLOCK' {
                if ($textLine -eq $splitter) {
                    $status = 'ENTER_BLOCK'
                    break
                } else {
                    $status = 'CONTENT'
                }
            }
            'CONTENT' {
                if ($textLine -eq $splitter) {
                    $status = 'ENTER_BLOCK'
                    break
                } else {
                    $status = 'CONTENT'
                }
            }
        }
    
        return $status
    }
    
    $status = 'INIT'
    $lineNumber = 0
    $block = @{}
    $targetPath = $null
    cat 全部消息记录.txt -Encoding UTF8 | foreach {
        $textLine = $_
        $lineNumber++
        $status = Get-Status $status $textLine $lineNumber $block
        switch ($status) {
            'LEAVE_BLOCK' {
                if ($block.Target -eq '最近联系人') {
                    break
                }
                $dirName = $block.Group.Replace('*', '.')
                if (!(Test-Path $dirName)) {
                    md $dirName | Out-Null
                }
    
                $fileName = $block.Target.Replace('*', '.')
    
                $targetPath = (Join-Path $dirName $fileName) + '.txt'
                if (Test-Path $targetPath) {
                    del $targetPath
                }
    
                echo $targetPath
            }
            'CONTENT' {
                #echo $textLine
                if ($block.Target -eq '最近联系人') {
                    break
                }
                Out-File -InputObject $textLine -Encoding utf8 -LiteralPath $targetPath -Append
            }
        }
    }

您也可以在[这里](/download/Split-QQMsg.ps1)下载完成后的版本。
