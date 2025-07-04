extends Object

##	Takes in a [Color] object and returns the necessary tags for print_rich text[br]
##	Accepts [Color][br]
##	Returns String Array [Opening color tag, closing color tag]
static func AsRichColor (DesiredColor: Color) -> Array[String]:
	return ["[color=" + DesiredColor.to_html() + "]", "[/color]"]
