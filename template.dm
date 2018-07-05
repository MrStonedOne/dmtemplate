//TG Template system
//Originally adopted from the SCC release used by SceneXpress, massively modified since

/datum/template
	var/static/list/tokenSets = list()
	var/datum/tokenSet/tokenSet
	var/list/variables
	var/file



//name should be the name of a .tpl template file in template folder
//name should be given without the .tpl extension
//vars should be an associative array in the form of varname => vardata
/datum/template/New(name, list/variables = list())
	if (name && !fexists("templates/[name].tpl"))
		CRASH("No such file for template [name]")


	if (!islist(variables))
		CRASH("2nd argument (variables) is not a list")
		return

	file = name
	src.variables = variables || list()
	if (!name)
		return
	if (!tokenSets[name])
		tokenSets[name] = makeTokenSet(file2text("templates/[name].tpl"))
	var/datum/tokenSet/TS = tokenSets[name]
	tokenSet = TS.dupe()
	#ifdef TESTING
	setvar("TESTING", "TRUE")
	#endif


//Generates (and returns) a tokenSet object from the template text passed to it.
//	this function is recursive
//The broad overview is that the proc loops through the provided text character by character and
//	puts the character into one of 3 buckets based on state. Creating token objects when it can.
//tplText can be a list of characters or a string.
/proc/makeTokenSet(tplText)
	var/list/tokenGroup = list()

	//position tracking
	var/stringStart = 1 //Position of the start of a string lit object
	var/tokenStart = 0 //Position of the start of the current token block
	var/cTokenStart = 0 //Position of the start of the conditional token currently being blocked
	var/cTokenEnd = 0 //Position of the end of the conditional token currently being blocked

	//state
	var/bracket = FALSE //tracks if we are in the middle of parsing a bracket object
	var/conditionalSkips = 0 //tracks nesting of conditional tokens

	var/k = length(tplText)

	var/list/searchingFor = list("{")

	var/i = 0
	while (i < k)
		if (searchingFor.len)
			i += 1+nonspantext(tplText, searchingFor[searchingFor.len], i+1)

		if (i > k)
			break
		var/char = tplText[i]
		if (char == "{" && tplText[i+1] == "{") //Start of a token
			bracket = TRUE
			tokenStart = i
			i++
			searchingFor += "}\\\""


		if (bracket) //we are currently reading a {} bracket token, lets see if we found the end
			if (char == "\\")
				i++
				continue
			else if (char == "\"")
				if (searchingFor[searchingFor.len] != "\"")
					searchingFor += "\""
				else
					searchingFor.len--
				continue
			else if (char == "}" && tplText[i+1] == "}") //we found the end, lets parse it
				i++
				searchingFor.len--
				var/tType = tokenType(copytext(tplText, tokenStart, i+1))

				//We are currently looking for the closing token of a conditional block
				if (conditionalSkips > 0)
					if (tType > T_TOKEN_ENDIF)
						conditionalSkips++ //nested conditional block, increase the number of closing tokens we are looking for.
					else if (tType == T_TOKEN_ENDIF)
						conditionalSkips-- //closing token, lower that same number.

					if (conditionalSkips > 0) //Still higher then 0, move on.
						continue

					//if we got here, the count was higher then 0, but now its not, we have our closing token. Time to parse the conditional token as a whole.
					var/conditionalToken = copytext(tplText, cTokenStart, cTokenEnd+1)
					var/cType = tokenType(conditionalToken) //get the stored starting conditional token's type
					var/cvar = "" //what var does the condition rely on.
					var/cvar_start = findtext(conditionalToken, ":")
					if (cvar_start) //conditional tokens without a reliant var is valid syntax
						cvar = copytext(conditionalToken, cvar_start+1, -2)

					//make the token and add it, parsing its block as a separate tokenset
					if (stringStart < cTokenStart)
						tokenGroup += new /datum/templateToken/TStringLiteral(null, copytext(tplText, stringStart, cTokenStart))
					var/path = tType2type(cType)
					tokenGroup += new path (null, cvar, makeTokenSet(copytext(tplText, cTokenEnd+1, tokenStart)))

					//reset state and continue
					bracket = FALSE
					stringStart = i+1
					continue


				//do token stuff:

				//unhandled types, treat as string lit, reset state, and continue;
				else if (!tType)
					bracket = FALSE
					continue


				else if (tType > T_TOKEN_ENDIF)
					conditionalSkips = 1
					cTokenEnd = i
					cTokenStart = tokenStart
					bracket = FALSE
					continue

				else
					var/tVar = copytext(tplText, tokenStart+2, i-1)
					if (stringStart < tokenStart)
						tokenGroup += new /datum/templateToken/TStringLiteral(null, copytext(tplText, stringStart, tokenStart))
					var/tPath = tType2type(tType)
					tokenGroup += new tPath (null, tVar)
					stringStart = i+1
					bracket = FALSE

		else if (!stringStart)
			stringStart = i



	//reached the end, finalize things.

	if (conditionalSkips > 0) //no matching endif block
		throw EXCEPTION("Expected T_TOKEN_ENDIF ([copytext(tplText, cTokenStart, cTokenEnd+2)] has no closure)")

	if (stringStart < i) //finalize the end of the file into a stringLit
		tokenGroup += new /datum/templateToken/TStringLiteral(null, copytext(tplText, stringStart, k+1))

	return new /datum/tokenSet(tokenGroup)



