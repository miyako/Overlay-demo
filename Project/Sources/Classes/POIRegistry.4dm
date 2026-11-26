// POIRegistry — the demo's points of interest and the SVG map.
//
// The class is intentionally stateless: the form holds selection and visit
// state, the registry only describes the island and renders it. Every public
// function is static so the headless Smoke method can exercise the same code
// as the form.


Function all() : Collection
	var $pois : Collection
	$pois:=New collection(New object("id"; "tidepools"; "index"; 1; "name"; "Tide Pools"; "subtitle"; "Sea anemones at low water"; "accent"; "#0E7C86"; "u"; 0.22; "v"; 0.62; "blurb"; "A shelf of black rock that empties twice a day. The ranger station posts the low-tide window every morning."; "card"; "Overlay/card_01_tidepools.png"))
	$pois.push(New object("id"; "lighthouse"; "index"; 2; "name"; "Lighthouse Bluff"; "subtitle"; "The oldest light on the coast"; "accent"; "#B45309"; "u"; 0.72; "v"; 0.18; "blurb"; "The 1868 tower still runs on its original clockwork. The last keeper left in 1974 and the stairs are open on weekends."; "card"; "Overlay/card_02_lighthouse.png"))
	$pois.push(New object("id"; "whale_pier"; "index"; 3; "name"; "Whale Watch Pier"; "subtitle"; "Boats leave at first light"; "accent"; "#1D4ED8"; "u"; 0.86; "v"; 0.55; "blurb"; "The pier is 180 metres long. Humpbacks pass offshore between April and October; the board at the gate lists the morning sightings."; "card"; "Overlay/card_03_whale_pier.png"))
	$pois.push(New object("id"; "fern_grotto"; "index"; 4; "name"; "Fern Grotto"; "subtitle"; "Cool air under the canopy"; "accent"; "#15803D"; "u"; 0.46; "v"; 0.34; "blurb"; "A basalt overhang lined with sword ferns. The air stays near 14 degrees even in midsummer and the floor is always wet."; "card"; "Overlay/card_04_fern_grotto.png"))
	$pois.push(New object("id"; "copper_mine"; "index"; 5; "name"; "Copper Mine"; "subtitle"; "Tunnels closed in 1932"; "accent"; "#9A3412"; "u"; 0.30; "v"; 0.22; "blurb"; "The headframe is the only building left. The adits are sealed, but the spoil heaps are still stained green."; "card"; "Overlay/card_05_copper_mine.png"))
	$pois.push(New object("id"; "sundial"; "index"; 6; "name"; "Sundial Plaza"; "subtitle"; "Market square centrepiece"; "accent"; "#6D28D9"; "u"; 0.58; "v"; 0.74; "blurb"; "The brass dial is recalibrated every leap year. Around it, the Saturday market sells bread, rope and second-hand charts."; "card"; "Overlay/card_06_sundial.png"))
	$pois.push(New object("id"; "night_market"; "index"; 7; "name"; "Night Market"; "subtitle"; "Stalls open after sunset"; "accent"; "#BE123C"; "u"; 0.40; "v"; 0.86; "blurb"; "Paper lanterns from six until midnight. The fish stalls at the north end cook whatever the boats did not sell that day."; "card"; "Overlay/card_07_night_market.png"))
	return $pois

Function find($id : Text) : Object
	var $poi; $result : Object
	$result:=Null
	For each ($poi; cs.POIRegistry.new().all())
		If ($poi.id=$id)
			$result:=$poi
		End if
	End for each
	return $result

Function nearest($u : Real; $v : Real) : Object
	// Nearest marker in normalised map space, or Null beyond the tolerance.
	var $poi; $best : Object
	var $bestDistance; $distance : Real
	$best:=Null
	$bestDistance:=0.09
	For each ($poi; cs.POIRegistry.new().all())
		$distance:=Square root((Num($poi.u)-$u)^2+(Num($poi.v)-$v)^2)
		If ($distance<=$bestDistance)
			$best:=$poi
			$bestDistance:=$distance
		End if
	End for each
	return $best

