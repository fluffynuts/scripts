# copy this to $PROFILE.CurrentUserCurrentHost

Import-Module posh-git
Import-Module PSReadLine

Remove-Item alias:cp
Remove-Item alias:rm
Remove-Item alias:ls
Remove-Item alias:rmdir
Remove-Item alias:mv

Set-Alias find C:\apps\gnuwin32\bin\find.exe
Set-PSReadlineOption -EditMode Emacs
Set-PSReadlineKeyHandler -Key ctrl+d -Function ViExit
