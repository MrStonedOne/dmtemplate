
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
	if (length(resolveVariable(variable, T_VAR_IDENTIFY) - compile_time_template_variables))
		crash("TParse Error: Invalid Case Statement: `[variable]` (only compile-time values may be used in case statements)")
	case = resolveVariable(variable, T_VAR_ACCESS, compile_time_template_variables)

	if (isnum(case))
		case = "{{CASE_NUMBER \"[num2text(case, 99)]\"}}" //no way this will ever collide.

	//tokenSet = new(tokens)


/datum/templateToken/TConditional/TCase/getRequestedVars()
	return varSet || list()

/datum/templateToken/TConditional/TElse/TDefault