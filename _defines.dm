#define T_TOKEN_STRINGLIT 0
#define T_TOKEN_VARIABLE 1
#define T_TOKEN_ESCAPED_VARIABLE 2
#define T_TOKEN_ENDIF 3 //any tokens higher then this are assumed to be conditional tokens and follow that syntax
#define T_TOKEN_IFDEF 4
#define T_TOKEN_IFNDEF 5
#define T_TOKEN_ARRAY 6
#define T_TOKEN_IFEMPTY 7
#define T_TOKEN_IFNEMPTY 8

#define islist(thing) istype(thing, /list)