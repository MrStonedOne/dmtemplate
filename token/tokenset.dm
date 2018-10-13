/datum/tokenSet
	var/list/tokens
	var/list/requestedVars
	var/list/tokenVarMappings
	var/list/listeners

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
			if (!token)
				token = tokens[i]
				crash("failed dupe by `[token.type]` - `[token]`")

		newtokens[i] = token

	return newtokens