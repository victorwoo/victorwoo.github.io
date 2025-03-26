---
layout: post
date: 2023-05-23 00:00:48
title: "PowerShell 技能连载 - 创建 ISO 文件"
description: PowerTip of the Day - Creating ISO Files
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 可以将普通文件夹转换为 ISO 文件。ISO 文件是二进制文件，可以被挂载并表现得像只读 CD-ROM 驱动器。

过去，ISO 文件常用于挂载安装媒体。如今，您可以轻松地创建自己的 ISO 文件，这些文件是从您自己的文件夹和文件中创建的。这样，您可以创建一个简单的备份系统，或者轻松地在同事之间共享项目。由于 ISO 文件只是一个单一的文件，因此可以轻松地共享，而且由于 Windows 通过双击挂载它们，并在 Windows 资源管理器中显示它们作为 CD-ROM 驱动器，您可以立即使用数据而无需提取或解压任何内容。

与 VHD 映像文件不同，挂载 ISO 文件不需要管理员特权。任何人都可以挂载和使用 ISO 文件。

由于没有内置的 cmdlet 将文件夹结构转换为 ISO 文件，您需要自己调用内部 API。下面的代码定义了新函数 `New-IsoFile`：

```powershell
function New-IsoFile
{
  param
  (
    # path to local folder to store in
    # new ISO file (must exist)
    [Parameter(Mandatory)]
    [String]
    $SourceFilePath,

    # name of new ISO image (arbitrary,
    # turns later into drive label)
    [String]
    $ImageName = 'MyCDROM',

    # path to ISO file to be created
    [Parameter(Mandatory)]
    [String]
    $NewIsoFilePath,

    # if specified, the source base folder is
    # included into the image file
    [switch]
    $IncludeRoot
  )

  # use this COM object to create the ISO file:
  $fsi = New-Object -ComObject IMAPI2FS.MsftFileSystemImage

  # use this helper object to write a COM stream to a file:
  # compile the helper code using these parameters:
  $cp = [CodeDom.Compiler.CompilerParameters]::new()
  $cp.CompilerOptions = '/unsafe'
  $cp.WarningLevel = 4
  $cp.TreatWarningsAsErrors = $true
  $code = '
    using System;
    using System.IO;
    using System.Runtime.InteropServices.ComTypes;

    namespace CustomConverter
    {
     public static class Helper
     {
      // writes a stream that came from COM to a filesystem file
      public static void WriteStreamToFile(object stream, string filePath)
      {
       // open output stream to new file
       IStream inputStream = stream as IStream;
       FileStream outputFileStream = File.OpenWrite(filePath);
       int bytesRead = 0;
       byte[] data;

       // read stream in chunks of 2048 bytes and write to filesystem stream:
       do
       {
        data = Read(inputStream, 2048, out bytesRead);
        outputFileStream.Write(data, 0, bytesRead);
       } while (bytesRead == 2048);

       outputFileStream.Flush();
       outputFileStream.Close();
      }

      // read bytes from stream:
      unsafe static private byte[] Read(IStream stream, int byteCount, out int readCount)
      {
       // create a new buffer to hold the read bytes:
       byte[] buffer = new byte[byteCount];
       // provide a pointer to the location where the actually read bytes are reported:
       int bytesRead = 0;
       int* ptr = &bytesRead;
       // do the read:
       stream.Read(buffer, byteCount, (IntPtr)ptr);
       // return the read bytes by reference to the caller:
       readCount = bytesRead;
       // return the read bytes to the caller:
       return buffer;
      }
     }
  }'

  Add-Type -CompilerParameters $cp -TypeDefinition $code

  # define the ISO file properties:

  # create CDROM, Joliet and UDF file systems
  $fsi.FileSystemsToCreate = 7
  $fsi.VolumeName = $ImageName
  # allow larger-than-CRRom-Sizes
  $fsi.FreeMediaBlocks = -1

  $msg = 'Creating ISO File - this can take a couple of minutes.'
  Write-Host $msg -ForegroundColor Green

  # define folder structure to be written to image:
  $fsi.Root.AddTreeWithNamedStreams($SourceFilePath,$IncludeRoot.IsPresent)

  # create image and provide a stream to read it:
  $resultimage = $fsi.CreateResultImage()
  $resultStream = $resultimage.ImageStream

  # write stream to file
  [CustomConverter.Helper]::WriteStreamToFile($resultStream, $NewIsoFilePath)

  Write-Host 'DONE.' -ForegroundColor Green

}
```

运行此代码后，您现在将拥有一个名为“`New-IsoFile`”的新命令。从现有文件夹结构创建ISO文件现在变得轻而易举 - 只需确保源文件路径存在即可：

```powershell
PS> New-IsoFile -NewIsoFilePath $env:temp\MyTest.iso -ImageName Holiday -SourceFilePath 'C:\HolidayPics'
```

您将在临时文件夹（或您指定的其他文件路径）中获得一个新的 ISO 文件。如果您按照示例操作，只需打开临时文件夹：

```powershell
PS> explorer /select,$env:temp\MyTest.iso
```

当你在Windows资源管理器中双击ISO文件时，该映像将作为一个新的光驱挂载，你可以立即看到映像文件中存储的数据的副本。

在Windows资源管理器中右键单击新的光驱，并从上下文菜单中选择“弹出”将卸载该光驱。
<!--本文国际来源：[Creating ISO Files](https://blog.idera.com/database-tools/powershell/powertips/creating-iso-files/)-->

