%{
#include <stdio.h>
#include "phase2.h"
#include "phase2.tab.h"
#include<stdlib.h>
#include <string.h>

extern int yylineno;
extern FILE* yyin;
extern int yyerror (char* msg);
extern char * yytext;
extern int yylex();
extern int yyparse();

int numVariables = 0;
int scope = 1;

void undeclaredErrHandler(char variable[]);
void DuplicateErrHandler(char variable[]);
void relationalErHandler(char msg[],char dataType1[],char dataType2[]); 
void ifErHandler(char msg[]);
void assignmentErrHandler(char dataType1[], char dataType2[]);
void RepeatErrHandler(char msg[]);
struct symbols;

%}

%union {
    struct symbolRecord symbRecord;
}

%type <symbRecord>factor;
%type <symbRecord>exp;
%type <symbRecord>term;
%type <symbRecord>type;
%type <symbRecord>simple_exp;

%token<symbRecord> START END IF THEN ELSE IFEND READ WRITE REPEAT UNTIL
%token<symbRecord> INT DOUBLE 
%token<symbRecord> INT_LITERAL STRING_LITERAL DBL_LITERAL ID
%token<symbRecord> ASSIGN PLUS MINUS MULT DIV EQ LT LE GT GE NE LPAREN RPAREN



%%
Program :START stmt_sequence END ;

stmt_sequence :statment ';' stmt_sequence
              | statment ';' ;

statment :dec_stmt
         | if_stmt 
         | repeat_stmt
         | assign_stmt
         | read_stmt
         | write_stmt ;

dec_stmt :type ID        
{
	strcpy($2.type, $1.type);
	if(!storedVariable($2.name,scope))
		addVariable($2.name,$2.type);
	else DuplicateErrHandler($2.name);
};

type :INT { strcpy($$.name, "int"); strcpy($$.type, "int");}
     | DOUBLE  { strcpy($$.name, "double"); strcpy($$.type, "double");};

if_stmt :IF exp THEN stmt_sequence IFEND 
	{
		if(!storedVariable($2.name,scope))
			undeclaredErrHandler($2.name);
		if(strcmp($2.type,"boolean") != 0)
			ifErHandler($2.type);
	}
        |IF exp THEN stmt_sequence ELSE stmt_sequence IFEND 
		{
			if(!storedVariable($2.name,scope))
				undeclaredErrHandler($2.name);
			if(strcmp($2.type,"boolean") != 0)
				ifErHandler($2.type);
		};

repeat_stmt :REPEAT stmt_sequence UNTIL exp 
	{
	if(!storedVariable($4.name,scope))
		undeclaredErrHandler($4.name);
	if(strcmp($4.type,"boolean") != 0)
		RepeatErrHandler($4.type);

	}; 

assign_stmt :ID ASSIGN exp  
	{if(storedVariable($1.name,scope))
		{
			if(!isValidAssignment(lookUp($1.name,scope), $3.type))
			assignmentErrHandler(lookUp($1.name,scope), $3.type);
		}
			else undeclaredErrHandler($1.name);
			if(!storedVariable($3.name,scope)){
				undeclaredErrHandler($3.name);
			}
	};

read_stmt :READ ID ;

write_stmt :WRITE LPAREN exp RPAREN 
	{
		if(!storedVariable($3.name,scope))
			undeclaredErrHandler($3.name);
	}
          | WRITE LPAREN STRING_LITERAL RPAREN ;

exp :simple_exp comparison_op simple_exp 
	{
		if(strcmp($1.type,$3.type)==0)
		strcpy($$.type, "boolean");
		else relationalErHandler(" comparison between ",$1.type,$3.type);	
	}
    |simple_exp; 

comparison_op :EQ 
              |LT 
              |LE 
              |GT 
              |GE  
              |NE;

simple_exp  :simple_exp addopt term  
	{
		if((strcmp($1.type,"int") == 0 || strcmp($1.type,"double") == 0) && (strcmp($3.type,"int") == 0 || strcmp($3.type,"double") == 0))
		{
			if(strcmp($1.type,$3.type) == 0)
				strcpy($$.type, $1.type);
			else strcpy($$.type, "double");
		}
		else relationalErHandler(" operation between ",$1.type,$3.type);
	}	
            | term ;

addopt:PLUS
    |MINUS;

term :term multop factor
	{
		if((strcmp($1.type,"int") == 0 || strcmp($1.type,"double") == 0) && (strcmp($3.type,"int") == 0 || strcmp($3.type,"double") == 0))
		{
			if(strcmp($1.type,$3.type) == 0)
				strcpy($$.type, $1.type);
			else strcpy($$.type, "double");
		}
		else relationalErHandler(" operation between ",$1.type,$3.type);
	}	
     | factor ;

multop: MULT 
       |DIV;
factor : LPAREN exp RPAREN {$$=$2;}
       | INT_LITERAL  { strcpy($$.type, "int");}
       | DBL_LITERAL  { strcpy($$.type, "double");}
       | ID   { strcpy($$.type, lookUp($1.name, scope));}
	   ;

%%
int main (int argc, char *argv[])
{
        yyin=fopen(argv[1],"r");
        
	if(!yyparse())
	printf("\nParsing complete\n");	
	else
	printf("\nParsing failed\n");
	
	fclose(yyin);
	return 0;
}

extern int yyerror(char* msg)
{
	printf("\n %s in line: %d %s \n", msg, (yylineno), yytext);
	return 0;
}


void relationalErHandler(char msg[],char dataType1[], char dataType2[])
{
	printf("\nLine: %d:Incompatible type: %s %s and %s\n", yylineno, msg,dataType1,dataType2);

}

void ifErHandler(char msg[])
{
	printf("\nLine: %d: In IF stmt expression should be boolean not %s\n", yylineno, msg);
}

void RepeatErrHandler(char msg[])
{
	printf("\nLine: %d: In repeat stmt expression should be boolean not %s\n", yylineno, msg);

}

void assignmentErrHandler(char dataType1[], char dataType2[])
{

    printf("\nLine: %d: Incompatible type: Assigning %s to %s \n", yylineno, dataType1, (strcmp(dataType2,"")==0?"NA":dataType2));
	
}

void DuplicateErrHandler(char variable[])
{
    printf("\nDuplicate Variable Error: line %d, Duplicate variable '%s' found\n", yylineno, variable);
}

void undeclaredErrHandler(char variable[])
{
	printf("\nLine: %d: Cannot find symbol \"%s\"\n", yylineno, variable);
	
}

void addVariable(char variable[], char dataType[])
{
	strcpy(symbolTable[numVariables].name, variable);	
	strcpy(symbolTable[numVariables].type, dataType);
	symbolTable[numVariables].scope = scope;
	numVariables++;
}

int storedVariable(char variable[], int scope)
{
	for(int i=0; i<numVariables; i++)
		if(strcmp(symbolTable[i].name, variable) == 0 && symbolTable[i].scope == scope)
			return 1;

	return 0;
}

char* lookUp(char unknownVar[], int scope) 
{
	for(int i=0; i<numVariables; i++)
		if(strcmp(symbolTable[i].name, unknownVar) == 0 && symbolTable[i].scope == scope)
			return symbolTable[i].type;
	return "";
}

int isValidAssignment(char dataType1[], char dataType2[])
{
    if(strcmp(dataType1, dataType2) != 0)
        return 0;
    return 1;
}