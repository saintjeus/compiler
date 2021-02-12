//
// Abstract Syntax Tree Implementation
//
#include <stdlib.h>
#include <stdio.h>
#include "astree.h"
#include "symtable.h"

/* GLOBAL VARIABLES */
extern char *stringArray[100];
extern Symbol** table;
extern int strcounter;

// Create a new AST node 
// - allocates space and initializes node type, zeros other stuff out
// - returns pointer to node
ASTNode* newASTNode(ASTNodeType type)
{
   int i;
   ASTNode* node = (ASTNode*) malloc(sizeof(ASTNode));
   node->type = type;
   node->valtype = T_INT;
   node->strval = 0;
   node->next = 0;
   for (i=0; i < ASTNUMCHILDREN; i++)
      node->child[i] = 0;
   return node;
}

// Generate an indentation string prefix, for useS
// in printing the abstract syntax tree with indentation 
// used to indicate tree depth.
// -- NOT thread safe! (uses a static char array to hold prefix)
#define INDENTAMT 3
static char* levelPrefix(int level)
{
   static char prefix[128]; // static so that it can be returned safely
   int i;
   for (i=0; i < level*INDENTAMT && i < 126; i++)
      prefix[i] = ' ';
   prefix[i] = '\0';
   return prefix;
}

//
// Free an entire ASTree, along with string data it has
//
void freeASTree(ASTNode* node)
{
   if (!node)
      return;
   freeASTree(node->child[0]);
   freeASTree(node->child[1]);
   freeASTree(node->child[2]);
   freeASTree(node->next);
   if (node->valtype == T_STRING) 
      free(node->strval);
   free(node);
}

// Print the abstract syntax tree starting at the given node
// - this is a recursive function, your initial call should 
//   pass 0 in for the level parameter
// - comments in code indicate types of nodes and where they
//   are expected; this helps you understand what the AST looks like
// - out is the file to output to, can be "stdout" or other
void printASTree(ASTNode* node, int level, FILE *out)
{
   if (!node)
      return;
   fprintf(out,"%s",levelPrefix(level)); // note: no newline printed here!
   switch (node->type) {
    case AST_PROGRAM:
       fprintf(out,"Program\n");
       printASTree(node->child[0],level+1,out);  // child 0 is gobal var decls
       fprintf(out,"%s--functions--\n",levelPrefix(level+1));
       printASTree(node->child[1],level+1,out);  // child 1 is function defs
       break;
    case AST_VARDECL:
       fprintf(out,"Variable declaration (%s)",node->strval); // var name
       if (node->valtype == T_INT)
          fprintf(out," type int\n");
       else if (node->valtype == T_STRING)
          fprintf(out," type string\n");
       else
          fprintf(out," type unknown\n");
       break;
    case AST_FUNCTION:
       fprintf(out,"Function def (%s)\n",node->strval); // function name
       printASTree(node->child[0],level+1,out); // child 0 is param list
       fprintf(out,"%s--body--\n",levelPrefix(level+1));
       printASTree(node->child[1],level+1,out); // child 1 is body (stmt list)
       break;
    case AST_SBLOCK:
       fprintf(out,"Statement block\n");
       printASTree(node->child[0],level+1,out);  // child 0 is statement list
       break;
    case AST_FUNCALL:
       fprintf(out,"Function call (%s)\n",node->strval); // func name
       printASTree(node->child[0],level+1,out);  // child 0 is argument list
       break;
    case AST_ARGUMENT:
       fprintf(out,"Funcall argument\n");
       printASTree(node->child[0],level+1,out);  // child 0 is argument expr
       break;
    case AST_ASSIGNMENT:
       fprintf(out,"Assignment to (%s)\n", node->strval);
       printASTree(node->child[0],level+1,out);  // child 1 is right hand side
       break;
    case AST_WHILE:
       fprintf(out,"While loop\n");
       printASTree(node->child[0],level+1,out);  // child 0 is condition expr
       fprintf(out,"%s--body--\n",levelPrefix(level+1));
       printASTree(node->child[1],level+1,out);  // child 1 is loop body
       break;
    case AST_IFTHEN:
       fprintf(out,"If then\n");
       printASTree(node->child[0],level+1,out);  // child 0 is condition expr
       fprintf(out,"%s--ifpart--\n",levelPrefix(level+1));
       printASTree(node->child[1],level+1,out);  // child 1 is if body
       fprintf(out,"%s--elsepart--\n",levelPrefix(level+1));
       printASTree(node->child[2],level+1,out);  // child 2 is else body
       break;
    case AST_EXPRESSION: // only for binary op expression
       fprintf(out,"Expression (op %d)\n",node->ival);
       printASTree(node->child[0],level+1,out);  // child 0 is left side
       printASTree(node->child[1],level+1,out);  // child 1 is right side
       break;
    case AST_VARREF:
       fprintf(out,"Variable ref (%s)\n",node->strval); // var name
       break;
    case AST_CONSTANT: // for both int and string constants
       if (node->valtype == T_INT)
          fprintf(out,"Int Constant = %d\n",node->ival);
       else if (node->valtype == T_STRING)
          fprintf(out,"String Constant = (%s)\n",node->strval);
       else 
          fprintf(out,"Unknown Constant\n");
       break;
     case AST_RELEXPR:
     	fprintf(out, "Relational expression\n");
     	printASTree(node->child[0], level+1, out); //child 0 is left side
     	fprintf(out, "%srelop: %c\n", levelPrefix(level+1), node->ival); //ival is relop
     	printASTree(node->child[1], level+1, out); //child1 
     	break;
    default:
       fprintf(out,"Unknown AST node!\n");
   }
   // IMPORTANT: walks down sibling list (for nodes that form lists, like
   // declarations, functions, parameters, arguments, and statements)
   printASTree(node->next,level,out);
}

