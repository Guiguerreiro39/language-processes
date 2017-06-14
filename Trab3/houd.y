%{
  #define _GNU_SOURCE
  #include <string.h>
  #include <stdio.h>
  #import <glib.h>
  int yylex();
  int yyerror(char *);
  void add_var(char *);
  void add_array(char *, int, int);
  int get_var_addr(char *);
  int get_array_addr(char *);
  int get_array_cols_length(char *);

  int label;

  typedef struct Array {
    int address;
    int rows;
    int cols;
  } Array;

  typedef struct StringW {
    char *begin;
    char *end;
  } StringW;

%}

%union{
  char * s;
  int n;
  StringW ss;
}

%token Inteiro INICIAR PARAR escrever ler funct chamar
/* Variáveis terminais */
%token <s> VAR STRING
%token <n> NUM
/* Variáveis não terminais */
%type <s> vars var inteiros intructs express simbol factor instruct function functions
%type <ss> char

%%
/* Inicio do compilador */
houd: inteiros functions INICIAR intructs PARAR  { printf("%sjump inic\n%sstart\ninic: %sstop\n", $1, $2, $4); }
    ;

/* Instruções */
intructs: instruct                               { $$ = $1; }
        | intructs instruct                      { asprintf(&$$, "%s%s", $1, $2); }

instruct: escrever '(' factor ')' ';'            { asprintf(&$$, "%s\twritei\n", $3);}
        | escrever '(' '"' STRING '"' ')'';'     { asprintf(&$$, "\tpushs \"%s\"\n\twrites\n", $4); }
        | ler '(' char ')' ';'                   { asprintf(&$$, "%s\tread\n\tatoi\n\%s", $3.begin, $3.end); }
        | char '=' express ';'                   { asprintf(&$$, "%s%s%s", $1.begin, $3, $1.end); }
        | '?''('express')' '{' intructs '}'      { asprintf(&$$, "%s\tjz label%d\n%slabel%d: ", $3, label, $6, label); label++; }
        | '?''('express')''{' intructs '}''_''{' intructs '}'
                                                 { asprintf(&$$, "%s\tjz label%d\n%sjump label%d\nlabel%d: %slabel%d: ",
                                                   $3, label, $6, label + 1, label, $10, label + 1); label += 2; }
        | '@''('express')' '{' intructs '}'      { asprintf(&$$, "label%d: %s\tjz label%d\n%sjump label%d\nlabel%d: ",
                                                   label, $3, label + 1, $6, label, label + 1); label += 2; }
        | chamar STRING ';'                      { asprintf(&$$, "\tpusha %s\n\tcall\n\tnop\n", $2); }
        |                                        { $$ = ""; }
    ;

/* simbulos para as Expressões */
simbol: simbol '*' factor                     { asprintf(&$$, "%s%s\tmul\n", $1, $3); }
      | simbol '/' factor                     { asprintf(&$$, "%s%s\tdiv\n", $1, $3); }
      | simbol '%' factor                     { asprintf(&$$, "%s%s\tmod\n", $1, $3); }
      | simbol '>' factor                     { asprintf(&$$, "%s%s\tsup\n", $1, $3); }
      | simbol '<' factor                     { asprintf(&$$, "%s%s\tinf\n", $1, $3); }
      | simbol '>''=' factor                  { asprintf(&$$, "%s%s\tsupeq\n", $1, $4); }
      | simbol '<''=' factor                  { asprintf(&$$, "%s%s\tinfeq\n", $1, $4); }
      | simbol '!''=' factor                  { asprintf(&$$, "%s%s\tequal\npushi 1\ninf\n", $1, $4); }
      | simbol '=''=' factor                  { asprintf(&$$, "%s%s\tequal\n", $1, $4); }
      | simbol '&' factor                     { asprintf(&$$, "%s%s\tadd\n\tpushi 2\n\tequal\n", $1, $3); }
      | simbol '|' factor                     { asprintf(&$$, "%s%s\tadd\n\tpushi 0\n\tsup\n", $1, $3); }
      | factor                                { $$ = $1; }
      ;

/* Variáveis sem NUM */
char: VAR                                     { asprintf(&$$.begin, ""); asprintf(&$$.end, "\tstoreg %d\n", get_var_addr($1)); }
    | VAR '[' express ']'                     { asprintf(&$$.begin, "\tpushgp\n\tpushi %d\n\tpadd\n%s", get_array_addr($1), $3);
                                            asprintf(&$$.end, "\tstoren\n"); }
    | VAR '[' express ']' '[' express ']'     { asprintf(&$$.begin, "\tpushgp\n\tpushi %d\n\tpadd\n%s\tpushi %d\n\tmul\n%s\tadd\n",  get_array_addr($1), $3, get_array_cols_length($1), $6); asprintf(&$$.end, "\tstoren\n"); }

/* Expressões */
express: simbol                               { $$ = $1; }
       | express '+' simbol                   { asprintf(&$$, "%s%s\tadd\n", $1, $3); }
       | express '-' simbol                   { asprintf(&$$, "%s%s\tsub\n", $1, $3); }
       ;

