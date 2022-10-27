function Get-Ed2kLink {
    Param(
        [string]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage = 'Enter an ed2k:// url')]
        $Link
    )

    $regex = [regex]@'
(?x)
\bed2k://
\|file\|(?<FILE_NAME>[^|]+)
\|(?<FILE_SIZE>\d+)
\|(?<FILE_HASH>[0-9a-fA-F]+)
(?:\|p=(?:(?<HASH_SET>[0-9a-fA-F]+):?)+)?
(?:\|h=(?<ROOT_HASH>[0-9a-zA-Z]+))?
(?:\|s=(?<HTTP_SOURCE>[^|]+))*
\|\/
\|sources(?:,(?<SOURCES_HOST>[0-9a-zA-Z.]+):(?<SOURCES_PORT>\d+))*
|\/\b
'@
    $match = $regex.Match($Link)
    if ($match.Success) {
        $sourcesHost = $match.Groups['SOURCES_HOST'].Captures | Select-Object -ExpandProperty Value
        $sourcesPort = $match.Groups['SOURCES_PORT'].Captures | Select-Object -ExpandProperty Value
        $sources = @()
        for ($i = 0; $i -lt $sourcesHost.Length; $i++) {
            $sources += [PSCustomObject][Ordered]@{
                Host = $sourcesHost[$i]
                Port = $sourcesPort[$i]
            }
        }

        $result = [PSCustomObject][Ordered]@{
            File = $match.Groups['FILE_NAME'].Value;
            FileSize = $match.Groups['FILE_SIZE'].Value;
            FileHash = $match.Groups['FILE_HASH'].Value;
            HashSet = $match.Groups['HASH_SET'].Captures | Select-Object -ExpandProperty Value
            RootHash = $match.Groups['ROOT_HASH'].Value;
            HttpSource = $match.Groups['HTTP_SOURCE'].Captures | Select-Object -ExpandProperty Value
            Sources = $sources;
        }
    } else {
	    $result = $null
    }

    return $result
}

Get-Ed2kLink 'ed2k://|file|BingPinyinSetup_1.5.24.02.exe|31485072|C8C9282E6112455E624EE82941E5BA00|p=79A822E1788353E0B289D2ADD5DA3BDE:FB9BB40DEDB1D2307E9D734A6416704B:0732B122C4ECF70065B181C92BF72400:437958DF590D764DE1694F91AC085225|h=HLXRQSANEO5MHIVOYNM5FNQOHJG3D5MP|s=http://www.abc.com/def.zip|s=http://www.vichamp.com/qq.zip|/|sources,127.0.0.1:1234,192.168.1.1:8888|/'