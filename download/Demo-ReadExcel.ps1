#requires -version 2.0

<#
  Integrating Excel with PowerShell Part 3 Sample script
  
  Run the script with -Visible if you want to see
  the Excel spreadsheet

#>

[cmdletbinding()]

Param ([switch]$Visible)

$file="c:\work\testdata.xlsx"

$xl=New-Object -ComObject "Excel.Application" 
$wb=$xl.Workbooks.Open($file)

$ws=$wb.ActiveSheet

$xl.visible=$Visible

$Row=2

do {
  $data=$ws.Range("A$Row").Text

  if ($data) {
    Write-Verbose "Querying $data" 
      $ping=Test-Connection -ComputerName $data -Quiet
      if ($Ping) {
        $OS=(Get-WmiObject -Class Win32_OperatingSystem -Property Caption -computer $data).Caption
      }
      else {
        $OS=$Null
      }
      New-Object -TypeName PSObject -Property @{
        Computername=$Data.ToUpper()
        OS=$OS
        Ping=$Ping
        Location=$ws.Range("B$Row").Text
        AssetAge=((Get-Date)-($ws.Range("D$Row").Text -as [datetime])).TotalDays -as [int]
      }
  }
  #increment the row counter
  $Row++
} While ($data)

#close Excel
#$xl.displayAlerts=$False
$wb.Close()
$xl.Quit()

Write-Verbose "Finished"