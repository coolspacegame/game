extends Object

##	Takes in a [Color] object and returns the necessary tags for print_rich text[br]
##	Accepts [Color][br]
##	Returns String Array [Opening color tag, closing color tag]
static func as_rich_color (desired_color: Color) -> Array[String]:
	return ["[color=" + desired_color.to_html() + "]", "[/color]"]
