DIR_FILE = ficheiros/viaverde.xml
DIR_SCRIPT = script/viaverde.gawk

viaverde:
	gawk -f $(DIR_SCRIPT) $(DIR_FILE)