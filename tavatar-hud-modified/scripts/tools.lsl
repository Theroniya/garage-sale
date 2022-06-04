// some quick&dirty tools for uploades meshes

// This file is in the publich domain. You can do whatever you wish.


list regionLower = [
    "aPelvisF",
    "aPelvisB", //7
    "aLeg6R",
    "aLeg6L",
    "aLeg5R",
    "aLeg5L",
    "aLeg4L",
    "aLeg3R",
    "aLeg4R",
    "aLeg3L",
    "aLeg2R",
    "aLeg2L",
    "aLeg1L",
    "aPrivate", //1
    "aCrotch", //1
    "aFootR", //?
    "aLeg1R",
    "aFootL" //?
];

list regionUpper = [
    "aHandR", //7
    "aHandL", //7
    "aChest",
    "aBrestL", //5
    "aBrestR", //5
    "aBackupper", //5
    "aBelly", //6
    "aBacklower", //5
    "aArmR",
    "aArmL"

];

list regionHead = [
    "aHead"
];

log(string msg) {
    llOwnerSay(msg);
}

setupColorgrid() {
    integer linkNumber;
    for (linkNumber = 1; linkNumber <= llGetNumberOfPrims(); linkNumber++) {
        string name = llGetLinkName(linkNumber);
        if (llGetSubString(name, 0, 0) == "a") {
            log("part: " + name);
            list params = llGetLinkPrimitiveParams(linkNumber, [PRIM_TEXTURE, 0]);
            if (params != []) {
                params = llListReplaceList(params, [PRIM_TEXTURE, ALL_SIDES, TEXTURE_BLANK], 0, 0);
                llSetLinkPrimitiveParamsFast(linkNumber, params);
            }
            llSetLinkColor(linkNumber, <1.0, 0.0, 0.0>, 0);
            llSetLinkColor(linkNumber, <0.0, 0.0, 1.0>, 1);
            llSetLinkColor(linkNumber, <0.0, 1.0, 0.0>, 2);
            llSetLinkColor(linkNumber, <1.0, 1.0, 0.0>, 3);
            llSetLinkColor(linkNumber, <0.0, 0.4, 0.0>, 4);
            llSetLinkColor(linkNumber, <1.0, 0.4, 0.0>, 5);
            llSetLinkColor(linkNumber, <0.2, 0.5, 1.0>, 6);
            llSetLinkColor(linkNumber, <0.5, 0.0, 1.0>, 7);

        }
    }
}

setupButtonColorgrid() {
    integer linkNumber;
    for (linkNumber = 1; linkNumber <= llGetNumberOfPrims(); linkNumber++) {
        string name = llGetLinkName(linkNumber);
        list nameParts  = llParseString2List(name, ["."], []);
        if (llGetListLength(nameParts) >= 2) {
            log("part: " + name);
            llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_FULLBRIGHT, ALL_SIDES, TRUE]);
            if (llList2String(nameParts, 0) == "aCrotch") {
                llSetLinkColor(linkNumber, <0.1, 0.1, 0.89>, 0);
            } else if (llList2String(nameParts, 1) == "f") {
                llSetLinkColor(linkNumber, <0.81, 0.18, 0.18>, 0);
                llSetLinkColor(linkNumber, <0.18, 0.16, 0.83>, 1);
                llSetLinkColor(linkNumber, <0.3, 0.52, 0.29>, 2);
                llSetLinkColor(linkNumber, <0.81, 0.79, 0.14>, 3);
                llSetLinkColor(linkNumber, <0.13, 0.26, 0.16>, 4);
                llSetLinkColor(linkNumber, <0.34, 0.12, 0.12>, 5);
                llSetLinkColor(linkNumber, <0.3, 0.65, 0.89>, 6);
                llSetLinkColor(linkNumber, <0.46, 0.2, 0.64>, 7);
            } else {
                llSetLinkColor(linkNumber, <0.7, 0.7, 0.7>, ALL_SIDES);
            }
        }
    }
}

setupBOM() {
    integer ln;
    for (ln = 1; ln <= llGetNumberOfPrims(); ln++) {
        integer linkNumber = ln;
        if (llGetNumberOfPrims() == 1) {
            linkNumber = 0;
        }
        string name = llGetLinkName(linkNumber);
        list nameParts  = llParseString2List(name, ["."], []);
        name = llList2String(nameParts, 0);
        if (llList2String(nameParts, 1) == "cs") {
            log("part: " + name);
            key texture = TEXTURE_BLANK;
            if (~llListFindList(regionLower, (list)name)) texture = IMG_USE_BAKED_LOWER;
            if (~llListFindList(regionUpper, (list)name)) texture = IMG_USE_BAKED_UPPER;
            if (~llListFindList(regionHead, (list)name)) texture = IMG_USE_BAKED_HEAD;
            list params = llGetLinkPrimitiveParams(linkNumber, [PRIM_TEXTURE, 0]);
            if (params != []) {
                params = llListReplaceList(params, [PRIM_TEXTURE, ALL_SIDES, texture], 0, 0);
                llSetLinkPrimitiveParamsFast(linkNumber, params);
            }
            llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_ALPHA_MODE, ALL_SIDES, PRIM_ALPHA_MODE_NONE, 128]);
            llSetLinkColor(linkNumber, <1.0, 1.0, 1.0>, ALL_SIDES);
        }
    }
}

