IDIR = examples
ODIR = vm

_VM = quadrado.vm menor.vm produtorio.vm ArrayMenor.vm impar.vm Array.vm
VM = $(patsubst %,$(ODIR)/%,$(_VM))

all: houd vm

houd: houd.lex houd.y
	flex houd.lex
	yacc houd.y
	gcc y.tab.c `pkg-config --cflags --libs glib-2.0` -o houd

vm: houd.lex houd.y $(VM)

$(ODIR)/%.vm: $(IDIR)/%.hd houd.lex houd.y
	./houd < $< > $@

clean:
	rm -f y.tab.c lex.yy.c houd
	rm -f vm/*.vm
