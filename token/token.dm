/*
 * Interface
 */

/datum/templateToken
	var/static/nextid = 1
	var/name
	var/selector
	var/listenflags

/datum/templateToken/New(selector)
	//if (!(listenflags & T_LISTEN_DIFF) && length(selector))
	grantSelector(selector)

//Makes the token updating.
/datum/templateToken/proc/grantSelector(selector)
	if (isnull(selector))
		selector = "token-[num2text(nextid++, 99)]"
	src.selector = selector
	listenflags |= T_LISTEN_DIFF

//returns a list of template variables this token depends on.
/datum/templateToken/proc/getRequestedVars()

//returns a list with the computed text(s)
/datum/templateToken/proc/compute(list/variables, selectorAppend)

//returns a assoicated list with css selectors to update and their new value.
/datum/templateToken/proc/computeDiff(list/variables, selectorAppend)

//called when a token stops being visable.
/datum/templateToken/proc/onHide(list/variables, selectorAppend)

//returns a templateToken object that is a duplicate of this one.
//	(used to give each view its own tokenset so they can handle remembering state for updates)
/datum/templateToken/proc/dupe()
	return new type(selector)



//parses a variable argument.
/datum/templateToken/proc/resolveVariable(variable, operation, list/variables)
	if (isnull(variable))
		return null
	var/trimspace = spantext(variable, " ")
	if (trimspace)
		variable = copytext(variable, trimspace+1)

	. = "!#!#ERR:`[variable]`" //so on errors we resolve to a string with the invalid input
	if (variable == "")
		return null
	var/bracketpos

	var/l = length(variable)
	var/variable_end = l //last parsed character

	if (variable[1] == "\"")
		var/quoteend

		var/i = nonspantext(variable, "\"\\\[", 2)+2
		var/list/string = list(copytext(variable, 2, i))
		var/list/varlist = list()

		while (i <= l)
			switch (variable[i])
				if ("\"")
					quoteend = i
					break

				if ("\\")
					i++
					switch (variable[i])
						if ("n")
							string += "\n"
						else
							string += variable[i]

				if ("\[")
					var/word = resolveVariable(copytext(variable, i+1), T_VAR_RETURN)
					var/wordl = length(word)
					if (!wordl || word[wordl] != "]")
						crash("TParse Error: expected `]`, got `[word[wordl]]` in string [variable]")
					word = copytext(word, 1, length(word))
					switch (operation)
						if (T_VAR_IDENTIFY)
							varlist += resolveVariable(word, T_VAR_IDENTIFY)
						if (T_VAR_ACCESS)
							string += resolveVariable(word, T_VAR_ACCESS, variables)
					i += wordl
					//world.log << "RVwl: [variable[i]]"

				else
					string += variable[i]

			var/skip = nonspantext(variable, "\"\\\[", i)
			if (skip)
				//world.log << "RVsk: `[skip]` - `[i]` - `[l]`"
				string += copytext(variable, i+1, i+skip)
				i += skip
			else
				i++




		if (!quoteend)
			crash("TParse Error: Unclosed String: [variable]")
		switch (operation)
			if (T_VAR_IDENTIFY)
				return varlist
			if (T_VAR_RETURN)
				return copytext(variable, 1, quoteend+1)
			if (T_VAR_ACCESS)
				return jointext(string, "")

	else if (!isnull(text2num(variable)))
		switch (operation)
			if (T_VAR_IDENTIFY)
				return list()
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
