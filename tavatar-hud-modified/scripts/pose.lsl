// Start and stop animations. Facial expressions and finger positions

// This file is in the publich domain. You can do whatever you wish.

/*
off:anklelock
30_Ankle_Lock:anklelock

off:e
40_E:e:1,41_E:e:2,42_E:e:3,43_E:e:4,44_E:e:5,45_E:e:6,46_E:e:7
50_E:e:1,51_E:e:2,52_E:e:3,53_E:e:4,54_E:e:5,55_E:e:6,56_E:e:7

off:m
60_M:m:0,61_M:m:1,62_M:m:2,63_M:m:3,64_M:m:4,65_M:m:5,66_M:m:6,67_M:m:7
68_M:m:4,69_M:m:5,70_M:m:6,71_M:m:7

off:l
01_LH:l:0,03_LH:l:1,05_LH:l:2,07_LH:l:3,09_LH:l:4,11_LH:l:5,13_LH:l:6,15_LH:l:7
17_LH:l:4,19_LH:l:5,21_LH:l:6,23_LH:l:7
off:r
02_RH:r:0,04_RH:r:1,06_RH:r:2,08_RH:r:3,10_RH:r:4,12_RH:r:5,14_RH:r:6,16_RH:r:7
18_RH:r:4,20_RH:r:5,22_RH:r:6,24_RH:r:7
*/

vector colorRunning = <0.0, 0.0, 0.0>;
float alphaRunning = 0.45;
vector colorOff = <0.74, 0.53, 0.31>;
float alphaOff = 0.25;

list DEFAULT_POSES = ["01_LH", "02_RH"];

// [uuid, name, group, buttonNumber, faceNumber, ...]
list poses = [];


debug(string msg) {
    llOwnerSay(llGetScriptName() + ": " + msg);
}

processPose(integer linkNumber, integer faceNumber) {
    //debug("processPose: " + (string)linkNumber + ", " + (string)faceNumber);
    string desc = llList2String(llGetLinkPrimitiveParams(linkNumber, [PRIM_DESC]), 0);
    list actions = llParseString2List(desc, [","], []);
    integer a = 0;
    for (a = 0; a < llGetListLength(actions); a++) {
        list parts = llParseString2List(llList2String(actions, a), [":"], []);
        //debug("cheeck: " + llList2CSV(parts));
        integer face = ALL_SIDES;
        if (llGetListLength(parts) >= 3) {
            face = llList2Integer(parts, 2);
        }
        if (faceNumber == face || face == ALL_SIDES) {
            string posename = llList2String(parts, 0);
            string posegroup = llList2String(parts, 1);
            //stop other poses of the same group
            //debug("stop group: " + posegroup);
            list anims = llGetAnimationList(llGetOwner());
            integer i;
            for (i = 0; i < llGetListLength(anims); ++i) {
                key a = llList2Key(anims, i);
                integer slot = llListFindList(poses, [a]);
                //debug("check: " + (string)a + " = " + (string)slot);
                if (slot >= 0 && llList2String(poses, slot+2) == posegroup)  {
                    //debug("stop: " + llList2String(poses, slot+1));
                    llStopAnimation(a);
                }
            }
            //remove mark of all buttos of the same group
            for (i = 0; i < llGetListLength(poses); i+=5) {
                if (llList2String(poses, i+2) == posegroup)  {
                    //debug("off: " + llList2String(poses, i+3) + ", " + llList2String(poses, i+4));
                    llSetLinkPrimitiveParamsFast(llList2Integer(poses, i+3), [PRIM_COLOR, llList2Integer(poses, i+4), colorOff, alphaOff]);
                }
            }
            //start pose
            if (posename != "off" && llListFindList(poses, [posename]) >= 0) {
                //debug("start: " + posename);
                llStartAnimation(posename);
            }
            //debug("on: " + (string)linkNumber + ", " + (string)face);
            llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_COLOR, face, colorRunning, alphaRunning]);
        }
    }
}


