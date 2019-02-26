---
layout: post
date: 2019-02-22 00:00:00
title: "PowerShell 技能连载 - 创建 ASCII 艺术"
description: PowerTip of the Day - Create ASCII Art
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 的功能令人惊叹：只需要几行代码，就可以将任意照片和图片转化为一段 ASCII 艺术。PowerShell 只需要加载图片，然后然后逐行逐列扫描它，然后基于每个像素的亮度将每个像素替换为一个 ASCII 字符。

以下是该函数：

```powershell
 function Convert-ImageToAsciiArt
{
  param(
    [Parameter(Mandatory)][String]
    $Path,
    
    [ValidateRange(20,20000)]
    [int]$MaxWidth=80,
    
    # character height:width ratio
    [float]$ratio = 1.5
  )

  # load drawing functionality
  Add-Type -AssemblyName System.Drawing
  
  # characters from dark to light
  $characters = '$#H&@*+;:-,. '.ToCharArray()
  $c = $characters.count
  
  # load image and get image size
  $image = [Drawing.Image]::FromFile($path)
  [int]$maxheight = $image.Height / ($image.Width / $maxwidth)/ $ratio
  
  # paint image on a bitmap with the desired size
  $bitmap = new-object Drawing.Bitmap($image,$maxwidth,$maxheight)
  
  
  # use a string builder to store the characters
  [System.Text.StringBuilder]$sb = ""
  
  # take each pixel line...
  for ([int]$y=0; $y -lt $bitmap.Height; $y++){
    # take each pixel column...
    for ([int]$x=0; $x -lt $bitmap.Width; $x++){
      # examine pixel
      $color = $bitmap.GetPixel($x,$y)
      $brightness = $color.GetBrightness()
      # choose the character that best matches the
      # pixel brightness
      [int]$offset = [Math]::Floor($brightness*$c)
      $ch = $characters[$offset]
      if (-not $ch){ $ch = $characters[-1] }      
      # add character to line
      $null = $sb.Append($ch)
    }
    # add a new line
    $null = $sb.AppendLine()
  }

  # clean up and return string
  $image.Dispose()
  $sb.ToString()
}
```

以下是它的使用方法：

```powershell
$Path = "C:\Users\Tobias\Desktop\Somepic.jpg"
$OutPath = "$env:temp\asciiart.txt"

Convert-ImageToAsciiArt -Path $Path -MaxWidth 150 |
  Set-Content -Path $OutPath -Encoding UTF8 


Invoke-Item -Path $OutPath 
```

请确保调整了代码中的路径。将会在缺省的文本编辑器中打开 ASCII 艺术。请确保禁用了换行，选择一个等宽的字体和一个足够小的字号！
                                                                                                        
                                                                                                                                
                                             ;@&&&&&&@&&&&@+-                                           
                                           :@&&&&&&&&&&&&&&&&&&:.                                       
                                         ,&&&&&&&&&&&&&&&&&&&&&&&&&&*                                   
                                      -@&&&&&&&&&&&HHHHHH&&&&&&&&&&&&&*                                 
                                   :&&&&&&&&&&&&H&&&&&&&&&&&&&&&&&&&&&&&@                               
                                  *&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&,                             
                                 :&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&-                            
                                *&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*                           
                               &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&                          
                              @&&&&&&&&H&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&-                        
                             &&&&&&&&H&&&@;:+&&&&&&&*-....,:@&&&&&&&&&&&&&&&&&&&@                       
                            &&&&&&&&H&&;........................*&&&&&&&H&&&&&&&&&.                     
                          .&&&&&&&&&H;...........................&&&&&&&&H&&&&&&&&&-                    
                         ;&&&&&&&&&&:............................@@&&&&&&H&&&&&&&&&&                    
                        &&&&&&&&&&&.+...........................-.;&&&H&&H&&&&&&&&&&@                   
                       *&H&&&&&&&&;;..............................+@+&&HH&&&&&&&&&&&&                   
                       ;&H&&&&&&&&................................@*.&&&H&&&&&&&&&&&&:                  
                       :&H&&&&&&&*...............................:*..&H&&&&&&&&&&&&&&@                  
                       ,&&H&&&@&@...................................,&&&&&&&&&&&&&&&&&,                 
                       ,&&&&&&:+....................................+*.;:&&&&&&&&&&&&&&                 
                       +&&&&&&............................................@*@+&&&&&&&&&,                
                       &&&&&&;............................................,-..-+&&&&&&&                 
                      :&&&&&@-...................................................:&&&&&,                
                      &&&&&&&.....................................................&&&&&-                
                      &&&&&&+.....................................................&&&&&,,               
                      :&&&&&;.....................................................&&&H&                 
                       &&&&&;.......................................,.,...........&&&&H&@               
                      *-&&&&:...*&&&&&&&&&&&&&@*,.............-*&&&&&&&&&&&&:.....@&&&&+                
                        &&&&:.+&&HHHHHHHHHHHHH&&&&..........+&&&&HHHHHHHHHHHHH*...+&&&&@                
                       ,###H*+;;:,...........-;*&&##########&&&*:..........:;*@:;*&###H:                
                       :##H*.......................#@;---+#;.......................@###.                
                      ,@###+............+HH&+.....-&......-*......;&H&*............&##:.                
                       ,&&#-...........HHH&+H;....@;......,#.....@HHH;H@...........HH&-.                
                       ..;#,...........HHHHHH+....#........H,....&HHHHH&..........-#&:-                 
                       ...H*...........-;;;;;....-H........;@....,;;;;;,..........;#&..                 
                       ...&#.....................#-.........#.....................&H*..                 
                       ...:H&........,.........-#@..........-#;..........,,......:#&,..                 
                        ...-,&###&+::-,,::+&###+......  ......-###H*:::,,::+@####,....                  
                        ..........,,,,,,,,...........   ............,,,,,,,,..........                  
                         ............................   ..............................                  
                         ............................   .............................                   
                          .....................,.....   ............................                    
                           ....................,.....   .......,...................                     
                             ..................,,,...   .......,.................                       
                              ......................,.  ..,......................                       
                              ........................,,,.......................                        
                              ..................................................                        
                               .................................................                        
                               .............,-..................--.............                         
                                ...............--,,-----:-,. --...............                          
                                 ..................,,----,,...................                          
                                  ...........................................                           
                                   .........................................                            
                                    ......................................                              
                                     ....................................                               
                                       ................................                                 
                                        ..............................                                  
                                         .,,,,,,,,,,,,,,,,,,,,,,,,,,                                    
                                       ,&...,,,,,,,,,,,,,,,,,,,,,,...@,                                 
                                    &HHH......,,,,,,,,,,,,,,,,,,.....-HHH&                              
                                :HHHHHHH&.........,,,,,,,,,,,........HHHHHHHH;                          
                             *HHHHHHHHHHHH+........................*HHHHHHHHHHHH@                       
                          -HHHHHHHHHHHHHHHHH&;..................;&HHHHHHHHHHHHHHHHH,                    
                         HHHHHHHHHHHHHHHHHHHHHHHH&*;:---::;*&HHHHHHHHHHHHHHHHHHHHHHH&                   
                        HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH                  
    
这儿有一个很酷的优化技巧：在 `Convert-ImageToAsciiArt` 函数中，请注意 `$characters`。它是一个包含 ASCII 艺术中使用的字符的字符串，而这些字符是按亮度降序排列的。对于黑白作品，可以使用：

```powershell
$characters = [char]0x2588, ' '
```

<!--本文国际来源：[Create ASCII Art](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/create-ascii-art)-->
