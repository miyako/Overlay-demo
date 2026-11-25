// Tour_show_card — Show overlay button.

var $poi : Object
var $mode : Text
$poi:=Tour_selected_poi
If (Bool(Form.clickable))
	$mode:="clickable"
Else
	$mode:="passive"
End if
Tour_display(cs.POIRegistry.new().cardFile($poi.id); $mode; Bool(Form.useBlob); False)
