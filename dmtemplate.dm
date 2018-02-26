/*
	These are simple defaults for your project.
 */

/world
	fps = 25		// 25 frames per second
	icon_size = 32	// 32x32 icon size by default

	view = 6		// show up to 6 tiles outward from center (13x13 view)
	loop_checks = FALSE


// Make objects move 8 pixels per tick when walking

/mob
	step_size = 8

/obj
	step_size = 8

/client
	var/datum/template/idetemplate = new("ide", list("RENDERED" = ""))
	var/datum/template/ideinnertemplate = new("")



/client/verb/Openide()
	var/list/files = list("html_interface.js" = 'html_interface.js', "jquery.min.js" = 'jquery.min.js', "jquery-ui.js" = 'jquery-ui.min.js', "jquery-ui.css" = 'jquery-ui.min.css')
	for (var/filename in files)
		src << browse_rsc(files[filename], filename)
	ideinnertemplate.tokenSet = ideinnertemplate.makeTokenSet("")
	idetemplate.setvar("RENDERED", ideinnertemplate.compute())
	src << browse(idetemplate.compute(), "window=tgtemplateide;size=1100x650")

/client/Topic(href,list/href_list,hsrc)
	switch(href_list["action"])
		if ("tplupdate")
			try
				ideinnertemplate.tokenSet = ideinnertemplate.makeTokenSet(href_list["text"])
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