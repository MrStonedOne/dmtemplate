/world
	fps = 100
	icon_size = 32
	view = 7
	loop_checks = FALSE


/client
	var/datum/template/idetemplate = new("ide", list("RENDERED" = ""))
	var/datum/template/ideinnertemplate = new("")


/client/verb/Openide()
	var/list/files = list("html_interface.js" = 'html_interface.js', "jquery.min.js" = 'jquery.min.js', "jquery-ui.js" = 'jquery-ui.min.js', "jquery-ui.css" = 'jquery-ui.min.css')
	for (var/filename in files)
		src << browse_rsc(files[filename], filename)
	ideinnertemplate.tokenSet = makeTokenSet(null, "")
	idetemplate.setvar("RENDERED", ideinnertemplate.compute())
	src << browse(idetemplate.compute(), "window=tgtemplateide;size=1100x650")


/client/Topic(href,list/href_list,hsrc)
	switch(href_list["action"])
		if ("tplupdate")
			try
				ideinnertemplate.tokenSet = makeTokenSet(null, href_list["text"])
			catch (var/exception/E)
				var/json = json_encode(idetemplate.computeDiff(list("TPLERROR" = html_encode("[E]"))))
				src << output(list2params(list(json)), "tgtemplateide.browser:updateContent")
				return

			var/json = json_encode(idetemplate.computeDiff(list("TPLERROR" = null, "RENDERED" = ideinnertemplate.compute())))
			src << output(list2params(list(json)), "tgtemplateide.browser:updateContent")
		if ("jsonupdate")
			var/list/varSet
			try
				varSet = json_decode(href_list["text"])
			catch (var/exception/E)
				var/json = json_encode(idetemplate.computeDiff(list("JSONERROR" = html_encode("[E]"))))
				src << output(list2params(list(json)), "tgtemplateide.browser:updateContent")
				return

			ideinnertemplate.resetvars(varSet)
			var/json = json_encode(idetemplate.computeDiff(list("JSONERROR" = null, "RENDERED" = ideinnertemplate.compute())))
			src << output(list2params(list(json)), "tgtemplateide.browser:updateContent")
		else
			return ..()