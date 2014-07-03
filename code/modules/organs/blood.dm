/****************************************************
				BLOOD SYSTEM
****************************************************/
//Blood levels
var/const/BLOOD_VOLUME_SAFE = 501
var/const/BLOOD_VOLUME_OKAY = 336
var/const/BLOOD_VOLUME_BAD = 224
var/const/BLOOD_VOLUME_SURVIVE = 122

/mob/living/carbon/human/var/datum/reagents/blood/vessel	//Container for blood and BLOOD ONLY. Do not transfer other chems here.
/mob/living/carbon/human/var/pale = 0			//Should affect how mob sprite is drawn, but currently doesn't.

/datum/reagents/blood
/*	var/bleeding = 0
	var/bloodloss = 0
	var/bloodcalculation1 = 0
	var/countdown = 0
	var/totalbloodloss = 0
	//used in deciding how fast people bleed 5 is normal, an increase
	//increases the thickness making people bleed slower, above 8 starts
	//doing oxy and brute damage slowly
	//and below 5 increases the amount of bloodloss quite fast

	var/bloodthickness = 5 //Time of thin blood

	//Bloodpressure
	//Diastolic doesn't have any effect but is just there for IMMERSION.
	//Hypertension can result in a heart attack
*/
	var/systolic = 100
//	var/circ_pressure_mod = 0

	//Thrombosis
	//When you get thrombosis, it rolls for which type.
	//1 - Peripheral(leg) - 20%
	//2 - Peripheral(arm) - 20%
	//3 - Pulmonary Embolism - 25%
	//4 - Cerebrovascular Accident(Stroke) - 20%
	//5 - Myocardial Infarction - 15%
	//Severity can range from 0 to 4
	//0 is no thrombus, 4 is full blockage.

	var/thrombosis = 0
	var/thrombosis_severity = 0

	//Used in deciding how fast and if bleeding heals.
	//Higher than 7 brings a risk of thrombosis.

//	var/blood_clot = 5

	//Temporarily stops all bleeding, DO NOT LEAVE THIS SET TO 1

//	var/bloodstopper = 0

//Initializes blood vessels
/mob/living/carbon/human/proc/make_blood()
	if (vessel)
		return
	vessel = new/datum/reagents/blood(1000)
	vessel.my_atom = src
	vessel.add_reagent("blood",560)
	spawn(1)
		fixblood()

//Resets blood data
/mob/living/carbon/human/proc/fixblood()
	for(var/datum/reagent/blood/B in vessel.reagent_list)
		if(B.id == "blood")
			B.data = list(	"donor"=src,"viruses"=null,"blood_DNA"=dna.unique_enzymes,"blood_type"=dna.b_type,	\
							"resistances"=null,"trace_chem"=null, "virus2" = null, "antibodies" = null)

