New-ItemProperty -Path HKCU:\Software\Microsoft\GameBar -Name 'AllowAutoGameMode' -Value '0' -Type DWORD -Force

New-ItemProperty -Path HKCU:\Software\Microsoft\GameBar -Name 'AutoGameModeEnabled' -Value '0' -Type DWORD -Force