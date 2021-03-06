/proc/get_mech_image(var/decal, var/cache_key, var/cache_icon, var/image_colour, var/overlay_layer = FLOAT_LAYER)
	var/use_key = "[cache_key]-[cache_icon]-[decal ? decal : "none"]-[image_colour ? image_colour : "none"]"
	if(!global.mech_image_cache[use_key])
		var/image/I = image(icon = cache_icon, icon_state = cache_key)
		if(image_colour)
			I.color = image_colour
		if(decal)
			var/decal_key = "[decal]-[cache_key]"
			if(!global.mech_icon_cache[decal_key])
				var/template_key = "template-[cache_key]"
				if(!global.mech_icon_cache[template_key])
					global.mech_icon_cache[template_key] = icon(cache_icon, "[cache_key]_mask")
				var/icon/decal_icon = icon('icons/mecha/mech_decals.dmi',decal)
				decal_icon.AddAlphaMask(global.mech_icon_cache[template_key])
				global.mech_icon_cache[decal_key] = decal_icon
			I.overlays += get_mech_image(null, decal_key, global.mech_icon_cache[decal_key])
		I.appearance_flags |= RESET_COLOR
		I.layer = overlay_layer
		I.plane = FLOAT_PLANE
		global.mech_image_cache[use_key] = I
	return global.mech_image_cache[use_key]

/proc/get_mech_images(var/list/components = list(), var/overlay_layer = FLOAT_LAYER)
	var/list/all_images = list()
	for(var/obj/item/mech_component/comp in components)
		all_images += get_mech_image(comp.decal, comp.icon_state, comp.on_mech_icon, comp.color, overlay_layer)
	return all_images

/mob/living/exosuit/on_update_icon()

	..()
	for(var/overlay in get_mech_images(list(body, head), MECH_BASE_LAYER))
		add_overlay(overlay)

	if(body && !hatch_closed)
		add_overlay(get_mech_image(body.decal, "[body.icon_state]_cockpit", body.on_mech_icon, COLOR_WHITE, MECH_INTERMEDIATE_LAYER))
	update_pilots(FALSE)
	if(LAZYLEN(pilot_overlays))
		for(var/overlay in pilot_overlays)
			add_overlay(overlay)
	if(body)
		add_overlay(get_mech_image(body.decal, "[body.icon_state]_overlay[hatch_closed ? "" : "_open"]", body.on_mech_icon, body.color, MECH_COCKPIT_LAYER))
	if(arms)
		add_overlay(get_mech_image(arms.decal, arms.icon_state, arms.on_mech_icon, arms.color, MECH_ARM_LAYER))
	if(legs)
		add_overlay(get_mech_image(legs.decal, legs.icon_state, legs.on_mech_icon, legs.color, MECH_LEG_LAYER))
	for(var/hardpoint in hardpoints)
		var/obj/item/mech_equipment/hardpoint_object = hardpoints[hardpoint]
		if(hardpoint_object)
			var/use_icon_state = "[hardpoint_object.icon_state]_[hardpoint]"
			if(use_icon_state in global.mech_weapon_overlays)
				add_overlay(get_mech_image(null, use_icon_state, 'icons/mecha/mech_weapon_overlays.dmi', null, hardpoint_object.mech_layer))

/mob/living/exosuit/proc/update_pilots(var/update_overlays = TRUE)
	if(update_overlays && LAZYLEN(pilot_overlays))
		overlays -= pilot_overlays
	pilot_overlays = null
	if(body && !(body.hide_pilot))
		for(var/i = 1 to LAZYLEN(pilots))
			var/mob/pilot = pilots[i]
			var/image/draw_pilot = new
			draw_pilot.appearance = pilot
			draw_pilot.layer = MECH_PILOT_LAYER + (body ? ((LAZYLEN(body.pilot_positions)-i)*0.001) : 0)
			draw_pilot.plane = FLOAT_PLANE
			draw_pilot.appearance_flags = KEEP_TOGETHER
			if(body && i <= LAZYLEN(body.pilot_positions))
				var/list/offset_values = body.pilot_positions[i]
				var/list/directional_offset_values = offset_values["[dir]"]
				draw_pilot.pixel_x = pilot.default_pixel_x + directional_offset_values["x"]
				draw_pilot.pixel_y = pilot.default_pixel_y + directional_offset_values["y"]
				draw_pilot.pixel_z = 0
				draw_pilot.transform = null

			//Mask pilots!
			//Masks are 48x48 and pilots 32x32 (in theory at least) so some math is required for centering
			var/diff_x = 8 - draw_pilot.pixel_x
			var/diff_y = 8 - draw_pilot.pixel_y
			draw_pilot.filters = filter(type = "alpha", icon = icon(body.on_mech_icon, "[body.icon_state]_pilot_mask[hatch_closed ? "" : "_open"]", dir), x = diff_x, y = diff_y)
			
			LAZYADD(pilot_overlays, draw_pilot)
		if(update_overlays && LAZYLEN(pilot_overlays))
			overlays += pilot_overlays
