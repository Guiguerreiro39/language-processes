#!/usr/bin/gawk -f

BEGIN {
  enc = "<html> <head> <meta charset='UTF-8'/> </head> <body>"
  list_begin = "<li> "
  list_end = " </li>\n"
  par = "<p> %s: %.2f</p>\n"
  head2 = "<h2> %s </h2>\n"
  end = "</body> </html>"
  custo = 0.0
  custoParque = 0.0
  valorImportancia = 0.0
}

match($0,"<DATA_ENTRADA>(.*)</DATA_ENTRADA>", data){
	if(data[1] == "null")
		data[1] = "Entrada não registada"
	entrada[data[1]]++;
}

match($0,"<SAIDA>(.*)</SAIDA>", loc){
	listaL[loc[1]];
}

match($0,"<IMPORTANCIA>(.*)</IMPORTANCIA>", importancia){
  sub(/,/,".",importancia[1])
  custo += importancia[1]
  valorImportancia = importancia[1]
}

/Parques de estacionamento/{
  custoParque += valorImportancia
}


END {
  print enc > "index.html";

  printf(head2, "Número de entradas por dia") > "index.html"
  for (dia in entrada) printf (list_begin "%s: %d" list_end, dia, entrada[dia]) > "index.html";

  printf(head2, "Lista de locais de saída") > "index.html"
  for (local in listaL) printf (list_begin "%s" list_end, local) > "index.html"

  printf(head2, "Custo total do mês") > "index.html"
  printf(par, "Total", custo) > "index.html"

  printf(head2, "Total gasto em parques") > "index.html"
  printf(par, "Total", custoParque) > "index.html"

  print end > "index.html";
}