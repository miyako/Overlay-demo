// Tour_map_click — picture input On Clicked.
//
// MouseX/MouseY are object-relative for a picture input. Normalising them by
// the object size keeps the hit test independent of the map's rendered size.

var $poi : Object
var $left; $top; $right; $bottom : Integer
var $width; $height : Integer

OBJECT GET COORDINATES(*; "map"; $left; $top; $right; $bottom)
$width:=$right-$left
$height:=$bottom-$top

If (($width>0) & ($height>0))
	$poi:=cs.POIRegistry.new().nearest(MouseX/$width; MouseY/$height)
	If ($poi#Null)
		Form.selected:=$poi
		Form.selectedID:=$poi.id
		Form.blurb:=$poi.blurb
		LISTBOX SELECT ROW(*; "poiList"; $poi.index; lk replace selection)
		Tour_refresh
		Form.status:="Selected "+$poi.name+". Press Show overlay to place its card."
	Else
		Form.status:="No marker under the pointer. Click closer to a numbered circle."
	End if
End if
