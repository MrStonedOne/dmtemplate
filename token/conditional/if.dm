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

	var/lvalue = resolveVariable(left, T_VAR_ACCESS, variables)

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

