/*
 * Interface
 */

/datum/templateToken
	var/static/nextid = 1
	var/selector

/datum/templateToken/New(selector)
	if (isnull(selector))
		selector = "token-[num2text(nextid++, 99)]"
	src.selector = selector

//returns a list of template variables this token depends on.
/datum/templateToken/proc/getRequestedVars()

//returns a list with the computed text(s)
/datum/templateToken/proc/compute(list/variables, selectorAppend)

//returns a assoicated list with css selectors to update and their new value.
/datum/templateToken/proc/computeDiff(list/variables, selectorAppend)

//returns a templateToken object that is a duplicate of this one.
/datum/templateToken/proc/dupe()
	return new type(selector)


/*
 * Implementations
 */

/datum/templateToken/TStringLiteral
	var/stringLiteral

/datum/templateToken/TStringLiteral/New(selector, stringLiteral)
	src.stringLiteral = stringLiteral

/datum/templateToken/TStringLiteral/getRequestedVars()
	return

/datum/templateToken/TStringLiteral/compute()
	return stringLiteral

/datum/templateToken/TStringLiteral/TEscapedVariable/New(selector, stringLiteral)
	src.stringLiteral = "{{[copytext(stringLiteral, 2)]}}"

/datum/templateToken/TVariable
	var/variable
	var/isset = FALSE
	var/value = ""

/datum/templateToken/TVariable/New(selector, variable)
	//world << "selector:[selector], variable:[variable]"
	if (length(variable) >= 1 && variable[1] == "%")
		//world << "not batman"
		variable = copytext(variable, 2)
		..()
	else if (selector)
		..()
	src.variable = variable


/datum/templateToken/TVariable/getRequestedVars()
	return list(variable)


/datum/templateToken/TVariable/compute(list/variables, selectorAppend)
	value = variables[variable]
	if (!isset)
		if (value)
			isset = TRUE
		else if (variable in variables)
			isset = TRUE
		else
			//unset variables are printed as is.
			return "{{[variable]}}"

	return value

/datum/templateToken/TVariable/computeDiff(list/variables, selectorAppend)
	var/newvalue = variables[variable]

	if (isset && value == newvalue)
		return

	value = newvalue

	if (!isset)
		if (value)
			isset = TRUE
		else if (variable in variables)
			isset = TRUE
		else
			return

	return list("[selector][selectorAppend]" = list(T_UPDATE_REPLACE = value))


/datum/templateToken/TVariable/dupe()
	return new type (selector, variable)

/*
 * Conditionals
 */

/datum/templateToken/TConditional
	var/variable
	var/value = ""
	var/datum/tokenSet/tokenSet
	var/list/varSet
	var/list/valueSet
	var/lastRes = FALSE


/datum/templateToken/TConditional/New(selector, variable, datum/tokenSet/tokenSet)
	if (length(variable) >= 1 && variable[1] == "%")
		variable = copytext(variable, 2)
		..()
	else if (selector)
		..()

	src.variable = variable
	src.tokenSet = tokenSet
	varSet = tokenSet.listRequestedVars()
	valueSet = list()

/datum/templateToken/TConditional/getRequestedVars()
	//doing it this way ensures our conditional variable is first but never duplicated
	if (variable)
		return (list(variable) | varSet)
	return varSet

/datum/templateToken/TConditional/compute(list/variables, selectorAppend)
	if (variable)
		value = variables[variable]

	valueSet = variables

	if (!checkCondition())
		lastRes = FALSE
		return

	lastRes = TRUE
	return tokenSet.compute(valueSet, selectorAppend)

/datum/templateToken/TConditional/computeDiff(list/variables, selectorAppend)
	if (variable)
		value = variables[variable]

	valueSet = variables | valueSet
	var/newRes = checkCondition()

	if (lastRes == newRes)
		return tokenSet.computeDiff(variables, selectorAppend)

	lastRes = newRes

	if (!newRes)
		return list("[selector][selectorAppend]" = list(T_UPDATE_REPLACE = ""))

	return list("[selector][selectorAppend]" = list(T_UPDATE_REPLACE = jointext(compute(variables, selectorAppend), "")))


/datum/templateToken/TConditional/dupe()
	return new type(selector, variable, tokenSet.dupe())


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

/datum/templateToken/TConditional/TIfnEmpty/TArray
	var/list/cachedTokenSets

/datum/templateToken/TConditional/TIfnEmpty/TArray/compute(list/variables, selectorAppend)
	var/list/L = variables[variable]
	if (islist(L))
		value = L = L.Copy()
	else
		value = L
	if (selector)
		cachedTokenSets = list()

	if (!checkCondition())
		lastRes = FALSE
		return

	lastRes = TRUE
	var/list/res = list()

	if (selector)
		cachedTokenSets.len = length(L)

	var/list/varSet = src.varSet

	for (var/i in 1 to length(L))
		var/list/valueSet = variables.Copy()
		var/item = L[i]
		if (islist(item))
			valueSet += item
		else
			valueSet["[variable]-KEY"] = "[item]"
			if (!isnum(item) && ("[variable]-VALUE" in varSet))
				valueSet["[variable]-VALUE"] = "[L[item]]"

		valueSet["[variable]-INDEX"] = i
		var/datum/tokenSet/currentTokenSet = tokenSet
		if (selector)
			currentTokenSet = currentTokenSet.dupe()
			cachedTokenSets[i] = currentTokenSet
		res += currentTokenSet.compute(valueSet, "[selectorAppend]-A[i]")

	return res

