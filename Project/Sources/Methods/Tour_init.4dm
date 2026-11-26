// Tour_init — form On Load.
//
// Sets up the demo state, reads the helper metadata synchronously and renders
// the first map. Metadata failures are non-fatal: the rest of the demo still
// works, and the status line reports the problem.

Case of
	: (FORM Event.code=On Load)

		Form.pois:=cs.POIRegistry.new().all()
		Form.selected:=Form.pois[0]
		Form.selectedID:=Form.selected.id
		Form.blurb:=Form.selected.blurb
		Form.visits:=New object()
		Form.clickable:=True
		Form.useBlob:=False
		Form.timeoutMs:=6000
		Form.fadeMs:=150
		Form.opacity:=100
		Form.status:="Ready. Click a numbered marker on the map, then press Show overlay."
		Form.lastResult:=Null
		Form.overlay:=Null
		Form.overlayPosition:=New object("x"; 0; "y"; 0)
		Form.overlayPOI:=""
		Form.screens:=New collection()
		Form.primaryScreen:=New object("index"; 0; "x"; 0; "y"; 0; "width"; 0; "height"; 0; "scale"; 1)
		Form.version:=""
		Form.capabilities:=Null
		Form.metaVersion:="overlay-cli ..."
		Form.metaScreen:="screen ..."
		Form.metaCap:="PNG ..."
		Form.visitedText:="0 of 7 visited"

		// Storage properties must be shared objects: keep the flags in one.
		Use (Storage)
			Storage.tour:=New shared object("window"; Current form window; "open"; True)
		End use

		Tour_metadata
		Tour_refresh

		OBJECT SET ENABLED(*; "cancelButton"; False)

	: (FORM Event.code=On Unload)
		If (Storage.tour#Null)
			Use (Storage.tour)
				Storage.tour.open:=False
			End use
		End if
		If (Form.overlay#Null)
			Form.overlay.cancel()
		End if
End case
