// this is a modified version of
// https://marketplace.secondlife.com/p/Tavatar-ColorTexture-HUD-Kit-Free/4299174

integer USE_ALPHA = FALSE;
integer USE_COLOR = TRUE;

// The channel used for communication between the HUD and this slave. This must match in all scripts. Using the default of -841511254 is fine; products won't interfere unless they have the same face names. Texture scripts will also not interfere unless the passphrase matches. Nonetheless, Changing it is a fairly simple way to guarantee that different products of yours don't interfere
integer HUD_CHANNEL = -841511254;

// This configuration will be applied whenever this script is reset or sold
list DEFAULT_CONFIG = [];

//// Nothing configurable below this point ////

// you can also use <nolink>...</nolink> to escape auto link generation
string ERROR_NO_CONFIGURATION = "ERROR: No face names have yet been defined for any prim in this linkset. [http://tavatar.org/hud-kit/clothing-config/ Here are the instructions for setting them up.]";

// send ColorSyncCommand in chuncs
float NOTIFICATION_RATE_LIMIT = 0.5; // seconds

///////////////////////////////////////////////////////////////
///////////////////////// DEBUGGING ///////////////////////////
///////////////////////////////////////////////////////////////


debug(string msg) {
    llOwnerSay(llGetScriptName() + ": " + msg);
}


/////////////////////////////////////////////////////
//////////////////// COLOR STUFF ////////////////////
/////////////////////////////////////////////////////

// encodes multiple faces as a negative bitmask. ALL_SIDES is the same as all faces in this encoding. 123 -> 0b00001110. -430 -> 0b11100110
integer encodeFaces(string faceNums) {
    if (llStringLength(faceNums) == 1) return (integer)faceNums;
    integer isNegative = FALSE;
    integer ans = 0;
    integer i;
    for (i = 0; i < llStringLength(faceNums); i++) {
        string char = llGetSubString(faceNums, i, i);
        if (char == "-") {
            isNegative = TRUE;
        } else {
            ans = ans | (1 << (integer)char);
        }
    }
    if (isNegative) {
        return ~ans;
    } else {
        return ans | 0x80000000;
    }
}

integer isLinkValid(integer linkNumber) {
    if (llGetNumberOfPrims() == 1) return linkNumber == 0;
    if (linkNumber <= 0) return FALSE;
    if (linkNumber > llGetNumberOfPrims()) return FALSE;
    return TRUE;
}

integer checkFaceExists(integer linkNumber, integer face) {
    if (face == ALL_SIDES) return TRUE;
    if (face < llGetLinkNumberOfSides(linkNumber)) return TRUE;
    llOwnerSay("ERROR: face number out of range: " + (string)face +
        "\nPrim #" + (string)linkNumber + " has only " + (string)llGetLinkNumberOfSides(linkNumber) + " faces" +
        "\nPrim Name: " + llGetLinkName(linkNumber) +
        "\nPrim Description: " + llList2String(llGetLinkPrimitiveParams(linkNumber, [PRIM_DESC]), 0) + 
    "\n");
    return FALSE;
}

setColor(integer linkNumber, integer face, string configString) {
    if (face >= 0 || face == ALL_SIDES) {
        setFaceColor(linkNumber, face, configString);
    } else {
        integer i;
        for (i = llGetLinkNumberOfSides(linkNumber)-1; i >= 0; --i) {        
            if (face & (1 << i)) {
                setFaceColor(linkNumber, i, configString);
            }
        }
    }
}

setFaceColor(integer linkNumber, integer face, string configString) {
    if (!checkFaceExists(linkNumber, face)) return;
    list config = llParseString2List(configString, [":"], []);
    list params = [];
    integer i;
    //debug("setColor1(" + (string) linkNumber + ", " + (string) face + ", " + llList2CSV(config));
    for (i = 0; i < llGetListLength(config); i+=2) {
        string type = llList2String(config, i);
        string value = llList2String(config, i+1);
        if (type == "color") {
            //debug("setColor4: " + (string)linkNumber + ", " + value + ", " + (string)face);
            llSetLinkColor(linkNumber, (vector)value, face);
            //llSetLinkColor(0, <0.8, 0.8, 0.8>, ALL_SIDES);
        } else if (type == "alpha") {
            llSetLinkAlpha(linkNumber, (float)value, face);
        } else if (type == "glow") {
            params += [PRIM_GLOW, face, (float)value];
        } else if (type == "texture") {
            integer readFace = face;
            if (face == ALL_SIDES) readFace = 0; //FIXME
            list p = llGetLinkPrimitiveParams(linkNumber, [PRIM_TEXTURE, readFace]);
            p = llListReplaceList(p, [(key)value], 0, 0);
            params += [PRIM_TEXTURE, face] + p;
        } else if (type == "normal") {
            integer readFace = face;
            if (face == ALL_SIDES) readFace = 0; //FIXME
            list p = llGetLinkPrimitiveParams(linkNumber, [PRIM_NORMAL, readFace]);
            p = llListReplaceList(p, [(key)value], 0, 0);
            params += [PRIM_NORMAL, face] + p;
        } else if (type == "specGloss") {
            //FIXME more then one parameter in group
            integer readFace = face;
            if (face == ALL_SIDES) readFace = 0; //FIXME
            list p = llGetLinkPrimitiveParams(linkNumber, [PRIM_SPECULAR, readFace]);
            p = llListReplaceList(p, [(integer)value], 5, 5);
            params += [PRIM_SPECULAR, face] + p;
        }
    }
    if (params) {
//debug("setColor3: " + llList2CSV(params));
        llSetLinkPrimitiveParamsFast(linkNumber, params);
    }
}

