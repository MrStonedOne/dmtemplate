//TG Template system
//Originally adopted from the SCC release used by SceneXpress, massively modified since

/datum/template
	var/static/list/tokenSets = list()
	var/list/variables
	var/file



//name should be the name of a .tpl template file in template folder
//name should be given without the .tpl extension
//vars should be an associative array in the form of varname => vardata
/datum/template/New(name, list/variables = list())
	if (!fexists("templates/[name].tpl"))
		CRASH("No such file for template [name]")


	if (!islist(variables))
		CRASH("2nd argument (variables) is not a list")
		return

	file = name
	src.variables = variables

	if (tokenSets[name])
		return

	tokenSets[name] = makeTokenSet(file2text("templates/[name].tpl"))



//Generates (and returns) a tokenSet object from the template text passed to it.
//this function is recursive
/datum/template/proc/makeTokenSet(tplText)
	var/list/tokenGroup = list()
	var/list/stringLit = list() //stores the current text block to be added to a TStringLiteral object once we hit a bracket token.
	var/list/bracketTemp = list() //store the incomplete token while we parse it
	var/bracket = FALSE
	var/list/conditionalToken = list() //stores the conditional token in full for later parsing
	var/conditionalSkips = 0

	var/k = length(tplText)

	for (var/i in 1 to k)
		var/char = tplText[i]
		if (char == "{")
			if (bracket) //the innermost open bracket is what counts, no nesting
				stringLit += bracketTemp;
				bracketTemp = list()

			bracket = TRUE;

		if (bracket)
			bracketTemp += char
			if (char == "}")
				var/tType = tokenType(bracketTemp)

				//marks that we are currently looking for the closing token of a conditional block
				if (conditionalSkips > 0)
					if (tType > T_TOKEN_ENDIF)
						conditionalSkips++ //nested conditional block, increase the number of closing tokens we are looking for.
					else if (tType == T_TOKEN_ENDIF)
						conditionalSkips-- //closing token, lower that same number.

					if (conditionalSkips > 0) //Still higher then 0, dump the bracket into the string bucket and move on.
						stringLit += bracketTemp
						bracket = FALSE
						bracketTemp = list()
						continue

					//if we got here, the count was higher then 0, but now its not, we have our closing token. Time to parse the conditional token as a whole.

					var/cType = tokenType(conditionalToken) //stored starting conditional token
					var/cvar = "" //what var does the condition rely on.
					var/cvar_start = conditionalToken.Find(":")
					if (cvar_start) //conditional tokens without a reliant var is valid syntax
						cvar = jointext(conditionalToken.Copy(cvar_start+1, conditionalToken.len), "")

					//make the token and add it, parsing its block as a separate tokenset
					if (cType == T_TOKEN_IFDEF)
						tokenGroup += new /datum/templateToken/TConditional/TIfDef(cvar, makeTokenSet(stringLit))
					else if (cType == T_TOKEN_IFNDEF)
						tokenGroup += new /datum/templateToken/TConditional/TIfnDef(cvar, makeTokenSet(stringLit))
					else if (cType == T_TOKEN_ARRAY)
						tokenGroup += new /datum/templateToken/TConditional/TIfnEmpty/TArray(cvar, makeTokenSet(stringLit))
					else if (cType == T_TOKEN_IFEMPTY)
						tokenGroup += new /datum/templateToken/TConditional/TIfEmpty(cvar, makeTokenSet(stringLit))
					else if (cType == T_TOKEN_IFNEMPTY)
						tokenGroup += new /datum/templateToken/TConditional/TIfnEmpty(cvar, makeTokenSet(stringLit))

					//reset state and continue
					bracket = FALSE
					bracketTemp = list()
					stringLit = list()
					conditionalToken = list()
					conditionalSkips = 0
					continue

				//do token stuff:

				//normal variable token.
				if (tType == T_TOKEN_VARIABLE)
					var/list/tVar = bracketTemp.Copy(2, bracketTemp.len)
					if (tVar.len && tVar[1] == "!")  //escaped token, treat as string lit, reset state, then continue
						stringLit += "{"
						stringLit += tVar.Copy(2)
						stringLit += "}"
						bracketTemp = list()
						bracket = FALSE
						continue

					if (length(stringLit))
						tokenGroup += new /datum/templateToken/TStringLiteral(stringLit.Join(""))
					tokenGroup += new /datum/templateToken/TVariable(tVar.Join(""))
					bracketTemp = list()
					stringLit = list()
					bracket = FALSE
					continue


				//unhandled types, treat as string lit, reset state, and continue;
				if (tType <= T_TOKEN_STRINGLIT || tType > T_TOKEN_IFNEMPTY)
					stringLit += bracketTemp
					bracketTemp = list()
					bracket = TRUE
					continue


				//if we got to here, its a conditional token, configure state to capture the rest of the token.

				conditionalToken = bracketTemp
				conditionalSkips = 1

				if (length(stringLit))
					tokenGroup += new /datum/templateToken/TStringLiteral(stringLit.Join(""))
				bracketTemp = list()
				stringLit = list()
				bracket = FALSE
				continue

			if (text2ascii(char) <= 32)  //white space, {} vars don't have whitespace, reset and move on
				stringLit += bracketTemp
				bracketTemp = list()
				bracket = FALSE
				continue

		else
			stringLit += char



	//reached the end, finalize things.
	stringLit += bracketTemp

	if (conditionalSkips > 0) //no matching endif block, wrap the rest of the file up into the conditional token
		var/cType = tokenType(conditionalToken);//stored starting conditional token
		var/cvar = "" //what var does the condition rely on.
		var/cvar_start = conditionalToken.Find(":")
		if (cvar_start) //conditional tokens without a reliant var is valid syntax
			cvar = jointext(conditionalToken.Copy(cvar_start+1, conditionalToken.len), "")

		//make the token and add it, parsing its block as a separate tokenset
		if (cType == T_TOKEN_IFDEF)
			tokenGroup += new /datum/templateToken/TConditional/TIfDef(cvar, makeTokenSet(stringLit))
		else if (cType == T_TOKEN_IFNDEF)
			tokenGroup += new /datum/templateToken/TConditional/TIfnDef(cvar, makeTokenSet(stringLit))
		else if (cType == T_TOKEN_ARRAY)
			tokenGroup += new /datum/templateToken/TConditional/TIfnEmpty/TArray(cvar, makeTokenSet(stringLit))
		else if (cType == T_TOKEN_IFEMPTY)
			tokenGroup += new /datum/templateToken/TConditional/TIfEmpty(cvar, makeTokenSet(stringLit))
		else if (cType == T_TOKEN_IFNEMPTY)
			tokenGroup += new /datum/templateToken/TConditional/TIfnEmpty(cvar, makeTokenSet(stringLit))
		stringLit = list()


	if (length(stringLit))
		tokenGroup += new /datum/templateToken/TStringLiteral(stringLit.Join(""))

	return new /datum/tokenSet(tokenGroup)

/datum/template/proc/tokenType(list/token)
	var/tType = T_TOKEN_VARIABLE;
	if (token[2] == "#")
		var/list/bText = token.Copy(3, token.len)
		var/colonstart = bText.Find(":")
		if (colonstart)
			bText.Cut(colonstart)

		switch (bText.Join())
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


	return tType



/datum/template/proc/compute()
	#ifdef TESTING
		setvar("TESTING", "TRUE")
	#endif
	var/variables = src.variables
	resetvars()

	for (var/name in variables)
		var/data = variables[name]
		if (istype(data, /datum/template))
			var/datum/template/T = data
			variables[name] = T.compute()


	var/datum/tokenSet/tokenSet = tokenSets[file]

	return jointext(tokenSet.compute(variables), "")




/datum/template/proc/setvar(name, variable)
	variables[name] = variable


/datum/template/proc/resetvars(list/variables)
	src.variables = variables || list()
