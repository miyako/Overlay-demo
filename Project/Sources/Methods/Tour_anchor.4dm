// Tour_anchor — desktop top-left for the 300×166 card.
//
// The marker's desktop position is the window content origin (GET WINDOW RECT)
// plus the map object's form position plus the normalised POI offset. The card
// is centred over the marker with its pointer notch just above it, then clamped
// inside the primary screen.

#DECLARE($poi : Object; $centered : Boolean)->$position : Object
var $windowLeft; $windowTop; $windowRight; $windowBottom : Integer
var $left; $top; $right; $bottom : Integer
var $marker; $screen : Object
var $screenWidth; $screenHeight : Integer

$screen:=Form.primaryScreen
$screenWidth:=Int(Num($screen.width))
$screenHeight:=Int(Num($screen.height))

If ($centered)
	$position:=New object("x"; Round(Num($screenWidth-300)/2; 0); "y"; Round(Num($screenHeight-166)/2; 0); "clamped"; False; "marker"; New object("x"; 0; "y"; 0))
Else
	GET WINDOW RECT($windowLeft; $windowTop; $windowRight; $windowBottom; Current form window)
	OBJECT GET COORDINATES(*; "map"; $left; $top; $right; $bottom)
	$marker:=cs.TourGeometry.new().desktopPoint($windowLeft; $windowTop; $left; $top; $right-$left; $bottom-$top; Num($poi.u); Num($poi.v))
	$position:=cs.TourGeometry.new().cardTopLeft($marker.x; $marker.y; 300; 166; 10)
	$position:=cs.TourGeometry.new().clampToScreen($position.x; $position.y; 300; 166; $screenWidth; $screenHeight; 8)
	$position.marker:=$marker
End if