/*
        else if (type == "texture"   ) flag = PRIM_TEXTURE;
        else if (type == "normal"    ) flag = PRIM_NORMAL;
        else if (type == "specular"  ) flag = PRIM_SPECULAR;
        else if (type == "alpha"     ) { flag = PRIM_COLOR; index = 1; }
        else if (type == "alphaMode" ) flag = PRIM_ALPHA_MODE;
        else if (type == "glow"      ) flag = PRIM_GLOW;
        else if (type == "shiny"     ) flag = PRIM_BUMP_SHINY;
        else if (type == "fullbright") flag = PRIM_FULLBRIGHT;
        else if (type == "textRepeat") { flag = PRIM_TEXTURE;  index = 1; }
        else if (type == "textOffset") { flag = PRIM_TEXTURE;  index = 2; }
        else if (type == "normRepeat") { flag = PRIM_NORMAL;   index = 1; }
        else if (type == "normOffset") { flag = PRIM_NORMAL;   index = 2; }
        else if (type == "specRepeat") { flag = PRIM_SPECULAR; index = 1; }
        else if (type == "specOffset") { flag = PRIM_SPECULAR; index = 2; }
        else if (type == "specColor" ) { flag = PRIM_SPECULAR; index = 4; }
        else if (type == "specGloss" ) { flag = PRIM_SPECULAR; index = 5; }
        else if (type == "specEnv"   ) { flag = PRIM_SPECULAR; index = 6; }
*/

// "group:3" -> ["group", 3]; "group" -> ["group", ALL_SIDES]; "group:*" -> ["group", ALL_SIDES] on all prims
list parseGroupFace(string groupFace, integer linkNum) {
    integer colen = llSubStringIndex(groupFace, ":");
    //debug("parseGroupFace(" + groupFace + ", " + (string)linkNum + "); colen: " + (string)colen);
    if (colen < 0) return [groupFace, ALL_SIDES];

    string group = llDeleteSubString(groupFace, colen, -1);
    string face = llDeleteSubString(groupFace, 0, colen);
    //debug("parseGroupFace(" + groupFace + ", " + (string)linkNum + ")");
    if (face == "*" && linkNum <= 1) {
        wholePrimGroups += [group, ALL_SIDES];
        //debug("wholePrimGroups: " + llList2CSV(wholePrimGroups));
        return [];
    } else {
        return [group, encodeFaces(face)];
    }
}

list wholePrimGroups = [];

// answers a 2-strided list on what color groups the faces of the given link belong to. Stride is [groupName, faceNumber]. it is derived from the description, which is a comma-separated list of group names, optionally followed by a colen and face number. Face number is ALL_SIDES if absent
list linkColorGroups(integer linkNumber, integer expandFaceGroups) {
    //debug("linkColorGroups(" + (string)linkNumber + ")");
    if (!isLinkValid(linkNumber)) return [];
    list groups = llParseString2List(llList2String(llGetLinkPrimitiveParams(linkNumber, [PRIM_DESC]), 0), [","], []);
    //debug("groups: " + llList2CSV(groups));
    if (llList2String(groups, 0) == "(No Description)") return [];
    
    integer i;
    for (i = 0; i < llGetListLength(groups); i += 2) {
        string groupFace = llList2String(groups, i);
        groups = llListReplaceList(groups, parseGroupFace(groupFace, linkNumber), i, i);
    }
    groups += wholePrimGroups;
    if (!expandFaceGroups) {
        //debug("groups: " + llList2CSV(groups));
        return groups;
    }

    for (i = llGetListLength(groups) - 2; i >= 0; i -= 2) {
        string groupName = llList2String(groups, i);
        if (llGetSubString(groupName, -2, -1) == ".f") {
            groupName = llGetSubString(groupName, 0, -3);
            integer faceNums = llList2Integer(groups, i+1);
            list expansion = [];
            if (faceNums >= 0) { // single face
                expansion = [groupName + "." + (string)faceNums, faceNums];
            } else { // multiple faces
                integer f;
                for (f = llGetLinkNumberOfSides(linkNumber)-1; f >= 0; --f) {        
                    if (faceNums & (1 << f)) {
                        expansion = [groupName + "." + (string)f, f] + expansion;
                    }
                }
            }
            groups = llListReplaceList(groups, expansion, i, i+1);
        }
    }
    //debug("groups: " + llList2CSV(groups));
    return groups;
}

