# Copyright (C) 2016 ilbers GmbH

LYNX = elinks

README:	README.md
	markdown $< >$@.html
	$(LYNX) $@.html >$@
