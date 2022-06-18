// show, hide ond switch the hud panels

// This file is in the publich domain. You can do whatever you wish.

integer HUD_PLANE_CHANGED = 83759837;

integer hudShown;
integer hudActive;

list hudXOffsetRange =  [0.3, 0.7, 1.3, 1.7, 2.3];
list backXOffsetRange = [2.3, 2.7];

list hudSwitchButtonsOn =  [<-0.01260, 0.163933, 0.13405>, <0.01630, 0.120813, 0.143066>, <0.01605, 0.085498, 0.143073>, <0.01582, 0.050183, 0.143066>,
                            <0.01630, 0.120813, 0.125153>];
list hudSwitchButtonsOff = [<-0.01260, 0.163933, 0.13405>, <0.01630, 0.163933, 0.13405>, <0.01630, 0.163933, 0.13405>, <0.01630, 0.163933, 0.13405>, 
                            <0.01630, 0.163933, 0.13405>];
list hudRightButtonsOff =  [<-0.01260, -0.163933, 0.13405>, <0.01630, -0.163933, 0.13405>, <0.01630, -0.163933, 0.13405>, <0.01630, -0.163933, 0.13405>,
                            <0.01141, -0.163933, 0.13405>];

/*
list hudXOffsetRange =  [0.3, 0.7, 1.3, 1.7, 2.3, 2.7, 3.3];
list backXOffsetRange = [3.3, 3.7, 4.3, 4.7, 5.3];

list hudSwitchButtonsOn =  [<-0.01260, 0.163933, 0.13405>, <0.01630, 0.120813, 0.143066>, <0.01605, 0.085498, 0.143073>, <0.01582, 0.050183, 0.143066>,
                            <0.01630, 0.120813, 0.125153>, <0.01630, 0.085498, 0.125153>];
list hudSwitchButtonsOff = [<-0.01260, 0.163933, 0.13405>, <0.01630, 0.163933, 0.13405>, <0.01630, 0.163933, 0.13405>, <0.01630, 0.163933, 0.13405>, 
                            <0.01630, 0.163933, 0.13405>, <0.01630, 0.163933, 0.13405>];
list hudRightButtonsOff =  [<-0.01260, -0.163933, 0.13405>, <0.01630, -0.163933, 0.13405>, <0.01630, -0.163933, 0.13405>, <0.01630, -0.163933, 0.13405>,
                            <0.01141, -0.163933, 0.13405>, <0.01630, -0.163933, 0.13405>];
*/
/*                            
list hudSwitchButtonsOn =  [<-0.01260, 0.23419, 0.19150>, <0.01630, 0.17259, 0.20438>, <0.01605, 0.12214, 0.20439>, <0.01582, 0.07169, 0.20438>,
                            <0.01630, 0.17259, 0.17879>, <0.01630, 0.12214, 0.17879>];
list hudSwitchButtonsOff = [<-0.01260, 0.23419, 0.19150>, <0.01630, 0.23419, 0.19150>, <0.01630, 0.23419, 0.19150>, <0.01630, 0.23419, 0.19150>, 
                            <0.01630, 0.23419, 0.19150>, <0.01630, 0.23419, 0.19150>];
list hudRightButtonsOff =  [<-0.01260, -0.23419, 0.19150>, <0.01630, -0.23419, 0.19150>, <0.01630, -0.23419, 0.19150>, <0.01630, -0.23419, 0.19150>,
                            <0.01630, -0.23419, 0.19150>, <0.01630, -0.23419, 0.19150>];
*/

rotation rotShown;
rotation rotShown1;
rotation rotHidden;
rotation rotShownColorPicker;
rotation rotHiddenColorPicker;


debug(string msg) {
    llOwnerSay(llGetScriptName() + ": " + msg);
}

