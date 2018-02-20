/*
	These are simple defaults for your project.
 */

world
	fps = 25		// 25 frames per second
	icon_size = 32	// 32x32 icon size by default

	view = 6		// show up to 6 tiles outward from center (13x13 view)
	loop_checks = FALSE


// Make objects move 8 pixels per tick when walking

mob
	step_size = 8

obj
	step_size = 8

client
	var/datum/template/active_template
	var/list/tvars
	var/list/tpls
	var/update = FALSE
	verb
		activate_template(template_name as text)
			tvars = list()
			active_template = new(template_name, tvars.Copy())
			src << browse(active_template.compute(), "window=template")

		set_var(key as text, value as message)
			world << "1 `[key]` = `[value]`"
			tvars[key] = value
			active_template.resetvars(tvars.Copy())
			src << browse(active_template.compute(), "window=template")

		testmsoplayerdetailsloop()
			var/json = file2text("data/msotpldata.txt")
			var/list/L = json_decode(json)
			var/stoptime = world.timeofday + 600
			tpls = list()
			while (world.timeofday < stoptime)
				var/datum/template/tpl = new("playerdetails")
				tpl.resetvars(L)
				tpl.compute()
				tpls += tpl

		testmsoplayerdetailsupdateloop()
			var/json = file2text("data/msotpldata.txt")
			var/list/L = json_decode(json)
			var/stoptime = world.timeofday + 600

			var/datum/template/tpl = new("playerdetails")
			tpl.resetvars(L)
			tpl.compute()
			while (world.timeofday < stoptime)
				var/return_json = json_encode(tpl.computeDiff(L))
				//src << output(list2params(list(json)), "testupdate.browser:updateContent")

		testmsoplayerdetails()
			var/datum/template/tpl = new("playerdetails")
			var/json = file2text("data/msotpldata.txt")
			var/list/L = json_decode(json)
			tpl.resetvars(L)
			src << browse(tpl.compute(), "window=template")

		updatetoggle()
			if (update)
				update = FALSE
				return
			var/list/files = list("html_interface.js" = 'html_interface.js', "jquery.min.js" = 'jquery.min.js')
			for (var/filename in files)
				src << browse_rsc(files[filename], filename)

			var/datum/template/tpl = new("testupdate")
			tpl.setvar("TIME", world.time)
			src << browse(tpl.compute(), "window=testupdate")
			update = TRUE
			while(update)
				var/json = json_encode(tpl.computeDiff(list("TIME" = world.time)))
				src << output(list2params(list(json)), "testupdate.browser:updateContent")
				sleep(0.5)

		testupdateloop()
			var/list/files = list("html_interface.js" = 'html_interface.js', "jquery.min.js" = 'jquery.min.js')
			for (var/filename in files)
				src << browse_rsc(files[filename], filename)

			var/datum/template/tpl = new("testupdate")
			tpl.setvar("TIME", world.time)
			src << browse(tpl.compute(), "window=testupdate")
			sleep(10)
			var/timetostop = world.timeofday + 60
			while(world.timeofday < timetostop)
				var/json = json_encode(tpl.computeDiff(list("TIME" = world.time)))

