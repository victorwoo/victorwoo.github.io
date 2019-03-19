---
title: 掌握 PowerShell 的 XML 日常操作
description: Mastering Everyday XML Tasks in PowerShell
date: 2017-06-03 13:40:50
tags: [powershell]
categories: [powershell]
---
# PowerShell 处理 XML 之葵花宝典

PowerShell 对 XML 的支持非常酷。这篇文章整理了所有日常的 XML 任务，甚至非常复杂的任务，都可以轻松搞定。

我们从一个简单的例子开始，以免把脑子搞乱。

我们先创建一个 XML 文档，然后加入数据集合，改变一些信息，增加新数据，删除数据，最后将修改好的版本保存为一个格式化过的 XML 文件。

# 新建 XML 文档

从头开始创建新的 XML 文档是一件很乏味的事。许多写脚本的人干脆以纯文本的方式来创建 XML 文件。虽然这样也可以，但是容易出错。这样很有可能拼写错误导致问题，而且您会发现自己身处一个和 XML 很不友好的世界里。

其实不然，只要用 `XMLTextWriter` 对象就可以创建 XML 文档了。这个对象屏蔽了处理原生 XML 对象模型的细节，并且帮您将信息写入 XML 文件。

开始之前，我们用下面的代码创建一个 TMD 复杂的 XML 文档来玩。这段代码的目的是创建一个包含所有典型内容的 XML 文档，包括节点、属性、数据区、注释。

    # 这是文档存储的路径:
    $Path = "$env:temp\inventory.xml"

    # 新建一个 XMLTextWriter 来创建 XML:
    $XmlWriter = New-Object System.XMl.XmlTextWriter($Path,$Null)

    # 设置排版参数:
    $xmlWriter.Formatting = 'Indented'
    $xmlWriter.Indentation = 1
    $XmlWriter.IndentChar = "`t"

    # 写入头部:
    $xmlWriter.WriteStartDocument()

    # 声明 XSL
    $xmlWriter.WriteProcessingInstruction("xml-stylesheet", "type='text/xsl' href='style.xsl'")

    # 创建根对象“machines”，并且添加一些属性
    $XmlWriter.WriteComment('List of machines')
    $xmlWriter.WriteStartElement('Machines')
    $XmlWriter.WriteAttributeString('current', $true)
    $XmlWriter.WriteAttributeString('manager', 'Tobias')

    # 加入一些随机的节点
    for($x=1; $x -le 10; $x++)
    {
        $server = 'Server{0:0000}' -f $x
        $ip = '{0}.{1}.{2}.{3}' -f  (0..256 | Get-Random -Count 4)

        $guid = [System.GUID]::NewGuid().ToString()

        # 每个数据集的名字都是“machine”，并且增加一个随机的属性：
        $XmlWriter.WriteComment("$x. machine details")
        $xmlWriter.WriteStartElement('Machine')
        $XmlWriter.WriteAttributeString('test', (Get-Random))

        # 增加三条信息：
        $xmlWriter.WriteElementString('Name',$server)
        $xmlWriter.WriteElementString('IP',$ip)
        $xmlWriter.WriteElementString('GUID',$guid)

        # 增加一个含有属性和正文的节点：
        $XmlWriter.WriteStartElement('Information')
        $XmlWriter.WriteAttributeString('info1', 'some info')
        $XmlWriter.WriteAttributeString('info2', 'more info')
        $XmlWriter.WriteRaw('RawContent')
        $xmlWriter.WriteEndElement()

        # 增加一个含有 CDATA 段的节点：
        $XmlWriter.WriteStartElement('CodeSegment')
        $XmlWriter.WriteAttributeString('info3', 'another attribute')
        $XmlWriter.WriteCData('this is untouched code and can contain special characters /\@<>')
        $xmlWriter.WriteEndElement()

        # 关闭“machine”节点：
        $xmlWriter.WriteEndElement()
    }

    # 关闭“machines”节点：
    $xmlWriter.WriteEndElement()

    # 完成整个文档：
    $xmlWriter.WriteEndDocument()
    $xmlWriter.Flush()
    $xmlWriter.Close()

    notepad $path