rotateHud(integer hudNumber, integer show) {
    //debug("rotateHud " + (string)hudNumber + " " + (string)show);
    rotation rot;
    rotation rotColorPicker;
    if (show == 1) {
        rot = rotShown1;
        rotColorPicker = rotShownColorPicker;
    } else if (show == 2) {
        rot = rotShown;
        rotColorPicker = rotShownColorPicker;
    } else {
        rot = rotHidden;
        rotColorPicker = rotHiddenColorPicker;
    }

    //float xOffsetMin1 = llList2Float(hudXOffsetRange, hudNumber -1);
    //float xOffsetMax1 = llList2Float(hudXOffsetRange, hudNumber);
    //float xOffsetMin2 = xOffsetMin1;
    //float xOffsetMax2 = xOffsetMax1;
    //if (hudNumber == 4 || hudNumber == 5) {
    //    xOffsetMin2 = llList2Float(hudXOffsetRange, 6 -1);
    //    xOffsetMax2 = llList2Float(hudXOffsetRange, 6);
    //}
    //integer backplane = hudNumber;
    //if (hudNumber == 5) backplane = 4;
    //float xOffsetMin3 = llList2Float(backXOffsetRange, backplane -1);
    //float xOffsetMax3 = llList2Float(backXOffsetRange, backplane);

    float xOffsetMin1 = llList2Float(hudXOffsetRange, hudNumber -1);
    float xOffsetMax1 = llList2Float(hudXOffsetRange, hudNumber);
    float xOffsetMin2 = llList2Float(hudXOffsetRange, 3);
    float xOffsetMax2 = llList2Float(hudXOffsetRange, 4);
    integer backplane = 1;
    float xOffsetMin3 = llList2Float(backXOffsetRange, backplane -1);
    float xOffsetMax3 = llList2Float(backXOffsetRange, backplane);
    
    integer linkNumber;
    for (linkNumber = 0; linkNumber <= llGetNumberOfPrims(); linkNumber++) {
        vector localPos = llList2Vector(llGetLinkPrimitiveParams(linkNumber,[PRIM_POS_LOCAL]),0);
        //debug((string)linkNumber + " " + (string)localPos + " " + (string)xOffsetMin1 + " - " + (string)xOffsetMax1 + " " + (string)xOffsetMin2 + " - " + (string)xOffsetMax2);
        if ((localPos.x > xOffsetMin1 && localPos.x < xOffsetMax1) || (localPos.x > xOffsetMin2 && localPos.x < xOffsetMax2) || (localPos.x > xOffsetMin3 && localPos.x < xOffsetMax3)) {
            if (llGetLinkName(linkNumber) == "Color Picker") {
                //debug("XXXXX Color Picker " + " " + (string)rotColorPicker);
                llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_ROT_LOCAL, rotColorPicker] );
            } else {
                //debug(llGetLinkName(linkNumber) + " " + (string)rot);
                llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_ROT_LOCAL, rot] );
            }            
        }
    }
} 

moveHudButtons() {
    list pos;
    if (hudShown > 0) {
        pos = hudSwitchButtonsOn;
    } else {
        integer attachPoint = llGetAttached();
        if (attachPoint == ATTACH_HUD_TOP_RIGHT || attachPoint == ATTACH_HUD_BOTTOM_RIGHT) {
            pos = hudRightButtonsOff;
        } else {
            pos = hudSwitchButtonsOff;
        }
    }
    integer linkNumber;
    for (linkNumber = 0; linkNumber <= llGetNumberOfPrims(); linkNumber++) {
        string linkName = llGetLinkName(linkNumber);
        list nameParts = llParseString2List(linkName, [" "], []);
        if (llGetListLength(nameParts) == 2 && llList2String(nameParts, 0) == "hudswitch") {
            vector linkPos = llList2Vector(pos, (integer) llList2String(nameParts, 1));
            //debug("hudswitch " + llList2String(nameParts, 1) + " -> " + (string)linkPos);
            llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_POS_LOCAL, linkPos] );
        } else if (llList2String(nameParts, 0) == "huddetach") {
            vector linkPos = llList2Vector(pos, 4); //FIXME
            llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_POS_LOCAL, linkPos] );
        } else if (llList2String(nameParts, 0) == "hudhide") {
            vector linkPos = llList2Vector(pos, 0);
            //debug("hudhide -> " + (string)linkPos);
            llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_POS_LOCAL, linkPos] );
        }
    }
}

position()
{
    integer attachPoint = llGetAttached();
    
    if(attachPoint != 0) {
        integer previousAttachPoint = -999;
    
        integer linkNumber = 0;
        while (previousAttachPoint == -999 && linkNumber <= llGetNumberOfPrims()) {
            string linkName = llGetLinkName(linkNumber);
            if (linkName == "hudhide") {
                previousAttachPoint = llList2Integer(llGetLinkPrimitiveParams(linkNumber, [PRIM_DESC]), 0);
            } else {
                linkNumber++;
            }
        }
        //debug("position " + (string) linkNumber + " " + (string)previousAttachPoint + " -> " + (string)attachPoint);

        if (attachPoint == previousAttachPoint) {
            return;
        }
        
        float y;
        float z;
        vector size = llGetScale(); 
        
        y = size.y / 2.0;
        z = size.z / 2.0 + 0.04;
        //debug("attach " + (string)attachPoint + " " + (string)y + " " + (string)z); 
        
        if (attachPoint == ATTACH_HUD_TOP_LEFT) {
            llSetPos(<0,-y,-z>);
            moveHudButtons();
            llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_DESC, (string)attachPoint]);
        } else if (attachPoint == ATTACH_HUD_TOP_CENTER) {
            llSetPos(<0,0,-z>);
            moveHudButtons();
            llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_DESC, (string)attachPoint]);
        } else if (attachPoint == ATTACH_HUD_TOP_RIGHT) {
            llSetPos(<0, y, -z>);
            moveHudButtons();
            llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_DESC, (string)attachPoint]);
        } else if (attachPoint == ATTACH_HUD_BOTTOM_LEFT) {
            llSetPos(<0, -y, z>);
            moveHudButtons();
            llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_DESC, (string)attachPoint]);
        } else if (attachPoint == ATTACH_HUD_BOTTOM) {
            llSetPos(<0, 0, z>);
            moveHudButtons();
            llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_DESC, (string)attachPoint]);
        } else if (attachPoint == ATTACH_HUD_BOTTOM_RIGHT) {
            llSetPos(<0, y, 0>);
            llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_DESC, (string)attachPoint]);
            moveHudButtons();
        } else if (attachPoint == ATTACH_HUD_CENTER_1) {
            llSetPos(<0, 0, 0>); //???
            moveHudButtons();
            llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_DESC, (string)attachPoint]);
        } else if (attachPoint == ATTACH_HUD_CENTER_2) {
            llSetPos(<0, 0, 0>); //???
            moveHudButtons();
            llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_DESC, (string)attachPoint]);
        }    
    }
}

