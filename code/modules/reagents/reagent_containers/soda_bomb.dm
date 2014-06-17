//soda bomb crafting//
/obj/item/weapon/reagent_containers/food/drinks/soda/attackby(var/obj/item/I, mob/user as mob)
	if((isigniter(I)) && assemblystate == 0)
		assemblystate++
		del(I)
		user << "<span class='notice'>You stuff the igniter in the can, emptying the can in process.</span>"
		reagents.clear_reagents()
		underlays += "grenade_ing"

	else if(istype(I, /obj/item/weapon/cable_coil) && assemblystate == 1)
		var/obj/item/weapon/cable_coil/C = I
		if(!C.use(2)) return

		assemblystate++
		user << "<span class='notice'>You wire the igniter.</span>"
		overlays += "grenade_w"
	else if(isprox(I) && assemblystate == 2 && !prox)
		del(I)
		user << "<span class='notice'>You attach the sensor.</span>"
		prox = 1

	else ..()

/obj/item/weapon/reagent_containers/food/drinks/soda
	throw_speed = 4
	throw_range = 20
	var/assemblystate = 0
	var/det_time = 50
	var/active = 0
	var/prox = 0

/obj/item/weapon/reagent_containers/food/drinks/soda/attack_self(mob/user as mob)
	if(assemblystate == 2 && !active)
		user << "<span class='warning'>You turn on the [name]!</span>"
		active = 1

		det_time = rand(30,80)
		if(prob(1))
			det_time = 5 //Poor guy!
		else if(prob(5))
			det_time = 140 //This crap just fail- BOOM!

		if(iscarbon(user))
			var/mob/living/carbon/C = user
			C.throw_mode_on()
		spawn(det_time)
			try_to_explode()
	else ..()

/obj/item/weapon/reagent_containers/food/drinks/soda/throw_impact(atom/hit_atom)
	..()
	if(active && prox)
		try_to_explode()

/obj/item/weapon/reagent_containers/food/drinks/soda/proc/try_to_explode()
	active = 0 //So you can reuse your failed bombs

	if(prob(10)) return //This crap just failed!

	var/expl_power = 0
	expl_power += reagents.get_reagent_amount("plasma") / 12.5	//2x power - bomber's choise!

	expl_power += reagents.get_reagent_amount("fuel") / 25

	expl_power += reagents.get_reagent_amount("ethanol") / 25

	expl_power += reagents.get_reagent_amount("vodka") / 25		//For that badass russians!
																//Maybe it needs ushanka (+1 to expl_power) and soviet uniform (+1 to expl_power) checks?

	expl_power = round(expl_power, 1)

	if(prob(4)) expl_power = min(expl_power - 1, 0) //Shit happens. Still better than nothing.

	if(expl_power)
		explosion(src.loc, expl_power - 3, expl_power - 2, expl_power)
		del(src)