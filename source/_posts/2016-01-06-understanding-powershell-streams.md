layout: post
date: 2016-01-06 12:00:00
title: "PowerShell 技能连载 - ___"
description: PowerTip of the Day - Understanding PowerShell Streams
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
PowerShell provides seven different streams you can use to output information. Streams help sort out information because streams can be muted. In fact, some streams are muted by default. Here is a sample function called Test-Stream. When you run it, it sends information to all seven streams.

Please note: Write-Information was added in PowerShell 5.0. Remove the call to Write-Information from the sample if you want to run it in older PowerShell versions!

    function Test-Stream
    {
        #region These are all the same and define return values
        'Return Value 1'
        echo 'Return Value 2'
        'Return Value 3' | Write-Output
        #endregion
        
        Write-Verbose 'Additional Information'
       Write-Debug 'Developer Information'
       Write-Host 'Mandatory User Information'
       Write-Warning 'Warning Information'
       Write-Error 'Error Information'
    
       # new in PowerShell 5.0
       Write-Information 'Auxiliary Information' 
    }
    

Here is what you will most likely see when you run Test-Stream:

     
    PS C:\> Test-Stream
    Return Value 1
    Return Value 2
    Return Value 3
    Mandatory User  Information
    WARNING: Warning  Information
    Test-Stream : Error  Information
    At line:1 char:1
    + Test-Stream
    + ~~~~~~~~~~~
        + CategoryInfo          : NotSpecified: (:) [Write-Error],  WriteErrorException
        + FullyQualifiedErrorId : Microsoft.PowerShell.Commands.WriteErrorException,Test-Stream 
     
    PS C:\> $result =  Test-Stream
    Mandatory User  Information
    WARNING: Warning  Information
    Test-Stream : Error  Information
    At line:1 char:1
    + Test-Stream
    + ~~~~~~~~~~~
        + CategoryInfo          : NotSpecified: (:) [Write-Error],  WriteErrorException
        + FullyQualifiedErrorId :  Microsoft.PowerShell.Commands.WriteErrorException,Test-Stream 
     
    PS C:\> $result
    Return Value 1
    Return Value 2
    Return Value 3
     
    PS C:\>
     

As you can see, echo and Write-Output work the same, and in fact are the same (because echo is an alias for Write-Output). They define the return value(s). They can be assigned to a variable. The same is true for unassigned values that your function leaves behind: they go to Write-Output as well.

Write-Host sends text output directly to the console, so it is guaranteed to be always visible. This cmdlet should be used for messages to the user.

The remaining streams are silent. To see the output from the remaining streams, you need to enable them first:

    $VerbosePreference = 'Continue'
    $DebugPreference = 'Continue'
    $InformationPreference = 'Continue'
    

Once you did this, Test-Stream produces output like this:

     
    PS C:\> Test-Stream
    Return Value 1
    Return Value 2
    Return Value 3
    VERBOSE: Additional Information
    DEBUG: Developer Information
    Mandatory User Information
    Auxiliary Information 
     

To restore the default values, reset the preference variables:

    $VerbosePreference = 'SilentlyContinue'
    $DebugPreference = 'SilentlyContinue'
    $InformationPreference = 'SilentlyContinue'
    

If you add the common parameters to your function, you can use -Verbose and -Debug when you call the function. Test-CommonParameter illustrates how you add common parameter support.

    function Test-CommonParameter
    {
        [CmdletBinding()]
        param()
        
        "VerbosePreference = $VerbosePreference"
        "DebugPreference = $DebugPreference"
    }
    

When you run Test-CommonParameter, you will immediately understand how the -Verbose and -Debug common parameters work: they simply change the local preference variables:

     
    PS C:\> Test-CommonParameter
    VerbosePreference = SilentlyContinue
    DebugPreference = SilentlyContinue
    
    PS C:\> Test-CommonParameters -Debug -Verbose
    VerbosePreference = Continue
    DebugPreference = Inquire

<!--more-->
本文国际来源：[Understanding PowerShell Streams](http://powershell.com/cs/blogs/tips/archive/2016/01/06/understanding-powershell-streams.aspx)