init() {
    //collect pose buttons
    poses = [];
    llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
    integer linkNumber;
    for (linkNumber = 0; linkNumber <= llGetNumberOfPrims(); linkNumber++) {
        string name = llGetLinkName(linkNumber);
        if (name == "pose") {            
            string desc = llList2String(llGetLinkPrimitiveParams(linkNumber, [PRIM_DESC]), 0);
            //if (desc) {
            list actions = llParseString2List(desc, [","], []);
            integer a = 0;
            for (a = 0; a < llGetListLength(actions); a++) {
                list parts = llParseString2List(llList2String(actions,a), [":"], []);            
                string posename = llList2String(parts, 0);
                string posegroup = llList2String(parts, 1);
                integer face = ALL_SIDES;
                //debug("init: " + llGetLinkName(linkNumber) + ", " + (string)face + " = " + posename + ", " + posegroup);
                if (llGetListLength(parts) >= 3) {
                    face = llList2Integer(parts, 2);
                }
                if (posename == "off") {
                    //debug("add pose: " + posename + ", " + (string)linkNumber + ", " + (string)face);
                    poses += [NULL_KEY, posename, posegroup, linkNumber, face];
                } else {
                    key uuid = llGetInventoryKey(posename);
                    if (uuid) {
                        //debug("add pose: " + (string) uuid + ", " + posename + ", " + posegroup + ", " + (string)linkNumber + ", " + (string)face);
                        poses += [uuid, posename, posegroup, linkNumber, face];
                    } else {
                        llOwnerSay("Can't find pose " + posename + " in inventory of this hud.");
                    }
                }
                //debug("mark off: " + (string)linkNumber + ", " + (string)face);
                llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_COLOR, face, colorOff, alphaOff]);
            }
            //}
        }
    }
    //mark running pose buttons
    list runningGroups = [];
    list anims = llGetAnimationList(llGetOwner());
    integer i;
    for (i = 0; i < llGetListLength(anims); ++i) {
        key a = llList2Key(anims, i);
        integer slot = llListFindList(poses, [a]);
        //debug("check: " + (string)a + " = " + (string)slot);
        if (slot >= 0)  {
            //debug("running: " + llList2String(poses, slot+1));
            runningGroups += llList2String(poses, slot+2);
            llSetLinkPrimitiveParamsFast(llList2Integer(poses, slot+3), [PRIM_COLOR, llList2Integer(poses, slot+4), colorRunning, alphaRunning]);
        }
    }
    //start missing default poses
    for (i = 0; i < llGetListLength(DEFAULT_POSES); i++) {
        string posename = llList2String(DEFAULT_POSES, i);
        integer slot = llListFindList(poses, [posename]) - 1;
        string posegroup = llList2String(poses, slot+2);
        if (llListFindList(runningGroups, [posegroup]) < 0)  {
            //debug("start: " + posename);
            llStartAnimation(posename);
            runningGroups += llList2String(poses, slot+2);
            llSetLinkPrimitiveParamsFast(llList2Integer(poses, slot+3), [PRIM_COLOR, llList2Integer(poses, slot+4), colorRunning, alphaRunning]);
        }
    }
    //mark off buttons
    for (i = 0; i < llGetListLength(poses); i+=5) {
        string posename = llList2String(poses, i+1);
        string posegroup = llList2String(poses, i+2);
        //if (posename == "off") debug("test: " + posegroup + " in " + llList2CSV(runningGroups));
        if (posename == "off" && llListFindList(runningGroups, [posegroup]) < 0)  {
            //debug("mark off button: " + llList2String(poses, i+3) + ", " + llList2String(poses, i+4));
            llSetLinkPrimitiveParamsFast(llList2Integer(poses, i+3), [PRIM_COLOR, llList2Integer(poses, i+4), colorRunning, alphaRunning]);
        }
    }
}

default
{
    on_rez(integer param) {
        init();
    }

   state_entry()
    {
        init();
        //llOwnerSay(llGetScriptName() + " Free memory: " + (string)llGetFreeMemory());
    }
    
    changed(integer change)
    {
        //debug("changed " + (string)change);
        if (change & (CHANGED_OWNER | CHANGED_INVENTORY | CHANGED_LINK)) {
            llResetScript();
        }
    }
    
    touch_start(integer total_number) {
        //if (llDetectedKey(0) != llGetOwner()) return;

        integer linkNumber = llDetectedLinkNumber(0);
        string linkName = llGetLinkName(linkNumber);
        if (linkName == "pose") {
            integer faceNumber = llDetectedTouchFace(0);
            processPose(linkNumber, faceNumber);
        }
    }
}
