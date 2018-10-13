/datum/templateToken/TStringLiteral
	var/stringLiteral

/datum/templateToken/TStringLiteral/New(selector, stringLiteral)
	src.stringLiteral = stringLiteral
	name = vars

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
