// Tour_receive — runs on worker 1 when an overlay invocation completes.
//
// The worker must not touch the form directly: CALL FORM marshals the result
// back to the form's own process.

#DECLARE($result : Object)
If (Storage.tour#Null)
	If (Storage.tour.open=True)
		CALL FORM(Storage.tour.window; Formula(Tour_apply_result($1)); $result)
	End if
End if
