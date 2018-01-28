/*
 * Interface
 */
/datum/templateToken
	//var/
//returns a list of template variables this token depends on.
/datum/templateToken/proc/getRequestedVars()

//this is how we pass the token its template variable.
/datum/templateToken/proc/setVar(varname, value = null)

//returns a string with the computed text.
/datum/templateToken/proc/compute()


/*
 * Implementations
 */

/datum/templateToken/TStringLiteral
	var/stringLiteral

/datum/templateToken/TStringLiteral/New(stringLiteral)
	src.stringLiteral = stringLiteral

/datum/templateToken/TStringLiteral/getRequestedVars()
	return list()

/datum/templateToken/TStringLiteral/setVar(variable, value = null)
	return

/datum/templateToken/TStringLiteral/compute()
	return stringLiteral



/datum/templateToken/TVariable
	var/variable
	var/isset = FALSE
	var/value = ""

/datum/templateToken/TVariable/New(variable)
	src.variable = variable


/datum/templateToken/TVariable/getRequestedVars()
	return list(variable)

/datum/templateToken/TVariable/setVar(variable, value = null)
	if (value == null || value == FALSE || variable != src.variable)
		return
	src.value = value
	isset = TRUE

/datum/templateToken/TVariable/compute()
	//we reset state so the token can be used again.
	var/value = src.value
	src.value = ""
	var/isset = src.isset
	src.isset = FALSE

	if (!isset) //unset variables are printed as is.
		return "{[variable]}"
	return value

/datum/templateToken/TVariable/escaped/compute()
	return "{[variable]}"

/datum/templateToken/TVariable/escaped/getRequestedVars()
	return list()

/datum/templateToken/TVariable/escaped/New(variable)
	src.variable = copytext(variable, 2)

/*
 * Conditionals
 */

/datum/templateToken/TConditional
	var/variable
	var/value = ""
	var/datum/tokenSet/tokenSet
	var/list/varSet
	var/list/valueSet

/datum/templateToken/TConditional/New(variable, datum/tokenSet/tokenSet)
	src.variable = variable
	src.tokenSet = tokenSet
	varSet = tokenSet.listRequestedVars()
	valueSet = list()

/datum/templateToken/TConditional/getRequestedVars()
	//doing it this way ensures our conditional variable is first but never duplicated
	return (list(variable) | varSet)

/datum/templateToken/TConditional/setVar(variable, value = null)
	if (variable == src.variable)
		src.value = value

	valueSet[variable] = value

/datum/templateToken/TConditional/compute()
	//copy over state
	var/check = checkCondition()
	var/valueSet = src.valueSet

	//reset state
	src.value = ""
	src.valueSet = list()

	//do stuff
	if (!check)
		return ""

	return tokenSet.compute(valueSet)


/datum/templateToken/TConditional/proc/checkCondition()
	CRASH("Invalid use of TConditional")


/datum/templateToken/TConditional/TIfDef/checkCondition()
	return (variable && value)


/datum/templateToken/TConditional/TIfnDef/checkCondition()
	return !(variable && value)


/datum/templateToken/TConditional/TIfnEmpty/checkCondition()
	if (!variable || !variable)
		return FALSE
	if (!islist(value) || length(value) <= 0)
		return FALSE
	return TRUE


/datum/templateToken/TConditional/TIfEmpty/checkCondition()
	if (!variable || !variable)
		return TRUE
	if (!islist(value) || length(value) <= 0)
		return TRUE
	return FALSE



/datum/templateToken/TConditional/TIfnEmpty/TArray/setVar(variable, value = null)
	if (!islist(value))
		return
	if (variable == src.variable)
		src.value = value

/datum/templateToken/TConditional/TIfnEmpty/TArray/getRequestedVars()
	return list(variable)

/datum/templateToken/TConditional/TIfnEmpty/TArray/compute()
	//copy over state
	var/check = checkCondition()
	var/list/arr = value

	//reset state
	value = ""
	valueSet = list()

	//do stuff
	if (!check)
		return ""
	var/list/res = list()

	for (var/list/valueSet in arr)
		valueSet = valueSet.Copy()
		for (var/key in valueSet)
			var/value = valueSet[key]
			if (!istext(value) && !isnum(value) && istype(value, /datum/template))
				var/datum/template/T = value
				valueSet[key] = T.compute()
		res += tokenSet.compute(valueSet)

	return res


/datum/tokenSet
	var/list/tokens
	var/list/requestedVars
	var/list/tokenVarMappings

/datum/tokenSet/New(list/tset)
	if (!islist(tset))
		CRASH("Token set must be an array")
	requestedVars = list()
	tokenVarMappings = list()
	for (var/thing in tset)
		var/datum/templateToken/token = thing

		if (!istype(token))
			CRASH("tset must contain only objects of type templateToken")
		var/list/tokenVariables = token.getRequestedVars()
		for (var/variable in tokenVariables)
			tokenVarMappings[variable] += list(token)
		requestedVars |= tokenVariables


	src.tokens = tset

/datum/tokenSet/proc/listRequestedVars()
	return requestedVars.Copy()

/datum/tokenSet/proc/compute(variables)
	if (!variables)
		variables = list()
	//first we initialize the tokens with their variables.
	for (var/variable in tokenVarMappings)
		var/list/tokens = tokenVarMappings[variable]
		var/value = variables[variable]
		if (!value)
			for (var/thing in tokens)
				var/datum/templateToken/token = thing
				token.setVar(variable)
			continue


		for (var/thing in tokens) //pass the variable value to each token that requested it.
			var/datum/templateToken/token = thing
			token.setVar(variable, value)


	var/list/rtn = list()
	for (var/thing in tokens)
		var/datum/templateToken/token = thing
		rtn += token.compute()
	return rtn


