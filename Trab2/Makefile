V=ProcessadorENG
$V: $V.fl
	flex $V.fl
	cc `pkg-config --cflags glib-2.0` lex.yy.c `pkg-config --libs glib-2.0` -o $V
