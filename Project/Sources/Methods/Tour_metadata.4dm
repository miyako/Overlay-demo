// Tour_metadata — read version, capabilities and screens from the helper.
//
// These three calls are synchronous (each launches the bundled CLI once). They
// are the only blocking calls in the demo; display is always asynchronous.

var $overlay : cs.Overlay.Overlay
var $result : Object
var $previous : Text
var $version; $summary; $screens : Text
var $screen : Object
var $modes : Collection
var $i : Integer

$previous:=Method called on error(ek local)
ON ERR CALL("Tour_error_capture"; ek local)
$overlay:=cs.Overlay.Overlay.new(Tour_target)

$result:=$overlay.version()
If ((Value type($result)=Is object) & $result.ok)
	If (Value type($result.value.version)=Is text)
		Form.version:=$result.value.version
	End if
End if

$result:=$overlay.capabilities()
If ((Value type($result)=Is object) & $result.ok)
	Form.capabilities:=$result.value
End if

$result:=$overlay.screens()
If ((Value type($result)=Is object) & $result.ok)
	If (Value type($result.value.screens)=Is collection)
		Form.screens:=$result.value.screens
	End if
End if

ON ERR CALL($previous; ek local)

If (Form.version#"")
	Form.metaVersion:="overlay-cli "+Form.version
Else
	Form.metaVersion:="overlay-cli unavailable"
End if

$summary:="PNG"
If (Form.capabilities#Null)
	If (Value type(Form.capabilities.modes)=Is collection)
		$modes:=Form.capabilities.modes
		If ($modes.length>0)
			$summary:="PNG · "
			For ($i; 0; $modes.length-1)
				If ($i>0)
					$summary:=$summary+"+"
				End if
				$summary:=$summary+String($modes[$i])
			End for
		End if
	End if
	If (Form.capabilities.modal=False)
		$summary:=$summary+" · no modal"
	End if
End if
Form.metaCap:=$summary

If (Form.screens.length>0)
	$screen:=Form.screens[0]
	Form.primaryScreen:=$screen
	$screens:="screen "+String($screen.width)+"×"+String($screen.height)
	If (Value type($screen.scale)=Is real)
		$screens:=$screens+" @"+String($screen.scale)+"x"
	End if
	Form.metaScreen:=$screens
Else
	Form.metaScreen:="no screen metadata"
End if
