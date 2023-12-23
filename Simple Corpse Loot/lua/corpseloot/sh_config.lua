CorpseLoot.Config = {
    Button_Loot = IN_USE;
    DragForce = 10;
    Button_Drag = KEY_T;
	DropCloth = "/dropcloth";
   
    BlackList = {
        ["weapon_example"] = true;
    };

	Messages = {
		Prefix = {Color(100, 255, 100); "[Loot]"; Color(255, 0, 0); " "; Color(255, 255, 255)};
		[1] = {"This corpse is already looting - someone else!"};
		[2] = {"Someone has already taken this weapon!"};
		[3] = {"You've already taken your clothes!"};
        [4] = {"You changed your clothes!"};
        [5] = {"You threw away your clothes!"};
	};
}