这段脚本用随机数据生成了一个虚拟的服务器进货单。结果自动用记事本，看起来如下：

    <?xml version="1.0"?>
    <?xml-stylesheet type='text/xsl' href='style.xsl'?>
    <!--List of machines-->
    <Machines current="True" manager="Tobias">
     <!--1. machine details-->
     <Machine test="578163632">
      <Name>Server0001</Name>
      <IP>31.248.95.170</IP>
      <GUID>51cb0dfb-75ed-4967-8392-47d87596c73c</GUID>
      <Information info1="some info" info2="more info">RawContent</Information>
      <CodeSegment info3="another attribute"><![CDATA[this is untouched code and can contain special characters /\@<>]]></CodeSegment>
     </Machine>
     <!--2. machine details-->
     <Machine test="124214010">
      <Name>Server0002</Name>
      <IP>33.60.233.89</IP>
      <GUID>9618b8bc-c200-46ce-b423-ee030555242d</GUID>
      <Information info1="some info" info2="more info">RawContent</Information>
      <CodeSegment info3="another attribute"><![CDATA[this is untouched code and can contain special characters /\@<>]]></CodeSegment>
     </Machine>
    (...)
    </Machines>

这个 XML 文档有两个目的：一是提供了一个创建 XML 文件的代码模板；二是为接下来的练习提供一个基础数据。

我们假想这个 XML 文件有重要的信息在里面，接下来要用各种方法来操作这个规范的 XML 文件。

**注意：**`XMLTextWriter` 做了很多智能的事情，不过你需要确保你创建的内容没问题。比如说一个常见的问题是节点名称非法。节点名称不得含有空格。

所以写成 `CodeSegment` 是正确的，而 `Code Segment` 是错误的。XML 将会试着将节点命名为 `Code`，然后增加一个名为 `Segment` 的属性，最后因为没有为属性设置值而出错。

## 查找 XML 文件中的信息

一个常见的任务是从 XML 文件中提取信息。我们假设您需要获得一个机器和 IP 地址的列表。加入您已经生成了上述的 XML 文件，那么以下是创建一个报告要做的所有事情：

    # 这是 XML 例子文件的存储路径：
    $Path = "$env:temp\inventory.xml"

    # 将它加载入 XML 对象：
    $xml = New-Object -TypeName XML
    $xml.Load($Path)
    # 注意：如果 XML 格式是非法的，这里会报异常
    # 一定要注意节点名不能包含空格

    # 只需要在节点中自由遍历，就能 select 获得您要的信息：
    $Xml.Machines.Machine | Select-Object -Property Name, IP

结果大概是这样：

    Name          IP
    ----          --
    Server0001    31.248.95.170
    Server0002    33.60.233.89
    Server0003    226.6.1.30
    Server0004    139.30.8.110
    Server0005    94.104.253.8
    Server0006    202.80.178.61
    Server0007    22.217.227.159
    Server0008    253.72.25.212
    Server0009    233.147.116.60
    Server0010    41.173.220.129

注意：有些人奇怪我为什么不直接用 XML 对象。这段是你们常见的代码：

    # 这是 XML 例子文件的存储路径：
    $Path = "$env:temp\inventory.xml"

    # 将它读入一个 XML 对象：
    [XML]$xml = Get-Content $Path

原因是性能问题。通过 `Get-Content` 将 XML 以纯文本文件的方式读入，第二步再将它转换为 XML 是一个非常消耗性能的过程。虽然我们的 XML 文件不算大，后面的方式也要比第一种方式消耗多大约 7 倍的时间，而且随着 XML 文件的增大，性能差异会更明显。

所以建议在任何读取 XML 文件的时候，都先创建 XML 对象，并调用它的 `Load()` 方法。这个方法能够智能地接受 URL，所以您也可以用 RSS feed 的 URL 地址（假设有现成的 Internet 连接，并且不需要设置代理服务器）。

## 筛选特定的内容

