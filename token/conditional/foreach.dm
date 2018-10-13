/datum/templateToken/TConditional/TIfEmpty/TIfnEmpty/TForEach
	var/list/cachedTokenSets
	var/indexVar
	var/keyVar
	var/valueVar

/datum/templateToken/TConditional/TIfEmpty/TIfnEmpty/TForEach/New(selector, tContents, list/tokens)
	var/var_start = findtext(tContents, " ")
	if (!var_start)
		crash("TParse Error: Invalid foreach")
	tContents = copytext(tContents, var_start+1)
	var/variable = resolveVariable(tContents, T_VAR_RETURN)
	var/arglen
	if ((arglen = length(variable)) < length(tContents))
		//chop off the first word
		tContents = copytext(tContents, arglen+1+spantext(tContents, " ", arglen+1))
		//consume the second
		indexVar = resolveVariable(tContents, T_VAR_RETURN)

		if ((arglen = length(indexVar)) < length(tContents)) //rinse
			tContents = copytext(tContents, arglen+1+spantext(tContents, " ", arglen+1))
			keyVar = resolveVariable(tContents, T_VAR_RETURN)

			if ((arglen = length(keyVar)) < length(tContents)) //repeat
				tContents = copytext(tContents, arglen+1+spantext(tContents, " ", arglen+1))
				valueVar = resolveVariable(tContents, T_VAR_RETURN)


	if (length(variable) >= 1 && variable[1] == "%")
		variable = copytext(variable, 2)
		if (isnull(selector))
			selector = "token-[num2text(nextid++, 99)]"

	..(selector, null, tokens)
	src.variable = variable
	//world.log << "TFN: `[variable]` - `[src.variable]`"

/datum/templateToken/TConditional/TIfEmpty/TIfnEmpty/TForEach/dupe()
	var/datum/templateToken/TConditional/TIfEmpty/TIfnEmpty/TForEach/F = ..()
	F.indexVar = indexVar
	F.keyVar = keyVar
	F.valueVar = valueVar
	return F

/datum/templateToken/TConditional/TIfEmpty/TIfnEmpty/TForEach/compute(list/variables, selectorAppend)
	var/list/L = resolveVariable(variable, T_VAR_ACCESS, variables)
	if (islist(L))
		value = L = L.Copy()
	else
		value = L
	if (selector)
		cachedTokenSets = list()

	if (!checkCondition(variables))
		//world.log << "FCC: 0 - [variable] - [type]"
		lastRes = FALSE
		return
	//world.log << "FCC: 1 - `[variable]` - `[type]`"
	//world.log << "...FCC: `[indexVar]` - `[keyVar]` - `[valueVar]`"
	lastRes = TRUE
	var/list/res = list()

	if (selector)
		cachedTokenSets.len = length(L)

	var/list/varSet = src.varSet

	for (var/i in 1 to length(L))
		var/list/valueSet = variables.Copy()
		var/item = L[i]
		if (!keyVar && islist(item))
			valueSet += item
		else
			valueSet["[keyVar]"] = item
			if (!isnum(item) && (valueVar in varSet))
				valueSet[valueVar] = L[item]

		if (indexVar)
			valueSet["[indexVar]"] = i
		var/datum/tokenSet/currentTokenSet = tokenSet
		if (selector)
			currentTokenSet = new /datum/tokenSet(currentTokenSet.dupe())
			cachedTokenSets[i] = currentTokenSet
		res += currentTokenSet.compute(valueSet, "[selectorAppend]-A[i]")

	return res

/datum/templateToken/TConditional/TIfEmpty/TIfnEmpty/TForEach/computeDiff(list/variables, selectorAppend)
	var/list/L = resolveVariable(variable, variables)
	var/newvalue

	if (islist(L))
		newvalue = L = L.Copy()
	else
		newvalue = L

	var/newres = checkCondition(variables)

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
		if (!keyVar && islist(item))
			valueSet += item
		else
			valueSet["[keyVar]"] = "[item]"
			if (valueVar && !isnum(item) && (valueVar in varSet))
				valueSet[valueVar] = "[L[item]]"

		if (indexVar)
			valueSet["[indexVar]"] = i
		var/datum/tokenSet/currentTokenSet = cachedTokenSets[i]

		if (i > oldlength)
			currentTokenSet = new /datum/tokenSet(tokenSet.dupe())
			cachedTokenSets[i] = currentTokenSet
			var/value = currentTokenSet.compute(valueSet, "[selectorAppend]-A[i]")
			res += list("[selector][selectorAppend]-A[i-1]" = list(T_UPDATE_ADD_AFTER = jointext(value, "")))
			continue

		res += currentTokenSet.computeDiff(valueSet, "[selectorAppend]-A[i]")

	value = newvalue

	return res
