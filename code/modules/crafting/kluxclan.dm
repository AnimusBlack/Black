
/obj/item/weapon/shard/attackby(obj/item/O as obj, mob/user as mob)
	if (istype(O, /obj/item/weapon/bedsheet))
		usr << "You start cutting bedsheet..."
		sleep(50)
		new /obj/item/clothing/head/kkc( get_turf(usr.loc), 2 )
		usr << "\blue You make a Klux Clan mask!"
		user.visible_message("\red [user] cut bedsheet into mask.")
		del(O)
		return

/obj/item/weapon/scalpel/attackby(obj/item/O as obj, mob/user as mob)
	if (istype(O, /obj/item/weapon/bedsheet))
		usr << "You start cutting bedsheet..."
		sleep(25)
		new /obj/item/clothing/head/kkc( get_turf(usr.loc), 2 )
		usr << "\blue You make a Klux Clan mask!"
		user.visible_message("\red [user] cut bedsheet into mask.")
		del(O)
		return

/obj/item/weapon/kitchenknife/attackby(obj/item/O as obj, mob/user as mob)
	if (istype(O, /obj/item/weapon/bedsheet))
		usr << "You start cutting bedsheet..."
		sleep(35)
		new /obj/item/clothing/head/kkc( get_turf(usr.loc), 2 )
		usr << "\blue You make a Klux Clan mask!"
		user.visible_message("\red [user] cut bedsheet into mask.")
		del(O)
		return