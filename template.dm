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
//	this function is recursive
//The broad overview is that the proc loops through the provided text character by character and
//	puts the character into one of 3 buckets based on state. Creating token objects when it can
/datum/template/proc/makeTokenSet(tplText)
	var/list/tokenGroup = list()

	//buckets
	var/list/stringLit = list() //stores the current text block to be added to a TStringLiteral object once we hit a bracket token.
	var/list/bracketTemp = list() //store the incomplete token while we parse it. When looking for a matching {#ENDIF}, this stores the entire text between the condition blocks.
	var/list/conditionalToken = list() //stores the conditional token in full for later parsing

	//state
	var/bracket = FALSE
	var/conditionalSkips = 0

	var/k = length(tplText)
	for (var/i in 1 to k)
		var/char = tplText[i]
		if (char == "{") //Start of a token

			if (bracket) //the innermost open bracket is what we want (eg {{VAR}} should print {1} if VAR was equal to 1)
				stringLit += bracketTemp;
				bracketTemp = list()

			bracket = TRUE

		if (bracket) //we are currently reading a {} bracket token, lets see if we found the end
			bracketTemp += char //add the current char to the bracket's bucket
			if (char == "}") //we found the end, lets parse it
				var/tType = tokenType(bracketTemp)

				//We are currently looking for the closing token of a conditional block
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

					var/cType = tokenType(conditionalToken) //get the stored starting conditional token's type
					var/cvar = "" //what var does the condition rely on.
					var/cvar_start = conditionalToken.Find(":")
					if (cvar_start) //conditional tokens without a reliant var is valid syntax (it lets one do comments)
						cvar = jointext(conditionalToken.Copy(cvar_start+1, conditionalToken.len), "")

					//make the token and add it, parsing its block as a separate tokenset
					var/path = ttype2type(cType)
					tokenGroup += new path (cvar, makeTokenSet(stringLit))

					//reset state and continue
					bracket = FALSE
					bracketTemp = list()
					stringLit = list()
					conditionalToken = list()
					conditionalSkips = 0

				//do token stuff:

				//unhandled types, treat as string lit, reset state, and continue;
				else if (!tType)
					stringLit += bracketTemp
					bracketTemp = list()
					bracket = TRUE


				else if (tType >= T_TOKEN_ENDIF)
					conditionalToken = bracketTemp
					conditionalSkips = 1

					if (length(stringLit))
						tokenGroup += new /datum/templateToken/TStringLiteral(stringLit.Join(""))
					bracketTemp = list()
					stringLit = list()
					bracket = FALSE

				else
					var/list/tVar = bracketTemp.Copy(2, bracketTemp.len)
					if (length(stringLit))
						tokenGroup += new /datum/templateToken/TStringLiteral(stringLit.Join(""))
					var/tPath = ttype2type(tType)
					tokenGroup += new tPath (tVar.Join(""))
					bracketTemp = list()
					stringLit = list()
					bracket = FALSE

			else if (text2ascii(char) <= 32)  //white space, {} vars don't have whitespace, reset and move on
				stringLit += bracketTemp
				bracketTemp = list()
				bracket = FALSE

		else
			stringLit += char



	//reached the end, finalize things.
	stringLit += bracketTemp

	if (conditionalSkips > 0) //no matching endif block, wrap the rest of the file up into the conditional token
		#ifdef TESTING
		world.log << "WARNING token [name] conditional block reached end of file without closure. This is supported but not always intended"
		#endif
		var/cType = tokenType(conditionalToken);//stored starting conditional token
		var/cvar = "" //what var does the condition rely on.
		var/cvar_start = conditionalToken.Find(":")
		if (cvar_start) //conditional tokens without a reliant var is valid syntax
			cvar = jointext(conditionalToken.Copy(cvar_start+1, conditionalToken.len), "")

		//make the token and add it, parsing its block as a separate tokenset
		var/path = ttype2type(cType)
		tokenGroup += new path (cvar, makeTokenSet(stringLit))
		stringLit = list()


	if (length(stringLit)) //finalize the end of the file into a stringLit
		tokenGroup += new /datum/templateToken/TStringLiteral(stringLit.Join(""))

	return new /datum/tokenSet(tokenGroup)

/datum/template/proc/tokenType(list/token)
	var/tType = T_TOKEN_VARIABLE;
	switch(token[2])
		if ("#")
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
		if ("!")
			tType = T_TOKEN_ESCAPED_VARIABLE


	return tType

/datum/template/proc/ttype2type(tType)
	switch(tType)
		if (T_TOKEN_STRINGLIT)
			return /datum/templateToken/TStringLiteral
		if (T_TOKEN_VARIABLE)
			return /datum/templateToken/TVariable
		if (T_TOKEN_ESCAPED_VARIABLE)
			return /datum/templateToken/TVariable/escaped
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
		else
			CRASH("Invalid tType")

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
