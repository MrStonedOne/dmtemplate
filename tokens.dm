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

//parses a variable argument.
/datum/templateToken/proc/resolveVariable(variable, operation, list/variables)
	if (isnull(variable))
		return null
	var/trimspace = spantext(variable, " ")
	if (trimspace)
		variable = copytext(variable, trimspace+1)

	. = variable //so on errors we resolve to a string with the invalid input
	if (variable == "")
		return null
	var/bracketpos

	var/l = length(variable)
	var/variable_end = l //last parsed character

	if (variable[1] == "\"")
		var/quoteend = findtext(variable, "\"", 2)
		if (!quoteend)
			crash("TParse Error: Unclosed String: [variable]")
		switch (operation)
			if (T_VAR_IDENTIFY)
				return null
			if (T_VAR_RETURN)
				return copytext(variable, 1, quoteend+1)
			if (T_VAR_ACCESS)
				return copytext(variable, 2, -1)

	else if (!isnull(text2num(variable)))
		switch (operation)
			if (T_VAR_IDENTIFY)
				return null
			if (T_VAR_RETURN)
				return copytext(variable, 1, nonspantext(variable, " ")+1)
			if (T_VAR_ACCESS)
				return text2num(variable)

	var/pos = 1+nonspantext(variable, "\[\] ")
	if (pos < l)
		switch (variable[pos])
			if ("\]")
				if (operation == T_VAR_RETURN)
					return copytext(variable, 1, pos+1)
				crash("TParse Error: Unexpected `]`")
			if (" ")
				variable_end = pos-1
			if ("\[")
				bracketpos = pos
	else
		pos = 0


	var/core = copytext(variable, 1, pos)

	var/list/context //multipurpose list holder

	switch (operation)
		if (T_VAR_IDENTIFY)
			context = list(core)
		if (T_VAR_ACCESS)
			context = variables

	while (context && bracketpos && bracketpos < l)
		if (variable[bracketpos] != "\[")
			break

		var/word = resolveVariable(copytext(variable, bracketpos+1), T_VAR_RETURN)

		var/end = bracketpos+length(word)+1
		if (variable[end] != "\]")
			. = variable
			crash("TParse Error: Invalid Key: [variable] at [end]")

		switch (operation)
			if (T_VAR_IDENTIFY)
				context |= (resolveVariable(word, T_VAR_IDENTIFY) || list())
			if (T_VAR_ACCESS)
				//var/context_accessor = resolveVariable(word, T_VAR_ACCESS, variables)
				//world.log << "CA\[]: `[core]`"
				context = context[core]
				//world.log << "WO\[]: `[word]`"
				core = resolveVariable(word, T_VAR_ACCESS, variables)

		variable_end = end
		bracketpos = end+1
	switch (operation)
		if (T_VAR_IDENTIFY)
			return context
		if (T_VAR_RETURN)
			//world.log << "rVr: `[copytext(variable, 1, variable_end+1)]`"
			return copytext(variable, 1, variable_end+1)
		if (T_VAR_ACCESS)
			//world.log << "CO: `[core]` - `[json_encode(context)]` - [istext(context)]"
			if (!islist(context))
				return null
			return context[core]



	crash("TError BUG: resolveVariable invoked with an invalid operation")


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
	var/sanitize
	var/value = ""

/datum/templateToken/TVariable/New(selector, tContents)
	////world.log << "TVV: selector:[selector], tContents:[tContents]"
	if (length(tContents) >= 1 && tContents[1] == "%")
		tContents = copytext(tContents, 2)
		..()
	else if (selector)
		..()
	////world.log << "...TVV: tContents:[tContents]"
	if (length(tContents) >= 1)
		switch (tContents[1])
			if ("$")
				sanitize = T_SAN_HTML
			if ("&")
				sanitize = T_SAN_URL
			if ("*")
				sanitize = T_SAN_UNSAFE
	if (sanitize)
		tContents = copytext(tContents, 2)
	////world.log << "......TVV: tContents:[tContents]"
	variable = tContents


/datum/templateToken/TVariable/getRequestedVars()
	return resolveVariable(variable, T_VAR_IDENTIFY) || list()


