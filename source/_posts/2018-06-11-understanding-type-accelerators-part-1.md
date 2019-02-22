---
layout: post
date: 2018-06-11 00:00:00
title: "PowerShell 技能连载 - 理解类型加速器（第 1 部分）"
description: PowerTip of the Day - Understanding Type Accelerators (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
“类型加速器”类似 .NET 类型别名。它们的目的是节约打字。例如，`[ADSI]` “类型”实际上并不存在。它只不过是 `System.DirectoryServices.DirectoryEntry` 的别名。您可以将 `[ADSI]` 替换为 `[System.DirectoryServices.DirectoryEntry]`：

```powershell
PS> [ADSI].FullName
System.DirectoryServices.DirectoryEntry


PS> [System.DirectoryServices.DirectoryEntry].FullName
System.DirectoryServices.DirectoryEntry
```

由于类型加速器是硬编码进 PowerShell 中的，所以使用它们是安全的。以下这行代码将显示所有预定义的类型加速器，如果您想使用 .NET 类型，您可以选用列表中的内容，因为它们在 PowerShell 中都很重要：

```powershell
PS> [PSObject].Assembly.GetType('System.Management.Automation.TypeAccelerators')::Get

Key                          Value
---                          -----
Alias                        System.Management.Automation.AliasAttribute
AllowEmptyCollection         System.Management.Automation.AllowEmptyCollecti...
AllowEmptyString             System.Management.Automation.AllowEmptyStringAt...
AllowNull                    System.Management.Automation.AllowNullAttribute
ArgumentCompleter            System.Management.Automation.ArgumentCompleterA...
array                        System.Array
bool                         System.Boolean
byte                         System.Byte
char                         System.Char
CmdletBinding                System.Management.Automation.CmdletBindingAttri...
datetime                     System.DateTime
decimal                      System.Decimal
double                       System.Double
DscResource                  System.Management.Automation.DscResourceAttribute
float                        System.Single
single                       System.Single
guid                         System.Guid
hashtable                    System.Collections.Hashtable
int                          System.Int32
int32                        System.Int32
int16                        System.Int16
long                         System.Int64
int64                        System.Int64
ciminstance                  Microsoft.Management.Infrastructure.CimInstance
cimclass                     Microsoft.Management.Infrastructure.CimClass
cimtype                      Microsoft.Management.Infrastructure.CimType
cimconverter                 Microsoft.Management.Infrastructure.CimConverter
IPEndpoint                   System.Net.IPEndPoint
NullString                   System.Management.Automation.Language.NullString
OutputType                   System.Management.Automation.OutputTypeAttribute
ObjectSecurity               System.Security.AccessControl.ObjectSecurity
Parameter                    System.Management.Automation.ParameterAttribute
PhysicalAddress              System.Net.NetworkInformation.PhysicalAddress
pscredential                 System.Management.Automation.PSCredential
PSDefaultValue               System.Management.Automation.PSDefaultValueAttr...
pslistmodifier               System.Management.Automation.PSListModifier
psobject                     System.Management.Automation.PSObject
pscustomobject               System.Management.Automation.PSObject
psprimitivedictionary        System.Management.Automation.PSPrimitiveDictionary
ref                          System.Management.Automation.PSReference
PSTypeNameAttribute          System.Management.Automation.PSTypeNameAttribute
regex                        System.Text.RegularExpressions.Regex
DscProperty                  System.Management.Automation.DscPropertyAttribute
sbyte                        System.SByte
string                       System.String
SupportsWildcards            System.Management.Automation.SupportsWildcardsA...
switch                       System.Management.Automation.SwitchParameter
cultureinfo                  System.Globalization.CultureInfo
bigint                       System.Numerics.BigInteger
securestring                 System.Security.SecureString
timespan                     System.TimeSpan
uint16                       System.UInt16
uint32                       System.UInt32
uint64                       System.UInt64
uri                          System.Uri
ValidateCount                System.Management.Automation.ValidateCountAttri...
ValidateDrive                System.Management.Automation.ValidateDriveAttri...
ValidateLength               System.Management.Automation.ValidateLengthAttr...
ValidateNotNull              System.Management.Automation.ValidateNotNullAtt...
ValidateNotNullOrEmpty       System.Management.Automation.ValidateNotNullOrE...
ValidatePattern              System.Management.Automation.ValidatePatternAtt...
ValidateRange                System.Management.Automation.ValidateRangeAttri...
ValidateScript               System.Management.Automation.ValidateScriptAttr...
ValidateSet                  System.Management.Automation.ValidateSetAttribute
ValidateTrustedData          System.Management.Automation.ValidateTrustedDat...
ValidateUserDrive            System.Management.Automation.ValidateUserDriveA...
version                      System.Version
void                         System.Void
ipaddress                    System.Net.IPAddress
DscLocalConfigurationManager System.Management.Automation.DscLocalConfigurat...
WildcardPattern              System.Management.Automation.WildcardPattern
X509Certificate              System.Security.Cryptography.X509Certificates.X...
X500DistinguishedName        System.Security.Cryptography.X509Certificates.X...
xml                          System.Xml.XmlDocument
CimSession                   Microsoft.Management.Infrastructure.CimSession
adsi                         System.DirectoryServices.DirectoryEntry
adsisearcher                 System.DirectoryServices.DirectorySearcher
wmiclass                     System.Management.ManagementClass
wmi                          System.Management.ManagementObject
wmisearcher                  System.Management.ManagementObjectSearcher
mailaddress                  System.Net.Mail.MailAddress
scriptblock                  System.Management.Automation.ScriptBlock
psvariable                   System.Management.Automation.PSVariable
type                         System.Type
psmoduleinfo                 System.Management.Automation.PSModuleInfo
powershell                   System.Management.Automation.PowerShell
runspacefactory              System.Management.Automation.Runspaces.Runspace...
runspace                     System.Management.Automation.Runspaces.Runspace
initialsessionstate          System.Management.Automation.Runspaces.InitialS...
psscriptmethod               System.Management.Automation.PSScriptMethod
psscriptproperty             System.Management.Automation.PSScriptProperty
psnoteproperty               System.Management.Automation.PSNoteProperty
psaliasproperty              System.Management.Automation.PSAliasProperty
psvariableproperty           System.Management.Automation.PSVariableProperty
```

<!--本文国际来源：[Understanding Type Accelerators (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/understanding-type-accelerators-part-1)-->
