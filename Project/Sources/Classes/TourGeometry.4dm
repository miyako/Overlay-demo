// TourGeometry — form coordinates to desktop coordinates.
//
// `GET WINDOW RECT` reports the window's content area in desktop points, and
// form object coordinates are relative to that content area, so a POI can be
// projected onto the desktop without any platform-specific chrome maths.


Function desktopPoint($windowLeft : Integer; $windowTop : Integer; $objectLeft : Integer; $objectTop : Integer; $objectWidth : Integer; $objectHeight : Integer; $u : Real; $v : Real) : Object
	return New object("x"; $windowLeft+$objectLeft+Round($u*$objectWidth; 0); "y"; $windowTop+$objectTop+Round($v*$objectHeight; 0))

Function cardTopLeft($markerX : Integer; $markerY : Integer; $cardWidth : Integer; $cardHeight : Integer; $gap : Integer) : Object
	// The card's pointer notch is at bottom centre, so centre the card over the
	// marker and lift it clear of the marker by `$gap`.
	return New object("x"; $markerX-Round($cardWidth/2; 0); "y"; $markerY-$cardHeight-$gap)

Function clampToScreen($x : Integer; $y : Integer; $width : Integer; $height : Integer; $screenWidth : Integer; $screenHeight : Integer; $margin : Integer) : Object
	var $result : Object
	var $maxX; $maxY : Integer
	$result:=New object("x"; $x; "y"; $y; "clamped"; False)
	If (($screenWidth<=0) | ($screenHeight<=0))
		return $result
	End if
	$maxX:=$screenWidth-$width-$margin
	$maxY:=$screenHeight-$height-$margin
	If ($result.x<$margin)
		$result.x:=$margin
		$result.clamped:=True
	End if
	If ($result.y<$margin)
		$result.y:=$margin
		$result.clamped:=True
	End if
	If ($result.x>$maxX)
		$result.x:=$maxX
		$result.clamped:=True
	End if
	If ($result.y>$maxY)
		$result.y:=$maxY
		$result.clamped:=True
	End if
	return $result