setupTavatarReceiver() {
    integer ln;
    for (ln = 1; ln <= llGetNumberOfPrims(); ln++) {
        integer linkNumber = ln;
        if (llGetNumberOfPrims() == 1) {
            linkNumber = 0;
        }
        string name = llGetLinkName(linkNumber);
        list nameParts  = llParseString2List(name, ["."], []);
        name = llList2String(nameParts, 0);
        if (llList2String(nameParts, 1) == "cs") {
            log("part: " + name + " " + (string)llGetLinkNumberOfSides(linkNumber));
            string desc = "";
            string prefix = "";
            integer face;
            for (face = 0; face < llGetLinkNumberOfSides(linkNumber); face++) {
                desc += prefix + name + (string) face + ":" + (string) face;
                prefix = ",";
            }
            llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_DESC, desc]);
        }
    }
}

setupTavatarAlphacutButtons() {
    integer linkNumber;
    list sides = [];
    for (linkNumber = 1; linkNumber <= llGetNumberOfPrims(); linkNumber++) {
        string name = llGetLinkName(linkNumber);
        list nameParts  = llParseString2List(name, ["."], []);
        if (llGetListLength(nameParts) >= 2) {
            if (llList2String(nameParts, 1) == "f") {
                log("part f: " + name + " " + (string)llGetLinkNumberOfSides(linkNumber));
                string desc = "";
                //if (llList2String(nameParts, 0) == "aHead") desc = "aEyes:2,";
                string prefix = "";
                integer face;
                for (face = 0; face < llGetLinkNumberOfSides(linkNumber); face++) {
                    desc += prefix + llList2String(nameParts, 0) + (string) face + ":" + (string) face;
                    prefix = ",";
                }
                llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_DESC, desc]);
                llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_NAME, "hide"]);
                sides += [llList2String(nameParts, 0), llGetLinkNumberOfSides(linkNumber)];
            }
        }
    }
    for (linkNumber = 1; linkNumber <= llGetNumberOfPrims(); linkNumber++) {
        string name = llGetLinkName(linkNumber);
        list nameParts  = llParseString2List(name, ["."], []);
        if (llGetListLength(nameParts) >= 2) {
            if (llList2String(nameParts, 1) == "a") {
                integer numberOfSides = llList2Integer(sides, llListFindList(sides, (list)llList2String(nameParts, 0)) + 1);
                log("part a: " + name + " " + (string)numberOfSides);
                string desc = "";
                if (llList2String(nameParts, 0) == "aHead") desc = "aEyes,";
                if (llList2String(nameParts, 0) == "aPelvisF") desc = "aPrivate0,aCrotch0,";
                string prefix = "";
                integer face;
                for (face = 0; face < numberOfSides; face++) {
                    desc += prefix + llList2String(nameParts, 0) + (string) face;
                    prefix = ",";
                }
                llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_DESC, desc]);
                llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_NAME, "hideGroup"]);
            }
        }
    }
}

linkInfo() {
    log("-------------------");
    integer linkNumber;
    for (linkNumber = 1; linkNumber <= llGetNumberOfPrims(); linkNumber++) {
        string name = llGetLinkName(linkNumber);
        vector linkPos=llList2Vector(llGetLinkPrimitiveParams(linkNumber,[PRIM_POSITION]),0);
        vector localPos=llList2Vector(llGetLinkPrimitiveParams(linkNumber,[PRIM_POS_LOCAL]),0);
        vector linkScale=llList2Vector(llGetLinkPrimitiveParams(linkNumber,[PRIM_SIZE]),0);
        
        log(llList2CSV([linkNumber, name, linkPos, localPos, linkScale]));

    }
}

inventoryInfo() {
    string info = "";
    integer i;
    for (i = 0; i < llGetInventoryNumber(INVENTORY_ALL); i++) {
        info += "\n" + llGetInventoryName(INVENTORY_ALL, i);
    }
    llOwnerSay(info);
}

default {
    state_entry() {
        //linkInfo();
    
        //setupColorgrid();
        setupBOM();
        setupTavatarReceiver();
        
        //setupButtonColorgrid();
        //setupTavatarAlphacutButtons();
        
        //inventoryInfo();
        llRemoveInventory(llGetScriptName());
    }
}

/*
nail description
fnLF:2,fnLFTip:6,fnLT:3,fnLTTip:7,fnRF:0,fnRFTip:4,fnRT:1,fnRTTip:5
tnLF:2,tnLFTip:6,tnLT:3,tnLTTip:7,tnRF:0,tnRFTip:4,tnRT:1,tnRTTip:5


Hand oben unten vertauscht
Gesicht Zähne Zunge
*/
