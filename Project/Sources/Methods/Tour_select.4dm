// Tour_select — list box On Selection Change.
//
// The list box binds the clicked element to Form.selected through
// currentItemSource, so this method only has to synchronise the map.

If (Form.selected#Null)
	Form.selectedID:=Form.selected.id
	Form.blurb:=Form.selected.blurb
	Tour_refresh
	Form.status:="Selected "+Form.selected.name+". Press Show overlay to place its card."
End if
