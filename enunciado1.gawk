#!/usr/bin/gawk -f

BEGIN{
	custo = 0.0
	custoParque = 0.0
	valorImportancia = 0.0
}

match($0,"<DATA_ENTRADA>(.*)</DATA_ENTRADA>", data){
	if(data[1] == "null")
		data[1] = "Entrada não registada"
	entrada[data[1]]++;
}

match($0,"<SAIDA>(.*)</SAIDA>", local){
	listaL[local[1]];
}

match($0,"<IMPORTANCIA>(.*)</IMPORTANCIA>", importancia){
	sub(/,/,".",importancia[1])
	custo += importancia[1]
	valorImportancia = importancia[1]
}

/Parques de estacionamento/{
	custoParque += valorImportancia
}

END{
	printf("\n#### Número de entradas por dia ####\n\n")

	for(dia in entrada)
		printf("%s: %s\n", dia, entrada[dia])

	printf("\n#### Lista de locais de saída ####\n\n")

	for(saida in listaL)
		printf("%s\n", saida)

	printf("\n#### Total gasto no mês ####\n\n")

	printf("Total: %.2f\n", custo)

	printf("\n#### Total gasto em parques ####\n\n")

	printf("Total: %.2f\n", custoParque)

	printf("\n#### END ####\n\n")
}