/* Variáveis com NUM */
factor: NUM                                   { asprintf(&$$, "\tpushi %d\n", $1); }
      | VAR                                   { asprintf(&$$, "\tpushg %d\n", get_var_addr($1)); }
      | VAR '[' express ']'                   { asprintf(&$$, "\tpushgp\n\tpushi %d\n\tpadd\n%s\tloadn\n", get_array_addr($1), $3); }
      | VAR '[' express ']' '[' express ']'   { asprintf(&$$, "\tpushgp\n\tpushi %d\n\tpadd\n%s\tpushi %d\n\tmul\n%s\tadd\n\tloadn\n", get_array_addr($1), $3, get_array_cols_length($1), $6); }
      | '(' express ')'                       { $$ = $2; }
      ;

/* Inteiros */
inteiros: Inteiro vars ';'                    { $$ = $2; }
        ;

/* Variáveis */
vars: var                                     { $$ = $1; }
    | vars ',' var                            { asprintf(&$$, "%s%s", $1, $3); }
    ;

var: VAR                                      { asprintf(&$$, "\tpushi 0\n"); add_var($1); }
   | VAR '=' NUM                              { asprintf(&$$, "\tpushi %d\n", $3); add_var($1); }
   | VAR '[' NUM ']'                          { asprintf(&$$, "\tpushn %d\n", $3); add_array($1, $3, 0);}
   | VAR '[' NUM ']' '[' NUM ']'              { asprintf(&$$, "\tpushn %d\n", $3 * $6); add_array($1, $3, $6);}
   ;

/* Funções */
functions: function                           { $$ = $1; }
         | functions function                 { asprintf(&$$, "%s%s", $1, $2); }
         |                                    { $$ = ""; }
         ;

function: funct STRING '{' intructs '}'       { asprintf(&$$, "%s: nop\n%s\treturn\n", $2, $4); }
        ;

%%

#include "lex.yy.c"

// Usamos HashTables para associar variaveis a endereços
GHashTable * var_addresses;
GHashTable * array_addresses;
int pointer;

int yyerror (char *s) {
  fprintf(stderr, "%s (%d)\n", s, yylineno);
  return 0;
}

int main() {
  // Endereço de variavel inicializada
  var_addresses = g_hash_table_new(g_str_hash, g_str_equal);
  array_addresses = g_hash_table_new(g_str_hash, g_str_equal);
  pointer   = 0;
  label     = 0;

  yyparse();

  return 0;
}

/* Adiciona uma variavel e o seu endereço à HashTable */
void add_var(char * var) {
  char *error_message;
  // Verifica se a variavel existe
  int *addr = (int *) g_hash_table_lookup(var_addresses, var);
  Array *array = (Array *) g_hash_table_lookup(array_addresses, var);
  if (addr == NULL && array == NULL) {
    addr = (int *) malloc(sizeof(int)); *addr = pointer;
    g_hash_table_insert(var_addresses, var, addr);
    pointer++;
  } else {
    // Pára a execução se a variavel já se encontrar inicializada
    asprintf(&error_message, "Variável '%s' já em utilização.", var);
    yyerror(error_message);
  }
}

/* Adiciona um array e o seu endereço à HashTable */
void add_array(char * var, int rows, int cols) {
  char *error_message;
  // Verifica se a variavel existe
  int *addr = (int *) g_hash_table_lookup(var_addresses, var);
  Array *array = (Array *) g_hash_table_lookup(array_addresses, var);
  if (array == NULL && addr == NULL && rows > 0) {
    array = (Array *) malloc(sizeof(Array));
    array->address = pointer;
    array->rows = rows;
    array->cols = cols;
    g_hash_table_insert(array_addresses, var, array);
    pointer += rows;
  }
  else {
    if (rows < 1) {
      // Pára a execução se o tamanho do array for demasiado pequeno
      asprintf(&error_message, "Tamanho do array '%s' demasiado baixo.", var);
      yyerror(error_message);
    }
    if (array != NULL || addr != NULL) {
      // Pára a execução se a variavel já existir
      asprintf(&error_message, "Variável '%s' já em utilização.", var);
      yyerror(error_message);
    }
  }
}

/*  Devolve o endereço de uma variavel */
int get_var_addr(char * var) {
  char *error_message;
  int * addr = (int *) g_hash_table_lookup(var_addresses, var);
  if (addr == NULL) {
    // Variable does not exist.
    asprintf(&error_message, "Variável '%s' não inicializada.", var);
    yyerror(error_message);
  }
  else {
    return *addr;
  }

  return 0;
}

int get_array_addr(char * var) {
  char *error_message;
  Array *array = (Array *) g_hash_table_lookup(array_addresses, var);
  if (array == NULL) {
    // A variavel não existe
    asprintf(&error_message, "Array '%s' não inicializado.", var);
    yyerror(error_message);
  }
  else {
    return array->address;
  }

  return 0;
}

int get_array_cols_length(char * var) {
  char *error_message;
  Array *array = (Array *) g_hash_table_lookup(array_addresses, var);
  if (array == NULL) {
    // Variable does not exist.
    asprintf(&error_message, "Array '%s' não inicializado.", var);
    yyerror(error_message);
  }
  else {
    return array->cols;
  }

  return 0;
}