假设您不想要整个服务器列表，而只是想要列表中某台服务器的 IP 地址以及 _info1_ 属性。你可以用类似这样的代码：

    $Xml.Machines.Machine |
    Where-Object { $_.Name -eq 'Server0009' } |
    Select-Object -Property IP, {$_.Information.info1}

这段代码将获取 _server0009_ 的 IP 地址以及 _info1_ 属性。您也可以不用在客户端过滤所有的元素，可以用 XPath（一种 XML 查询语言）来做：

    $item = Select-XML -Xml $xml -XPath '//Machine[Name="Server0009"]'
    $item.Node | Select-Object -Property IP, {$_.Information.Info1}

这段 XPath 查询语句 `//Machine[Name="Server0009"]` 在所有的 _Machine_ 节点中查找含有 _Name_ 子节点，且它的值为 _Server009_。

**强调**: XPath 是大小写敏感的，所以如果节点名称是 _Machine_，那么您不能用 _machine_ 来查询。

另外说一句，在这两种写法里，您都会用到脚本块来读写属性，这是因为 _“info1”_ 属性是 _“Information”_ 子节点的一部分。在这类场景中，您可以用哈希表来更好地呈现它的名字：

    $info1 = @{Name='AdditionalInfo'; Expression={$_.Information.Info1}}
    $item = Select-XML -Xml $xml -XPath '//Machine[Name="Server0009"]'
    $item.Node | Select-Object -Property IP, $info1

结果看起来如下：

    IP              AdditionalInfo
    --              --------------
    97.196.140.12   some info

