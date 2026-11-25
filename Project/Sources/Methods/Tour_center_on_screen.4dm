// Tour_center_on_screen — anchor the current card at the primary screen centre.
//
// Screen coordinates come from the helper's own screens() metadata, not from
// 4D form coordinates. This is the bridge between the two coordinate spaces.

var $poi : Object
var $mode : Text
$poi:=Tour_selected_poi
If (Bool(Form.clickable))
	$mode:="clickable"
Else
	$mode:="passive"
End if
If (Form.screens.length=0)
	Form.status:="The helper reported no screens, so screen-centre placement is unavailable."
	return
End if
Tour_display(cs.POIRegistry.new().cardFile($poi.id); $mode; Bool(Form.useBlob); True)
