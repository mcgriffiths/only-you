x <- read_xml("https://boardgamegeek.com/xmlapi2/plays?id=42&mindate=2018-07-01&maxdate=2018-07-31&page=1")

xml_name(x)
xml_children(x)
plays <- xml_find_all(x, ".//play")
users <- xml_attr(plays, "userid")
length(unique(users))

u <- read_xml("https://boardgamegeek.com/xmlapi2/plays?username=qwertymartin&mindate=2018-07-01&maxdate=2018-07-31&page=1")
items <- xml_find_all(u, ".//play/item")
users <- xml_attr(items, "objectid")