// basic glob pattern matching. Only recognizes *, not ? or +
integer globMatch(string s, string pattern) {
//debug("globMatch string \"" + s + "\" against pattern \"" + pattern + "\"");
    list patterns = llParseStringKeepNulls(pattern, ["*"], []);
    integer hunkCount = llGetListLength(patterns);
    if(hunkCount == 1) return s == pattern;

    pattern = llList2String(patterns, 0); // check first hunk
    //debug("Checking if \"" + s + "\" starts with \"" + pattern + "\"...");
    //debug("\"" + llDeleteSubString(s, llStringLength(pattern), -1) + "\" == \"" + pattern + "\"");
    if(llDeleteSubString(s, llStringLength(pattern), -1) != pattern) return FALSE;
    s = llGetSubString(s, llStringLength(pattern), -1);

    pattern = llList2String(patterns, -1); // check last hunk
    //debug("Checking if \"" + s + "\" ends with \"" + pattern + "\"...");
    //debug("\"" + llDeleteSubString(s, 0, -llStringLength(pattern) - 1) + "\" == \"" + pattern + "\"");
    if(llDeleteSubString(s, 0, -llStringLength(pattern) - 1) != pattern) return FALSE;
    s = llGetSubString(s, 0, -llStringLength(pattern) - 1);

    integer i;
    for (i = 1; i < hunkCount-1; ++i) {
        pattern = llList2String(patterns, i);
        //debug("Checking if \"" + s + "\" contains \"" + pattern + "\"...");
        integer p = llSubStringIndex(s, pattern);
        if (p < 0) return FALSE;
        s = llGetSubString(s, p + llStringLength(pattern), -1);
    }
    return TRUE;
}

setFacesByGroup(list params) {
    //debug("setFacesByGroup(" + llList2CSV(params) + ")");
    integer expandFaceGroups = llSubStringIndex(llDumpList2String(llList2ListStrided(params, 0, -1, 2), ""), ".") >= 0; // does any group name have a . in it?
//    debug("expandFaceGroups = " + (string)expandFaceGroups);
    integer faceGroupCount = 0;
    wholePrimGroups = [];
    integer linkNumber;
    for (linkNumber = 0; linkNumber <= llGetNumberOfPrims(); linkNumber++) {
        list colorGroups = linkColorGroups(linkNumber, expandFaceGroups);
        integer i;
        for (i = 0; i < llGetListLength(colorGroups); i += 2) {
            faceGroupCount++;
            string group = llList2String(colorGroups, i);
            integer face = llList2Integer(colorGroups, i+1);
            integer p;
            for (p = 0; p < llGetListLength(params); p += 2) {
                if (globMatch(group, llList2String(params, p))) {
                    string param = llList2String(params, p+1);
                    setColor(linkNumber, face, param);
                }
            }
        }
    }
    if (faceGroupCount == 0) llOwnerSay(ERROR_NO_CONFIGURATION);
}

integer cscLinkNumber;
integer cscGroupNumber;
integer cscActive = FALSE;
sendColorSyncCommand() {
    if (cscActive) {
        return; //FIXME
    }
    cscLinkNumber = 0;
    cscGroupNumber = 0;
    cscActive = TRUE;
    llSetTimerEvent(NOTIFICATION_RATE_LIMIT);
    sendColorSyncCommandChunk();
}

