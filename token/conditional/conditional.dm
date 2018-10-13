/datum/templateToken/TConditional
	var/variable
	var/value = ""
	var/datum/tokenSet/tokenSet
	var/list/varSet
	var/list/elseSet
	var/datum/templateToken/TConditional/lastRes = null


/datum/templateToken/TConditional/New(selector, tContents, list/tokens)
	var/variable = "" //what var does the condition rely on.
	var/var_start = findtext(tContents, " ")
	if (var_start && var_start < length(tContents)) //conditional tokens without a reliant var is valid syntax
		variable = resolveVariable(copytext(tContents, var_start+1), T_VAR_RETURN)

	if (length(variable) >= 1 && variable[1] == "%")
		variable = copytext(variable, 2)
		..()
	else if (selector && isnull(src.selector))
		..()

	src.variable = variable
	var/tStart = 0
	var/k = tokens.len
	for (var/i in 1 to k)
		var/datum/templateToken/TConditional/TElse/E = tokens[i]
		if (!E || E.type != /datum/templateToken/TConditional/TElse)
			//stupid way to avoid duplicating code,
			//the main loop can handle the final wrap up this way
			if (!elseSet && i != k)
				continue
			i++
		if (!elseSet)
			tokenSet = new /datum/tokenSet(tokens.Copy(1, i))
			varSet = tokenSet.listRequestedVars()
			if (i < k)
				elseSet = list()
		else
			var/datum/templateToken/TConditional/TElse/elsetoken = tokens[tStart]
			var/iftoken = copytext(elsetoken.variable, nonspantext(elsetoken.variable, " ")+1)
			if (length(iftoken))
				var/tType = tokenType("{{#[iftoken]}}")
				if (tType <= T_TOKEN_ELSE)
					crash("TParse Error: Unexpected `[iftoken]` after T_ELSE.")
				var/path = tType2type(tType)
				elsetoken = new path (null, elsetoken.variable, list())
				varSet |= elsetoken.getRequestedVars()
				if (elsetoken.selector)
					elsetoken.selector = null
					if (isnull(src.selector))
						..()
			var/datum/tokenSet/TS = new /datum/tokenSet(tokens.Copy(tStart+1, i))
			varSet |= TS.listRequestedVars()
			//world.log << "EIC: [elsetoken] - [tStart] - [length(tokens)]"
			elsetoken.tokenSet = TS
			elseSet += elsetoken

		tStart = i


	if (!tokenSet)
		tokenSet = new /datum/tokenSet(tokens) //TODO: else/elseif
		varSet = tokenSet.listRequestedVars()

	name = vars

/datum/templateToken/TConditional/getRequestedVars()
	//doing it this way ensures our conditional variables are first but never duplicated
	if (variable)
		return ((resolveVariable(variable, T_VAR_IDENTIFY) || list()) | varSet)
	return varSet

/datum/templateToken/TConditional/compute(list/variables, selectorAppend)
	if (variable)
		value = resolveVariable(variable, T_VAR_ACCESS, variables)

	if (!checkCondition(variables))
		lastRes = null
		for(var/thing in elseSet)
			var/datum/templateToken/TConditional/C = thing
			if (!C)
				continue
			if (!C.checkCondition(variables))
				continue
			lastRes = C
			return C.compute(variables, selectorAppend)

		//world.log << "TCC: 0 - [variable] - [type]"
		return
	//world.log << "TCC: 1 - [variable] - [type]"
	lastRes = src
	return tokenSet.compute(variables, selectorAppend)

/datum/templateToken/TConditional/computeDiff(list/variables, selectorAppend)
	var/datum/templateToken/TConditional/newRes
	if (checkCondition(variables))
		newRes = src
	else
		for(var/thing in elseSet)
			var/datum/templateToken/TConditional/C = thing
			if (!C)
				continue
			if (!C.checkCondition(variables))
				continue
			newRes = C

	if (newRes && lastRes == newRes)
		return newRes.tokenSet.computeDiff(variables, selectorAppend)

	lastRes = newRes

	if (!newRes)
		return list("[selector][selectorAppend]" = list(T_UPDATE_REPLACE = ""))

	return list("[selector][selectorAppend]" = list(T_UPDATE_REPLACE = jointext(newRes.tokenSet.compute(variables, selectorAppend), "")))


/datum/templateToken/TConditional/dupe()
	var/datum/templateToken/TConditional/C = new type(selector, "# [variable]", tokenSet.dupe())
	if (elseSet)
		C.elseSet = list()
		for (var/thing in elseSet)
			var/datum/templateToken/TConditional/CC = thing
			var/datum/tokenSet/TS = elseSet[CC]
			C.elseSet[CC] = new /datum/tokenSet(TS.dupe())
	return C


/datum/templateToken/TConditional/proc/checkCondition(list/variables)
	CRASH("TError BUG: Invalid use of TConditional")


/datum/templateToken/TConditional/TElse/New(selector, tContents, tokens)
	selector = null
	variable = tContents
	if (length(tokens))
		tokenSet = new (tokens)

/datum/templateToken/TConditional/TElse/checkCondition()
	return TRUE

/datum/templateToken/TConditional/TElse/dupe()
	return new type(selector, variable, tokenSet?.dupe())


/datum/templateToken/TConditional/TUpdatingBlock
	var/valueSet

/datum/templateToken/TConditional/TUpdatingBlock/New(selector, tContents, list/tokens)
	if (isnull(selector))
		selector = "token-[num2text(nextid++, 99)]"

	..(selector, tContents, tokens)

/datum/templateToken/TConditional/TUpdatingBlock/checkCondition(list/variables)
	return TRUE

/datum/templateToken/TConditional/TUpdatingBlock/compute(list/variables, selectorAppend)
	..()
	valueSet = variables

/datum/templateToken/TConditional/TUpdatingBlock/computeDiff(list/variables, selectorAppend)
	for (var/variable in varSet)
		if (valueSet[variable] ~! variables[variable])
			lastRes = FALSE
			return ..()
