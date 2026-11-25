// Tour_target — the native helper target for the current platform.
//
// Overlay 0.1.1 ships a universal macOS helper and a Windows x64 helper. The
// Windows target must be requested explicitly; an omitted target is macOS.

#DECLARE()->$target : Text
If (Is Windows)
	// Native Windows ARM64 is not supported by Overlay 0.1.1. This is the x64
	// helper, reached through the OS emulation layer on ARM64 Windows.
	$target:="Windows-x64"
Else
	$target:="macOS-universal"
End if
