/****
* Lex scanner reworked from example given by Dr. Jonathan Cook
* Student: Jesus Barba
****/

/****** Header definitions ******/
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symtable.h"
#include "astree.h"
#ifndef LEXONLY
// definitions auto-created by yacc (when using yacc)
#include "y.tab.h"
#else
// explicit definitions for standalone mode
typedef union { int ival; char* str; } yystype;
#define YYSTYPE yystype
yystype yylval;
#define kwint     1
#define kwwhile   2
#define kwif      3
#define kwelse    4
#define kwstring  5
#define id        6
#define string    7
#define lparen    8
#define rparen    9
#define lbrace    10
#define rbrace    11
#define semicolon 12
#define number    13
#define comma     14
#define addop     15
#define equals    16
#define relop     17
#endif
extern int debug; // declared and set in parser.y
%}

%option yylineno

/****** Token Patterns ******/
%%
[ \t\n\r]* { /* skipping white space */ }
int {
	if (debug) fprintf(stderr, "lex kwint\n");
	return (kwint);
	}
while {
	if (debug) fprintf(stderr, "lex kwwhile\n");
	return (kwwhile);
	}
if {
	if (debug) fprintf(stderr, "lex kwif\n");
	return (kwif);
	}
else {
	if (debug) fprintf(stderr, "lex kwelse\n");
	return (kwelse);
	}
char\* {
	if (debug) fprintf(stderr, "lex kwstring\n");
	return (kwstring);
	}
[_a-zA-Z][a-zA-Z0-9_]* {
	if (debug) fprintf(stderr, "lex id: (%s)\n", yytext);
	yylval.str = strdup(yytext);
	return(id);
	}
\"([^"]*)\" {

	if (debug) fprintf(stderr, "lex string: (%s)\n", yytext);
	yylval.str = strdup(yytext);
	return(string);
	}
\( {
	if (debug) fprintf(stderr, "lex lparen\n");
	yylval.ival = yytext[0];
	return (lparen);
	}
\) {
	if (debug) fprintf(stderr, "lex rparen\n");
	yylval.ival = yytext[0];
	return (rparen);
	}
\{ {
	if (debug) fprintf(stderr, "lex lbrace\n");
	yylval.ival = yytext[0];
	return (lbrace);
	}
\} {
	if (debug) fprintf(stderr, "lex rbrace\n");
	yylval.ival = yytext[0];
	return (rbrace);
	}
\; {
	if (debug) fprintf(stderr, "lex semicolon\n");
	yylval.ival = yytext[0];
	return (semicolon);
	}
[0-9]+ {
	if (debug) fprintf(stderr, "lex number: %s\n", yytext);
	yylval.ival = strtol(yytext,0,10);
	return (number);
	}
\,	{
	if (debug) fprintf(stderr, "lex comma\n");
	yylval.ival = yytext[0];
	return (comma);
	}
\+	{
	if (debug) fprintf(stderr, "lex plus relop\n");
	yylval.ival = yytext[0];
	return (addop);
	}
\- {
	if (debug) fprintf(stderr, "lex minus relop\n");
	yylval.ival = yytext[0];
	return (addop);
	}
\=	{
	if (debug) fprintf(stderr, "lex equals\n");
	yylval.ival = yytext[0];
	return (equals);
	}
\<	{
	if (debug) fprintf(stderr, "lex < relop\n");
	yylval.ival=yytext[0];
	return(relop);
	}
\>	{
	if (debug) fprintf(stderr, "lex > relop\n");
	yylval.ival = yytext[0];
	return(relop);
	}
\=\=	{
	if (debug) fprintf(stderr, "lex == relop\n");
	yylval.ival = yytext[0];
	return(relop);
	}
\!\=	{
	if (debug) fprintf(stderr, "lex != relop\n");
	yylval.ival = yytext[0];
	return (relop);
	}
	
%%
/****** Functions (not used when used with parser) *******/

//
// Code in the ifdef block below is only for compiling the
// scanner all by itself, for testing purposes. The 
// Makefile shows how to compile it under the "ltest" rule
// (do "make ltest" to build it)
//
#ifdef LEXONLY

// A main for standalone testing (uses just stdin as input)
int main(int argc, char **argv) 
{
   do {
      yylex();
   } while (1);
   // while (!feof(stdin)); doesn't work if redirecting a file
   // in because the file is read in and buffered, and eof is
   // true too early, causing lex to stop; rather, use while(1)
   // and then do a hard exit in yywrap(); ugly, but works!
   return 0;
}

int yywrap()
{
   exit(0); // hard exit!
   //return(1);
}

#endif // LEXONLY

