#requires -runasadministrator

Get-ChildItem -rec 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall' | Where-Object { 
    try {
        $displayname = (Get-ItemPropertyValue -Path $_.PSPath -Name 'DisplayName' -ErrorAction SilentlyContinue)
     }
     catch {
         $displayname = $null
     } 
     $displayname -match '^VLC media player' } | ForEach-Object {
    $displayname = Get-ItemPropertyValue -path $_.PSPath -Name 'DisplayName'
    $installlocation = Get-ItemPropertyValue -path $_.PSPath -Name 'InstallLocation'
    $displayversion = Get-ItemPropertyValue -path $_.PSPath -Name 'DisplayVersion'
    $exe = Join-Path -Path $installlocation -ChildPath 'vlc.exe'
    $exeversion = (Get-Item -LiteralPath $exe).VersionInfo.ProductVersionRaw.ToString()
    if ($displayversion -ne $exeversion)
    {
        Write-Host -ForegroundColor Yellow ("Display version for '{0}' is {1} whereas the EXE's version is {2} -- updating" -f $displayname, $displayversion, $exeversion)
        Set-ItemProperty -Path $_.PSPath -Name 'DisplayVersion' -Value $exeversion
    }
}
