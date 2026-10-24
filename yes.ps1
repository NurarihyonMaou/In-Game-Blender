$directory = "F:\XXMI\Games\Genshin\GIMI\Mods"  # Replace with the actual path
$globalCount = 0
$iniFiles = Get-ChildItem -Path $directory -Filter "*.ini" -Recurse
foreach ($iniFile in $iniFiles) {
  $content = Get-Content -Path $iniFile.FullName
  $globalCount += ($content | Select-String -Pattern "global" -CaseSensitive:$false).Count
}
Write-Host "The word 'global' appears a total of $globalCount times in the INI files in '$directory'.