sendColorSyncCommandChunk() {
    if (!cscActive) {
        llSetTimerEvent(0.0);
        return;
    }
    string params = COLOR_SYNC_COMMAND;
    while (cscLinkNumber <= llGetNumberOfPrims()) {
        list colorGroups = linkColorGroups(cscLinkNumber, FALSE);
        //debug("colorGroups " + llList2CSV(colorGroups));
        while (cscGroupNumber < llGetListLength(colorGroups)) {
            //llOwnerSay((string) done + " Free Memory " + (string)llGetFreeMemory());
            string group = llList2String(colorGroups, cscGroupNumber);
            if (llSubStringIndex(params, ";" + group + ";") < 0) {
                integer face = llList2Integer(colorGroups, cscGroupNumber+1);
                //integer debugFace = face;
                if (face == ALL_SIDES) {
                    face = 0;
                } else if (face < 0) {
                    integer i;
                    for (i = 0; face < 0 && i < llGetLinkNumberOfSides(cscLinkNumber); i++) {        
                        if (face & (1 << i)) {
                            face = i;
                        }
                    }
                }
                //debug("group " + group + " " + (string)debugFace + " -> " + (string)face);
                list p = llGetLinkPrimitiveParams(cscLinkNumber, [
                    PRIM_COLOR, face,
                    PRIM_GLOW, face,
                    //PRIM_BUMP_SHINY, activeColorButtonReadFace,
                    //PRIM_FULLBRIGHT, activeColorButtonReadFace,
                    //PRIM_ALPHA_MODE, activeColorButtonReadFace,
                    PRIM_SPECULAR, face
                ]);
                string toAdd = ";" + group + ";";
                vector c = llList2Vector(p, 0);
                if (USE_COLOR) {
                    toAdd += "color:<" + llGetSubString((string)c.x, 0, 4) +  "," + llGetSubString((string)c.y, 0, 4) +  "," + llGetSubString((string)c.z, 0, 4) + ">";
                    toAdd += ":glow:" + llGetSubString(llList2String(p, 2), 0, 4);
                    toAdd += ":specGloss:" + llList2String(p, 8);
                }
                if (USE_COLOR && USE_ALPHA) {
                    toAdd += ":";
                }
                if (USE_ALPHA) {
                    toAdd += "alpha:" + llGetSubString(llList2String(p, 1), 0, 4);
                }
                if (llStringLength(params) + llStringLength(toAdd) > 1000) {
                    //debug("send chunk");
                    //debug(params);
                    llSay(channel(), params);
                    return;
                }
                //debug("add: " + (string)llStringLength(params) +  " ;" + group + ";" + "alpha:" + llGetSubString(llList2String(p, 1), 0, 4));
                params += toAdd;
            }
            cscGroupNumber += 2;
        }
        cscLinkNumber++;
        cscGroupNumber = 0;
    }
    
    //debug("send last chunk");
    //debug(params);
    llSay(channel(), params);
    cscActive = FALSE;
}


/////////////////////////////////////////////////////
/////////////////// MESSAGE STUFF ///////////////////
/////////////////////////////////////////////////////

string COLOR_COMMAND = "color";
string COLOR_SYNC_COMMAND = "colorsync";
string COLOR_SYNC_REQUEST = "colorsyncrequest";

integer channel() {
    // Convert a key to an integer using the first 8 hex digits (32 bits)
    return HUD_CHANNEL ^ (integer)("0x" + llGetSubString((string)llGetOwner(), 0, 7));
}

processMessage(key id, string msg) {
    // check if the HUD is talking, and it's owned by the owner
    if (llGetOwnerKey(id) != llGetOwner())
        return;

//debug("processMessage(" + (string)id + " (" + llKey2Name(id) + "), \"" + msg + "\")");
//debug("processMessage( \"" + msg + "\")");
//debug("processMessage: " + (string)llStringLength(msg) + " bytes");
    list parsed  = llParseString2List(msg, [";"], []);
    string command = llList2String(parsed, 0);
    list params = llDeleteSubList(parsed, 0, 0);

    if (command == COLOR_COMMAND) {
        setFacesByGroup(params);
    } else if (command == COLOR_SYNC_REQUEST) {
        sendColorSyncCommand();
    }
}

/////////////////////////////////////////////////////
////////////////////// STATE ////////////////////////
/////////////////////////////////////////////////////

integer hudListener;
integer ownerListener;
startListeners() {
    llListenRemove(hudListener);
    llListenRemove(ownerListener);
    hudListener = llListen(channel(), "", NULL_KEY, "");
}
 
default {
    on_rez(integer param) {
        sendColorSyncCommand();
    }
    
    state_entry() {
        startListeners();
        sendColorSyncCommand();
        //setFacesByGroup(DEFAULT_CONFIG); FIXME
        //llOwnerSay(llGetScriptName() + ": " + (string)llGetFreeMemory() + " bytes free");
    }

    changed(integer change) {
        if (change & (CHANGED_OWNER | CHANGED_INVENTORY | CHANGED_LINK)) {
            llResetScript();
        }
    }
    
    listen(integer channel, string name, key id, string msg) {
        processMessage(id, msg);
    }
    
    timer () {
        //debug("timer");
        sendColorSyncCommandChunk();
    }

}
