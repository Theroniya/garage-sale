// this is a modified version of
// https://marketplace.secondlife.com/p/Tavatar-ColorTexture-HUD-Kit-Free/4299174

//integer HUD_CHANNEL = -841511254;       // channel for HUD communications
integer HUD_CHANNEL = -841511255;       // channel for HUD communications
string COLOR_SYNC_COMMAND = "colorsync";
string COLOR_SYNC_REQUEST = "colorsyncrequest";

// channels for interacting with the color picker and sliders
integer SET_COLOR = 93759837;
integer COLOR_CHANGED = 93759838;
integer SET_COLOR_SYNC = 93759839;
integer HUD_PLANE_CHANGED = 83759837;

// the color button that was clicked and whose color will be sent to the avatar
list activeColorButton = [-1, -1, -1];
list activeColorButtonReadFace = [0, 0, 0];
list activeColorButtonWriteFace = [0, 0, 0];

// the selected color indicator
integer selectedColorGadget = -999;
integer selectedColorGadgetVisible = -999;

// vector ON_COLOR = <0.0, 1.0, 0.0>; // green
// vector OFF_COLOR = <1.0, 0.0, 0.16863>; // red

vector ON_COLOR = <1.0, 1.0, 1.0>; // white
vector OFF_COLOR = <0.5, 0.5, 0.5>; // grey
vector OFF_COLOR_HIDE = <0.5, 0.5, 0.5>; // grey

float ON_ALPHA = 1.0;
float OFF_ALPHA = 0.25;


///////////////////////////////////////////////////////////////
///////////////////////// DEBUGGING ///////////////////////////
///////////////////////////////////////////////////////////////


debug(string msg) {
    llOwnerSay(llGetScriptName() + ": " + msg);
}


////////////////////////////////////////////////////////////////////
////////////////////////// General Utilities ///////////////////////
////////////////////////////////////////////////////////////////////

string llGetLinkDesc(integer linkNumber) {
    return llList2String(llGetLinkPrimitiveParams(linkNumber, [PRIM_DESC]), 0);
}

// float modulo (a mod b)
float mod(float a, float b) {
    return a - llFloor(a/b) * b;
}

// min of a vector
float min(vector v) {
    float min = v.x;
    if (v.y < min) min = v.y;
    if (v.z < min) min = v.z;
    return min;
}

// max of a vector
float max(vector v) {
    float max = v.x;
    if (max < v.y) max = v.y;
    if (max < v.z) max = v.z;
    return max;
}


// Converts an HSV colorspace to RGB colorspace
// Input is a vector:
//   x == hue (0 .. 1)
//   y == saturation (0 .. 1)
//   z == value (0 .. 1)
// Output is a vector:
//   x == red (0 .. 1)
//   y == green (0 .. 1)
//   z == blue (0 .. 1)
// Source: http://en.wikipedia.org/wiki/HSL_and_HSV#From_HSV
vector hsv2rgb(vector hsv) {
    float hue = hsv.x * 6.0; 
    float sat = hsv.y;
    float value = hsv.z;
    float chroma = sat * value;
    float min = value - chroma;

    float X = chroma * (1-llFabs(mod(hue, 2.0) - 1.0));
    float C = chroma;
    vector range;
    if (hue < 1.0) range = <C, X, 0>;
    else if (hue < 2.0) range = <X, C, 0>;
    else if (hue < 3.0) range = <0, C, X>;
    else if (hue < 4.0) range = <0, X, C>;
    else if (hue < 5.0) range = <X, 0, C>;
    else range = <C, 0, X>;

    return range + <min, min, min>;
}

// Converts an RGB colorspace to HSB colorspace
// Input is a vector:
//   x == red (0 .. 1)
//   y == green (0 .. 1)
//   z == blue (0 .. 1)
// Output is a vector:
//   x == hue (0 .. 359.9)
//   y == saturation (0 .. 1)
//   z == bright (value, lum) (0 .. 1)
vector rgb2hsv(vector rgb) {
    float min = min(rgb);
    float max = max(rgb);
    float chroma = max-min;
    if (chroma == 0.0) return <0.0, 0.0, max>;

    float r = rgb.x;
    float g = rgb.y;
    float b = rgb.z;
    float hue;

    if (max == r) hue = mod((g-b)/chroma, 6.0);
    else if (max == g) hue = (b-r)/chroma + 2.0;
    else if (max == b) hue = (r-g)/chroma + 4.0;

    return <hue/6.0, chroma/max, max>;
}

