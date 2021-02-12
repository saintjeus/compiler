#
# Make file for simple scanner and parser example
#

# flags and defs for built-in compiler rules
CFLAGS = -g -I. -Wall -Wno-unused-function
CC = gcc

# default rule to create executable from compiler-generated assembly code
# run "./a.out" to run executable after "make"
all: test.s
	gcc test.s

# rule to print ASTree to stdout, no assembly code
astree: ptest
	./ptest -d test.c

# rule to enable debugging output on parser and scanner
debug: ptest
	./ptest -t test.c

# compiler creates assembly code from test c file
test.s: ptest
	./ptest test.c

# yacc "-d" flag creates y.tab.h header
y.tab.c: parser.y
	yacc -d parser.y

# lex rule includes y.tab.c to force yacc to run first
# lex "-d" flag turns on debugging output
lex.yy.c: scanner.l y.tab.c
	lex scanner.l

# ptest executable needs scanner and parser object files
ptest: lex.yy.o y.tab.o symtable.o astree.o
	gcc -g -o ptest y.tab.o lex.yy.o symtable.c symtable.h astree.c astree.h

# ltest is a standalone lexer (scanner)
# build this by doing "make ltest"
# -ll for compiling lexer as standalone
ltest: scanner.l
	lex scanner.l
	gcc -DLEXONLY lex.yy.c -o ltest -ll

# clean the directory for a pure rebuild (do "make clean")
clean: 
	rm -f lex.yy.c a.out y.tab.c y.tab.h *.o ptest ltest *.s

# valgrind memcheck the ptest executable when it runs on a test c file
memcheck: ptest test.c
	valgrind --leak-check=full --show-leak-kinds=all ./ptest test.c
