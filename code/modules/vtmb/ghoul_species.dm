/datum/species/ghoul
	name = "Ghoul"
	id = "ghoul"
	default_color = "FFFFFF"
	toxic_food = RAW
	species_traits = list(EYECOLOR, HAIR, FACEHAIR, LIPS, HAS_FLESH, HAS_BONE)
	inherent_traits = list(TRAIT_ADVANCEDTOOLUSER, TRAIT_VIRUSIMMUNE, TRAIT_NOCRITDAMAGE)
	use_skintones = TRUE
	limbs_id = "human"
	mutant_bodyparts = list("tail_human" = "None", "ears" = "None", "wings" = "None")
	brutemod = 1	//0.8 instead, if changing.
	burnmod = 1
	punchdamagelow = 10
	punchdamagehigh = 20
	dust_anim = "dust-h"
	var/mob/living/carbon/human/master
	var/changed_master = FALSE
	var/last_vitae = 0

/datum/action/ghoulinfo
	name = "About Me"
	desc = "Check assigned role, master, humanity, masquerade, known contacts etc."
	button_icon_state = "masquerade"
	check_flags = NONE
	var/mob/living/carbon/human/host

/datum/action/ghoulinfo/Trigger()
	if(host)
		var/dat = {"
			<style type="text/css">

			body {
				background-color: #090909; color: white;
			}

			</style>
			"}
		dat += "<center><h2>Memories</h2><BR></center>"
		dat += "[icon2html(getFlatIcon(host), host)]I am "
		if(host.real_name)
			dat += "[host.real_name],"
		if(!host.real_name)
			dat += "Unknown,"
		var/datum/species/ghoul/G
		if(host.dna.species.name == "Ghoul")
			G = host.dna.species
			dat += " the ghoul"

		if(host.mind.assigned_role)
			if(host.mind.special_role)
				dat += ", carrying the [host.mind.assigned_role] (<font color=red>[host.mind.special_role]</font>) role."
			else
				dat += ", carrying the [host.mind.assigned_role] role."
		if(!host.mind.assigned_role)
			dat += "."
		dat += "<BR>"
		if(G.master)
			dat += "My Regnant is [G.master.real_name], I should obey their wants.<BR>"
			if(G.master.clane)
				if(G.master.clane.name != "Caitiff")
					dat += "Regnant's clan is [G.master.clane], maybe I can try some of it's disciplines..."
		if(host.vampire_faction == "Camarilla" || host.vampire_faction == "Anarch" || host.vampire_faction == "Sabbat")
			dat += "I belong to the [host.vampire_faction], I shouldn't disobey their rules.<BR>"
		if(host.mind.special_role)
			for(var/datum/antagonist/A in host.mind.antag_datums)
				if(A.objectives)
					dat += "[printobjectives(A.objectives)]<BR>"
		var/masquerade_level = " followed the Masquerade Tradition perfectly."
		switch(host.masquerade)
			if(4)
				masquerade_level = " broke the Masquerade rule once."
			if(3)
				masquerade_level = " made a couple of Masquerade breaches."
			if(2)
				masquerade_level = " provoked a moderate Masquerade breach."
			if(1)
				masquerade_level = " almost ruined the Masquerade."
			if(0)
				masquerade_level = "'m danger to the Masquerade and my own kind."
		dat += "Camarilla thinks I[masquerade_level]<BR>"
//		var/humanity = "I'm out of my mind."
//		switch(host.humanity)
//			if(8 to 10)
//				humanity = "I'm the best example of mercy and kindness."
//			if(7)
//				humanity = "I have nothing to complain about my humanity."
//			if(5 to 6)
//				humanity = "I'm slightly above the humane."
//			if(4)
//				humanity = "I don't care about kine."
//			if(2 to 3)
//				humanity = "There's nothing bad in murdering for <b>BLOOD</b>."
//			if(1)
//				humanity = "I'm slowly falling into madness..."
//		dat += "[humanity]<BR>"
		dat += "<b>Physique</b>: [host.physique]<BR>"
		dat += "<b>Social</b>: [host.social]<BR>"
		dat += "<b>Mentality</b>: [host.mentality]<BR>"
		dat += "<b>Lockpicking</b>: [host.lockpicking]<BR>"
		dat += "<b>Cruelty</b>: [host.blood]<BR>"
		if(host.friend_name)
			dat += "<b>Friend: [host.friend_name]</b><BR>"
		if(host.enemy_name)
			dat += "<b>Enemy: [host.enemy_name]</b><BR>"
		if(host.lover_name)
			dat += "<b>Lover: [host.lover_name]</b><BR>"
		if(length(host.knowscontacts) > 0)
			dat += "<b>I know some other of my kind in this city. Need to check my phone, there definetely should be:</b><BR>"
			for(var/i in host.knowscontacts)
				dat += "-[i] contact<BR>"
		host << browse(dat, "window=vampire;size=400x450;border=1;can_resize=1;can_minimize=0")
		onclose(host, "ghoul", src)

/datum/species/ghoul/on_species_gain(mob/living/carbon/human/C)
	..()
	C.update_body(0)
	C.last_experience = world.time+3000
	var/datum/action/ghoulinfo/infor = new()
	infor.host = C
	infor.Grant(C)
	var/datum/action/blood_heal/bloodheal = new()
	bloodheal.Grant(C)
	var/datum/action/take_vitae/TV = new()
	TV.Grant(C)
	C.generation = 13
	C.bloodpool = 10
	C.maxbloodpool = 10
	C.maxHealth = 100
	C.health = 100

/datum/species/ghoul/on_species_loss(mob/living/carbon/human/C, datum/species/new_species, pref_load)
	. = ..()
	for(var/datum/action/ghoulinfo/GI in C.actions)
		qdel(GI)
	for(var/datum/action/blood_heal/BH in C.actions)
		qdel(BH)
	for(var/datum/action/take_vitae/TV in C.actions)
		qdel(TV)

/datum/action/take_vitae
	name = "Take Vitae"
	desc = "Take vitae from a Vampire by force."
	button_icon_state = "ghoul"
	check_flags = AB_CHECK_HANDS_BLOCKED|AB_CHECK_IMMOBILE|AB_CHECK_LYING|AB_CHECK_CONSCIOUS
	var/taking = FALSE

/datum/action/take_vitae/Trigger()
	if(istype(owner, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = owner
		if(istype(H.pulling, /mob/living/carbon/human))
			var/mob/living/carbon/human/VIT = H.pulling
			if(iskindred(VIT))
				if(VIT.bloodpool)
					if(VIT.getBruteLoss() > 30)
						taking = TRUE
						if(do_mob(owner, VIT, 10 SECONDS))
							taking = FALSE
							H.drunked_of |= "[VIT.dna.real_name]"
							H.adjustBruteLoss(-25, TRUE)
							H.adjustFireLoss(-25, TRUE)
							VIT.bloodpool = max(0, VIT.bloodpool-1)
							H.bloodpool = min(H.maxbloodpool, H.bloodpool+1)
							H.update_blood_hud()
							to_chat(owner, "<span class='warning'>You feel precious <b>VITAE</b> entering your mouth and suspending your addiction.</span>")
							return
						else
							taking = FALSE
							return
					else
						to_chat(owner, "<span class='warning'>Damage [VIT] before taking vitae.</span>")
						return
				else
					to_chat(owner, "<span class='warning'>There is not enough <b>VITAE</b> in [VIT] to feed your addiction.</span>")
					return
			else
				to_chat(owner, "<span class='warning'>You don't sense the <b>VITAE</b> in [VIT].</span>")
				return

/datum/action/blood_heal
	name = "Blood Heal"
	desc = "Use vitae in your blood to heal your wounds."
	button_icon_state = "bloodheal"
	check_flags = AB_CHECK_HANDS_BLOCKED|AB_CHECK_IMMOBILE|AB_CHECK_LYING|AB_CHECK_CONSCIOUS
	var/last_heal = 0
	var/level = 1

/datum/action/blood_heal/Trigger()
	if(istype(owner, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = owner
		if(HAS_TRAIT(H, TRAIT_COFFIN_THERAPY))
			if(!istype(H.loc, /obj/structure/closet/crate/coffin))
				to_chat(usr, "<span class='warning'>You need to be in a coffin to use that!</span>")
				return
		if(H.bloodpool < 1)
			to_chat(owner, "<span class='warning'>You don't have enough <b>BLOOD</b> to do that!</span>")
			SEND_SOUND(H, sound('code/modules/wod13/sounds/need_blood.ogg', 0, 0, 75))
			return
		if(last_heal+30 >= world.time)
			return
		last_heal = world.time
		H.bloodpool = max(0, H.bloodpool-1)
<<<<<<< HEAD
		playsound(H, 'code/modules/wod13/sounds/bloodhealing.ogg', 50, FALSE)
=======
		H.playsound_local(H, 'code/modules/ziggers/sounds/bloodhealing.ogg', 50, FALSE)
>>>>>>> 86109dbd4d85e2e7a568b142a1174263d08cff4a
		H.adjustBruteLoss(-10*level, TRUE)
		H.adjustFireLoss(-10*level, TRUE)
		if(length(H.all_wounds))
			var/datum/wound/W = pick(H.all_wounds)
			W.remove_wound()
		H.update_damage_overlays()
		H.update_health_hud()
		H.update_blood_hud()
		H.visible_message("<span class='warning'>Some of [H]'s visible injuries disappear!</span>", "<span class='warning'>Some of your injuries disappear!</span>")

/datum/species/ghoul/check_roundstart_eligible()
	return TRUE

/datum/species/ghoul/spec_life(mob/living/carbon/human/H)
	. = ..()
	if(HAS_TRAIT(H, TRAIT_UNMASQUERADE))
		if(H.CheckEyewitness(H, H, 7, FALSE))
			H.AdjustMasquerade(-1)
	if(istype(get_area(H), /area/vtm))
		var/area/vtm/V = get_area(H)
		if(V.zone_type == "masquerade" && V.upper)
			if(H.pulling)
				if(ishuman(H.pulling))
					var/mob/living/carbon/human/pull = H.pulling
					if(pull.stat == 4)
						var/obj/item/card/id/id_card = H.get_idcard(FALSE)
						if(!istype(id_card, /obj/item/card/id/clinic) && !istype(id_card, /obj/item/card/id/police))
							if(H.CheckEyewitness(H, H, 7, FALSE))
								if(H.last_loot_check+50 <= world.time)
									H.last_loot_check = world.time
									H.last_nonraid = world.time
									H.killed_count = H.killed_count+1
									if(!H.warrant)
										if(H.killed_count >= 5)
											H.warrant = TRUE
											SEND_SOUND(H, sound('code/modules/wod13/sounds/suspect.ogg', 0, 0, 75))
											to_chat(H, "<span class='userdanger'><b>POLICE ASSAULT IN PROGRESS</b></span>")
										else
											SEND_SOUND(H, sound('code/modules/wod13/sounds/sus.ogg', 0, 0, 75))
											to_chat(H, "<span class='userdanger'><b>SUSPICIOUS ACTION (corpse)</b></span>")
			for(var/obj/item/I in H.contents)
				if(I)
					if(I.masquerade_violating)
						if(I.loc == H)
							var/obj/item/card/id/id_card = H.get_idcard(FALSE)
							if(!istype(id_card, /obj/item/card/id/police))
								if(H.CheckEyewitness(H, H, 7, FALSE))
									if(H.last_loot_check+50 <= world.time)
										H.last_loot_check = world.time
										H.last_nonraid = world.time
										H.killed_count = H.killed_count+1
										if(!H.warrant)
											if(H.killed_count >= 5)
												H.warrant = TRUE
												SEND_SOUND(H, sound('code/modules/wod13/sounds/suspect.ogg', 0, 0, 75))
												to_chat(H, "<span class='userdanger'><b>POLICE ASSAULT IN PROGRESS</b></span>")
											else
												SEND_SOUND(H, sound('code/modules/wod13/sounds/sus.ogg', 0, 0, 75))
												to_chat(H, "<span class='userdanger'><b>SUSPICIOUS ACTION (equipment)</b></span>")
	if(H.key && H.stat != DEAD)
		var/datum/preferences/P = GLOB.preferences_datums[ckey(H.key)]
		if(P)
//			if(P.humanity != H.humanity)
//				P.humanity = H.humanity
//				P.save_preferences()
//				P.save_character()
			if(P.masquerade != H.masquerade)
				P.masquerade = H.masquerade
				P.save_preferences()
				P.save_character()
//			if(H.last_experience+600 <= world.time)
//				var/addd = 5
//				if(H.mind)
//					if(!H.JOB)
//						H.JOB = SSjob.GetJob(H.mind.assigned_role)
//						if(H.JOB)
//							addd = H.JOB.experience_addition
//				P.exper = min(calculate_mob_max_exper(H), P.exper+addd+H.experience_plus)
//				P.save_preferences()
//				P.save_character()
//				H.last_experience = world.time
			if(H.humanity <= 2)
				if(prob(5))
					if(prob(50))
						H.Stun(20)
						to_chat(H, "<span class='warning'>You stop in fear and remember your crimes against humanity...</span>")
						H.emote("cry")
					else
						to_chat(H, "<span class='warning'>You feel the rage rising as your last sins come to your head...</span>")
						H.drop_all_held_items()
						H.emote("scream")
		if(last_vitae+3000 < world.time)
			last_vitae = world.time
			if(H.bloodpool > 1)
				H.bloodpool = max(1, H.bloodpool-1)
			else
				if(prob(20))
					to_chat(H, "<span class='userdanger'><b>I NEED VITAE...</b></span>")
					H.Stun(10)

/mob/living
	var/last_bloodpool_restore = 0

/datum/species/human/spec_life(mob/living/carbon/human/H)
	. = ..()
	if(HAS_TRAIT(H, TRAIT_UNMASQUERADE))
		if(H.CheckEyewitness(H, H, 7, FALSE))
			H.AdjustMasquerade(-1)
	if(istype(get_area(H), /area/vtm))
		var/area/vtm/V = get_area(H)
		if(V.zone_type == "masquerade" && V.upper)
			if(H.pulling)
				if(ishuman(H.pulling))
					var/mob/living/carbon/human/pull = H.pulling
					if(pull.stat == 4)
						var/obj/item/card/id/id_card = H.get_idcard(FALSE)
						if(!istype(id_card, /obj/item/card/id/clinic) && !istype(id_card, /obj/item/card/id/police))
							if(H.CheckEyewitness(H, H, 7, FALSE))
								if(H.last_loot_check+50 <= world.time)
									H.last_loot_check = world.time
									H.last_nonraid = world.time
									H.killed_count = H.killed_count+1
									if(!H.warrant)
										if(H.killed_count >= 5)
											H.warrant = TRUE
											SEND_SOUND(H, sound('code/modules/wod13/sounds/suspect.ogg', 0, 0, 75))
											to_chat(H, "<span class='userdanger'><b>POLICE ASSAULT IN PROGRESS</b></span>")
										else
											SEND_SOUND(H, sound('code/modules/wod13/sounds/sus.ogg', 0, 0, 75))
											to_chat(H, "<span class='userdanger'><b>SUSPICIOUS ACTION (corpse)</b></span>")
			for(var/obj/item/I in H.contents)
				if(I)
					if(I.masquerade_violating)
						if(I.loc == H)
							var/obj/item/card/id/id_card = H.get_idcard(FALSE)
							if(!istype(id_card, /obj/item/card/id/police))
								if(H.CheckEyewitness(H, H, 7, FALSE))
									if(H.last_loot_check+50 <= world.time)
										H.last_loot_check = world.time
										H.last_nonraid = world.time
										H.killed_count = H.killed_count+1
										if(!H.warrant)
											if(H.killed_count >= 5)
												H.warrant = TRUE
												SEND_SOUND(H, sound('code/modules/wod13/sounds/suspect.ogg', 0, 0, 75))
												to_chat(H, "<span class='userdanger'><b>POLICE ASSAULT IN PROGRESS</b></span>")
											else
												SEND_SOUND(H, sound('code/modules/wod13/sounds/sus.ogg', 0, 0, 75))
												to_chat(H, "<span class='userdanger'><b>SUSPICIOUS ACTION (equipment)</b></span>")
	if(H.last_bloodpool_restore+600 <= world.time)
		H.last_bloodpool_restore = world.time
		H.bloodpool = min(H.maxbloodpool, H.bloodpool+1)

//	if(H.key && H.stat != DEAD)
//		var/datum/preferences/P = GLOB.preferences_datums[ckey(H.key)]
//		if(P)
//			if(P.humanity != H.humanity)
//				P.humanity = H.humanity
//				P.save_preferences()
//				P.save_character()
//			if(H.last_experience+600 <= world.time)
//				P.exper = min(calculate_mob_max_exper(H), P.exper+5+H.experience_plus)
//				P.save_preferences()
//				P.save_character()
//				H.last_experience = world.time

//			if(H.humanity <= 2)
//				if(prob(5))
//					if(prob(50))
//						H.Stun(10)
//						to_chat(H, "<span class='warning'>You stop in fear and remember your crimes against humanity...</span>")
//						H.emote("cry")
//					else
//						to_chat(H, "<span class='warning'>You feel the rage rising as your last sins come to your head...</span>")
//						H.drop_all_held_items()
//						H.emote("scream")

/datum/species/garou/spec_life(mob/living/carbon/human/H)
	. = ..()
	if(HAS_TRAIT(H, TRAIT_UNMASQUERADE))
		if(H.CheckEyewitness(H, H, 7, FALSE))
			H.adjust_veil(-1)
	if(istype(get_area(H), /area/vtm))
		var/area/vtm/V = get_area(H)
		if(V.zone_type == "masquerade" && V.upper)
			if(H.pulling)
				if(ishuman(H.pulling))
					var/mob/living/carbon/human/pull = H.pulling
					if(pull.stat == 4)
						var/obj/item/card/id/id_card = H.get_idcard(FALSE)
						if(!istype(id_card, /obj/item/card/id/clinic) && !istype(id_card, /obj/item/card/id/police))
							if(H.CheckEyewitness(H, H, 7, FALSE))
								if(H.last_loot_check+50 <= world.time)
									H.last_loot_check = world.time
									H.last_nonraid = world.time
									H.killed_count = H.killed_count+1
									if(!H.warrant)
										if(H.killed_count >= 5)
											H.warrant = TRUE
											SEND_SOUND(H, sound('code/modules/wod13/sounds/suspect.ogg', 0, 0, 75))
											to_chat(H, "<span class='userdanger'><b>POLICE ASSAULT IN PROGRESS</b></span>")
										else
											SEND_SOUND(H, sound('code/modules/wod13/sounds/sus.ogg', 0, 0, 75))
											to_chat(H, "<span class='userdanger'><b>SUSPICIOUS ACTION (corpse)</b></span>")
			for(var/obj/item/I in H.contents)
				if(I)
					if(I.masquerade_violating)
						if(I.loc == H)
							var/obj/item/card/id/id_card = H.get_idcard(FALSE)
							if(!istype(id_card, /obj/item/card/id/police))
								if(H.CheckEyewitness(H, H, 7, FALSE))
									if(H.last_loot_check+50 <= world.time)
										H.last_loot_check = world.time
										H.last_nonraid = world.time
										H.killed_count = H.killed_count+1
										if(!H.warrant)
											if(H.killed_count >= 5)
												H.warrant = TRUE
												SEND_SOUND(H, sound('code/modules/wod13/sounds/suspect.ogg', 0, 0, 75))
												to_chat(H, "<span class='userdanger'><b>POLICE ASSAULT IN PROGRESS</b></span>")
											else
												SEND_SOUND(H, sound('code/modules/wod13/sounds/sus.ogg', 0, 0, 75))
												to_chat(H, "<span class='userdanger'><b>SUSPICIOUS ACTION (equipment)</b></span>")
	if(H.last_bloodpool_restore+600 <= world.time)
		H.last_bloodpool_restore = world.time
		H.bloodpool = min(H.maxbloodpool, H.bloodpool+1)
