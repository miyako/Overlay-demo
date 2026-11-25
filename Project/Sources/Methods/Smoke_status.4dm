// Smoke_status — maps a Boolean assertion to the report vocabulary.
#DECLARE($ok : Boolean)->$status : Text
If ($ok)
	$status:="passed"
Else
	$status:="failed"
End if