default
{
    on_rez(integer param) {
        //debug("on_rez " + (string)param);
        //rotShown = llEuler2Rot(<0.0, 0.0, 0.0>);
        //rotHidden = llEuler2Rot(<0.0, 0.0, PI>);
        //rotateHud(1, TRUE);
        //hudShown = 1;
        //hudActive = 1;
    }
    
    state_entry()
    {
        rotShown = llEuler2Rot(<0.0, 0.0, 0.0>);
        rotShown1 = llEuler2Rot(<0.0, 0.1, 0.0>);
        //rotHidden = llEuler2Rot(<0.0, 0.0, PI>);
        rotHidden = llEuler2Rot(<0.0, 1.0/2.0*PI, 0.0>);
        rotShownColorPicker = llEuler2Rot(<0.0, 3.0/2.0*PI, 3.0/2.0*PI>);
        //rotHiddenColorPicker = llEuler2Rot(<0.0, 1.0/2.0*PI, 3.0/2.0*PI>);
        rotHiddenColorPicker = llEuler2Rot(<    0.0, 0.0, 3.0/2.0*PI>);
        //hudShown = 3;
        //hudActive = 3;
        //rotateHud(1, 0);
        //rotateHud(2, 0);
        //rotateHud(3, 2);
        //rotateHud(4, 0);
        //rotateHud(5, 0);
        hudShown = 1;
        hudActive = 1;
        rotateHud(2, 0);
        rotateHud(3, 0);
        rotateHud(1, 2);
        moveHudButtons();
        //llOwnerSay(llGetScriptName() + " Free memory: " + (string)llGetFreeMemory());
    }
    
    changed(integer change)
    {
        if (change & (CHANGED_OWNER | CHANGED_INVENTORY | CHANGED_LINK)) {
            llResetScript();
        }
    }

    attach(key id)
    {
        //debug("attach " + (string)id);
        if (id != NULL_KEY)
        {
            position();
        }
    }

    touch_start(integer total_number)
    {
        integer linkNumber = llDetectedLinkNumber(0);
        vector localPos=llList2Vector(llGetLinkPrimitiveParams(linkNumber,[PRIM_POS_LOCAL]),0);
        string linkName = llGetLinkName(linkNumber);
        //debug("Touched. " + (string) linkNumber + " " + linkName + (string)localPos);
        if (linkName == "hudhide") {
            if (hudShown > 0) {
                rotateHud(hudShown, 0);
                hudShown = 0;
                moveHudButtons();
            } else {
                hudShown = hudActive;
                rotateHud(hudActive, 2);
                moveHudButtons();
            }
        } else if (linkName == "hudswitch 1" || linkName == "hudswitch 2" || linkName == "hudswitch 3" || linkName == "hudswitch 4" || linkName == "hudswitch 5") {
            integer plane = llList2Integer(llParseString2List(linkName, [" "], []), 1);
            if (plane != hudActive) {
                if (hudShown > 0) {
                    rotateHud(hudShown, 0);
                }
                hudShown = plane;
                hudActive = plane;
                rotateHud(hudActive, 2);
                llMessageLinked(LINK_SET, HUD_PLANE_CHANGED, (string)plane, "");
            }
        } else if (linkName == "huddetach") {
            llRequestPermissions(llGetOwner(), PERMISSION_ATTACH);
        }
    }
    
    run_time_permissions(integer perm)
    {
        if(perm & PERMISSION_ATTACH) {
            llDetachFromAvatar( );
        }
    }
}
