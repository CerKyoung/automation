$Path = "F:\Dumps"
#
$Comp=$env:COMPUTERNAME
$File = Get-ChildItem $Path | Where { $_.LastWriteTime -ge [datetime]::Now.AddMinutes(-5) }
If ($File)
{   $EventGeneral = "`nThe following Dump Files have recently been added/changed on $comp :`n`n"
	$File | ForEach { $EventGeneral += "$($_.FullName)`n" }
    write-EventLog -LogName DayforceHCM -Source "DF Hosting" -EntryType Information -EventId 11 -message "$EventGeneral"
}