/datum/templateToken/TConditional/TIfnEmpty/TArray/computeDiff(list/variables, selectorAppend)
	var/list/L = variables[variable]
	var/newvalue

	if (islist(L))
		newvalue = L = L.Copy()
	else
		newvalue = L

	if (value ~= newvalue)
		value = newvalue
		return

	var/newres = checkCondition()

	if (!newres)
		if (lastRes)
			lastRes = newres
			return list("[selector][selectorAppend]" = list(T_UPDATE_REPLACE = ""))
		lastRes = newres
		return
	else if (newres && !lastRes)
		return list("[selector][selectorAppend]" = list(T_UPDATE_REPLACE = jointext(compute(variables, selectorAppend), "")))

	var/list/res = list()

	var/newlength = length(newvalue)
	var/oldlength = length(value)

	cachedTokenSets.len = newlength

	//todo: Add proper diffing.
	for (var/i in 1 to max(newlength, oldlength))
		if (i > newlength)
			res += list("[selector][selectorAppend]-A[i]" = list(T_UPDATE_REMOVE = ""))
			continue

		var/list/valueSet = variables.Copy()
		var/item = L[i]
		if (islist(item))
			valueSet += item
		else
			valueSet["[variable]-KEY"] = "[item]"
			if (!isnum(item) && ("[variable]-VALUE" in varSet))
				valueSet["[variable]-VALUE"] = "[L[item]]"

		valueSet["[variable]-INDEX"] = i
		var/datum/tokenSet/currentTokenSet = cachedTokenSets[i]

		if (i > oldlength)
			currentTokenSet = tokenSet.dupe()
			cachedTokenSets[i] = currentTokenSet
			var/value = currentTokenSet.compute(valueSet, "[selectorAppend]-A[i]")
			res += list("[selector][selectorAppend]-A[i-1]" = list(T_UPDATE_ADD_AFTER = jointext(value, "")))
			continue

		res += currentTokenSet.computeDiff(valueSet, "[selectorAppend]-A[i]")

	value = newvalue

	return res

/datum/templateToken/TConditional/TUpdatingBlock/New(selector, variable, datum/tokenSet/tokenSet)
	if (isnull(selector))
		selector = "token-[num2text(nextid++, 99)]"

	..(selector, variable, tokenSet)

/datum/templateToken/TConditional/TUpdatingBlock/checkCondition()
	return TRUE

/datum/templateToken/TConditional/TUpdatingBlock/computeDiff(list/variables, selectorAppend)
	for (var/variable in varSet)
		if (valueSet[variable] ~! variables[variable])
			lastRes = FALSE
			return ..()


/datum/tokenSet
	var/list/tokens
	var/list/requestedVars
	var/list/tokenVarMappings

/datum/tokenSet/New(list/tset)
	if (!islist(tset))
		CRASH("Token set must be a list")

	var/list/tokens = list()
	requestedVars = list()
	tokenVarMappings = list()

	for (var/thing in tset)
		var/datum/templateToken/token = thing
		var/list/tokenVariables = token.getRequestedVars()
		for (var/variable in tokenVariables)
			tokenVarMappings[variable] += list(token)
		requestedVars |= tokenVariables
		tokens[token] = tokenVariables

	src.tokens = tokens


/datum/tokenSet/proc/listRequestedVars()
	return requestedVars.Copy()

/datum/tokenSet/proc/compute(variables, selectorAppend)
	if (!variables)
		variables = list()

	var/list/tokens = src.tokens

	var/list/rtn = list()
	for (var/thing in tokens)
		var/datum/templateToken/token = thing
		var/selector = token.selector
		if (selector)
			rtn += {"<span id="[selector][selectorAppend]">"}
			rtn += token.compute(variables, selectorAppend)
			rtn += "</span>"
		else
			var/value = token.compute(variables, selectorAppend)
			if (value)
				rtn += value
	return rtn

/datum/tokenSet/proc/computeDiff(variables, selectorAppend)
	if (!variables)
		variables = list()


	var/list/tokens = src.tokens

	var/list/rtn = list()
	for (var/thing in tokens)
		var/datum/templateToken/token = thing
		var/selector = token.selector
		if (selector)
			var/list/res = token.computeDiff(variables, selectorAppend)
			if (!length(res))
				continue
			rtn += res
	return rtn

/datum/tokenSet/proc/dupe()
	var/list/tokens = src.tokens
	var/l = length(tokens)
	var/list/newtokens = new(l)
	for (var/i in 1 to l)
		var/datum/templateToken/token = tokens[i]
		if (token.selector)
			token = token.dupe()
		newtokens[i] = token

	return new type(newtokens)