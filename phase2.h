#include <stdlib.h>
#include <string.h>
#include <stdio.h>
extern int yylineno;





struct symbolRecord{
char name[30];
char type[30];
double value;
}symbRecord;

struct variableRecord{
int scope;
char type[30];
char name[30];
};

struct variableRecord symbolTable[30];

void addVariable(char variable[], char dataType[]);
int storedVariable(char variable[], int scope);
char* lookUp (char unknownVar[], int scope);

int isValidAssignment(char dataType1[], char dataType2[]);

void undeclaredErrHandler(char variable[]);
void DuplicateErrHandler(char variable[]);
void relationalErHandler(char msg[],char dataType1[],char dataType2[]); 
void ifErHandler(char msg[]);
void assignmentErrHandler(char dataType1[], char dataType2[]);
void RepeatErrHandler(char msg[]);