//
// Below here is code for generating our output assembly code from
// an AST. You will probably want to move some things from the
// grammar file (.y file) over here, since you will no longer be 
// generating code in the grammar file. You may have some global 
// stuff that needs accessed from both, in which case declare it in
// one and then use "extern" to reference it in the other.

// In my code, I moved over this stuff:
//void outputConstSec(FILE* out);
//int argnum=0;
//char *argregs[] = {"di", "si", "dx", "cx", "r8", "r9"};

// Generate assembly code from AST
// - this function should look _alot_ like the print function;
//   indeed, the best way to start would be to copy over the 
//   code from printASTree() and change all the recursive calls
//   to this function; then, instead of printing info, we are 
//   going to print assembly code. Easy!
// - param node is the current node being processed
// - param count is a counting parameter (similar to level in
//   the printASTree() function) that can be used to keep track
//   of a position in a list -- I use it only in one place, to keep
//   track of arguments and then to use the correct argument register
//   (count is my index into my argregstr[] array); otherwise this
//   can just be 0
// - param out is the output file handle. Use "fprintf(out,..." 
//   instead of printf(...); call it with "stdout" for terminal output
int argnum = 0;
char *argreg[] = {"%rdi", "%rsi", "%rdx", "%rcx", "%r8", "%r9"};
char *instr;
int relopcount = 101;
void genCode(ASTNode* node, int count, FILE *out){
	if (!node)
		return;
		
	switch(node->type){
	case AST_PROGRAM:
		fprintf(out, "\t.data\n");
		genCode(node->child[0], count, out); //global var decl
		fprintf(out, "\t.text\n\t.section\t.rodata\n");
		for(int i = 0; i<= (strcounter-1);i++){
		fprintf(out, ".LC%d:\n\t.string %s\n", i, stringArray[i]);
		}
		genCode(node->child[1], count, out);
		break;
		
	case AST_VARDECL:
		if (node->valtype == T_INT)
		fprintf(out, "%s:\t.long 0\n", node->strval);
		else if (node->valtype == T_STRING)
		fprintf(out, "%s:\t.long 0\n", node->strval);
		else
		fprintf(out, "%s:\t.long 0\n", node->strval);
		break;
		
	case AST_FUNCTION:
		fprintf(out, "\t.text\n");
		fprintf(out, "\t.globl %s\n\t.type\t%s, @function\n%s:\n", node->strval, node->strval, node->strval);
		fprintf(out, "\n\t.cfi_startproc\n\tendbr64\n\tpushq %%rbp\n\t.cfi_def_cfa_offset 16\n\t.cfi_offset 6,-16\n\tmovq\t%%rsp, %%rbp\n\t.cfi_def_cfa_register 6\n");
		
		//statements which can be funcall or assignment
		genCode(node->child[1], count, out);
		fprintf(out, "\tpopq\t%%rbp\n\t.cfi_def_cfa 7,8\n\tret\n\t.cfi_endproc\n");
		fprintf(out, "\t.size\t%s, \t.-%s\n", node->strval, node->strval);
		//genCode(child[0], count, out); //parameters
		break;
		
	case AST_SBLOCK: //unused for lab 4
		genCode(node->child[0], count, out);
		break;
		
	case AST_FUNCALL:
		genCode(node->child[0], count++, out);
		fprintf(out, "\tcall\t%s\n", node->strval);
		argnum = 0;
		break;
		
	case AST_ARGUMENT:
		genCode(node->child[0], count, out);
		//if (node->child[0]->valtype == T_INT){
			fprintf(out, "\tmovq\t%%rax, %s\n", argreg[argnum]);
			argnum++;
			
		break;
		
	case AST_ASSIGNMENT:
		genCode(node->child[0], count, out);
		fprintf(out, "\tmovl\t%%eax, %s(%%rip)\n", node->strval);
		break;
		
	case AST_WHILE: //FIXME
		relopcount++;
		fprintf(out, "\tjmp LL%d\n", relopcount);
		relopcount--;
		/*LOOP BODY*/
		fprintf(out, "LL%d:\n", relopcount);
		genCode(node->child[1], count, out); //loop body code
		/*END OF LOOP BODY*/
		relopcount++;
		/*WHILE CONDITION*/
		fprintf(out, "LL%d:\n", relopcount);
		relopcount--;
		genCode(node->child[0], count, out); //condition expression
		/*END OF WHILE CONDITION*/
		relopcount++;
		relopcount++;
		break;
		
	case AST_IFTHEN: //FIXME
		genCode(node->child[0], count, out); //condition expression
		//condition expression includes the cmpl and jump type
		
		genCode(node->child[2], count, out); //else body
		
		relopcount++;
		fprintf(out, "\tjmp\tLL%d\n", relopcount);
		relopcount--;
		
		fprintf(out, "LL%d:\n", relopcount);
		genCode(node->child[1], count, out); //if body
		
		relopcount++;
		fprintf(out, "LL%d:\n", relopcount);
		
		relopcount++;
		break;
		
	case AST_EXPRESSION: //FIXME addop can be plus or minus
		//fprintf(out, "before child 0 in ast_expression\n");
		if (node->ival == '+'){
		genCode(node->child[0], count, out);
		fprintf(out, "\tpushq\t%%rax\n");
		genCode(node->child[1], count, out);
		fprintf(out, "\tpopq\t%%rcx\n\taddl\t%%ecx, %%eax\n");
		}
		else if(node->ival == '-'){
		genCode(node->child[1], count, out);
		fprintf(out, "\tpushq\t%%rax\n");
		genCode(node->child[0], count, out);
		fprintf(out, "\tpopq\t%%rcx\n\tsubl\t%%ecx, %%eax\n");
		}
		/*
		ALTERNATE SOLUTION TO ADDL AND SUBL
		genCode(node->child[0], count, out);
		fprintf(out, "\tpushq\t%%rax\n");
		genCode(node->child[1], count, out);
		if (node->ival == '+')
		fprintf(out, "\tpopq\t%%rcx\n\taddl\t%%ecx, %%eax\n");
		else if (node->ival == '-')
		fprintf(out, "\tpopq\t%%rcx\n\tsubl\t%%ecx, %%eax\n");//move result movl\t%%ecx, %%eax*/
		else
		fprintf(out, "math operation not recognized\n");
		break;
		
	case AST_VARREF:
		if (findSymbol(table, node->strval) != NULL)
		fprintf(out, "\tmovl\t%s(%%rip), %%eax\n", node->strval);
		break;
		
	case AST_CONSTANT:
		if (node->valtype == T_INT){
		 fprintf(out, "\tmovl\t$%d, %%eax\n", node->ival);
		 //count++;
		 }
		 else if (node->valtype == T_STRING){
		 fprintf(out, "\tleaq\t.LC%d(%%rip), %%rax\n", node->ival);
		 }
		 else
		 fprintf(out, "unknown constnat\n");
		break;
	case AST_RELEXPR:
		genCode(node->child[0], 0, out);
		fprintf(out, "\tpushq\t%%rax\n");
		genCode(node->child[1], 0, out);
		fprintf(out, "\tpopq\t%%rcx\n");
		fprintf(out, "\tcmpl\t%%eax, %%ecx\n"); //checking in wrong order?
		//fprintf(out, "\tcmpl\t%%ecx, %%eax\n");
		switch(node->ival){
			case '<': instr = "jl"; break;
			case '>': instr = "jg"; break;
			case '!': instr = "jne"; break;
			case '=': instr = "je"; break;
			default: instr = "unknown relop";
		}
		fprintf(out, "\t%s\tLL%d\n", instr, relopcount);
		break;
	default:
		fprintf(out, "Unknown AST node\n");
}
genCode(node->next, count, out);
}