// Takes care blood loss and regeneration
/mob/living/carbon/human/proc/handle_blood()
	vessel.handle_bloodpressure()

	if(stat != DEAD && bodytemperature >= 170)	//Dead or cryosleep people do not pump the blood.

		var/blood_volume = round(vessel.get_reagent_amount("blood"))

		//Blood regeneration if there is some space
		if(blood_volume < 560 && blood_volume)
			var/datum/reagent/blood/B = locate() in vessel.reagent_list //Grab some blood
			if(B) // Make sure there's some blood at all
				if(B.data["donor"] != src) //If it's not theirs, then we look for theirs
					for(var/datum/reagent/blood/D in vessel.reagent_list)
						if(D.data["donor"] == src)
							B = D
							break

				B.volume += 0.1 // regenerate blood VERY slowly
				if (reagents.has_reagent("nutriment"))	//Getting food speeds it up
					B.volume += 0.4
					reagents.remove_reagent("nutriment", 0.1)
				if (reagents.has_reagent("iron"))	//Hematogen candy anyone?
					B.volume += 0.8
					reagents.remove_reagent("iron", 0.1)

		// Damaged heart virtually reduces the blood volume, as the blood isn't
		// being pumped properly anymore.
		var/datum/organ/internal/heart/heart = internal_organs["heart"]
		switch(heart.damage)
			if(5 to 10)
				blood_volume -= 8
			if(11 to 20)
				blood_volume -= 5
			if(21 to INFINITY)
				blood_volume -= 3

		//Effects of bloodloss
		switch(blood_volume)
			if(700 to 1.#INF)
				gib()
			if(BLOOD_VOLUME_SAFE to 700)
				if(pale)
					pale = 0
					update_body()
			if(BLOOD_VOLUME_OKAY to BLOOD_VOLUME_SAFE)
				if(!pale)
					pale = 1
					update_body()
					var/word = pick("dizzy","woosey","faint")
					src << "\red You feel [word]"
				if(prob(1))
					var/word = pick("dizzy","woosey","faint")
					src << "\red You feel [word]"
				if(oxyloss < 20)
					oxyloss += 3
			if(BLOOD_VOLUME_BAD to BLOOD_VOLUME_OKAY)
				if(!pale)
					pale = 1
					update_body()
				eye_blurry += 6
				if(oxyloss < 50)
					oxyloss += 10
				oxyloss += 1
				if(prob(15))
					Paralyse(rand(1,3))
					var/word = pick("dizzy","woosey","faint")
					src << "\red You feel extremely [word]"
			if(BLOOD_VOLUME_SURVIVE to BLOOD_VOLUME_BAD)
				eye_blurry += 6
				oxyloss += 8
				if(heart.arrhythmia == 0)
					heart.arrhythmia = 3 //Ventricular Fibrillation
				if(prob(15))
					var/word = pick("dizzy","woosey","faint")
					src << "\red You feel extremely [word]"
			if(-1.#INF to BLOOD_VOLUME_SURVIVE)
				// There currently is a strange bug here. If the mob is not below -100 health
				// when death() is called, apparently they will be just fine, and this way it'll
				// spam deathgasp. Adjusting toxloss ensures the mob will stay dead.
				oxyloss += 300 // just to be safe!
				death()

		vessel.handle_thrombosis()

		// Without enough blood you slowly go hungry.
		if(blood_volume < BLOOD_VOLUME_SAFE)
			if(nutrition >= 300)
				nutrition -= 3
			else if(nutrition >= 200)
				nutrition -= 1


		if (!blood_volume)
			return
			//No blood - no bleeding. - Rel

		//Bleeding out
		var/blood_max = 0
		for(var/datum/organ/external/temp in organs)
			if(!(temp.status & ORGAN_BLEEDING) || temp.status & ORGAN_ROBOT)
				continue
			for(var/datum/wound/W in temp.wounds)
				if(W.bleeding())
					blood_max += W.damage / 4
				if(W.internal && !W.is_treated())
					vessel.remove_reagent("blood",0.07 * W.damage)

			if(temp.status & ORGAN_DESTROYED && !(temp.status & ORGAN_GAUZED) && !temp.amputated)
				blood_max += 20 //Yer missing a fucking limb.
			if (temp.open)
				blood_max += 2  //Yer stomach is cut open


		drip(blood_max)

//Makes a blood drop, leaking certain amount of blood from the mob
/mob/living/carbon/human/proc/drip(var/amt as num)
	if(!amt)
		return

	var/blood_volume = round(vessel.get_reagent_amount("blood"))
	if (!blood_volume)
		return

	var/amm = 0.1 * amt
	var/turf/T = get_turf(src)
	var/list/obj/effect/decal/cleanable/blood/drip/nums = list()
	var/list/iconL = list("1","2","3","4","5")

	vessel.remove_reagent("blood",amm)

	for(var/obj/effect/decal/cleanable/blood/drip/G in T)
		nums += G
		iconL.Remove(G.icon_state)

	if (nums.len < 5)
		var/obj/effect/decal/cleanable/blood/drip/this = new(T)
		this.icon_state = pick(iconL)
		this.blood_DNA = list()
		this.blood_DNA[dna.unique_enzymes] = dna.b_type
	else
		for(var/obj/effect/decal/cleanable/blood/drip/G in nums)
			del G
		T.add_blood(src)

/****************************************************
				BLOOD TRANSFERS
****************************************************/

//Gets blood from mob to the container, preserving all data in it.
/mob/living/carbon/proc/take_blood(obj/item/weapon/reagent_containers/container, var/amount)
	var/datum/reagent/B = get_blood(container.reagents)
	if(!B) B = new /datum/reagent/blood
	B.holder = container
	B.volume += amount

	//set reagent data
	B.data["donor"] = src
	if (!B.data["virus2"])
		B.data["virus2"] = list()
	B.data["virus2"] |= virus_copylist(src.virus2)
	B.data["antibodies"] = src.antibodies
	B.data["blood_DNA"] = copytext(src.dna.unique_enzymes,1,0)
	if(src.resistances && src.resistances.len)
		if(B.data["resistances"])
			B.data["resistances"] |= src.resistances.Copy()
		else
			B.data["resistances"] = src.resistances.Copy()
	B.data["blood_type"] = copytext(src.dna.b_type,1,0)

	var/list/temp_chem = list()
	for(var/datum/reagent/R in src.reagents.reagent_list)
		temp_chem += R.id
		temp_chem[R.id] = R.volume
	B.data["trace_chem"] = list2params(temp_chem)
	return B

//For humans, blood does not appear from blue, it comes from vessels.
/mob/living/carbon/human/take_blood(obj/item/weapon/reagent_containers/container, var/amount)
	if(vessel.get_reagent_amount("blood") < amount)
		return null
	. = ..()
	vessel.remove_reagent("blood",amount) // Removes blood if human

//Transfers blood from container ot vessels
/mob/living/carbon/proc/inject_blood(obj/item/weapon/reagent_containers/container, var/amount)
	var/datum/reagent/blood/injected = get_blood(container.reagents)
	if (!injected)
		return
	src.virus2 |= virus_copylist(injected.data["virus2"])
	if (injected.data["antibodies"] && prob(5))
		antibodies |= injected.data["antibodies"]
	var/list/chems = list()
	chems = params2list(injected.data["trace_chem"])
	for(var/C in chems)
		src.reagents.add_reagent(C, (text2num(chems[C]) / 560) * amount)//adds trace chemicals to owner's blood
	reagents.update_total()

	container.reagents.remove_reagent("blood", amount)

//Transfers blood from container ot vessels, respecting blood types compatability.
/mob/living/carbon/human/inject_blood(obj/item/weapon/reagent_containers/container, var/amount)
	var/datum/reagent/blood/our = get_blood(vessel)
	var/datum/reagent/blood/injected = get_blood(container.reagents)
	if (!injected || !our)
		return
	if(blood_incompatible(injected.data["blood_type"],our.data["blood_type"]) )
		reagents.add_reagent("toxin",amount * 0.5)
		reagents.update_total()
	else
		vessel.add_reagent("blood", amount, injected.data)
		vessel.update_total()
	..()

//Gets human's own blood.
/mob/living/carbon/proc/get_blood(datum/reagents/container)
	var/datum/reagent/blood/res = locate() in container.reagent_list //Grab some blood
	if(res) // Make sure there's some blood at all
		if(res.data["donor"] != src) //If it's not theirs, then we look for theirs
			for(var/datum/reagent/blood/D in container.reagent_list)
				if(D.data["donor"] == src)
					return D
	return res

proc/blood_incompatible(donor,receiver)
	if(!donor || !receiver) return 0
	var
		donor_antigen = copytext(donor,1,lentext(donor))
		receiver_antigen = copytext(receiver,1,lentext(receiver))
		donor_rh = (findtext(donor,"+")>0)
		receiver_rh = (findtext(receiver,"+")>0)
	if(donor_rh && !receiver_rh) return 1
	switch(receiver_antigen)
		if("A")
			if(donor_antigen != "A" && donor_antigen != "O") return 1
		if("B")
			if(donor_antigen != "B" && donor_antigen != "O") return 1
		if("O")
			if(donor_antigen != "O") return 1
		//AB is a universal receiver.
	return 0

/********************************************************
			BLOOD PRESSURE
***********************************************************/

/datum/reagents/blood/proc/handle_bloodpressure()
	calculate_bloodpressure()

	switch(systolic)
		if(-INFINITY to 4) //Lol no heartrate I guess hur hur
			my_atom:oxyloss += 15
			//bloodstopper = 1
		if(5 to 49) //Severe Hypotension
			if(prob(40))
				my_atom:paralysis += 10
			my_atom:oxyloss += 2
			//bloodstopper = 1
		if(50 to 79) //Light Hypotension
			//?
		if(80 to 139) //Normal
			//?
		if(140 to 179) //Hypertension
			if(prob(20))
				src << "\red You have a seizure!"
				for(var/mob/O in viewers(src, null))
					if(O == src)
						continue
					O.show_message(text("\red <B>[src] starts having a seizure!"), 1)
				//my_atom:paralysis = max(10, paralysis)
				my_atom:make_jittery(1000)
			if(!thrombosis)
				if(prob(70))
					give_thrombosis()
		if(180 to INFINITY) //Death
			my_atom:oxyloss += 300
			my_atom:death()




/datum/reagents/blood/proc/calculate_bloodpressure()
	var/datum/organ/internal/heart/heart = my_atom:internal_organs["heart"]
	var/blood_volume = round(get_reagent_amount("blood"))

	if (!heart.heartrate)
		systolic = 0
		return
	systolic = max((blood_volume/560) * ((heart.heartrate - 20) * 2),0) //Base
/*	systolic += circ_pressure_mod
	if(circ_pressure_mod > 0)
		circ_pressure_mod--
	else if(circ_pressure_mod < 0)
		circ_pressure_mod++
	systolic += (bloodthickness - 5)*10
*/

/datum/reagents/blood/proc/handle_thrombosis()
	var/datum/organ/internal/heart/heart = my_atom:internal_organs["heart"]
	var/S = thrombosis_severity

	if(S==0)
		thrombosis = 0
	switch(thrombosis)
		if(0)
			thrombosis_severity = 0
		if(1)
			switch(S)
				if(1 to 2)
					if(prob(70))
						thrombosis_severity+=1
					if(prob(5))
						my_atom:oxyloss += 1
				if(2 to 3)
					if(prob(100))
						thrombosis = 0
						give_thrombosis()
					my_atom:oxyloss += 1
		if(2)
			switch(S)
				if(1 to 2)
					if(prob(70))
						thrombosis_severity+=1
					if(prob(5))
						my_atom:oxyloss += 1
				if(2 to 3)
					if(prob(100))
						thrombosis = 0
						give_thrombosis()
					my_atom:oxyloss += 1
		if(3) //Pulmonary Embolism
			switch(S)
				if(1 to 2)
					my_atom:drowsyness=5
					if(prob(10))
						thrombosis_severity+=1
					if(prob(5))
						my_atom:oxyloss += 2
				if(3)
					my_atom:drowsyness=10
					if(prob(20))
						thrombosis_severity+=1
					my_atom:brainloss += 2
					my_atom:oxyloss += 1
					if(prob(5))
						my_atom:losebreath+=1
				if(4)
					//Let the arrhythmia do the work.
					heart.arrhythmia = 2 //Pulseless electrical activity
					//Yes, the person most likely dies, unless he was in the medbay.
		if(4) //CVA(Stroke)
			switch(S)
				if(1 to 2)
					my_atom:drowsyness=10
					if(prob(10))
						thrombosis_severity+=1
					if(prob(5))
						my_atom:brainloss += 2
						my_atom:oxyloss += 1
					if(S==2)
						my_atom:eye_blurry += 1
				if(3)
					my_atom:drowsyness=20
					if(prob(20))
						thrombosis_severity+=1
					my_atom:brainloss += 2
					my_atom:oxyloss += 1
					my_atom:paralysis++
				if(4)
					my_atom:drowsyness=30
					my_atom:brainloss += 15
					my_atom:oxyloss += 2
					my_atom:eye_blind += 1
					my_atom:paralysis++
					my_atom:losebreath += 1
					if(prob(15))
						heart.arrhythmia = 1 //DIE
		if(5) //Myocardial Infarction
			switch(S)
				if(1 to 2)
					my_atom:eye_blurry += 1
					my_atom:drowsyness+=5
					if(prob(10))
						thrombosis_severity+=1
					if(prob(5))
						my_atom:brainloss += 5
						my_atom:oxyloss += 5
						if(heart.heartrate > 40)
							heart.heartrate -= 5
				if(3)
					if(prob(20))
						thrombosis_severity+=1
					my_atom:brainloss += 5
					my_atom:oxyloss += 2
					my_atom:paralysis++
					my_atom:eye_blind += 1
					my_atom:losebreath += 1
					my_atom:paralysis += 1
				if(4)
					//Let the arrhythmia do the work.
					heart.arrhythmia = 2 //Pulseless electrical activity
					//Yes, the person most likely dies, unless he was in the medbay.


/datum/reagents/blood/proc/give_thrombosis()
	//Already has thrombosis? Increase severity
	if(thrombosis > 0)
		thrombosis_severity += 1
	else
		thrombosis_severity = prob(2)?1:2
	//Roll for type
	if(!thrombosis)
		if(prob(30))
		{
			thrombosis = 1 //Leg
			switch(thrombosis_severity)
				if(1 to 2)
					src << "\red Your legs feel tingly."
				if(3 to 4)
					src << "\red You legs feel numb."
		}
		else if(prob(30))
		{
			thrombosis = 2 //Arm
			switch(thrombosis_severity)
				if(1 to 2)
					src << "\red Your arms feel tingly."
				if(3 to 4)
					src << "\red You arms feel numb."
		}
		else if(prob(25))
		{
			thrombosis = 3 //Pulmonary Embolism
			switch(thrombosis_severity)
				if(1)
					src << "\red You have difficulty breathing"
				if(2)
					src << "\red You can barely breathe"
		}
		else if(prob(10))
		{
			thrombosis = 4 //CVA(Stroke)
			switch(thrombosis_severity)
				if(1 to 2)
					src << "\red You feel slow and clumsy."
		}
		else
		{
			thrombosis = 5 //Myocardial Infarction
			switch(thrombosis_severity)
				if(1 to 2)
					src << "\red You feel a sharp pain in your chest"
		}


