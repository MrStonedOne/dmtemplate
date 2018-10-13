/world
	fps = 100
	icon_size = 32
	view = 7
	loop_checks = FALSE

/proc/crash(message)
	CRASH(message)

/client
	var/datum/template/idetemplate = new("ide", list("rendered" = ""))
	var/datum/template/ideinnertemplate = new("")


/client/verb/Openide()
	var/list/files = list("dmtemplate-ui.js" = "dmtemplate-ui.js", "jquery.min.js" = "jquery.min.js", "jquery-ui.js" = "jquery-ui.min.js", "jquery-ui.css" = "jquery-ui.min.css")
	for (var/filename in files)
		src << browse_rsc(file(files[filename]), filename)
	idetemplate.tokenSet = new /datum/tokenSet(makeTokenSet("ide.tpl", file2text("templates/ide.tpl")))
	ideinnertemplate.tokenSet = new /datum/tokenSet(makeTokenSet(null, ""))
	idetemplate.setvar("rendered", ideinnertemplate.compute())
	var/html = idetemplate.compute()
	src << browse(html, "window=tgtemplateide;size=1100x650")
	//src << html_encode(html)
	//src << html_encode(json_encode(idetemplate.tokenSet.tokens))


/client/Topic(href,list/href_list,hsrc)
	//src << "topic: [href]"
	if(href_list["tgui2"])
		switch(href_list["action"])
			if ("tplupdate")
				sleep(1)
				var/output
				try
					ideinnertemplate.tokenSet = (new /datum/tokenSet(makeTokenSet(null, href_list["text"])))
					output = ideinnertemplate.compute()
				catch (var/exception/E)
					var/json = json_encode(idetemplate.computeDiff(list("tplerror" = "[E]")))
					src << output(list2params(list(json)), "tgtemplateide.browser:updateContent")
					throw E
					return

				var/json = json_encode(idetemplate.computeDiff(list("tplerror" = null, "rendered" = output)))
				src << output(list2params(list(json)), "tgtemplateide.browser:updateContent")
				//src << html_encode(json)
				//src << html_encode(json_encode(ideinnertemplate.tokenSet.tokens))

			if ("jsonupdate")
				sleep(1)
				var/list/varSet
				try
					varSet = json_decode(href_list["text"])
				catch (var/exception/E)
					var/json = json_encode(idetemplate.computeDiff(list("jsonerror" = "[E]")))
					src << output(list2params(list(json)), "tgtemplateide.browser:updateContent")
					throw E
					return

				ideinnertemplate.resetvars(varSet)
				var/json = json_encode(idetemplate.computeDiff(list("jsonerror" = null, "rendered" = ideinnertemplate.compute())))
				src << output(list2params(list(json)), "tgtemplateide.browser:updateContent")
				//src << html_encode(json)
			else
				..()