/****************************************************
				INTERNAL ORGANS
****************************************************/

/mob/living/carbon/human/var/list/internal_organs = list()



/datum/organ/internal
	// amount of damage to the organ
	var/damage = 0
	var/min_bruised_damage = 10
	var/min_broken_damage = 30
	var/parent_organ = "chest"

/datum/organ/internal/proc/is_bruised()
	return damage >= min_bruised_damage

/datum/organ/internal/proc/is_broken()
	return damage >= min_broken_damage


/datum/organ/internal/New(mob/living/carbon/human/H)
	..()
	var/datum/organ/external/E = H.organs_by_name[src.parent_organ]
	if(E.internal_organs == null)
		E.internal_organs = list()
	E.internal_organs += src
	H.internal_organs[src.name] = src
	src.owner = H

/datum/organ/internal/proc/take_damage(amount, var/silent=0)
	src.damage += amount

	var/datum/organ/external/parent = owner.get_organ(parent_organ)
	if (!silent)
		owner.custom_pain("Something inside your [parent.display_name] hurts a lot.", 1)

/****************************************************
				INTERNAL ORGANS DEFINES
****************************************************/

/datum/organ/internal/heart
	name = "heart"
	parent_organ = "chest"
	var/heartrate = 80			//Heartrate
								//Value depends on a multitude of factors.
								//The value itself has an effect on the blood pressure.
								//If this is lower than 60,
								//If this is 0, SEVERE oxyloss and brainloss happen.

	var/arrhythmia = 0		//Arrhythmia
							//Can be caused by genetic traits and outside influences.
							//Every sort of arrhythmia is different
							//1 - Asystole: Inevitable death.
							//2 - Pulseless electrical activity: Results in heavy damage, asystole usually follows if not treated.
							//3 - Ventricular Fibrillation: Results in heavy damage, asystole usually follows if not treated.


	process()
		if (owner.stat == DEAD)
			heartrate = 0
			return heartrate

		if (owner.bodytemperature <= 170)
			heartrate--
			return heartrate


		if (damage > 50)
			owner.oxyloss += 300
			owner.death()
			heartrate = 0
			return heartrate

		if (heartrate < 5)
			if (!arrhythmia)
				arrhythmia = 1
		if (heartrate > 160)
			damage++
			if (prob(damage) || heartrate > 200)
				arrhythmia = 1


		if(owner.status_flags & FAKEDEATH)
			heartrate = 0   //pretend that we're dead. unlike actual death, can be inflienced by meds

		for(var/datum/reagent/R in owner:reagents.reagent_list) //This will be better, i guess. - Rel
			if(R.cardic)
				heartrate = max(heartrate + R.cardic,0)
			else
				//slowly returns to normal
				if (heartrate > 0)
					if (heartrate < 80)
						heartrate++
					else if (heartrate > 80)
						heartrate--
						//sleep(20)
				else
					if (arrhythmia == 0)
						heartrate++

		handle_arrhythmia()


	proc/handle_arrhythmia()                          //Why not? - Rel
		var/datum/reagents/blood/B = owner:vessel
		//Epinephrine, ha ha ha!
		switch(arrhythmia)
			if(1) //Asystole, or flatline
				//PERSON DIES
				heartrate = 0
				owner.losebreath++
				owner.paralysis += 5
				B.systolic = 0
				if(prob(50) && !owner.reagents.has_reagent("polyadrenalobin"))
					owner.oxyloss += 300
					owner.death()
					return heartrate
				arrhythmia = 0
				//DEAD DEAD DEAD DEAD DEEEED!
			if(2) //Pulseless Electrical Activity
				//PERSON IS KIND OF SCREWED
				heartrate = 0
				owner.losebreath++
				owner.paralysis += 5
				B.systolic = 0
				if(prob(10))
					arrhythmia = 3
				if(prob(10))
					arrhythmia = 1
			if(3) //Ventricular Fibrillation
				//Still saveable
				heartrate = 0
				owner.losebreath++
				owner.paralysis += 5
				if(prob(2)) //Flatline the fucker
					arrhythmia = 1
				if(prob(25)) //PEA
					arrhythmia = 2
				if(B.systolic > 100)
					B.systolic = 50
				if(B.systolic > 10)
					B.systolic -= 10
				if(prob(20))
					arrhythmia = 0

		return heartrate


/datum/organ/internal/lungs
	name = "lungs"
	parent_organ = "chest"

	process()
		if(is_bruised())
			if(prob(2))
				spawn owner.emote("me", 1, "coughs up blood!")
				owner.drip(10)
			if(prob(4))
				spawn owner.emote("me", 1, "gasps for air!")
				owner.losebreath += 5

/datum/organ/internal/liver
	name = "liver"
	parent_organ = "chest"
	var/process_accuracy = 10

	process()
		if(owner.life_tick % process_accuracy == 0)
			if(src.damage < 0)
				src.damage = 0

			//High toxins levels are dangerous
			if(owner.getToxLoss() >= 60 && !owner.reagents.has_reagent("anti_toxin"))
				//Healthy liver suffers on its own
				if (src.damage < min_broken_damage)
					src.damage += 0.1 * process_accuracy
				//Damaged one shares the fun
				else
					var/victim = pick(owner.internal_organs)
					var/datum/organ/internal/O = owner.internal_organs[victim]
					O.damage += 0.1  * process_accuracy

			//Detox can heal small amounts of damage
			if (src.damage && src.damage < src.min_bruised_damage && owner.reagents.has_reagent("anti_toxin"))
				src.damage -= 0.2 * process_accuracy

			// Damaged liver means some chemicals are very dangerous
			if(src.damage >= src.min_bruised_damage)
				for(var/datum/reagent/R in owner.reagents.reagent_list)
					// Ethanol and all drinks are bad
					if(istype(R, /datum/reagent/ethanol))
						owner.adjustToxLoss(0.1 * process_accuracy)

				// Can't cope with toxins at all
				for(var/toxin in list("toxin", "plasma", "sacid", "pacid", "cyanide", "lexorin", "amatoxin", "chloralhydrate", "carpotoxin", "zombiepowder", "mindbreaker"))
					if(owner.reagents.has_reagent(toxin))
						owner.adjustToxLoss(0.3 * process_accuracy)

/datum/organ/internal/kidney
	name = "kidney"
	parent_organ = "chest"

/datum/organ/internal/brain
	name = "brain"
	parent_organ = "head"