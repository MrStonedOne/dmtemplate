/*
	These are simple defaults for your project.
 */

world
	fps = 60		// 25 frames per second
	icon_size = 32	// 32x32 icon size by default

	view = 6		// show up to 6 tiles outward from center (13x13 view)
	loop_checks = FALSE

/mob
	step_size = 8

/obj
	step_size = 8

/client
	var/datum/template/active_template
	var/list/tvars
/client/verb/activate_template(template_name as text)
	tvars = list()
	active_template = new(template_name, tvars.Copy())
	src << browse(active_template.compute(), "window=template")

/client/verb/set_var(key as text, value as message)
	world << "1 `[key]` = `[value]`"
	tvars[key] = value
	active_template.resetvars(tvars.Copy())
	src << browse(active_template.compute(), "window=template")

/client/verb/testmsoplayerdetailsloop()
	var/datum/template/tpl = new("playerdetails")
	var/json = file2text("data/msotpldata.txt")
	var/list/L = json_decode(json)
	var/stoptime = world.timeofday + 600
	while (world.timeofday < stoptime)
		tpl.resetvars(L)
		tpl.compute()

/client/verb/testmsoplayerdetails()
	var/datum/template/tpl = new("playerdetails")
	var/json = file2text("data/msotpldata.txt")
	var/list/L = json_decode(json)
	tpl.resetvars(L)
	src << browse(tpl.compute(), "window=template")
