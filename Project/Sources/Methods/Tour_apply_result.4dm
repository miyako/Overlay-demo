// Tour_apply_result — form-process side of the completion callback.
//
// Runs in the form's process via CALL FORM, so it may update Form and objects.

#DECLARE($result : Object)
var $value; $diagnostic; $origin : Object
var $outcome; $reason; $id : Text
var $x; $y : Integer
var $poi : Object

Form.lastResult:=$result
Form.overlay:=Null
OBJECT SET ENABLED(*; "cancelButton"; False)

If (Value type($result)#Is object)
	Form.status:="Overlay returned an unexpected result type."
	return
End if

If ($result.ok=True)
	$value:=$result.value
	$outcome:=""
	$reason:=""
	If (Value type($value.outcome)=Is text)
		$outcome:=$value.outcome
	End if
	If (Value type($value.reason)=Is text)
		$reason:=$value.reason
	End if
	Case of
		: ($outcome="accepted")
			$id:=Form.overlayPOI
			If ($id="")
				$id:=Form.selectedID
			End if
			Form.visits[$id]:=True
			$poi:=cs.POIRegistry.new().find($id)
			Tour_refresh
			If ((Value type($value.x)=Is real) | (Value type($value.x)=Is longint))
				$x:=Int($value.x)
				$y:=Int($value.y)
				$origin:=Form.overlayPosition
				Form.status:="Accepted: "+$poi.name+" was clicked at overlay-local ("+String($x)+", "+String($y)+"), desktop ("+String($origin.x+$x)+", "+String($origin.y+$y)+"). Visit marked (pointer location, not a native click test)."
			Else
				Form.status:="Accepted: "+$poi.name+". Visit marked."
			End if
		: ($outcome="dismissed")
			Form.status:="Dismissed: "+$reason+" (no click). The form never blocked while the overlay was open."
		Else
			Form.status:="Overlay completed with outcome "+$outcome+" / "+$reason+"."
	End case
Else
	$diagnostic:=Tour_error_details($result)
	If ($diagnostic.cancelled)
		Form.status:="Cancelled before a terminal native event. "+$diagnostic.message
	Else
		Form.status:="Overlay failed. "+$diagnostic.message
	End if
End if
