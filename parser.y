/*****
* Yacc parser for CS370 Lab5
* Jesus Barba
* 
*****/

/****** Header definitions ******/
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "astree.h"
#include "symtable.h"

// function prototypes from lex
int yyerror(char *s);
int yylex(void);
void yylex_destroy(void);
//_____________________

//global variables
int debug = 0;
int strcounter = 0;
char* stringArray[100];
int addString(char * s);
int argNum;
extern int yylineno; // from lex
ASTNode *programAST;
Symbol** table;
%}

/* token value data types */
%union { int ival; // for most scanner tokens
	char* str; //tokens that need a string, like id and string
	struct astnode_s * astnode;} //for all grammar nonterminals 

/* Starting non-terminal */
%start PROG
%type <astnode> FUNCTIONS FUNCTION STATEMENTS STATEMENT FUNCALL ARGUMENTS
%type <astnode> ARGUMENT EXPRESSION PARAMETERS DECLARATIONS ASSIGNMENT
%type <astnode> VARDECL PROG
%type <astnode> WHILELOOP IFTHEN IFTHENELSE RELEXPR
/* Token types */
%token <ival> comma semicolon lparen rparen lbrace rbrace number equals kwint kwstring
%token <ival> kwif relop kwelse addop kwwhile
%token <str> id string
%%
/******* Rules *******/

PROG : DECLARATIONS FUNCTIONS {
	programAST = newASTNode(AST_PROGRAM);
	programAST->child[0] = $1; //child 0 is global var decls
	programAST->child[1] = $2; //child 1 is function decls
	};
DECLARATIONS : /*empty*/ {
		$$=0;
		}
	| VARDECL semicolon DECLARATIONS
	{
	if (debug) printf("\ny: matched Declarations\n");
	$1->next=$3;
	$$=$1;
	}
VARDECL : kwint id
	{
	if (debug) fprintf(stderr, "matched Vardecl: int id\n");
	$$ = newASTNode(AST_VARDECL);
	$$->strval = $2;
	$$->valtype = T_STRING;
	addSymbol(table, $2, 0, T_INT);
	}
	| kwstring id
	{
	if (debug) fprintf(stderr, "matched VarDecl: char id\n");
	$$ = newASTNode(AST_VARDECL);
	$$->strval = $2;
	$$->valtype = T_STRING;
	addSymbol(table, $2, 0, T_STRING);
	}
FUNCTIONS : FUNCTION FUNCTIONS
	{
	   if (debug) fprintf(stderr, "matched Functions\n");
	   $1->next = $2;
	   $$ = $1;
	
	}
	| /*empty*/
	{
	  $$ = 0;
	}

FUNCTION : id lparen PARAMETERS rparen lbrace STATEMENTS rbrace{
	if (debug) fprintf(stderr, "matched Function\n");
	$$ = newASTNode(AST_FUNCTION);
	$$->valtype = T_STRING;
	$$->strval = $1;
	$$->child[0] = $3;
	$$->child[1] = $6;
	$$->next = 0;
	};
STATEMENTS : STATEMENT STATEMENTS{
	if (debug) fprintf(stderr, "matched Statements\n");
	$1->next = $2;
	$$ = $1;
	}
	| /*empty*/
	{
	$$ = 0;
	};

STATEMENT : FUNCALL semicolon
	{
	$$ = $1;
	}
	| ASSIGNMENT semicolon //added in compiler 5
	{
	$$ = $1;
	}
	| WHILELOOP
	{
	$$=$1;
	}
	| IFTHEN
	{
	$$=$1;
	}
	| IFTHENELSE
	{
	$$=$1;
	}

FUNCALL : id lparen ARGUMENTS rparen
	{
	if (debug) fprintf(stderr, "matched Funcall\n");
	$$ = newASTNode(AST_FUNCALL);
	$$->valtype = T_STRING;
	$$->strval = $1;
	$$->child[0] = $3;
	}

ASSIGNMENT : id equals EXPRESSION
	{
	if (debug) fprintf(stderr, "matched assignment\n");
	if (findSymbol(table, $1)!=NULL){
	$$ = newASTNode(AST_ASSIGNMENT);
	$$->valtype = T_STRING;
	$$->strval = $1;
	$$->child[0] = $3;
	}
	else{
	fprintf(stderr, "line %d syntax error: variable %s does not exist", yylineno, $1);
	exit(-1);
	}
	}
WHILELOOP : kwwhile lparen RELEXPR rparen lbrace STATEMENTS rbrace
	{
	if (debug) fprintf(stderr, "matched whileloop\n");
	$$ = newASTNode(AST_WHILE);
	$$->child[0] = $3; //child[0] is condition expression
	$$->child[1] = $6; //child[1] is loop body
	}
IFTHEN : kwif lparen RELEXPR rparen lbrace STATEMENTS rbrace
	{
	if (debug) fprintf(stderr, "matched ifthen\n");
	$$ = newASTNode(AST_IFTHEN);
	$$->child[0] = $3; //child[0] is condition expression
	$$->child[1] = $6; //child[1] is the if statements body
	}
IFTHENELSE : kwif lparen RELEXPR rparen lbrace STATEMENTS rbrace kwelse lbrace STATEMENTS rbrace
	{
	if (debug) fprintf(stderr, "matched ifthenelse\n");
	$$=newASTNode(AST_IFTHEN);
	$$->child[0] = $3; //child[0] is condition expression
	$$->child[1] = $6; //child[1] is the if statements body
	$$->child[2] = $10; //child[2] is the else statements body
	}