vector contrastingColor(vector color) {
    vector hsv = rgb2hsv(color);
    integer shinyColor = FALSE;
    if (hsv.x > 0.03 && hsv.x < 0.58) shinyColor = TRUE;
    integer darkColor = FALSE;
    if (hsv.x > 0.6 && hsv.x < 0.85) darkColor = TRUE;
    
    float newH = hsv.x;
    
    float newS = (1.0 - hsv.y) / 2;
    if (darkColor) {
        newS /= 4;
    }
    
    float newV = 0.9;
    if (shinyColor && hsv.z > 0.5) {
        newV = 0.2;
    }
    if (!darkColor && hsv.y < 0.5 && hsv.z > 0.5) {
        newV = 0.2;
    }
    if (darkColor && hsv.y < 0.3 && hsv.z > 0.5) {
        newV = 0.2;
    }
    //debug((string)color + " hsv " + (string)<newH, newS, newV>);
    return hsv2rgb(<newH, newS, newV>);
}

// "group:3" -> ["group", 3]; "group" -> ["group", ALL_SIDES]
list parseGroupFace(string groupFace) {
    integer colen = llSubStringIndex(groupFace, ":");
    if (colen < 0) return [groupFace, ALL_SIDES];
    return [
        llDeleteSubString(groupFace, colen, -1),
        (integer)llDeleteSubString(groupFace, 0, colen)];
}

// answers a 2-strided list on what color groups the faces of the given link belong to. Stride is [groupName, faceNumber]. it is derived from the description, which is a comma-separated list of group names, optionally followed by a colen and face number. Face number is ALL_SIDES if absent. Does not expand .f
list linkColorGroups(string config) {
    list groups = llParseString2List(config, [","], []);
    integer i;
    for (i = 0; i < llGetListLength(groups); i += 2) {
        string groupFace = llList2String(groups, i);
        groups = llListReplaceList(groups, parseGroupFace(groupFace), i, i);
    }
    return groups;
}

