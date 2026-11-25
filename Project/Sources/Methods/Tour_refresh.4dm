// Tour_refresh — rebuild the SVG map for the current selection/visits.

Form.mapPicture:=cs.POIRegistry.new().picture(Form.selectedID; Form.visits)
Form.visitedText:=String(cs.POIRegistry.new().visitedCount(Form.visits))+" of "+String(Form.pois.length)+" visited"
