//Ocular warden: Low-damage, low-range turret. Deals constant damage to whoever it makes eye contact with.
/obj/structure/destructible/clockwork/ocular_warden
	name = "ocular warden"
	desc = "A large brass eye with tendrils trailing below it and a wide red iris."
	clockwork_desc = "A fragile turret that will deal sustained damage to any non-faithful it sees."
	icon_state = "ocular_warden"
	unanchored_icon = "ocular_warden_unwrenched"
	obj_integrity = 25
	max_integrity = 25
	construction_value = 15
	layer = HIGH_OBJ_LAYER
	break_message = "<span class='warning'>The warden's eye gives a glare of utter hate before falling dark!</span>"
	debris = list(/obj/item/clockwork/component/belligerent_eye/blind_eye = 1)
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	var/damage_per_tick = 2.7
	var/sight_range = 3
	var/atom/movable/target
	var/list/idle_messages = list(" sulkily glares around.", " lazily drifts from side to side.", " looks around for something to burn.", " slowly turns in circles.")

/obj/structure/destructible/clockwork/ocular_warden/New()
	..()
	START_PROCESSING(SSfastprocess, src)

/obj/structure/destructible/clockwork/ocular_warden/Destroy()
	STOP_PROCESSING(SSfastprocess, src)
	return ..()

/obj/structure/destructible/clockwork/ocular_warden/examine(mob/user)
	..()
	user << "<span class='brass'>[target ? "<b>It's fixated on [target]!</b>" : "Its gaze is wandering aimlessly."]</span>"

/obj/structure/destructible/clockwork/ocular_warden/hulk_damage()
	return 25

/obj/structure/destructible/clockwork/ocular_warden/can_be_unfasten_wrench(mob/user)
	if(anchored)
		if(obj_integrity <= max_integrity * 0.25)
			user << "<span class='warning'>[src] is too damaged to unsecure!</span>"
			return FAILED_UNFASTEN
	else
		for(var/obj/structure/destructible/clockwork/ocular_warden/W in orange(3, src))
			user << "<span class='neovgre'>You sense another ocular warden too near this location. Activating this one this close would cause them to fight.</span>"
			return FAILED_UNFASTEN
	return SUCCESSFUL_UNFASTEN

/obj/structure/destructible/clockwork/ocular_warden/ratvar_act()
	..()
	if(ratvar_awakens)
		damage_per_tick = 10
		sight_range = 6
	else
		damage_per_tick = initial(damage_per_tick)
		sight_range = initial(sight_range)

/obj/structure/destructible/clockwork/ocular_warden/process()
	if(!anchored)
		lose_target()
		return
	var/list/validtargets = acquire_nearby_targets()
	if(target)
		if(!(target in validtargets))
			lose_target()
		else
			if(isliving(target))
				var/mob/living/L = target
				if(!L.null_rod_check())
					if(isrevenant(L))
						var/mob/living/simple_animal/revenant/R = L
						if(R.revealed)
							R.unreveal_time += 2
						else
							R.reveal(10)
					L.adjustFireLoss((!iscultist(L) ? damage_per_tick : damage_per_tick * 2) * get_efficiency_mod()) //Nar-Sian cultists take additional damage
					if(ratvar_awakens && L)
						L.adjust_fire_stacks(damage_per_tick)
						L.IgniteMob()
			else if(istype(target,/obj/mecha))
				var/obj/mecha/M = target
				M.take_damage(damage_per_tick * get_efficiency_mod(), BURN, "melee", 1, get_dir(src, M))

			PoolOrNew(/obj/effect/overlay/temp/ratvar/ocular_warden, get_turf(target))

			setDir(get_dir(get_turf(src), get_turf(target)))
	if(!target)
		if(validtargets.len)
			target = pick(validtargets)
			visible_message("<span class='warning'>[src] swivels to face [target]!</span>")
			if(isliving(target))
				var/mob/living/L = target
				L << "<span class='heavy_brass'>\"I SEE YOU!\"</span>\n<span class='userdanger'>[src]'s gaze [ratvar_awakens ? "melts you alive" : "burns you"]!</span>"
			else if(istype(target,/obj/mecha))
				var/obj/mecha/M = target
				M.occupant << "<span class='heavy_brass'>\"I SEE YOU!\"</span>" //heeeellooooooo, person in mech.
		else if(prob(0.5)) //Extremely low chance because of how fast the subsystem it uses processes
			if(prob(50))
				visible_message("<span class='notice'>[src][pick(idle_messages)]</span>")
			else
				setDir(pick(cardinal))//Random rotation

/obj/structure/destructible/clockwork/ocular_warden/proc/acquire_nearby_targets()
	. = list()
	for(var/mob/living/L in viewers(sight_range, src)) //Doesn't attack the blind
		var/obj/item/weapon/storage/book/bible/B = L.bible_check()
		if(B)
			if(!(B.resistance_flags & ON_FIRE))
				L << "<span class='warning'>Your [B.name] bursts into flames!</span>"
			for(var/obj/item/weapon/storage/book/bible/BI in L.GetAllContents())
				if(!(BI.resistance_flags & ON_FIRE))
					BI.fire_act()
		else if(!is_servant_of_ratvar(L) && !L.stat && L.mind && !L.restrained() && !(L.buckled && (L.lying || istype(L.buckled, /obj/structure/destructible/clockwork/geis_binding))) && \
		!(L.disabilities & BLIND) && !L.null_rod_check())
			. += L
	for(var/N in mechas_list)
		var/obj/mecha/M = N
		if(get_dist(M, src) <= sight_range && M.occupant && !is_servant_of_ratvar(M.occupant) && (M in view(sight_range, src)))
			. += M

/obj/structure/destructible/clockwork/ocular_warden/proc/lose_target()
	if(!target)
		return 0
	target = null
	visible_message("<span class='warning'>[src] settles and seems almost disappointed.</span>")
	return 1