ARGUMENTS : /* empty */
	{
	$$ = 0;
	}
| ARGUMENT
	{
	if (debug) fprintf(stderr, "matched Args Arg\n");
	$$ = $1;
	}
| ARGUMENT comma ARGUMENTS
	{
	if (debug) fprintf(stderr, "matched Arguments\n");
	$1->next = $3;
	$$ = $1;
	}
ARGUMENT : EXPRESSION
	{
	if (debug) printf("\ny: matched Arg Exp\n");
	$$ = newASTNode(AST_ARGUMENT);
	$$->child[0] = $1;
	}
EXPRESSION : 
	number
	{
	if (debug) fprintf(stderr, "matched Expression number\n");
	$$ = newASTNode(AST_CONSTANT);
	$$->ival = $1;
	$$->valtype = T_INT;
	}
	| id
	{
	if (debug) fprintf(stderr, "matched Exp ID\n");
	if (findSymbol(table, $1)!=NULL){
	$$ = newASTNode(AST_VARREF);
	$$->valtype = T_STRING;
	$$->strval = $1;
	}
	else{
	printf("line %d syntax error: variable %s does not exist", yylineno, $1);
	exit(-1);
	}
	}
	| EXPRESSION addop EXPRESSION
	{
	if (debug) printf("\ny: matched Exp plus Exp\n");
	$$ = newASTNode(AST_EXPRESSION);
	$$->ival = $2;
	$$->child[0]=$1;
	$$->child[1]=$3;
	}
	| string
	{
	if (debug) fprintf(stderr, "matched Exp String\n");
	int tableid = addString($1);
	$$ = newASTNode(AST_CONSTANT);
	$$->ival = tableid;
	$$->valtype = T_STRING;
	$$->strval = $1;
	}
RELEXPR : EXPRESSION relop EXPRESSION{
	if (debug) fprintf(stderr, "matched relexpr\n");
	$$ = newASTNode(AST_RELEXPR);
	$$->ival = $2; //stores relop
	$$->child[0]=$1; //child[0] stores the left side
	$$->child[1]=$3;
	}
PARAMETERS : /*empty*/
	{
	$$ = 0;
	}
	| VARDECL
	{
	$$ = 0;
	free($1);
	}
	| VARDECL comma PARAMETERS
	{
	$$ = 0;
	free($1);
	}

%%
/******* Functions *******/
extern FILE *yyin; // from lex
int main(int argc, char **argv)
{
   int pstat = 0;
   table = newSymbolTable();
   int doAssembly = 1;
   int doASTree = 0;
   int opt;
   int fileInt = 0;
   
   while ((opt = getopt(argc, argv, "dt"))!=-1){
   	switch(opt){
   	case 't': //enable debugging output on parser and scanner
   	 debug = 1;
   	 break;
   	case 'd': //print ASTree to stdout, no assembly code
   	doASTree = 1;
   	doAssembly = 0;
   	 break;
   	}
   }
   char *check = ".c";
   if (argc < 2){
   //yacc reads from stdin and outputs to stdout
   }
   //compiler invoked with filename argument
   if (argc==2) {
      fileInt = 1;
      if (strstr(argv[1], check)){// if filename in argv[1] contains ".c"
      yyin = fopen(argv[1],"r");
      if (!yyin) {
         printf("Error: unable to open file (%s)\n",argv[1]);
         return(1);
      }
      //TODO fix save filename without .c to add .s for output
    }
    	else{
    	fprintf(stderr, "filename must end in .c\n"); exit(-1);
    	}
   }
   if (argc==3){
      fileInt = 2;
      if(strstr(argv[2], check)){  
      yyin = fopen(argv[2],"r");
      if (!yyin) {
         printf("Error: unable to open file (%s)\n",argv[1]);
         return(1);
       }
      }
      else{
      fprintf(stderr, "filename must end in .c\n"); exit(-1);
      }
   }
   pstat = yyparse();
   
   
   
   if (doAssembly == 1){
	   char *cfile = (char*)(malloc(sizeof(char)*strlen(argv[fileInt])+1)); //error1: invalid write of size 1
	   char *sfile = (char*)(malloc(sizeof(char)*strlen(argv[fileInt])+1)); //error2, error 3: invalid write of size 2, syscall param openat(filename)
	   strcpy(cfile, argv[fileInt]);
	   strncpy(sfile, cfile, (int)strlen(argv[fileInt])-2); //error1: invalid write of size 1
	   sfile[strlen(argv[fileInt])-2] = '\0';
	   strcat(sfile, ".s");
	   FILE *outFile = fopen(sfile, "w"); //error2: invalid write of size 1
	genCode(programAST, 0, outFile); // error3: syscall param openat(filename)
	   fclose(outFile);
	   free(cfile);
	   free(sfile);
   }
   
   if (doASTree == 1)
   printASTree(programAST, 0, stdout);
   fclose(yyin);
   freeAllSymbols(table);
   free(table);
   freeASTree(programAST);
   yylex_destroy();
   return(pstat);
}


int yyerror(char *s)
{
   fprintf(stderr, "Error: line %d: %s\n",yylineno,s);
   return 0;
}

int yywrap()
{
   return(1);
}
int addString(char *str){
	stringArray[strcounter] = str;
	strcounter++;
	return (strcounter - 1);
}
