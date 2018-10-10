//TG Template system
//Originally adopted from the SCC release used by SceneXpress, massively modified since

var/list/compile_time_template_variables = list (
	"null" = null,
#ifdef TESTING
	"TESTING" = TRUE,
#endif
	"TRUE" = TRUE,
	"FALSE" = FALSE

)

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
	src.variables = variables | compile_time_template_variables
	if (!name)
		return
	if (!tokenSets[name])
		tokenSets[name] = new /datum/tokenSet(makeTokenSet("[file].tpl", file2text("templates/[name].tpl")))

	var/datum/tokenSet/TS = tokenSets[name]
	if (!TS)
		CRASH("Unable to parse template: [name]")

	tokenSet = new /datum/tokenSet(TS.dupe())


//Generates (and returns) a tokenSet object from the template text passed to it.
//	this function is recursive
/proc/makeTokenSet(file = "MEMORY", tplText)
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

	var/list/searchingFor = list("{") //stack, each item containing a string of characters to search for.

	var/i = 0
	while (i < k)
		i += 1+nonspantext(tplText, searchingFor[searchingFor.len], i+1)

		if (i > k)
			break
		var/char = tplText[i]


		if (char == "{" && tplText[i+1] == "{") //Start of a token
			bracket = TRUE
			tokenStart = i
			i++ //consume the second bracket character
			//searchingFor += "}\\\"" //update the searching stack
			searchingFor += "}" //update the searching stack


		if (bracket) //we are currently looking for the end of a {{}} bracket token
			/*if (char == "\\")
				i++ //consume the next character
				continue
			else if (char == "\"")
				if (searchingFor[searchingFor.len] != "\\\"")
					searchingFor += "\\\"" //we are now only searching for double quotes
				else
					searchingFor.len-- //we found the other double quotes, pop our search off the stack
				continue

			else*/if (char == "}" && tplText[i+1] == "}") //we found the end, lets parse it
				i++  //consume the second bracket character
				searchingFor.len-- //pop our search off the stack
				var/tType = tokenType(copytext(tplText, tokenStart, i+1))

				//We are currently looking for the closing token of a conditional block
				if (conditionalSkips > 0)
					if (tType > T_TOKEN_ELSE)
						conditionalSkips++ //nested conditional block, increase the number of closing tokens we are looking for.
					else if (tType == T_TOKEN_ENDIF)
						conditionalSkips-- //closing token, lower that same number.

					if (conditionalSkips > 0) //Still higher then 0, move on.
						continue

					//if we got here, the count was higher then 0, but now its not, we have our closing token. Time to parse the conditional token as a whole.
					var/conditionalToken = copytext(tplText, cTokenStart, cTokenEnd+1) //grab the original token
					var/cType = tokenType(conditionalToken)

					//make the token and add it, parsing its block as a separate tokenset
					if (stringStart < cTokenStart) //but first we have to consume the stringLit before the token
						tokenGroup += new /datum/templateToken/TStringLiteral(null, copytext(tplText, stringStart, cTokenStart))
					var/path = tType2type(cType)

					tokenGroup += new path (null, copytext(conditionalToken, 3, -2), makeTokenSet(file, copytext(tplText, cTokenEnd+1, tokenStart)))

					//reset state and continue
					bracket = FALSE
					stringStart = i+1
					continue


				//unhandled types are treated as string lit
				else if (!tType)
					bracket = FALSE
					continue

				else if (tType == T_TOKEN_ENDIF)
					throw EXCEPTION("[file]: Unexpected T_TOKEN_ENDIF ([copytext(tplText, tokenStart, i+1)])")

				else if (tType > T_TOKEN_ELSE) //conditional token
					conditionalSkips = 1
					cTokenEnd = i
					cTokenStart = tokenStart
					bracket = FALSE
					continue

				else
					var/tContents = copytext(tplText, tokenStart+2, i-1)
					if (stringStart < tokenStart)
						tokenGroup += new /datum/templateToken/TStringLiteral(null, copytext(tplText, stringStart, tokenStart))
					var/tPath = tType2type(tType)
					tokenGroup += new tPath (null, tContents)
					stringStart = i+1
					bracket = FALSE



	//reached the end, finalize things.

	if (conditionalSkips > 0) //no matching endif block
		throw EXCEPTION("[file]: Expected T_TOKEN_ENDIF ([copytext(tplText, cTokenStart, cTokenEnd+1)] has no closure)")

	if (stringStart < i) //finalize the end of the file into a stringLit
		tokenGroup += new /datum/templateToken/TStringLiteral(null, copytext(tplText, stringStart, k+1))

	return tokenGroup



/proc/tokenType(token)
	var/tType = T_TOKEN_VARIABLE
	switch(token[3])
		if ("#")
			var/bText = copytext(token, 4, -2)

			var/spacestart = findtext(bText, " ")
			if (spacestart)
				bText = copytext(bText, 1, spacestart)
			switch (bText)
				if ("else")
					tType = T_TOKEN_ELSE
				if ("endif")
					tType = T_TOKEN_ENDIF
				if ("if")
					tType = T_TOKEN_IF
				if ("if!")
					tType = T_TOKEN_IFN
				if ("foreach")
					tType = T_TOKEN_FOREACH
				if ("ifempty")
					tType = T_TOKEN_IFEMPTY
				if ("ifempty!")
					tType = T_TOKEN_IFNEMPTY
				if ("switch")
					tType = T_TOKEN_SWITCH
				if ("case")
					tType = T_TOKEN_CASE
				if ("default")
					tType = T_TOKEN_DEFAULT

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
		if (T_TOKEN_ELSE)
			return /datum/templateToken/TConditional/TElse
		if (T_TOKEN_IF)
			return /datum/templateToken/TConditional/TIf
		if (T_TOKEN_IFN)
			return /datum/templateToken/TConditional/TIf/TIfn
		if (T_TOKEN_FOREACH)
			return /datum/templateToken/TConditional/TIfEmpty/TIfnEmpty/TForEach
		if (T_TOKEN_IFEMPTY)
			return /datum/templateToken/TConditional/TIfEmpty
		if (T_TOKEN_IFNEMPTY)
			return /datum/templateToken/TConditional/TIfEmpty/TIfnEmpty
		if (T_TOKEN_SWITCH)
			return /datum/templateToken/TConditional/TSwitch
		if (T_TOKEN_CASE)
			return /datum/templateToken/TConditional/TCase
		if (T_TOKEN_DEFAULT)
			return /datum/templateToken/TConditional/TElse/TDefault
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
	variables[name] = variable


/datum/template/proc/resetvars(list/variables)
	src.variables = (variables || list()) | compile_time_template_variables