/datum/templateToken/TVariable/compute(list/variables, selectorAppend)
	switch (sanitize)
		if (T_SAN_HTML)
			value = html_encode(resolveVariable(variable, T_VAR_ACCESS, variables))
		if (T_SAN_URL)
			value = url_encode(resolveVariable(variable, T_VAR_ACCESS, variables))
		if (T_SAN_UNSAFE)
			value = resolveVariable(variable, T_VAR_ACCESS, variables)
		else
			value = html_encode(resolveVariable(variable, T_VAR_ACCESS, variables)) //todo: add default toggling.
	//world.log << "TV: `[sanitize]` `[variable]` - `[value]` -- `[json_encode(variables)]`"
	return value

/datum/templateToken/TVariable/computeDiff(list/variables, selectorAppend)
	if (value == compute(variables, selectorAppend))
		return


	return list("[selector][selectorAppend]" = list(T_UPDATE_REPLACE = value))


/datum/templateToken/TVariable/dupe()
	var/datum/templateToken/TVariable/V = new type (selector, variable)
	V.sanitize = sanitize
	return V

/*
 * Conditionals
 */

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

/datum/templateToken/TConditional/TIf
	var/right
	var/operator
	var/left

/datum/templateToken/TConditional/TIf/New(selector, tContents, list/tokens)
	var/ogtContents = tContents
	var/var_start = findtext(tContents, " ")
	if (var_start) //conditional tokens without a reliant var is valid syntax
		tContents = copytext(tContents, var_start+1) //chop off the #if
		//world.log << "iff tc:`[tContents]`"
		right = resolveVariable(tContents, T_VAR_RETURN) //pull the first word.
		var/arglen
		if ((arglen = length(right)) < length(tContents))
			//chop off the first word (and whitespace)
			tContents = copytext(tContents, arglen+1+spantext(tContents, " ", arglen+1))
			//consume the second
			operator = copytext(tContents, 1, findtext(tContents, " "))

			if ((arglen = length(operator)) < length(tContents)) //repeat
				tContents = copytext(tContents, arglen+1+spantext(tContents, " ", arglen+1))
				if (length(tContents))
					//snowflaked until \ is supported
					if (tContents[1] == "\"" && tContents[length(tContents)] == "\"")
						left = tContents
					else
						left = resolveVariable(tContents, T_VAR_RETURN)


	if (length(right) && right[1] == "%")
		right = copytext(right, 2)
		if (isnull(selector))
			selector = "token-[num2text(nextid++, 99)]"

	if (length(left) && left[1] == "%")
		left = copytext(left, 2)
		if (isnull(selector))
			selector = "token-[num2text(nextid++, 99)]"
	//world.log << html_encode("TC: variable = [variable]; ogtContents = [ogtContents], [right] - [operator] - [left]")
	..(selector, ogtContents, tokens)

/datum/templateToken/TConditional/TIf/dupe()
	var/datum/templateToken/TConditional/TIf/I = ..()
	I.right = right
	I.operator = operator
	I.left = left
	return I

/datum/templateToken/TConditional/TIf/getRequestedVars()
	. = list()
	if (right)
		. |= resolveVariable(right, T_VAR_IDENTIFY) || list()
	if (left)
		. |= resolveVariable(left, T_VAR_IDENTIFY) || list()
	. |= varSet

/datum/templateToken/TConditional/TIf/checkCondition(list/variables)
	if (!length(right))
		value = null
		return FALSE

	if (!length(operator))
		value = resolveVariable(right, T_VAR_ACCESS, variables)
		return !!value

	if (!length(left))
		crash("TParse Error: Invalid If! (no left hand argument)")

	var/rvalue = resolveVariable(right, T_VAR_ACCESS, variables)

	var/lvalue
	//snowflake to support strings containing doublequotes in the last argument by only listening to the last doublequote.
	if (length(left) && left[1] == "\"" && left[length(left)] == "\"")
		lvalue = copytext(left, 2, length(left))
	else
		lvalue = resolveVariable(left, T_VAR_ACCESS, variables)

	switch (operator) //look ma! its a byond vm.
		if ("==")
			value = (rvalue == lvalue)
		if ("!=")
			value = (rvalue != lvalue)
		if (">")
			value = (rvalue > lvalue)
		if ("<")
			value = (rvalue < lvalue)
		if (">=")
			value = (rvalue >= lvalue)
		if ("<=")
			value = (rvalue <= lvalue)
		if ("|")
			value = (rvalue | lvalue)
		if ("&")
			value = (rvalue & lvalue)
		if ("%")
			value = (rvalue % lvalue)
		if ("^")
			value = (rvalue ^ lvalue)
		if ("~=")
			value = (rvalue ~= lvalue)
		if ("~!")
			value = (rvalue ~! lvalue)

		if ("in")
			value = (rvalue in lvalue)
		if ("contains")
			value = (lvalue in rvalue) //this is correct
		else
			crash("TParse Error: Unknown operator `[operator]`")

	//world.log << "ICC: [right]=[rvalue] - [operator] - [left]=[lvalue] - [value]"
	return value


