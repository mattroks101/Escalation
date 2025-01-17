/obj/structure/brutswehrincomplete
	name = "incomplete brustwehr"
	icon = 'icons/obj/structures.dmi'
	icon_state = "brustwehr_isntready"
	density = 0
	throwpass = 1//we can throw grenades despite its density
	anchored = 1
	flags = OBJ_CLIMBABLE
	var/digstage = 0

/obj/structure/brutswehrincomplete/Initialize(var/obj/structure/flora/F)
	if(locate(F) in src.loc.contents)
		qdel(F)

/obj/structure/brutswehrincomplete/attackby(obj/item/weapon/W as obj, mob/user as mob)

	if(istype(W,/obj/item/weapon/shovel))
		var/obj/item/weapon/shovel/C = W
		if(C.working)
			return
		C.working = 1
		if(!C.ground > 0)
			C.working = 0
			return
		playsound(src, 'sound/effects/empty_shovel.ogg', 50, 1)
		if(!do_after(user, 10,src))
			to_chat(user, "Hold still to do this.")
			C.working = 0
			return
		C.ground--
		digstage++
		C.working = 0
		to_chat(user, "You put some ground onto [src].")
		if(digstage <= 3)
			to_chat(user, "<span class='warning'>You need [4 - digstage] more piles.</span>")
		C.update_icon()
		update_stage()

	else
		return ..()

/obj/structure/brutswehrincomplete/proc/update_stage()
	if(digstage >= 4)
		new /obj/structure/brutswehr(src.loc)
		qdel(src)

/obj/structure/brutswehr
	name = "brustwehr"
	desc = "A breast-high earthwork structure meant to provide cover."
	icon = 'icons/obj/sandbags.dmi'
	icon_state = "brustwehr_0"
	density = 1
	throwpass = 1//we can throw grenades despite its density
	anchored = 1
	flags = OBJ_CLIMBABLE
	var/basic_chance = 20
	var/health = 200 //Actual health depends on snow layer
	var/reinforced = 0 //has there been a bridge built?

/obj/structure/brutswehr/Initialize(var/obj/structure/flora/F)
	if(locate(F) in src.loc.contents)
		qdel(F)


/obj/structure/brutswehr/New()
	..()
	flags |= ON_BORDER
	update_nearby_icons()

/obj/structure/brutswehr/Destroy()
	basic_chance = null
	..()

/obj/structure/brutswehr/examine(mob/user)
	. = ..(user)
	switch(health)
		if(200 to INFINITY)
			to_chat(user, "It's intact.")
		if(150 to 200)
			to_chat(user, "It's slightly damaged.")
		if(100 to 150)
			to_chat(user, "<span class='warning'>It's badly damaged.</span>")
		if(50 to 100)
			to_chat(user, "<span class='warning'>It's heavily damaged.</span>")
		else
			to_chat(user, "<span class='warning'>It's falling apart!</span>")

/obj/structure/brutswehr/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if(istype(mover, /obj/item/projectile))
		var/obj/item/projectile/proj = mover

		if(proj.firer && Adjacent(proj.firer))
			return 1

		if (get_dist(proj.starting, loc) <= 1)//allows to fire from 1 tile away of sandbag
			return 1

		return check_cover(mover, target)

	else if(istype(mover, /obj))
		return 1

	else
		..()

//checks if projectile 'P' from turf 'from' can hit whatever is behind the table. Returns 1 if it can, 0 if bullet stops.
/obj/structure/brutswehr/proc/check_cover(obj/item/projectile/P, turf/from)
	var/turf/cover = get_step(loc, get_dir(from, loc))
	if (get_dist(P.starting, loc) <= 1) //Barricades won't help you if people are THIS close
		return 1
	if (get_turf(P.original) == cover)
		var/chance = 70
		if (ismob(P.original))
			var/mob/M = P.original
			if (M.lying)
				chance += 20				//Lying down lets you catch less bullets
		if(prob(chance))
			health -= P.damage/4
			visible_message("<span class='warning'>[P] hits [src]!</span>")
			health_check()
			return 0
	return 1

/obj/structure/brutswehr/MouseDrop_T(obj/O as obj, mob/user as mob)
	..()
	if ((!( istype(O, /obj/item/weapon) ) || user.get_active_hand() != O))
		return
	if(isrobot(user))
		return
	//user.drop_item()
	if (O.loc != user.loc)
		to_chat(user, "you start climbing onto [O]...")
		step(O, get_dir(O, src))
	return

	//Check Health
/obj/structure/brutswehr/proc/health_check(var/die)
	if(health < 1 || die)
		update_nearby_icons()
		visible_message("\red <B>[src] falls apart!</B>")
		qdel(src)

	//Explosion Act
/obj/structure/brutswehr/ex_act(severity)
	switch(severity)
		if(1.0)
			visible_message("\red <B>[src] is blown apart!</B>")
			src.update_nearby_icons()
			qdel(src)
			return
		if(2.0)
			src.health -= rand(30,60)
			if (src.health <= 0)
				visible_message("\red <B>[src] is blown apart!</B>")
				src.update_nearby_icons()
				qdel(src)
			return
		if(3.0)
			src.health -= rand(10,30)
			if (src.health <= 0)
				visible_message("\red <B>[src] is blown apart!</B>")
				src.update_nearby_icons()
				qdel(src)
			return

	//Update Sides
