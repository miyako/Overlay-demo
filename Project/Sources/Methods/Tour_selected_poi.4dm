// Tour_selected_poi — the current POI object, or the first one as a fallback.

#DECLARE()->$poi : Object
$poi:=Form.selected
If (($poi=Null) | (Value type($poi)#Is object))
	$poi:=cs.POIRegistry.new().find(Form.selectedID)
End if
If ($poi=Null)
	$poi:=Form.pois[0]
End if
