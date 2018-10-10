#define T_TOKEN_STRINGLIT 0
#define T_TOKEN_VARIABLE 1
#define T_TOKEN_ESCAPED_VARIABLE 2
#define T_TOKEN_ENDIF 3 //any tokens higher then this are assumed to be conditional tokens and follow that syntax
#define T_TOKEN_ELSE 4
#define T_TOKEN_IF 5
#define T_TOKEN_IFN 6
#define T_TOKEN_FOREACH 7
#define T_TOKEN_IFEMPTY 8
#define T_TOKEN_IFNEMPTY 9
#define T_TOKEN_SWITCH 10
#define T_TOKEN_CASE 11
#define T_TOKEN_DEFAULT 12
#define T_TOKEN_UPDATING_BLOCK 14

#define T_UPDATE_REPLACE "REPLACE"
#define T_UPDATE_APPEND "APPEND"
#define T_UPDATE_PREPEND "PREPEND"
#define T_UPDATE_ADD_BEFORE "BEFORE"
#define T_UPDATE_ADD_AFTER "AFTER"
#define T_UPDATE_REMOVE "REMOVE"

//returns a list of variables access by this expression
#define T_VAR_IDENTIFY 1
//returns the expression and nothing else.
#define T_VAR_RETURN 2
//evaluates the expression.
#define T_VAR_ACCESS 3

#define T_SAN_HTML 1
#define T_SAN_URL 2
#define T_SAN_UNSAFE 3

#define islist(thing) istype(thing, /list)