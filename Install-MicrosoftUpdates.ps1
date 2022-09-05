Function Initialize-Reboot {
	$TaskSequence = New-Object -ComObject "Microsoft.SMS.TSEnvironment"
	$TaskSequence.Value("SMSTSRetryRequested") = $True
	$TaskSequence.Value("SMSTSRebootRequested") = $True
}

Try {
    Import-Module -Name PSWindowsUpdate
    $Updates = Get-WindowsUpdate
    If ($Updates) {
        $NewUpdates = $True
        Do {
            Install-WindowsUpdate -AcceptAll -IgnoreReboot -Confirm:$False
            If (Get-ChildItem -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -ErrorAction SilentlyContinue) {
                Initialize-Reboot
                $NewUpdates = $False
            } ElseIf (Get-Item -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -ErrorAction SilentlyContinue) {
                Initialize-Reboot
                $NewUpdates = $False
            } ElseIf (Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager" -Name "PendingFileRenameOperations" -ErrorAction SilentlyContinue) {
                Initialize-Reboot
                $NewUpdates = $False
            } ElseIf ((([WMIClass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities").DetermineIfRebootPending().RebootPending) -eq $True) {
                Initialize-Reboot
                $NewUpdates = $False
            }
            If ($NewUpdates -eq $True) {
                $Updates = Get-WindowsUpdate
                If (-not ($Updates)) {
                    $NewUpdates = $False
                }
            }
        } While ($NewUpdates -eq $True)
    }
    Else {
        Exit 0
    }
}
Catch {
    Exit 1
}