/obj/structure/brutswehr/proc/update_nearby_icons()
	update_icon()
	for(var/direction in GLOB.cardinal)
		for(var/obj/structure/brutswehr/B in get_step(src,direction))
			B.update_icon()

	//Update Icons
/obj/structure/brutswehr/update_icon()
	spawn(2)
		if(!src)
			return
		var/junction = 0 //will be used to determine from which side the barricade is connected to other barricades
		for(var/obj/structure/brutswehr/B in orange(src,1))
			if(abs(x-B.x)-abs(y-B.y) ) 		//doesn't count barricades, placed diagonally to src
				junction |= get_dir(src,B)

		icon_state = "brustwehr_[junction]"
		return

/obj/structure/brutswehr/attackby(var/obj/item/I, mob/user as mob)
	if(istype(I, /obj/item/stack/material/wood))
		if(!reinforced)

			var/obj/item/stack/material/wood/R = I

			if(R.amount >= 3)
				if(!do_after(user, 20, src))
					return 0
				desc = "A brustwehr covered with some wooden planks."
				flags |= OBJ_CLIMBABLE
				R.use(3)
				health += 100
				reinforced = 1
				throwpass = 0
				playsound(get_turf(loc), "rustle", 15, 1, -3)
				basic_chance += 10
				density = 1
				src.overlays += image('icons/obj/sandbags.dmi', "brustwehr_barricadeoverlay", layer=3.1)
			else
				to_chat(user, "<span class='notice'>You do not have enough wood to reinforce the brustwehr.</span>")

	else if(istype(I, /obj/item/stack/material/r_wood))
		if(!reinforced)
			var/obj/item/stack/material/r_wood/R = I

			if(R.amount >= 3)
				if(!do_after(user, 20, src))
					return 0
				desc = "A brustwehr covered with some wooden planks."
				flags |= OBJ_CLIMBABLE
				basic_chance += 20
				R.use(3)
				health += 150
				playsound(get_turf(loc), "rustle", 15, 1, -3)
				throwpass = 0
				reinforced = 2
				density = 1
				src.overlays += image('icons/obj/sandbags.dmi', "brustwehr_barricadeoverlay", layer=3.1)
			else
				to_chat(user, "<span class='notice'>You do not have enough wood to reinforce the brustwehr.</span>")

	else if(istype(I, /obj/item/weapon/sandbag))
		if(!reinforced)
			var/obj/item/weapon/sandbag/R = I

			if(R.sand_amount >= 4)
				if(!do_after(user, 20, src))
					return 0
				desc = "A brustwehr covered with some sandbags."
				flags |= OBJ_CLIMBABLE
				basic_chance += 30
				health += 200
				qdel(R)
				playsound(get_turf(loc), "rustle", 15, 1, -4)
				reinforced = 3
				density = 1
				src.overlays += image('icons/obj/sandbags.dmi', "brustwehr_sandbagoverlay", layer=3.1)
			else
				to_chat(user, "<span class='notice'>The sandbag isn't full enough to reinforce the brustwehr.</span>")

	else if(istype(I, /obj/item/weapon/shovel))
		var/obj/item/weapon/shovel/S = I
		if(S.ground)
			to_chat(user, "<span class='notice'>The brustwehr is fully built.</span>")
			return 0
		if(reinforced)
			to_chat(user, "<span class='notice'>You begin to disassemble the reinforcement.</span>")
			if(!do_after(user, 20, src))
				return 0
			playsound(src, 'sound/items/Deconstruct.ogg', 50, 1)
			desc = "A breast-high earthwork structure meant to provide cover."
			src.overlays = null
			basic_chance = 20
			throwpass = 1
			switch(reinforced)
				if(1)
					var/obj/item/stack/material/wood/R =  new /obj/item/stack/material/wood(get_turf(src))
					R.amount = 3
					health = max(100, health - 100)
				if(2)
					var/obj/item/stack/material/r_wood/R =  new /obj/item/stack/material/r_wood(get_turf(src))
					R.amount = 3
					health = max(100, health - 150)
				if(3)
					var/obj/item/weapon/sandbag/R =  new /obj/item/weapon/sandbag(get_turf(src))
					R.sand_amount = 4
					R.w_class++
					R.update_icon()
					health = max(100, health - 200)
			reinforced = 0
		else
			to_chat(user, "<span class='notice'>You start to take down the brustwehr.</span>")
			playsound(src, 'sound/effects/empty_shovel.ogg', 50, 1)
			if(!do_after(user, 20, src))
				return 0
			for(var/i=0, i<5, i++)
				new /obj/item/weapon/ore/glass(src.loc)
			src.update_nearby_icons()
			qdel(src)

/*
/obj/item/weapon/ore/glass/attack_self(mob/user as mob)
	if(!isturf(user.loc))
		to_chat(user, "\red Haha. Nice try.")
		return

	if(!check4struct(user))
		return

	var/obj/structure/brutswehr/B = new(user.loc)
	B.set_dir(user.dir)
	user.drop_item()
	qdel(src)
*/