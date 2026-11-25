// Tour_copy_result — put the last completion envelope on the clipboard.

If (Form.lastResult=Null)
	Form.status:="No completion result yet. Show an overlay first."
Else
	SET TEXT TO PASTEBOARD(JSON Stringify(Form.lastResult))
	Form.status:="Last completion envelope copied as JSON. The envelope includes ok/stdout/stderr/exitCode/value."
End if
