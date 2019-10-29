Import-Module posh-git
Import-Module PSReadLine

Remove-Item alias:cp -force
Remove-Item alias:rm -force
Remove-Item alias:ls -force
Remove-Item alias:rmdir -force
Remove-Item alias:mv -force
Remove-Item alias:diff -force

Set-Alias find C:\apps\gnuwin32\bin\find.exe
Set-PSReadlineOption -EditMode Emacs
Set-PSReadlineKeyHandler -Key ctrl+d -Function ViExit

Function Ls-Real {
    C:\apps\gnuwin32\bin\ls.exe --color @Args
}

Set-Alias ls Ls-Real
