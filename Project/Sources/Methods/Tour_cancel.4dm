// Tour_cancel — Cancel button. Cancellation is queued to the invocation's
// owning worker, so it is safe while the form is still busy.

If (Form.overlay#Null)
	If (Form.overlay.cancel())
		Form.status:="Cancellation requested. The overlay closes asynchronously."
	Else
		Form.status:="Nothing to cancel (the overlay already completed)."
	End if
Else
	Form.status:="No active overlay."
End if
