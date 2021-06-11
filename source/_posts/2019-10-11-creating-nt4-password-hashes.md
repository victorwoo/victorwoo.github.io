---
layout: post
date: 2019-10-11 00:00:00
title: "PowerShell 技能连载 - 创建 NT4 密码哈希"
description: PowerTip of the Day - Creating NT4 Password Hashes
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在内部，ActiveDirectory 将所有密码存储为所谓的 NTLM 哈希。有许多安全分析工具可以读取和转储这些哈希。

幸运的是，没有可行的方法来解密这些散列并检索原始密码，您可以使用（已知）密码并将其转换为 NTLM 哈希。这是字典攻击的基本过程：他们获取到很长的“已知密码”列表，将它们转换为 NTLM 散列，当它们与实际的 AD 帐户散列匹配时，就算破解出了密码。

这样，您的安全部门就可以将密码黑名单中的不安全密码(如“P@ssw0rd”)转换为NTLM散列，并将它们与Active Directory的密码散列进行比较，以识别需要更改密码的帐户。

这是将纯文本变为 NTLM HASH 的 PowerShell 代码：

```powershell
    function ConvertTo-NTLMPasswordHash
    {
      #Work based on code found here: https://www.myotherpcisacloud.com/post/getmd4hash
      #Original Author: Ryan Ries, 2014
      param(
        [Parameter(Mandatory=$true)][string]$password
      )

      Function Get-MD4Hash
      {
        Param ([Parameter(Mandatory=$True, ValueFromPipeline=$False)]
        [Byte[]]$DataToHash)

          Set-StrictMode -Version Latest
          Add-Type -TypeDefinition @'
            using System;
            using System.Text;
            using System.Runtime.InteropServices;
            public class BCrypt
            {
                [DllImport("bcrypt.dll", CharSet = CharSet.Auto)]
                public static extern NTStatus BCryptOpenAlgorithmProvider(
                    [Out] out IntPtr phAlgorithm,
                    [In] string pszAlgId,
                    [In, Optional] string pszImplementation,
                    [In] UInt32 dwFlags);

                [DllImport("bcrypt.dll")]
                public static extern NTStatus BCryptCloseAlgorithmProvider(
                    [In, Out] IntPtr hAlgorithm,
                    [In] UInt32 dwFlags);

                [DllImport("bcrypt.dll", CharSet = CharSet.Auto)]
                public static extern NTStatus BCryptCreateHash(
                    [In, Out] IntPtr hAlgorithm,
                    [Out] out IntPtr phHash,
                    [Out] IntPtr pbHashObject,
                    [In, Optional] UInt32 cbHashObject,
                    [In, Optional] IntPtr pbSecret,
                    [In] UInt32 cbSecret,
                    [In] UInt32 dwFlags);

                [DllImport("bcrypt.dll")]
                public static extern NTStatus BCryptDestroyHash(
                    [In, Out] IntPtr hHash);

                [DllImport("bcrypt.dll")]
                public static extern NTStatus BCryptHashData(
                    [In, Out] IntPtr hHash,
                    [In, MarshalAs(UnmanagedType.LPArray)] byte[] pbInput,
                    [In] int cbInput,
                    [In] UInt32 dwFlags);

                [DllImport("bcrypt.dll")]
                public static extern NTStatus BCryptFinishHash(
                    [In, Out] IntPtr hHash,
                    [Out, MarshalAs(UnmanagedType.LPArray)] byte[] pbInput,
                    [In] int cbInput,
                    [In] UInt32 dwFlags);

                [Flags]
                public enum AlgOpsFlags : uint
                {
                    BCRYPT_PROV_DISPATCH = 0x00000001,
                    BCRYPT_ALG_HANDLE_HMAC_FLAG = 0x00000008,
                    BCRYPT_HASH_REUSABLE_FLAG = 0x00000020
                }

                // This is a gigantic enum and I don't want to copy all of it into this Powershell script.
                // Basically anything other than zero means something went wrong.
                public enum NTStatus : uint
                {
                    STATUS_SUCCESS = 0x00000000
                }
            }
    '@

          [Byte[]]$HashBytes   = New-Object Byte[] 16
          [IntPtr]$PHAlgorithm = [IntPtr]::Zero
          [IntPtr]$PHHash      = [IntPtr]::Zero
          $NTStatus = [BCrypt]::BCryptOpenAlgorithmProvider([Ref] $PHAlgorithm, 'MD4', $Null, 0)
          If ($NTStatus -NE 0)
          {
            Write-Error "BCryptOpenAlgorithmProvider failed with NTSTATUS $NTStatus"
            If ($PHAlgorithm -NE [IntPtr]::Zero)
            {
              $NTStatus = [BCrypt]::BCryptCloseAlgorithmProvider($PHAlgorithm, 0)
            }
            Return
          }
          $NTStatus = [BCrypt]::BCryptCreateHash($PHAlgorithm, [Ref] $PHHash, [IntPtr]::Zero, 0, [IntPtr]::Zero, 0, 0)
          If ($NTStatus -ne 0)
          {
            Write-Error "BCryptCreateHash failed with NTSTATUS $NTStatus"
            If ($PHHash -ne [IntPtr]::Zero)
            {
              $NTStatus = [BCrypt]::BCryptDestroyHash($PHHash)
            }
            If ($PHAlgorithm -ne [IntPtr]::Zero)
            {
              $NTStatus = [BCrypt]::BCryptCloseAlgorithmProvider($PHAlgorithm, 0)
            }
            Return
          }

          $NTStatus = [BCrypt]::BCryptHashData($PHHash, $DataToHash, $DataToHash.Length, 0)
          $NTStatus = [BCrypt]::BCryptFinishHash($PHHash, $HashBytes, $HashBytes.Length, 0)

          If ($PHHash -NE [IntPtr]::Zero)
          {
            $NTStatus = [BCrypt]::BCryptDestroyHash($PHHash)
          }
          If ($PHAlgorithm -NE [IntPtr]::Zero)
          {
            $NTStatus = [BCrypt]::BCryptCloseAlgorithmProvider($PHAlgorithm, 0)
          }

          $HashString = New-Object System.Text.StringBuilder
          Foreach ($Byte In $HashBytes)
          {
            $null = $HashString.Append($Byte.ToString("x2"))
          }
          $HashString.ToString()

      }
      Get-MD4Hash -DataToHash ([System.Text.Encoding]::Unicode.getBytes($password))
    }
```

<!--本文国际来源：[Creating NT4 Password Hashes](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/creating-nt4-password-hashes)-->

