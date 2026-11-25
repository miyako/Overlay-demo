// Tour_display — queue one overlay invocation.
//
// $file   : the PNG to display
// $mode   : "clickable" or "passive"
// $useBlob: send the bytes with showBlob() instead of a file path
// $center : anchor in the middle of the primary screen instead of at the POI

#DECLARE($file : 4D.File; $mode : Text; $useBlob : Boolean; $center : Boolean)
var $poi : Object
var $overlay : cs.Overlay.Overlay
var $handle : cs.Overlay.OverlayHandle
var $options; $position; $screen : Object
var $callback : Object
var $timeout; $fade; $opacity : Integer
var $blob : Blob
var $note : Text

If ($file=Null)
	Form.status:="No card file for this point of interest."
	return
End if
If ($mode#"clickable")
	$mode:="passive"
End if

$poi:=Tour_selected_poi
$position:=Tour_anchor($poi; $center)
$screen:=Form.primaryScreen

$timeout:=Int(Num(Form.timeoutMs))
If ($timeout<0)
	$timeout:=0
End if
$fade:=Int(Num(Form.fadeMs))
If ($fade<0)
	$fade:=0
End if
If ($fade>60000)
	$fade:=60000
End if
$opacity:=Int(Num(Form.opacity))
If ($opacity<10)
	$opacity:=10
End if
If ($opacity>100)
	$opacity:=100
End if

$options:=New object
$options.x:=$position.x
$options.y:=$position.y
$options.mode:=$mode
$options.timeoutMs:=$timeout
$options.fadeInMs:=$fade
$options.fadeOutMs:=$fade
$options.opacity:=$opacity/100

$callback:=Formula(CALL WORKER(1; Formula(Tour_receive($1)); $1))
$overlay:=cs.Overlay.Overlay.new(Tour_target)

If ($useBlob)
	DOCUMENT TO BLOB($file.platformPath; $blob)
	$handle:=$overlay.showBlob($blob; $options; $callback)
Else
	$options.image:=$file
	$handle:=$overlay.show($options; $callback)
End if

Form.overlay:=$handle
Form.overlayPOI:=$poi.id
Form.overlayPosition:=New object("x"; $position.x; "y"; $position.y)
OBJECT SET ENABLED(*; "cancelButton"; True)

If ($mode="clickable")
	If ($timeout=0)
		$note:="untimed: Cancel or Escape dismisses it"
	Else
		$note:=String($timeout)+" ms"
	End if
Else
	$note:=String($timeout)+" ms"
End if

If ($center)
	$note:=$note+", centred on screen"
End if
If ($useBlob)
	$note:=$note+", Blob input"
End if
Form.status:="Queued "+$poi.name+" as a "+$mode+" overlay ("+$note+"). Desktop origin "+String($position.x)+", "+String($position.y)+". The form stays responsive."