/proc/tokenType(token)
	var/tType = T_TOKEN_VARIABLE
	switch(token[3])
		if ("#")
			var/bText = copytext(token, 4, -2)

			var/colonstart = findtext(bText, ":")
			if (colonstart)
				bText = copytext(bText, 1, colonstart)
			world.log << "[token]|||[bText]"
			switch (bText)
				if ("ENDIF")
					tType = T_TOKEN_ENDIF

				if ("IFDEF")
					tType = T_TOKEN_IFDEF

				if ("IFNDEF")
					tType = T_TOKEN_IFNDEF

				if ("ARRAY")
					tType = T_TOKEN_ARRAY

				if ("IFEMPTY")
					tType = T_TOKEN_IFEMPTY

				if ("IFNEMPTY")
					tType = T_TOKEN_IFNEMPTY

		if ("!")
			tType = T_TOKEN_ESCAPED_VARIABLE

		if ("%")
			if (length(token) == 5)
				tType = T_TOKEN_UPDATING_BLOCK
		if ("/")
			tType = T_TOKEN_ENDIF

	return tType

/proc/tType2type(tType)
	switch(tType)
		if (T_TOKEN_STRINGLIT)
			return /datum/templateToken/TStringLiteral
		if (T_TOKEN_VARIABLE)
			return /datum/templateToken/TVariable
		if (T_TOKEN_ESCAPED_VARIABLE)
			return /datum/templateToken/TStringLiteral/TEscapedVariable
		if (T_TOKEN_ENDIF)
			return null
		if (T_TOKEN_IFDEF)
			return /datum/templateToken/TConditional/TIfDef
		if (T_TOKEN_IFNDEF)
			return /datum/templateToken/TConditional/TIfnDef
		if (T_TOKEN_ARRAY)
			return /datum/templateToken/TConditional/TIfnEmpty/TArray
		if (T_TOKEN_IFEMPTY)
			return /datum/templateToken/TConditional/TIfEmpty
		if (T_TOKEN_IFNEMPTY)
			return /datum/templateToken/TConditional/TIfnEmpty
		if (T_TOKEN_UPDATING_BLOCK)
			return /datum/templateToken/TConditional/TUpdatingBlock
		else
			CRASH("Invalid tType")

/datum/template/proc/compute()
	return jointext(tokenSet.compute(variables), "")

/datum/template/proc/computeDiff(newVars)
	variables = newVars|variables
	return tokenSet.computeDiff(variables)


/datum/template/proc/setvar(name, variable)
	world.log << "\ref[variables]|||isnull(variables)|||islist(variables)"
	variables[name] = variable


/datum/template/proc/resetvars(list/variables)
	src.variables = variables || list()