/datum/templateToken/TConditional/TIf/TIfn/checkCondition(list/variables)
	return !..()


/datum/templateToken/TConditional/TIfEmpty/TIfnEmpty/checkCondition(list/variables)
	return !..()


/datum/templateToken/TConditional/TIfEmpty/checkCondition(list/variables)
	if (!variable || !value)
		return TRUE
	if (!islist(value) || length(value) <= 0)
		return TRUE
	return FALSE

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

/datum/templateToken/TConditional/TElse/New(selector, tContents, tokens)
	selector = null
	variable = tContents
	if (length(tokens))
		tokenSet = new (tokens)

/datum/templateToken/TConditional/TElse/checkCondition()
	return TRUE

/datum/templateToken/TConditional/TElse/dupe()
	return new type(selector, variable, tokenSet?.dupe())

/datum/templateToken/TConditional/TSwitch
	var/list/caseTable
	var/datum/templateToken/TConditional/TElse/default

/datum/templateToken/TConditional/TSwitch/New(selector, tContents, tokens)
	..(selector, tContents, list())
	caseTable = list()
	for(var/thing in tokens)
		var/datum/templateToken/TConditional/TCase/C = thing
		switch (C.type)
			if (/datum/templateToken/TStringLiteral)
				continue
			if (/datum/templateToken/TConditional/TElse, /datum/templateToken/TConditional/TElse/TDefault)
				if (default)
					crash("TParse Error: Mutilple defaults in switch statement for `[variable]`")
				default = C
			if (/datum/templateToken/TConditional/TCase)
				if (caseTable["[C.case]"])
					crash("TParse Error: Duplicate Case Statement for `[C.variable]`(`[C.case]`) in switch statement for `[variable]`")
				caseTable["[C.case]"] = C
				varSet |= C.getRequestedVars()
			else
				crash("TParse Error: Unexpected `[C.type]` in switch statement for `[variable]`")

/datum/templateToken/TConditional/TSwitch/compute(list/variables, selectorAppend)
	value = resolveVariable(variable, T_VAR_ACCESS, variables)
	if (isnum(value))
		value = "{{CASE_NUMBER \"[num2text(value, 99)]\"}}"
	if ((lastRes = caseTable[value]))
		return lastRes.tokenSet.compute(variables, selectorAppend)
	if ((lastRes = default))

		return default.tokenSet.compute(variables, selectorAppend)

/datum/templateToken/TConditional/TSwitch/computeDiff(list/variables, selectorAppend)
	value = resolveVariable(variable, T_VAR_ACCESS, variables)
	var/datum/templateToken/TConditional/newRes
	if (caseTable[value])
		newRes = src
	else if (default)
		newRes = default

	if (newRes && lastRes == newRes)
		return newRes.tokenSet.computeDiff(variables, selectorAppend)

	lastRes = newRes

	if (!newRes)
		return list("[selector][selectorAppend]" = list(T_UPDATE_REPLACE = ""))

	return list("[selector][selectorAppend]" = list(T_UPDATE_REPLACE = jointext(newRes.tokenSet.compute(variables, selectorAppend), "")))




/datum/templateToken/TConditional/TCase
	var/case

/datum/templateToken/TConditional/TCase/New(selector, tContents, tokens)
	var/var_start = findtext(tContents, " ")
	if (!var_start)
		crash("TParse Error: Empty Case Statement")
	..()
	case = resolveVariable(variable, T_VAR_ACCESS, compile_time_template_variables)
	if (isnull(case))
		crash("TParse Error: Invalid Case Statement: `[variable]` (only compile-time values may be used in case statements)")
	if (isnum(case))
		case = "{{CASE_NUMBER \"[num2text(case, 99)]\"}}" //no way this will ever collide.

	//tokenSet = new(tokens)


/datum/templateToken/TConditional/TCase/getRequestedVars()
	return varSet || list()

/datum/templateToken/TConditional/TElse/TDefault

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
			if (!token)
				token = tokens[i]
				crash("failed dupe by `[token.type]` - `[token]`")

		newtokens[i] = token

	return newtokens