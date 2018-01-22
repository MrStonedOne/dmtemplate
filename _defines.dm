#define T_TOKEN_STRINGLIT 0
#define T_TOKEN_VARIABLE 1
#define T_TOKEN_ENDIF 2
#define T_TOKEN_IFDEF 3
#define T_TOKEN_IFNDEF 4
#define T_TOKEN_ARRAY 5
#define T_TOKEN_IFEMPTY 6
#define T_TOKEN_IFNEMPTY 7

#define islist(thing) istype(thing, /list)