Function cardFile($id : Text) : 4D.File
	var $poi : Object
	$poi:=cs.POIRegistry.new().find($id)
	If ($poi=Null)
		return Null
	End if
	return File("/RESOURCES/"+$poi.card)

Function escape($value : Text) : Text
	var $text : Text
	$text:=Replace string($value; "&"; "&amp;"; *)
	$text:=Replace string($text; "<"; "&lt;"; *)
	$text:=Replace string($text; ">"; "&gt;"; *)
	$text:=Replace string($text; "\""; "&quot;"; *)
	return $text

Function svg($selectedID : Text; $visits : Object) : Text
	var $svg; $body; $label; $dash; $color : Text
	var $poi; $selected : Object
	var $i; $x; $y; $lx; $ly; $width; $height; $cx; $cy : Integer
	var $visited : Boolean

	$width:=584
	$height:=420
	$selected:=cs.POIRegistry.new().find($selectedID)
	$svg:="<svg xmlns=\"http://www.w3.org/2000/svg\" width=\""+String($width)+"\" height=\""+String($height)+"\" viewBox=\"0 0 "+String($width)+" "+String($height)+"\">"

	// Sea and a soft horizon band.
	$svg:=$svg+"<defs><linearGradient id=\"sea\" x1=\"0\" y1=\"0\" x2=\"0\" y2=\"1\"><stop offset=\"0\" stop-color=\"#0B3A53\"/><stop offset=\"1\" stop-color=\"#0E4F6B\"/></linearGradient><linearGradient id=\"land\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0\" stop-color=\"#F2E8C9\"/><stop offset=\"1\" stop-color=\"#E4D3A4\"/></linearGradient></defs>"
	$svg:=$svg+"<rect width=\""+String($width)+"\" height=\""+String($height)+"\" fill=\"url(#sea)\"/>"
	For ($i; 1; 5)
		$y:=70+$i*58
		$svg:=$svg+"<path d=\"M0 "+String($y)+" Q 90 "+String($y-10)+" 180 "+String($y)+" T 360 "+String($y)+" T 584 "+String($y-4)+"\" fill=\"none\" stroke=\"#7DD3FC\" stroke-width=\"1\" opacity=\"0.13\"/>"
	End for

	// Island silhouette.
	$svg:=$svg+"<path d=\"M46 322 L74 208 L168 132 L292 104 L420 138 L518 232 L540 320 L470 382 L330 394 L178 374 L82 350 Z\" fill=\"url(#land)\" stroke=\"#C9AE72\" stroke-width=\"2\"/>"
	$svg:=$svg+"<path d=\"M120 330 L150 246 L238 190 L342 182 L438 236 L470 318 L404 360 L284 372 L178 352 Z\" fill=\"#EADCB6\" opacity=\"0.75\"/>"
	$svg:=$svg+"<path d=\"M236 240 L300 224 L366 248 L378 300 L320 330 L254 314 L226 276 Z\" fill=\"#A5C9B0\" opacity=\"0.55\"/>"

	// Trails between related markers.
	$dash:=" fill=\"none\" stroke=\"#8A6B2F\" stroke-width=\"2\" stroke-dasharray=\"5 5\" opacity=\"0.45\""
	$svg:=$svg+"<path d=\"M"+String(Round(0.22*$width; 0))+" "+String(Round(0.62*$height; 0))+" L"+String(Round(0.46*$width; 0))+" "+String(Round(0.34*$height; 0))+" L"+String(Round(0.58*$width; 0))+" "+String(Round(0.74*$height; 0))+" L"+String(Round(0.40*$width; 0))+" "+String(Round(0.86*$height; 0))+"\""+$dash+"/>"
	$svg:=$svg+"<path d=\"M"+String(Round(0.30*$width; 0))+" "+String(Round(0.22*$height; 0))+" L"+String(Round(0.46*$width; 0))+" "+String(Round(0.34*$height; 0))+"\""+$dash+"/>"
	$svg:=$svg+"<path d=\"M"+String(Round(0.72*$width; 0))+" "+String(Round(0.18*$height; 0))+" L"+String(Round(0.86*$width; 0))+" "+String(Round(0.55*$height; 0))+" L"+String(Round(0.58*$width; 0))+" "+String(Round(0.74*$height; 0))+"\""+$dash+"/>"

	// Selection halo and label.
	If ($selected#Null)
		$x:=Round(Num($selected.u)*$width; 0)
		$y:=Round(Num($selected.v)*$height; 0)
		$svg:=$svg+"<circle cx=\""+String($x)+"\" cy=\""+String($y)+"\" r=\"24\" fill=\"none\" stroke=\""+$selected.accent+"\" stroke-width=\"3\" opacity=\"0.8\"/>"
		$lx:=$x-84
		$ly:=$y-58
		If ($lx<8)
			$lx:=8
		End if
		If ($lx>($width-176))
			$lx:=$width-176
		End if
		If ($ly<8)
			$ly:=8
		End if
		$svg:=$svg+"<g><rect x=\""+String($lx)+"\" y=\""+String($ly)+"\" width=\"168\" height=\"30\" rx=\"9\" fill=\"#0F172A\" opacity=\"0.93\"/><text x=\""+String($lx+84)+"\" y=\""+String($ly+20)+"\" text-anchor=\"middle\" font-family=\"Arial, Helvetica, sans-serif\" font-size=\"13\" font-weight=\"bold\" fill=\"#F8FAFC\">"+cs.POIRegistry.new().escape($selected.name)+"</text></g>"
	End if

	// Markers.
	For each ($poi; cs.POIRegistry.new().all())
		$x:=Round(Num($poi.u)*$width; 0)
		$y:=Round(Num($poi.v)*$height; 0)
		$color:=$poi.accent
		$visited:=False
		If ($visits#Null)
			If (Value type($visits[$poi.id])=Is boolean)
				$visited:=$visits[$poi.id]
			End if
		End if
		$svg:=$svg+"<g id=\"poi_"+cs.POIRegistry.new().escape($poi.id)+"\">"
		If ($visited)
			$svg:=$svg+"<circle cx=\""+String($x)+"\" cy=\""+String($y)+"\" r=\"17\" fill=\"#FDE68A\" opacity=\"0.85\"/>"
		End if
		$svg:=$svg+"<circle cx=\""+String($x)+"\" cy=\""+String($y)+"\" r=\"13\" fill=\""+$color+"\" stroke=\"#FFFFFF\" stroke-width=\"2.5\"/>"
		$svg:=$svg+"<text x=\""+String($x)+"\" y=\""+String($y+4)+"\" text-anchor=\"middle\" font-family=\"Arial, Helvetica, sans-serif\" font-size=\"12\" font-weight=\"bold\" fill=\"#FFFFFF\">"+String($poi.index)+"</text>"
		$svg:=$svg+"</g>"
	End for each

	// Legend.
	$label:="Click a numbered point of interest"
	$svg:=$svg+"<g><rect x=\"14\" y=\"378\" width=\"292\" height=\"26\" rx=\"8\" fill=\"#0F172A\" opacity=\"0.72\"/><text x=\"26\" y=\"395\" font-family=\"Arial, Helvetica, sans-serif\" font-size=\"12\" fill=\"#E2E8F0\">"+$label+"</text></g>"
	$svg:=$svg+"</svg>"
	return $svg

Function picture($selectedID : Text; $visits : Object) : Picture
	var $svg; $dom : Text
	var $picture : Picture
	$svg:=cs.POIRegistry.new().svg($selectedID; $visits)
	// SVG EXPORT TO PICTURE takes an XML tree reference, not SVG source text.
	$dom:=DOM Parse XML variable($svg)
	SVG EXPORT TO PICTURE($dom; $picture)
	DOM CLOSE XML($dom)
	return $picture

Function visitedCount($visits : Object) : Integer
	var $count : Integer
	var $id : Text
	$count:=0
	If ($visits=Null)
		return 0
	End if
	For each ($id; OB Keys($visits))
		If (Value type($visits[$id])=Is boolean)
			If ($visits[$id])
				$count:=$count+1
			End if
		End if
	End for each
	return $count
