---
layout: post
date: 2020-05-18 00:00:00
title: "PowerShell 技能连载 - 检测泄露的密码（第 2 部分）"
description: PowerTip of the Day - Identifying Compromised Passwords (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您想向 PowerShell 函数提交敏感信息时，通常使用 `SecureString` 类型。这种类型可确保用户通过一个带遮罩的对话框输入数据，这样能保护输入内容免受不会被旁人看到。

由于 `SecureString` 始终可以由创建 `SecureString` 的人解密为纯文本，因此您可以利用带的输入框，但仍可以使用输入的纯文本：

```powershell
function Test-Password
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory, Position=0)]
    [System.Security.SecureString]
    $Password
  )

  # take a SecureString and get the entered plain text password
  # we are using a SecureString only to get a masked input box
  $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
  $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

  "You entered: $plain"
}
```

当您运行代码然后运行 `Test-Password` 时，系统会提示您带有遮罩的输入。在函数内部，会将提交的 `SecureString` 解密为纯文本。

但是，这种方法有一个明显的缺点：如果希望通过参数传入信息，则现在必须提交 SecureString。您不能再传入纯文本：

```powershell
# fails:
PS> Test-Password -Password test
Test-Password : Cannot process argument transformation on parameter 'Password'. Cannot convert the "test" value of type "System.String" to type "System.Security.SecureString".

# works
PS> Test-Password -Password ("test" | ConvertTo-SecureString -AsPlainText -Force)
You entered: test
```

不过，使用自定义属性，您可以为任何参数添加自动功能，以将纯文本自动转换为 SecureString：

```powershell
# create a transform attribute that transforms plain text to a SecureString
class SecureStringTransformAttribute : System.Management.Automation.ArgumentTransformationAttribute
{
  [object] Transform([System.Management.Automation.EngineIntrinsics]$engineIntrinsics, [object] $inputData)
  { if ($inputData -is [SecureString]) { return $inputData }
      elseif ($inputData -is [string]) { return $inputData | ConvertTo-SecureString -AsPlainText -Force }
    throw "Unexpected Error."
  }
}

function Test-Password
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory, Position=0)]
    [System.Security.SecureString]
    [SecureStringTransform()]
    $Password
  )

  # take a SecureString and get the entered plain text password
  # we are using a SecureString only to get a masked input box
  $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
  $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

  "You entered: $plain"
}
```

现在，用户可以在不使用参数的情况下运行 `Test-Password`，并获得带掩码对话框的提示。用户还可以直接传入纯文本：

```powershell
# use built-in masked input
PS> Test-Password
cmdlet Test-Password at command pipeline position 1
Supply values for the following parameters:
Password: ******
You entered: secret

# use text-to-SecureString transformation attribute
PS> Test-Password -Password secret
You entered: secret
```

如果您想了解转换属性的工作原理，请查看以下详细信息：[https://powershell.one/powershell-internals/attributes/transformation](https://powershell.one/powershell-internals/attributes/transformation)

<!--本文国际来源：[Identifying Compromised Passwords (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/identifying-compromised-passwords-part-2)-->