XPath 是非常强大的 XML 查询语言。您在网上到处都可以找到它的语法介绍（比如这些链接：[http://www.w3schools.com/xpath/](http://www.w3schools.com/xpath/) 和 [http://go.microsoft.com/fwlink/?LinkId=143609](http://go.microsoft.com/fwlink/?LinkId=143609)）。当您阅读这些文档的时候，您会发现 XPath 可以使用一些称为“用户定义函数”的东西，比如 `last()` 和 `lowercase()`。这里不支持这些函数。

## 改变 XML 内容

您常常需要更改 XML 文档的内容。与其手工解析 XML 文档，不如用上刚刚学到的技术。

假设您想修改 _Server0006_ 并且为它赋值一个新的名称和一个新的 IP 地址，需要做以下事情：

    $item = Select-XML -Xml $xml -XPath '//Machine[Name="Server0006"]'
    $item.node.Name = "NewServer0006"
    $item.node.IP = "10.10.10.12"
    $item.node.Information.Info1 = 'new attribute info'

    $NewPath = "$env:temp\inventory2.xml"
    $xml.Save($NewPath)
    notepad $NewPath

如您所见，修改信息十分简单，所有做出的改变会自动反映到相应的 XML 对象中。您所需要做的只是将修改后的 XML 对象保存到文件，将修改的地方持久化起来。结果将显示在记事本中，看起来类似这样：

    <!--6. machine details-->
      <Machine test="559669990">
        <Name>NewServer0006</Name>
        <IP>10.10.10.12</IP>
        <GUID>cca8df99-78e1-48e0-8c4d-193c6d4acbd2</GUID>
        <Information info1="new attribute info" info2="more info">RawContent</Information>
        <CodeSegment info3="another attribute"><![CDATA[this is untouched code and can contain special characters /\@<>]]></CodeSegment>
      </Machine>

您不用任何解析工作就瞬间完成了对已有 XML 文档的修改，并且不会破坏 XML 的结构。

用同样的方式，您可以进行大量的修改。假设所有的服务器都要赋予一个新的名称。旧名称是 _“ServerXXXX”_，新名称是 _“Prod\_ServerXXXX”_。以下是解决方法：

    Foreach ($item in (Select-XML -Xml $xml -XPath '//Machine'))
    {
        $item.node.Name = 'Prod_' + $item.node.Name
    }

    $NewPath = "$env:temp\inventory2.xml"
    $xml.Save($NewPath)
    notepad $NewPath

请注意 XML 文档中的所有服务器名称都更新了。`Select-XML` 这回不仅返回一个对象，而是返回多个，每个对象都是一个服务器。这是因为这回的 XPath 选择所有的“Machine”节点，并没有做特别的过滤。所以 foreach 循环里对所有节点都进行了操作。

在循环内部，_Name_ 节点被赋予了一个新的值，当所有“Machine”节点都更新完以后，XML 文档被保存到文件并用记事本打开。

您可以能对这个例子有意见，为服务器名添加_“Prod\_”_前缀，这点小改动太弱智了。不过我们在这里主要是向您介绍如何改变 XML 数据，而不是关注怎么做字符串操作。

不过，如果您坚持想知道如何实现例如将 _“ServerXXXX”_ 替换成 _“PCXX”_（包括将四位数字转换为二位数字，这不算一个弱智的需求了吧），以下是解决方法：

    foreach($item in (Select-XML -Xml $xml -XPath '//Machine'))
    {
        if ($item.node.Name -match 'Server(\d{4})')
        {
          $item.node.Name = 'PC{0:00}' -f [Int]$matches[1]
        }
    }
    $NewPath = "$env:temp\inventory2.xml"
    $xml.Save($NewPath)
    notepad $NewPath

这次，我们用正则表达式以数字块的方式提取原先服务器的名称，然后用 `-f` 操作符重新格式化数字，并加上新的前缀。

我们这篇文章不关注正则表达式，也不关注数字的格式化。重要的是您能理解可以用任何技术来构造新的服务器名称。在剩下的部分，我们也遵循这一原则。

## 添加新数据

有些时候，改变数据还不够。您可能会需要向列表添加新的服务器。这也是十分简单的。您只需要选择一个已有的节点，把它克隆一份，然后更新它的内容，再将它附加到父节点上即可。通过这种方式，您无须自己创建复杂的节点结构，并且可以确保新节点的结构和已有的节点完全一致。

这段代码将向服务器列表添加一台新的机器：

    # 克隆已有的节点结构
    $item = Select-XML -Xml $xml -XPath '//Machine[1]'
    $newnode = $item.Node.CloneNode($true)

    # 根据需要更新信息
    # 所有其它信息都和原始节点中的一致
    $newnode.Name = 'NewServer'
    $newnode.IP = '1.2.3.4'

    # 获取您希望新节点所附加到的父节点：
    $machines = Select-XML -Xml $xml -XPath '//Machines'
    $machines.Node.AppendChild($newnode)

    $NewPath = "$env:temp\inventory2.xml"
    $xml.Save($NewPath)
    notepad $NewPath

由于您新加的节点是从已有的节点克隆的，所以旧节点的所有信息都拷贝到了新的节点。您不想更新的信息可以保持原有的值。

那么如何向列表的顶部插入新的节点呢？只需要用 `InsertBefore()` 代替 `AppendChild()`：

    # 向列表的顶部添加节点：
    $machines.Node.InsertBefore($newnode, $item.node)

类似地，您可以在任意处插入新的节点。以下代码将在 _Server0007_ 之后插入：

    # 在“Server0007”之后插入：
    $parent = Select-XML -Xml $xml -XPath '//Machine[Name="Server0007"]'
    $machines.Node.InsertAfter($newnode, $parent.node)

## 移除 XML 内容

从 XML 文件中删除数据也同样很简单。如果您想从列表中删掉 _Server0007_，以下是实现方法：

    # 删除“Server0007”：
    $item = Select-XML -Xml $xml -XPath '//Machine[Name="Server0007"]'
    $null = $item.Node.ParentNode.RemoveChild($item.node)

## 您指尖上的强大力量

通过以上展现的例子，您可以通过几行代码实现常见的 XML 操作需求。值得投入一些时间来提高 XML 和 XPath 的熟练度，这样您可以通过它们实现令人惊叹的功能。

对于一路读到这儿的朋友，我为你们准备了一点小礼物：一个我常用的很棒的小工具，我相信应该对你们也十分有用。

`_ConvertTo-XML` 可以将所有的对象转换为 XML，并且由于 XML 是一个分层的数据格式，所以通过控制深度，能够很好地展现嵌套的对象属性。所以您可以“展开”一个对象的结构并且查看它的所有属性，甚至递归地查看嵌套的属性。

不用 XML 和 XPath 的话，您只能查看原始的 XML 并且靠自己查找信息。例如，如果您想查看 PowerShell 的颜色信息到底存储在 $host 对象的什么地方，您可以这么做（也许不是一个好方法，因为您可能会被原始的 XML 信息淹没）：

    $host | ConvertTo-XML -Depth 5 | Select-Object -ExpandProperty outerXML

通过刚才演示的知识，您现在可以读取原始的 XML ，然后解析并过滤对象的属性。

以下是称为 `Get-ObjectProperty` 的辅助函数，有点类似 `Get-Member` 的意思。它能告诉您对象中的哪个属性存放了您想要的值。让我们来看看：

    PS> $host | Get-ObjectProperty -Depth 2 -Name *color*

    Name                    Value                   Path                    Type
    ----                    -----                   ----                    ----
    TokenColors                                     $obj1.PrivateData.To... Microsoft.PowerShel...
    ConsoleTokenColors                              $obj1.PrivateData.Co... Microsoft.PowerShel...
    XmlTokenColors                                  $obj1.PrivateData.Xm... Microsoft.PowerShel...
    ErrorForegroundColor    #FFFF0000               $obj1.PrivateData.Er... System.Windows.Medi...
    ErrorBackgroundColor    #FFFFFFFF               $obj1.PrivateData.Er... System.Windows.Medi...
    WarningForegroundColor  #FFFF8C00               $obj1.PrivateData.Wa... System.Windows.Medi...
    WarningBackgroundColor  #00FFFFFF               $obj1.PrivateData.Wa... System.Windows.Medi...
    VerboseForegroundColor  #FF00FFFF               $obj1.PrivateData.Ve... System.Windows.Medi...
    VerboseBackgroundColor  #00FFFFFF               $obj1.PrivateData.Ve... System.Windows.Medi...
    DebugForegroundColor    #FF00FFFF               $obj1.PrivateData.De... System.Windows.Medi...
    DebugBackgroundColor    #00FFFFFF               $obj1.PrivateData.De... System.Windows.Medi...
    ConsolePaneBackgroun... #FF012456               $obj1.PrivateData.Co... System.Windows.Medi...
    ConsolePaneTextBackg... #FF012456               $obj1.PrivateData.Co... System.Windows.Medi...
    ConsolePaneForegroun... #FFF5F5F5               $obj1.PrivateData.Co... System.Windows.Medi...
    ScriptPaneBackground... #FFFFFFFF               $obj1.PrivateData.Sc... System.Windows.Medi...
    ScriptPaneForeground... #FF000000               $obj1.PrivateData.Sc... System.Windows.Medi...

这将返回 _$host_ 中所有名字包含 _“Color”_ 的嵌套属性。控制台输出很可能被截断，所以您最好将结果输出到 grid view 窗口：

    $host | Get-ObjectProperty -Depth 2 -Name *color* | Out-GridView

请注意 _“Path”_ 列：这个属性精确指示了您如何存取一个指定的嵌套属性。在这个例子里，`Get-ObjectProperty` 在对象层次中遍历两层。如果指定更深的便利层次，将会展开更多的信息，不过也会导致结果中含有更多的垃圾信息。

虽然您可以通过管道输入多个对象，但是最好一次只导入一个，以免产生大量的结果数据。这行代码将列出进程对象所有嵌套的属性，递归层次为 5，将产生大量的结果：

    PS> Get-Process -id $pid | Get-ObjectProperty -Depth 5 -IsNumeric

    Name                    Value                   Path                    Type
    ----                    -----                   ----                    ----
    Handles                 684                     $obj1.Handles           System.Int32
    VM                      1010708480              $obj1.VM                System.Int32
    WS                      291446784               $obj1.WS                System.Int32
    PM                      251645952               $obj1.PM                System.Int32
    NPM                     71468                   $obj1.NPM               System.Int32
    CPU                     161,0398323             $obj1.CPU               System.Double
    BasePriority            8                       $obj1.BasePriority      System.Int32
    HandleCount             684                     $obj1.HandleCount       System.Int32
    Id                      4560                    $obj1.Id                System.Int32
    Size                    264                     $obj1.MainModule.Size   System.Int32
    ModuleMemorySize        270336                  $obj1.MainModule.Mod... System.Int32
    FileBuildPart           9421                    $obj1.MainModule.Fil... System.Int32
    FileMajorPart           6                       $obj1.MainModule.Fil... System.Int32
    FileMinorPart           3                       $obj1.MainModule.Fil... System.Int32
    ProductBuildPart        9421                    $obj1.MainModule.Fil... System.Int32
    ProductMajorPart        6                       $obj1.MainModule.Fil... System.Int32
    ProductMinorPart        3                       $obj1.MainModule.Fil... System.Int32
    Size                    264                     $obj1.Modules[0].Size   System.Int32
    ModuleMemorySize        270336                  $obj1.Modules[0].Mod... System.Int32
    (...)

这行代码将返回 spooler 服务对象中所有“String”类型的嵌套属性：

    PS> Get-Service -Name spooler | Get-ObjectProperty -Type System.String

    Name                    Value                   Path                    Type
    ----                    -----                   ----                    ----
    Name                    spooler                 $obj1.Name              System.String
    Name                    RPCSS                   $obj1.RequiredServic... System.String
    Name                    DcomLaunch              $obj1.RequiredServic... System.String
    DisplayName             DCOM Server Process ... $obj1.RequiredServic... System.String
    MachineName             .                       $obj1.RequiredServic... System.String
    ServiceName             DcomLaunch              $obj1.RequiredServic... System.String
    Name                    RpcEptMapper            $obj1.RequiredServic... System.String
    DisplayName             RPC Endpoint Mapper     $obj1.RequiredServic... System.String
    (...)


以下是 `Get-ObjectProperty` 的源代码。它虽然不只是几行代码，但仍然相当短小精悍。

它完全使用了刚才介绍的技术，所以如果您对以上的例子感到满意，您也可以尝试并消化它的代码，或只是把它当做一个工具，而不用关心它对 XML 做的魔法。

    Function Get-ObjectProperty
    {
      param
      (
        $Name = '*',
        $Value = '*',
        $Type = '*',
        [Switch]$IsNumeric,

        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Object[]]$InputObject,

        $Depth = 4,
        $Prefix = '$obj'
      )

      Begin
      {
        $x = 0
        Function Get-Property
        {
          param
          (
            $Node,
            [String[]]$Prefix
          )

          $Value = @{Name='Value'; Expression={$_.'#text' }}
          Select-Xml -Xml $Node -XPath 'Property' | ForEach-Object {$i=0} {
            $rv = $_.Node | Select-Object -Property Name, $Value, Path, Type
            $isCollection = $rv.Name -eq 'Property'

            if ($isCollection)
            {
              $CollectionItem = "[$i]"
              $i++
              $rv.Path = (($Prefix) -join '.') + $CollectionItem
            }
            else
            {
              $rv.Path = ($Prefix + $rv.Name) -join '.'
            }

            $rv

            if (Select-Xml -Xml $_.Node -XPath 'Property')
            {
              if ($isCollection)
              {
                $PrefixNew = $Prefix.Clone()
                $PrefixNew[-1] += $CollectionItem
                Get-Property -Node $_.Node -Prefix ($PrefixNew )
              }
              else
              {
                Get-Property -Node $_.Node -Prefix ($Prefix + $_.Node.Name )
              }
            }
          }
        }
      }

      Process
      {
        $x++
        $InputObject |
        ConvertTo-Xml -Depth $Depth |
        ForEach-Object { $_.Objects } |
        ForEach-Object { Get-Property $_.Object -Prefix $Prefix$x  } |
        Where-Object { $_.Name -like "$Name" } |
        Where-Object { $_.Value -like $Value } |
        Where-Object { $_.Type -like $Type } |
        Where-Object { $IsNumeric.IsPresent -eq $false -or $_.Value -as [Double] }
      }
    }
