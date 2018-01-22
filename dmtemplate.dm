/*
	These are simple defaults for your project.
 */

world
	fps = 25		// 25 frames per second
	icon_size = 32	// 32x32 icon size by default

	view = 6		// show up to 6 tiles outward from center (13x13 view)


// Make objects move 8 pixels per tick when walking

mob
	step_size = 8

obj
	step_size = 8

client
	var/datum/template/active_template
	var/list/tvars
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

