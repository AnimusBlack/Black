/datum/job/assistant
	title = "Assistant"
	flag = ASSISTANT
	department_flag = CIVILIAN
	faction = "Station"
	total_positions = -1
	spawn_positions = -1
	supervisors = "absolutely everyone"
	selection_color = "#dddddd"
	access = list(access_maint_tunnels)
	minimal_access = list(access_maint_tunnels)
	alt_titles = list("Technical Assistant","Medical Intern","Research Assistant","Security Cadet")

/datum/job/assistant/equip(var/mob/living/carbon/human/H)
	if(!H)	return 0
	H.equip_to_slot_or_del(new /obj/item/clothing/under/color/grey(H), slot_w_uniform)
	H.equip_to_slot_or_del(new /obj/item/clothing/shoes/black(H), slot_shoes)
	H.equip_to_slot_or_del(new /obj/item/weapon/storage/wallet/random(H.back), slot_r_hand)
	return 1
/*
/datum/job/assistant/get_access()
	if(config.assistant_maint)
		return list(access_maint_tunnels)
	else
		return list()
*/