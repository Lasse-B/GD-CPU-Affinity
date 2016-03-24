#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/sf
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <WinAPI.au3>

Opt("TrayAutoPause", 0) ; no auto-pause on click on tray icon

$CPUthreads = _Processor() ; see how many threads the CPU supports
$affinityMask = _CreateAffinityMask($CPUthreads) ; create an affinity mask to use only every other core

While 1
	Sleep(100)
	$PID = ProcessExists("Grim Dawn.exe") ; check if the Grim Dawn.exe process exists
	If $PID <> 0 Then
		WinWaitActive("[TITLE:Grim Dawn; CLASS:Grim Dawn]") ; wait for the game window to become responsive
		Sleep(5000) ; wait an additional five seconds just to be on the safe side, because changing affinity too early has no effect at all
		$hProc = _WinAPI_OpenProcess(0x1F0FFF, False, $PID) ; open a handle to the Grim Dawn process with full rights
		$ret = _WinAPI_SetProcessAffinityMask($hProc, $affinityMask) ; change CPU affinity to use only every other core
		$lasterr = _WinAPI_GetLastError() ; remember any last error thrown by the system
		_WinAPI_CloseHandle($hProc) ; close the handle
		If $ret <> 1 Then
			MsgBox(16, "Error", "Setting CPU affinity for Grim Dawn has failed." & @CRLF & "Error code " & $lasterr) ; notify user if setting CPU affinity failed
		EndIf
		Do
			Sleep(100) ; wait for Grim Dawn to close since we need to set CPU affinity just once for every session
		Until Not ProcessExists("Grim Dawn.exe")
	EndIf
WEnd

Func _Processor($Computer = "127.0.0.1")
	$WMIConnect = ObjGet('winmgmts:{impersonationLevel=impersonate}!\\' & $Computer & '\root\CIMV2')
	If Not IsObj($WMIConnect) Then Return SetError(-1, @error, 0)
	$ObjList = $WMIConnect.ExecQuery('SELECT Name FROM Win32_PerfRawData_PerfOS_Processor', 'WQL', 0x10 + 0x20)
	If Not IsObj($ObjList) Then Return SetError(-2, @error, 0)
	$iReturn = 0
	For $ObjItem In $ObjList
		If StringInStr($ObjItem.Name, "_Total") = 0 Then $iReturn += 1
	Next
	Return $iReturn
EndFunc   ;==>_Processor

Func _CreateAffinityMask($CPUthreads)
	Local $dMask = 1, $hMask = 1, $current = 1
	For $i = 2 To $CPUthreads
		$current *= 2
		If BitAND($i, 1) Then $dMask += $current
	Next
	$hMask = hex($dMask)
	Return "0x" & $hMask
EndFunc   ;==>_CreateAffinityMask