// answers a 1-strided list of color group names
list linkFaceColorGroups(string config, integer faceNumber) {
    list colorGroups = linkColorGroups(config);
    list groups = [];
    integer i;
    for (i = 0; i < llGetListLength(colorGroups); i += 2) {
        string group = llList2String(colorGroups, i);
        integer face = llList2Integer(colorGroups, i+1);
        if (llGetSubString(group, -2, -1) == ".f") {
            groups += [llGetSubString(group, 0, -2) + (string)faceNumber];
        } else if (faceNumber == face || face == ALL_SIDES) {
            groups += [group];
        }
    }
//    debug("linkFaceColorGroups(\"" + config + "\", " + (string)faceNumber + "): " + printList(groups));
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


////////////////////////////////////////////////////////////////////
///////////////////// Selected color gadget ////////////////////////
////////////////////////////////////////////////////////////////////


setSelectedColorGadget() {
    integer linkNumber;

    if (selectedColorGadget == -999) {
        selectedColorGadget == -1;
        for (linkNumber = 0; selectedColorGadget < 0 && linkNumber <= llGetNumberOfPrims(); linkNumber++) {
            if (llGetLinkName(linkNumber) == "selected color") {
                selectedColorGadget = linkNumber;
                if (getActiveColorButton() < 0) {
                    llSetLinkAlpha(selectedColorGadget, 0.0, ALL_SIDES);
                    selectedColorGadgetVisible = FALSE;
                } else {
                    llSetLinkAlpha(selectedColorGadget, 1.0, ALL_SIDES);
                    selectedColorGadgetVisible = TRUE;
                }            
            }
        }
    }
    //if (selectedColorGadget >= 0 && getActiveColorButton() >= 0 && getActiveColorButton() == activeColorButtonNails) {
    //debug("setSelectedColorGadget " + (string)selectedColorGadget + " " + (string)getActiveColorButton());
    if (selectedColorGadget >= 0 && getActiveColorButton() >= 0) {
        if (!selectedColorGadgetVisible) {
            llSetLinkAlpha(selectedColorGadget, 1.0, ALL_SIDES);
            selectedColorGadgetVisible = TRUE;
        }
        vector gadgetPos = llList2Vector(llGetLinkPrimitiveParams(selectedColorGadget, [PRIM_POS_LOCAL]), 0);
        vector buttonPos = llList2Vector(llGetLinkPrimitiveParams(getActiveColorButton(), [PRIM_POS_LOCAL]), 0);
        vector newPos = <gadgetPos.x, buttonPos.y, buttonPos.z>;
//debug("setSelectedColorGadget active:" + (string)activeColorButton + " gadget:" + (string)selectedColorGadget + (string)gadgetPos + " " + (string)buttonPos + " " + (string)newPos);
        llSetLinkPrimitiveParamsFast(selectedColorGadget, [PRIM_POS_LOCAL, newPos]);
    }
}

////////////////////////////////////////////////////////////////////
////////////////////// Color Button Functions //////////////////////
////////////////////////////////////////////////////////////////////

integer getActiveColorButtonIdx() {
    integer idx;
    for (idx = 0; idx < llGetListLength(activeColorButton); idx++) {
        integer linkNum = llList2Integer(activeColorButton, idx);
        if (linkNum > 0) {
            rotation localRot=llList2Rot(llGetLinkPrimitiveParams(linkNum,[PRIM_ROT_LOCAL]),0);
            vector r = llRot2Euler(localRot);
            if (llRound(r.y) == 0) {
                //debug("getActiveColorButtonIdx " + (string)idx);
                return idx;
            }
        }
    }
    return -1;
}

integer getActiveColorButton() {
    integer idx = getActiveColorButtonIdx();
    if (idx >= 0) {
        return llList2Integer(activeColorButton, idx);
    }
    return -1;
}

integer getActiveColorButtonReadFace() {
    integer idx = getActiveColorButtonIdx();
    if (idx >= 0) {
        return llList2Integer(activeColorButtonReadFace, idx);
    }
    return -1;
}

integer getActiveColorButtonWriteFace() {
    integer idx = getActiveColorButtonIdx();
    if (idx >= 0) {
        return llList2Integer(activeColorButtonWriteFace, idx);
    }
    return -1;
}

setActiveColorButtonReadFace(integer face) {
    integer idx = getActiveColorButtonIdx();
    if (idx >= 0) {
        activeColorButtonReadFace = llListReplaceList(activeColorButtonReadFace, [face], idx, idx);
    }
}

setActiveColorButtonWriteFace(integer face) {
    integer idx = getActiveColorButtonIdx();
    if (idx >= 0) {
        activeColorButtonWriteFace = llListReplaceList(activeColorButtonWriteFace, [face], idx, idx);
    }
}

integer isColorButton(integer linkNumber) {
    string linkName = llGetLinkName(linkNumber);
    return linkName == "basic button" || linkName == "image button" || linkName == "specColor image button";
}

integer isTextureButton(integer linkNumber) {
    string linkName = llGetLinkName(linkNumber);
    return linkName == "texture basic" || linkName == "normal basic";
}

setButtonColor(integer linkNumber, string configString) {
    list config = llParseString2List(configString, [":"], []);
    string linkName = llGetLinkName(linkNumber);
//debug("setButtonColor1(" + (string) linkNumber + ", " + linkName + ", " + llList2CSV(config) + ")");
    integer i;
    list params = [];
    for (i = 0; i < llGetListLength(config); i+=2) {
        string type = llList2String(config, i);
        string value = llList2String(config, i+1);
        //debug("setButtonColor2(" + (string) linkNumber + ", " + linkName + ", " + type + ", " + value + ")");
        if (type == "color" && linkName == "basic button") {
            vector color = (vector)value;
            llSetLinkColor(linkNumber, color, getActiveColorButtonWriteFace());
        } else if (type == "color" && linkName == "image button") {
            vector color = (vector)value;
            llSetLinkColor(linkNumber, color, ALL_SIDES);
            // 2 layer mesh button: 0: background. 1: foreground
            llSetLinkColor(linkNumber, contrastingColor(color), 1);
            // cube button: 5: background. 4: foreground
            llSetLinkColor(linkNumber, contrastingColor(color), 4);
        } else if (type == "specColor" && linkName == "specColor image button") {
            vector color = (vector)value;
            llSetLinkColor(linkNumber, color, ALL_SIDES);
            // 2 layer mesh button: 0: background. 1: foreground
            llSetLinkColor(linkNumber, contrastingColor(color), 1);
            // cube button: 5: background. 4: foreground
            llSetLinkColor(linkNumber, contrastingColor(color), 4);
        }
        else if (type == "glow") {
            params += [PRIM_GLOW, getActiveColorButtonWriteFace(), ((float)value)];
        }
        else if (type == "specGloss") {
            //FIXME more then one parameter in group
            list p = llGetLinkPrimitiveParams(linkNumber, [PRIM_SPECULAR, 0]);
            p = llListReplaceList(p, [(integer)value], 5, 5);
            params += [PRIM_SPECULAR, getActiveColorButtonWriteFace()] + p;
        }
    }
    if (params) {
//debug("setButtonColor3: " + llList2CSV(params));
        llSetLinkPrimitiveParamsFast(linkNumber, params);
    }
}

//FIXME also use a:1:b:2 for sending to sliders
list getColorForSliders() {
    list params = llGetLinkPrimitiveParams(getActiveColorButton(), [
        PRIM_COLOR, getActiveColorButtonReadFace(),
        PRIM_GLOW, getActiveColorButtonReadFace(),
        PRIM_SPECULAR, getActiveColorButtonReadFace()
    ]);
    //debug("getButtonColor " + llDumpList2String(params, ";"));
    return [
        "color:"      + llList2String(params, 0),
        "glow:"       + (string)(llList2Float(params, 2)),
        "specGloss:" + llList2String(params, 8)
    ];
}

// input: a 2-strided list of name, commands. commands is a ; seperated list of llSetLinkX commands
setButtonColorParams(integer linkNum, list params) {
//debug("setButtonColorParams(" + (string) linkNum + ", " + printList(params) + ")");
    list config = linkColorGroups(llGetLinkDesc(linkNum));
    integer savedWriteFace = getActiveColorButtonWriteFace();
    integer i;
    integer foundAllGroups = TRUE;
//debug("------ looking for " + (string)(llGetListLength(config)/2));
    for (i = 0; i < llGetListLength(config); i+=2) {
        string colorGroup = llList2String(config, i);
        setActiveColorButtonWriteFace(llList2Integer(config, i+1));
//debug("looking for " + colorGroup + " in " + llList2CSV(params));
        integer j;
        integer foundGroup = FALSE;
        for (j = 0; j < llGetListLength(params); j+=2) {
            if (globMatch(colorGroup, llList2String(params, j))) {
//debug("found " + colorGroup + ": " + llList2String(params, j) + " " + llList2String(params, j+1));
                foundGroup = TRUE;
            }
        }
        foundAllGroups = foundAllGroups && foundGroup;
    }
//debug("------ found all " + (string)foundAllGroups);
    if (foundAllGroups) {
        integer done = FALSE;
        for (i = 0; i < llGetListLength(config) && !done; i+=2) {
            string colorGroup = llList2String(config, i);
            setActiveColorButtonWriteFace(llList2Integer(config, i+1));
//debug("looking for " + colorGroup + " in " + llList2CSV(params));
            integer j;
            for (j = 0; j < llGetListLength(params); j+=2) {
                if (globMatch(colorGroup, llList2String(params, j))) {
//debug("found " + colorGroup + ": " + llList2String(params, j) + " " + llList2String(params, j+1));
                    setButtonColor(linkNum, llList2String(params, j+1));
                    done = TRUE;
                }
            }
        }
    }
    setActiveColorButtonWriteFace(savedWriteFace);
}

// input: a 2-strided list of name, color. color can be either a vector or a string encoding of a vector. Set any prims named name to the associated color
setAllButtonColorParams(list params) {
//debug("setAllButtonColorParams(" + printList(params) + ")");
    integer linkNumber;
    for (linkNumber = 0; linkNumber <= llGetNumberOfPrims(); linkNumber++) {
        if (isColorButton(linkNumber)) {
            setButtonColorParams(linkNumber, params);
        }
    }
}

list colorButtonParams(integer linkNumber, string color) {
    list params = [];
    string linkDesc = llGetLinkDesc(linkNumber);
//debug("linkDesc: \"" + linkDesc + "\"");
    list colorGroups = linkFaceColorGroups(linkDesc, getActiveColorButtonReadFace());
//debug("colorGroups: " + printList(colorGroups));
    integer g;
    integer s;
    for (g = 0; g < llGetListLength(colorGroups); g++) {
        string group = llList2String(colorGroups, g);
        params += [group, color];
    }
//debug("colorButtonParams(" + (string)linkNumber + " (" + linkDesc + "), " + printList(colorSettings) + "): " + printList(params));
    return params;
}

//list getAllColorParams() {
//    list params = ["color"];
//    integer linkNumber;
//    for (linkNumber = 0; linkNumber <= llGetNumberOfPrims(); linkNumber++) {
//        if (isColorButton(linkNumber)) {
//            list color = getButtonColor(linkNumber);
//            params += colorButtonParams(linkNumber, color);
//        }
//    }
//    return params;
//}

setActiveColorButton(integer linkNumber, integer faceNumber) {
    vector localPos=llList2Vector(llGetLinkPrimitiveParams(linkNumber,[PRIM_POS_LOCAL]),0);
    integer idx = (integer)((localPos.x - 0.3)*2);
    //debug("localPos.x " + (string)localPos.x + " -> " + (string)((localPos.x - 0.2)*2) + " -> " + (string)idx);
    activeColorButton = llListReplaceList(activeColorButton, [linkNumber], idx, idx);
    if (llGetLinkName(linkNumber) == "basic button") {
        setActiveColorButtonReadFace(faceNumber);
        setActiveColorButtonWriteFace(faceNumber);
    } else {
        setActiveColorButtonReadFace(0);
        setActiveColorButtonWriteFace(ALL_SIDES);
    }
    setSelectedColorGadget();
}

setActiveColor(string color) {
    if (llGetLinkName(getActiveColorButton()) == "specColor image button") {
        color =  "specColor" + llGetSubString(color, 5,  -1); //FIXME
        //debug("setActiveColor1: " + color + " -> " + tmp);
    }
    list params = colorButtonParams(getActiveColorButton(), color);
//debug("setActiveColor: " + color + " -> " + llList2CSV(params));
    sendToAvatar(["color"] + params);
    setAllButtonColorParams(params);
}


////////////////////////////////////////////////////////////////////
///////////////////// Texture button Functions /////////////////////
////////////////////////////////////////////////////////////////////

processTexture(integer linkNumber) {
    string linkDesc = llGetLinkDesc(linkNumber);
    list groups = llParseString2List(linkDesc, [","], []);
    list params = ["color"];
    
    string type = "texture:";
    if (llGetSubString(llGetLinkName(linkNumber), 0, 5) == "normal") type = "normal:";
    //debug("'" + llGetSubString(llGetLinkName(linkNumber), 0, 5) + "'");
    integer i;
    for (i = 0; i < llGetListLength(groups); i += 2) {
        string faceName = llList2String(groups, i);
        string uuid = llList2String(groups, i+1);
        if (faceName == "CURRENT") {
            if (getActiveColorButton() < 0) {
                //sendInfoNoActiveArea();
                return;
            }
            string activeDesc = llGetLinkDesc(getActiveColorButton());
            //FIXḾE set fingernail texture in plate and tip
            if (activeDesc == "fnLF,fnLT,fnRF,fnRT") {
                activeDesc = "fnLF,fnLT,fnRF,fnRT,fnLFTip,fnLTTip,fnRFTip,fnRTTip";
            } else if (activeDesc == "fnLF") {
                activeDesc = "fnLF,fnLFTip";
            } else if (activeDesc == "fnLT") {
                activeDesc = "fnLT,fnLTTip";
            } else if (activeDesc == "fnRF") {
                activeDesc = "fnRF,fnRFTip";
            } else if (activeDesc == "fnRT") {
                activeDesc = "fnRT,fnRTTip";
            } else if (activeDesc == "tnLF,tnLT,tnRF,tnRT") {
                activeDesc = "tnLF,tnLT,tnRF,tnRT,tnLFTip,tnLTTip,tnRFTip,tnRTTip";
            } else if (activeDesc == "tnLF") {
                activeDesc = "tnLF,tnLFTip";
            } else if (activeDesc == "tnLT") {
                activeDesc = "tnLT,tnLTTip";
            } else if (activeDesc == "tnRF") {
                activeDesc = "tnRF,tnRFTip";
            } else if (activeDesc == "tnRT") {
                activeDesc = "tnRT,tnRTTip";
            }
            list activeGroups = llParseString2List(activeDesc, [","], []);
            integer c;
            for (c = 0; c < llGetListLength(activeGroups); c++) {
                string activeFaceName = llList2String(activeGroups, c);
//debug("processTexture current " + activeFaceName + ", " + uuid);                
                params += [activeFaceName, type + uuid];
            }
        } else {
//debug("processTexture " + faceName + ", " + uuid);
            params += [faceName, type + uuid];
        }
    }
//debug("params: " + printList(params));
    sendToAvatar(params);

}


////////////////////////////////////////////////////////////////////
////////////////// Alpha hide button Functions /////////////////////
////////////////////////////////////////////////////////////////////

// answers the value of the given check mark: TRUE if checked, FALSE if not, or -1 and an error if not found
integer getHideButtonValue(integer linkNumber, integer faceNumber) {
    list faceColor = llGetLinkPrimitiveParams(linkNumber, [PRIM_COLOR, faceNumber]);
    float alpha = llList2Float(faceColor, 1);
    return alpha > ((ON_ALPHA + OFF_ALPHA) / 2.0);
    //vector color = llGetLinkColor(linkNumber, faceNumber);
    //return color == ON_COLOR;
}

// set the value of the given check mark and answer the new value: TRUE if checked, FALSE if not
integer setHideButtonValue(integer linkNumber, integer faceNumber, integer value) {
    float alpha = OFF_ALPHA;
    //vector color = OFF_COLOR_HIDE;
    if (value) {
        alpha = ON_ALPHA;
        //color = ON_COLOR;
    }
//    llSetLinkAlpha(linkNumber, alpha, 0);
//llOwnerSay("llSetLinkColor(" + (string)linkNumber + ", " + (string)color + ", " + (string)ALL_SIDES);
//    llSetLinkColor(linkNumber, color, faceNumber);
    llSetLinkAlpha(linkNumber, alpha, faceNumber);
    return value;
}

// toggle the value of the given check mark and answer the new value: TRUE if checked, FALSE if not, or -1 and an error if not found
integer toggleHideButtonValue(integer linkNumber, integer faceNumber) {
    return setHideButtonValue(linkNumber, faceNumber, !getHideButtonValue(linkNumber, faceNumber));
}

// Set the faces in linkNumber that match optionNames to value. value can be TRUE (set on), FALSE (set off), or -1 (toggle). Answers the value any matching faces were set to
integer scanAndSetHideButton(integer linkNum, list optionNames, integer value) {
    list config = linkColorGroups(llGetLinkDesc(linkNum));
//debug("looking for " + printList(optionNames) + " in " + printList(config));
    integer i;
    for (i = 0; i < llGetListLength(config); i += 2) {
        string faceName = llList2String(config, i);
        integer faceNum = llList2Integer(config, i+1);
        integer j;
        for (j = 0; j < llGetListLength(optionNames); j++) {
            if (globMatch(faceName, llList2String(optionNames, j))) {
//debug("found " + faceName);
                if (value < 0) {
                    value = toggleHideButtonValue(linkNum, faceNum);
                } else {
                    setHideButtonValue(linkNum, faceNum, value);
                }
            }
        }
    }
    return value;
}

// Set the faces in linkNumber from the COLOR_SYNC params [name, color, alpha, name...]
syncHideButton(integer linkNum, list params) {
    list config = llParseStringKeepNulls(llGetLinkDesc(linkNum), [",", ":"], []);
//debug("looking for [" + llList2CSV(params) + "] in [" + llList2CSV(config) + "]");
//debug("looking in [" + llList2CSV(config) + "]");
    integer i;
    for (i = 0; i < llGetListLength(config); i += 2) {
        string faceName = llList2String(config, i);
        integer faceNum = llList2Integer(config, i+1);
        integer nameIndex;
        nameIndex = llListFindList(params, [faceName]);
        if (nameIndex >= 0) {
//debug("found " + faceName + ", " + (string) faceNum + " = " + llList2String(params, nameIndex) + " " + llList2String(params, nameIndex + 1));
            list todo = llParseString2List(llList2String(params, nameIndex + 1), [";", ":"], []);
            integer i;
            for (i = 0; i < llGetListLength(todo); i+=2) {
                string type = llList2String(todo, i);
                if (type == "alpha") {
                    integer value = (integer)llList2Float(todo, i+1);
//debug("setAlpha: " + (string) value);                    
                    setHideButtonValue(linkNum, faceNum, value);
                }
            }
        }
    }
}

// Set the faces in all hide prims that match optionNames to value. value can be TRUE (set on), FALSE (set off), or -1 (toggle). Answers the value any matching faces were set to
integer scanAndSetHideButtons(list optionNames, integer value) {
    integer linkNum;
    for (linkNum = 1; linkNum <= llGetNumberOfPrims(); linkNum++) {
        string linkName = llGetLinkName(linkNum);
        if (linkName == "hide") {
            value = scanAndSetHideButton(linkNum, optionNames, value);
         }
    }
    return value;
}


list alphaHideParams(list colorGroups, integer visible) {
    list params = ["color"];
    integer i;
    for (i = 0; i < llGetListLength(colorGroups); i++) {
        string group = llList2String(colorGroups, i);
        params += [group, "alpha:" + (string)visible];
    }
    return params;
}

////////////////////////////////////////////////////////////////////
////////////////////// Messaging Functions /////////////////////////
////////////////////////////////////////////////////////////////////

integer channel() {
    // Convert a key to an integer using the first 8 hex digits (32 bits)
    return HUD_CHANNEL ^ (integer)("0x" + llGetSubString((string)llGetOwner(), 0, 7));
}

sendTo(key id, list message) {
    string m = llDumpList2String(message, ";");
    llRegionSayTo(id, channel(), m);
}

sendToAvatar(list message) {
    string s = llDumpList2String(message, ";");
    debug("sendToAvatar " + s);
    llSay(channel(), s);
}

integer listener;
listenForSyncRequests() {
    llListenRemove(listener);
    listener = llListen(channel(), "", NULL_KEY, "");
}

init() {
    integer linkNumber;
    for (linkNumber = 0; linkNumber <= llGetNumberOfPrims(); linkNumber++) {
        string linkName = llGetLinkName(linkNumber);
        string linkDesc = llGetLinkDesc(linkNumber);
        //if (linkName == "image button" && linkDesc == "fnLF,fnLT,fnRF,fnRT") {
        //    //debug("init nails default " + (string)linkNumber);
        //    activeColorButtonNails = linkNumber;
        //    activeColorButtonNailsReadFace = 0;
        //    activeColorButtonNailsWriteFace = ALL_SIDES;
        //}
        //if (linkName == "image button" && linkDesc == "privateTint") {
        //    //debug("init private default " + (string)linkNumber);
        //    activeColorButtonPrivate = linkNumber;
        //    activeColorButtonPrivateReadFace = 0;
        //    activeColorButtonPrivateWriteFace = ALL_SIDES;
        //}
        if (linkName == "image button" && linkDesc == "pants0,pants1,pants2,pants3,pants4,pants5,pants6,pants7") {
            //debug("init default 0 " + (string)linkNumber);
            activeColorButton = llListReplaceList(activeColorButton, [linkNumber], 0, 0);
            setActiveColorButtonReadFace(0);
            setActiveColorButtonWriteFace(ALL_SIDES);
        }
        if (linkName == "image button" && linkDesc == "shirt0,shirt1,shirt2,shirt3,shirt4,shirt5,shirt6,shirt7") {
            //debug("init default 1 " + (string)linkNumber);
            activeColorButton = llListReplaceList(activeColorButton, [linkNumber], 1, 1);
            setActiveColorButtonReadFace(0);
            setActiveColorButtonWriteFace(ALL_SIDES);
        }
        if (linkName == "image button" && linkDesc == "string0,string1") {
            //debug("init default 2 " + (string)linkNumber);
            activeColorButton = llListReplaceList(activeColorButton, [linkNumber], 2, 2);
            setActiveColorButtonReadFace(0);
            setActiveColorButtonWriteFace(ALL_SIDES);
        }
    }
    //debug("init " + llList2CSV(activeColorButton));
}

default {
    on_rez(integer param) {
        llResetScript();
    }

    state_entry() {
        init();
        llOwnerSay(llGetScriptName() + " Free memory: " + (string)llGetFreeMemory());
        setSelectedColorGadget();
        listenForSyncRequests();
        sendToAvatar([COLOR_SYNC_REQUEST]);
    }
    
    changed (integer change) {
        if (change & (CHANGED_OWNER | CHANGED_INVENTORY | CHANGED_LINK)) {
            llResetScript();
        }
    }
    
    touch_start(integer total_number) {
        integer linkNumber = llDetectedLinkNumber(0);
        integer faceNumber = llDetectedTouchFace(0);
        string linkName = llGetLinkName(linkNumber);
        string linkDesc = llGetLinkDesc(linkNumber);
        vector rawInput = llDetectedTouchST(0);

        if (isColorButton(linkNumber)) {
            setActiveColorButton(linkNumber, faceNumber);
//debug("send set_color " + llDumpList2String(getActiveColor(), ";"));
            llMessageLinked(LINK_SET, SET_COLOR_SYNC, llDumpList2String(getColorForSliders(), ";"), "");
        } else if (isTextureButton(linkNumber)) {
            processTexture(linkNumber);
        } else if (linkName == "hide") {
            list colorGroups = linkFaceColorGroups(linkDesc, faceNumber);
            integer visible = toggleHideButtonValue(linkNumber, faceNumber);
            sendToAvatar(alphaHideParams(colorGroups, visible));
        } else if (llGetSubString(linkName, 0, 8) == "hideGroup") {
            list colorGroups = linkFaceColorGroups(linkDesc, faceNumber);
            integer visible = scanAndSetHideButtons(colorGroups, -1);
            sendToAvatar(alphaHideParams(colorGroups, visible));
        }
    }

    link_message (integer sender_num, integer num, string str, key id) {
        if (num == COLOR_CHANGED) {
//debug("COLOR CHANGED " + str);
            if (getActiveColorButton() < 0) {
                //sendInfoNoActiveArea();
                return;
            }
            setActiveColor(str);
        } else if (num == HUD_PLANE_CHANGED) {
            //debug("HUD PLANE CHANGED " + str);
            if (getActiveColorButton() >= 0) {
                llMessageLinked(LINK_SET, SET_COLOR_SYNC, llDumpList2String(getColorForSliders(), ";"), "");
                setSelectedColorGadget();
            }
        }
    }

    listen(integer channel, string name, key id, string msg) {
        list params = llParseStringKeepNulls(msg, [";"], []);
        msg = "";
        if  (llList2String(params, 0) == COLOR_SYNC_COMMAND) {
            params = llList2List(params, 1, -1);
            debug("COLORSYNC " + llList2CSV(params));
            //processSync(params);
            //debug("ps1 " + (string)llGetFreeMemory());
            //debug("processSync([" + llList2CSV(params) + "])");
            integer linkNumber;
            for (linkNumber = 0; linkNumber <= llGetNumberOfPrims(); linkNumber++) {
                if (isColorButton(linkNumber)) {
                    setButtonColorParams(linkNumber, params);
                } else if (llGetLinkName(linkNumber) == "hide") {
                    syncHideButton(linkNumber, params);
                }
            }
            //debug("ps2 " + (string)llGetFreeMemory());

            if (getActiveColorButton() >= 0) {
                llMessageLinked(LINK_SET, SET_COLOR_SYNC, llDumpList2String(getColorForSliders(), ";"), "");
            }
        }
    }

}
