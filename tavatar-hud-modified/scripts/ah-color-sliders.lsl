// this is a modified version of
// https://marketplace.secondlife.com/p/Tavatar-ColorTexture-HUD-Kit-Free/4299174

string COLOR_PICKER_LINK_NAME = "Color Picker";
integer COLOR_PICKER_LINK = -1;
vector cachedColor;

string GLOW_PICKER_LINK_NAME = "Glow Picker";
integer GLOW_PICKER_LINK = -1;
float cachedGlow;

string SHINY_PICKER_LINK_NAME = "Shiny Picker";
integer SHINY_PICKER_LINK = -1;
integer cachedGloss;

string FULLBRIGHT_PICKER_LINK_NAME = "Fullbright Picker";
integer FULLBRIGHT_PICKER_LINK = -1;
integer cachedFullBright;

string ALPHAMODE_PICKER_LINK_NAME = "Alphamode Picker";
integer ALPHAMODE_PICKER_LINK = -1;
integer cachedAlphaMode;

//* Mesh config
string           HUE_SAT_TEXTURE = "03422dcb-ab0b-18dd-ae48-5e271240677b";
string             VALUE_TEXTURE = "643de1bf-3cb2-7512-6da6-5c7ca926669c";
string HUE_SAT_INDICATOR_TEXTURE = "ec18f540-32a6-ea59-06e2-bfa6646ea296";
string   VALUE_INDICATOR_TEXTURE = "ad9041c8-ebe8-d9af-55db-bddbef0b9d1d";
string    GLOW_INDICATOR_TEXTURE = "bb5b0c7b-231c-cc50-7aec-1240cef44f43";
string   SHINY_INDICATOR_TEXTURE = "bb5b0c7b-231c-cc50-7aec-1240cef44f43";
string CENTAUR_INDICATOR_TEXTURE = "d1ccfd55-cdef-a8d9-c1de-321daa832653";

integer HUE_SAT_FACE = 0;
integer VALUE_FACE = 1;
integer HUE_SAT_INDICATOR_FACE = 2;
integer VALUE_INDICATOR_FACE = 3;
integer GLOW_FACE = 1;
integer GLOW_INDICATOR_FACE = 3;
integer SHINY_FACE = 1;
integer SHINY_INDICATOR_FACE = 3;

rotation HUE_SAT_RECT = < 0.15, 0.0556,  0.982 , 0.9444>;
rotation    GLOW_RECT = <0.1, 0.5, 0.9, 0.5001>;
rotation   SHINY_RECT = <0.1, 0.5, 0.9, 0.5001>;
rotation   VALUE_RECT = <0.5, 0.0556, 0.501, 0.9444>;

/*/ // Prim config
string           HUE_SAT_TEXTURE = "03422dcb-ab0b-18dd-ae48-5e271240677b";
string             VALUE_TEXTURE = "643de1bf-3cb2-7512-6da6-5c7ca926669c";
string HUE_SAT_INDICATOR_TEXTURE = "ec18f540-32a6-ea59-06e2-bfa6646ea296";
string   VALUE_INDICATOR_TEXTURE = "68105a85-e4dd-84c9-2de3-0b5e8dfe9c8e";
string    GLOW_INDICATOR_TEXTURE = "bb5b0c7b-231c-cc50-7aec-1240cef44f43";
string   SHINY_INDICATOR_TEXTURE = "bb5b0c7b-231c-cc50-7aec-1240cef44f43";
string CENTAUR_INDICATOR_TEXTURE = "d1ccfd55-cdef-a8d9-c1de-321daa832653";

integer HUE_SAT_FACE = 5;
integer VALUE_FACE = 7;
integer HUE_SAT_INDICATOR_FACE = 3;
integer VALUE_INDICATOR_FACE = 4;
integer GLOW_FACE = 5;
integer GLOW_INDICATOR_FACE = 3;
integer SHINY_FACE = 5;
integer SHINY_INDICATOR_FACE = 3;

rotation HUE_SAT_RECT = <0.15, 0.0556, 0.982 , 0.9444>;
rotation   VALUE_RECT = <0.25, 0.0556, 0.2501, 0.9444>;
rotation    GLOW_RECT = <0.1, 0.5, 0.9, 0.5001>;
rotation   SHINY_RECT = <0.1, 0.5, 0.9, 0.5001>;
//*/

////////////////////////////////////////////////////////////////////
///////////////////////// Other Constants //////////////////////////
////////////////////////////////////////////////////////////////////

rotation     ONE_RECT = <0.0 , 0.0   , 1.0   , 1.0   >;

vector ONE_VECTOR = <1.0, 1.0, 1.0>;

string COLOR_SAVER = "color saver";
string COLOR_HELP = "color help";
float SAVE_HOLD_TIME = 3.0; // seconds

float NOTIFICATION_RATE_LIMIT = 0.5; // seconds

// channels for interacting with the color picker and sliders
integer SET_COLOR = 93759837;
integer COLOR_CHANGED = 93759838;
integer SET_COLOR_SYNC = 93759839;

///////////////////////////////////////////////////////////////
///////////////////////// DEBUGGING ///////////////////////////
///////////////////////////////////////////////////////////////


debug(string msg) {
    llOwnerSay(llGetScriptName() + ": " + msg);
}

// round a vector to integers and print
string printIntVector(vector v) {
    v += <0.5, 0.5, 0.5>;
    return
        (string)((integer)v.x) + ", " +
        (string)((integer)v.y) + ", " +
        (string)((integer)v.z);
}

// print an rgb color vector (0..1) as (0..255)
string printRGB(vector rgb) {
    return printIntVector(rgb * 255.0);
}

// print an hsb color vector <1.0, 1.0, 1.0> as 360, 100, 100
string printHSB(vector hsb) {
    hsb.x *= 360;
    hsb.y *= 100;
    hsb.z *= 100;
    return printIntVector(hsb);
}


////////////////////////////////////////////////////////////////////
//////////////////////// Color Conversion //////////////////////////
////////////////////////////////////////////////////////////////////

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
    vector highContrast = ZERO_VECTOR;
    if (color.x < 0.5) highContrast.x = 1.0;
    if (color.y < 0.5) highContrast.y = 1.0;
    if (color.z < 0.5) highContrast.z = 1.0;
    return highContrast;
//    return <1.0, 1.0, 1.0> - color;
}

////////////////////////////////////////////////////////////////////
///////////////////// Slider Common Utilities //////////////////////
////////////////////////////////////////////////////////////////////

// Touch coordinates range from 0.0, 1.0 in upper left to 1.0, 0.0 in lower right
// Offsets range from 0.5, -0.5 in upper left to -0.5, 0.5 in lower right

/* convert a point to the integer index of the nearest point in the 0.0 - 1.0 square grid. For example, for 5 rows and 3 columns, the conversion would be:
 0: <0.0, 0.0 , 0.0>  1: <0.5, 0.0 , 0.0>  2: <1.0, 0.0 , 0.0>
 3: <0.0, 0.25, 0.0>  4: <0.5, 0.25, 0.0>  5: <1.0, 0.25, 0.0>
 6: <0.0, 0.5 , 0.0>  7: <0.5, 0.5 , 0.0>  8: <1.0, 0.5 , 0.0>
 9: <0.0, 0.75, 0.0> 10: <0.5, 0.75, 0.0> 11: <1.0, 0.75, 0.0>
12: <0.0, 1.0 , 0.0> 13: <0.5, 1.0 , 0.0> 14: <1.0, 1.0 , 0.0>
*/
integer point2GridIndex(vector point, integer cols, integer rows) {
    float cellWidth  = 1.0;
    float cellHeight = 1.0;
    if (cols > 1) cellWidth  = 1.0 / (cols - 1);
    if (rows > 1) cellHeight = 1.0 / (rows - 1);

    integer col = (integer)llFloor((point.x + cellWidth /2.0) / cellWidth );
    integer row = (integer)llFloor((point.y + cellHeight/2.0) / cellHeight);

    if (col < 0) col = 0;
    if (row < 0) row = 0 ;
    if (col >= cols) col = cols - 1;
    if (row >= rows) row = rows - 1;

    return row * cols + col;
}

/* inverse of point2GridIndex */
vector gridIndex2Point(integer index, integer cols, integer rows) {
    if (index < 0) index = 0;
    if (index >= rows * cols) index = rows * cols - 1;

    integer col = index % cols;
    integer row = index / cols;

    vector point = <0.5, 0.5, 0.0>;
    if (cols > 1) point.x = col * 1.0 / (cols - 1);
    if (rows > 1) point.y = row * 1.0 / (rows - 1);
    return point;
}

// keep <point.x, point.y> within the rectangle rect: <xMin, yMin, xMax, yMax>
vector keepWithinRect(vector point, rotation rect) {
    if (point.x < rect.x) point.x = rect.x;
    if (point.y < rect.y) point.y = rect.y;
    if (point.x > rect.z) point.x = rect.z;
    if (point.y > rect.s) point.y = rect.s;
    return point;
}

vector scalePointFromRectToRect(vector point, rotation srcRect, rotation destRect) {
    float slope = (destRect.x - destRect.z)/(srcRect.x - srcRect.z);
    float intercept = destRect.x - slope * srcRect.x;
    point.x = intercept + slope * point.x;
    slope = (destRect.y - destRect.s)/(srcRect.y - srcRect.s);
    intercept = destRect.y - slope * srcRect.y;
    point.y = intercept + slope * point.y;
    return point;
}

vector llGetLinkColor(integer link, integer face) {
    return llList2Vector(llGetLinkPrimitiveParams(link, [PRIM_COLOR, face]), 0);
}

// component multiply
vector mult(vector a, vector b) {
    return <a.x * b.x, a.y * b.y, a.z * b.z>;
}

// component divide
vector div(vector a, vector b) {
    return <a.x / b.x, a.y / b.y, 0.0>; // repeats.z is always 0. ignore
}

// convert a touch position to a texture offset
vector touchPos2Offset(vector touchPos, vector repeats) {
    return mult(<0.5, 0.5, 0.0> - touchPos, repeats);
}

// convert a texture offset to a touch position
vector offset2TouchPos(vector offset, vector repeats) {
    return <0.5, 0.5, 0.0> - div(offset, repeats);
}

////////////////////////////////////////////////////////////////////
//////////////////// High-Level Slider API /////////////////////////
////////////////////////////////////////////////////////////////////

// Params to pass to llSetLinkPrimitiveParamsFast to set the slider
list setSliderParams(integer linkNum, integer face, vector value, rotation rect, key texture) {
    list params = llGetLinkPrimitiveParams(linkNum, [PRIM_TEXTURE, face]);
    vector repeats = llList2Vector(params, 1);
    vector offset = scalePointFromRectToRect(value, ONE_RECT, rect);
    offset = touchPos2Offset(offset, repeats);
    return [PRIM_TEXTURE, face, texture, repeats, offset, 0.0];
}

vector getTouchValue(vector rawInput, rotation rect) {
    return scalePointFromRectToRect(keepWithinRect(rawInput, rect), rect, ONE_RECT);
}

vector getSliderValue(integer linkNum, integer face, rotation rect) {
    list params = llGetLinkPrimitiveParams(linkNum, [PRIM_TEXTURE, face]);
    vector repeats = llList2Vector(params, 1);
    vector offset = llList2Vector(params, 2);
    vector input = offset2TouchPos(offset, repeats);
    return scalePointFromRectToRect(input, rect, ONE_RECT);
}

////////////////////////////////////////////////////////////////////
/////////////////////// Color Widget Logic /////////////////////////
////////////////////////////////////////////////////////////////////

vector getColorHSV() {
    if (COLOR_PICKER_LINK == -1) return ZERO_VECTOR; // error
    vector hsv = getSliderValue(COLOR_PICKER_LINK, HUE_SAT_INDICATOR_FACE, HUE_SAT_RECT);
    vector v = getSliderValue(COLOR_PICKER_LINK, VALUE_INDICATOR_FACE, VALUE_RECT);
    hsv.z = v.y;
    return hsv;
}

vector getColor() {
    cachedColor = hsv2rgb(getColorHSV());
    return cachedColor;
}

basicSetColor(vector hsv, vector rgb) {
    cachedColor = rgb;
    if (COLOR_PICKER_LINK == -1) return; // error
    
    vector v = <hsv.z, hsv.z, hsv.z>;
    vector hs;
    if (hsv.z == 0.0) hs = hsv2rgb(<hsv.x, hsv.y, 1.0>);
    else hs = rgb / hsv.z;
    vector inverse = contrastingColor(rgb);

    llSetLinkPrimitiveParamsFast(COLOR_PICKER_LINK, 
        setSliderParams(COLOR_PICKER_LINK, HUE_SAT_INDICATOR_FACE, hsv,
            HUE_SAT_RECT, HUE_SAT_INDICATOR_TEXTURE) +
        setSliderParams(COLOR_PICKER_LINK, VALUE_INDICATOR_FACE, v,
            VALUE_RECT, VALUE_INDICATOR_TEXTURE) + [
        PRIM_COLOR, HUE_SAT_FACE, v, 1.0,
        PRIM_COLOR, VALUE_FACE, hs, 1.0,
        PRIM_COLOR, HUE_SAT_INDICATOR_FACE, inverse, 1.0]);
}

setColorHSV(vector hsv) {
    basicSetColor(hsv, hsv2rgb(hsv));
}

setColor(vector rgb) {
    basicSetColor(rgb2hsv(rgb), rgb);
}

float getGlow() {
    if (GLOW_PICKER_LINK == -1) return 0.0; // error
    vector v = getSliderValue(GLOW_PICKER_LINK, GLOW_INDICATOR_FACE, GLOW_RECT);
    cachedGlow = llPow(v.x, 4);
    return cachedGlow;
}

basicSetGlowSlider(float glow) {
//debug("basicSetGlowSlider " + (string)glow);
    if (GLOW_PICKER_LINK == -1) return; // error
    llSetLinkPrimitiveParamsFast(GLOW_PICKER_LINK, setSliderParams(GLOW_PICKER_LINK,
        GLOW_INDICATOR_FACE, <glow, 0.0, 0.0>, GLOW_RECT, GLOW_INDICATOR_TEXTURE));
}

setGlow(float glow) {
    cachedGlow = glow;
    basicSetGlowSlider(llPow(glow, 0.25));
}

//integer getShiny() {
//    if (SHINY_PICKER_LINK == -1) return 0; // error
//    cachedShiny = point2GridIndex(getSliderValue(SHINY_PICKER_LINK, SHINY_INDICATOR_FACE, SHINY_RECT), 4, 1);
//    return cachedShiny;
//}

//setShiny(integer shiny) {
//    cachedShiny = shiny;
//    if (SHINY_PICKER_LINK == -1) return; // error
//    llSetLinkPrimitiveParamsFast(SHINY_PICKER_LINK, setSliderParams(SHINY_PICKER_LINK,
//        SHINY_INDICATOR_FACE, gridIndex2Point(shiny, 4, 1), SHINY_RECT, SHINY_INDICATOR_TEXTURE));
//}

float getGloss() {
    if (SHINY_PICKER_LINK == -1) return 0; // error
    vector v = getSliderValue(SHINY_PICKER_LINK, SHINY_INDICATOR_FACE, SHINY_RECT);
    cachedGloss = (integer)(v.x * 255);
//debug("cachedGloss = " + (string)cachedGloss);
    return cachedGloss;
}

basicSetGlossSlider(float gloss) {
//debug("basicSetGlossSlider " + (string)gloss);
    if (SHINY_PICKER_LINK == -1) return; // error
    llSetLinkPrimitiveParamsFast(SHINY_PICKER_LINK, setSliderParams(SHINY_PICKER_LINK,
        SHINY_INDICATOR_FACE, <gloss, 0.0, 0.0>, SHINY_RECT, SHINY_INDICATOR_TEXTURE));
}

setGloss(integer gloss) {
//debug("setGloss " + (string)gloss);
    cachedGloss = gloss;
    basicSetGlossSlider(gloss / 255.0);
}

integer getFullBright() {
    if (FULLBRIGHT_PICKER_LINK == -1) return 0; // error
    integer faceNum;
    for (faceNum = 0; faceNum < llGetLinkNumberOfSides(FULLBRIGHT_PICKER_LINK); faceNum++) {
        float alpha = llList2Float(llGetLinkPrimitiveParams(FULLBRIGHT_PICKER_LINK, [PRIM_COLOR, faceNum]), 1);
//debug("face: " + (string)faceNum + "; alpha: " + (string)alpha);
        if (alpha > 0.5) {
            cachedFullBright = faceNum;
            return cachedFullBright;
        }
    }
    cachedFullBright = 0;
    return cachedFullBright;
}

setFullBright(integer on) {
    cachedFullBright = on;
    if (FULLBRIGHT_PICKER_LINK == -1) return; // error
    llSetLinkAlpha(FULLBRIGHT_PICKER_LINK, 0.0, ALL_SIDES);
    llSetLinkAlpha(FULLBRIGHT_PICKER_LINK, 1.0, on);
}

integer getAlphaMode() {
    if (ALPHAMODE_PICKER_LINK == -1) return 0; // error
    integer faceNum;
    for (faceNum = 0; faceNum < llGetLinkNumberOfSides(ALPHAMODE_PICKER_LINK); faceNum++) {
        float alpha = llList2Float(llGetLinkPrimitiveParams(ALPHAMODE_PICKER_LINK, [PRIM_COLOR, faceNum]), 1);
//debug("face: " + (string)faceNum + "; alpha: " + (string)alpha);
        if (alpha > 0.5) {
            cachedAlphaMode = faceNum;
            return cachedAlphaMode;
        }
    }
    cachedAlphaMode = 0;
    return cachedAlphaMode;
}

setAlphaMode(integer on) {
    cachedAlphaMode = on;
    if (ALPHAMODE_PICKER_LINK == -1) return; // error
    llSetLinkAlpha(ALPHAMODE_PICKER_LINK, 0.0, ALL_SIDES);
    llSetLinkAlpha(ALPHAMODE_PICKER_LINK, 1.0, on);
}

string lastNotifyColorChanged = "X";

basicNotifyColorChanged () {
    if (COLOR_PICKER_LINK < 0) return;

    string msg = "color:" + (string)cachedColor;
    if (GLOW_PICKER_LINK >= 0) msg += ":glow:" + (string)cachedGlow;
    if (SHINY_PICKER_LINK >= 0) msg += ":specGloss:" + (string)cachedGloss;
    if (FULLBRIGHT_PICKER_LINK >= 0) msg += ":fullbright:" + (string)cachedFullBright;
    if (ALPHAMODE_PICKER_LINK >= 0) msg += ":alphaMode:" + (string)cachedAlphaMode + "|128";
//debug("basicNotifyColorChanged " + lastNotifyColorChanged + " -> " + msg);

    if (lastNotifyColorChanged == msg) {
        return;
    }
    lastNotifyColorChanged = msg;
    llMessageLinked(LINK_SET, COLOR_CHANGED, msg, "");
}

notifyColorChanged () {
    float timeToNextNotify = NOTIFICATION_RATE_LIMIT - llGetTime();
    if (timeToNextNotify < 0) {
        basicNotifyColorChanged();
        llSetTimerEvent(0.0);
        llResetTime();
    } else {
        llSetTimerEvent(timeToNextNotify);
    }
}


integer setAllColorPickers(list config) {
    vector color = <-999, -999, -999>;
    float glow = -999;
    integer gloss = -999;
    integer fullBright = -999;
    integer alphaMode = -999;

    integer i;
    for (i = 0; i < llGetListLength(config); i+=2) {
        string type = llList2String(config, i);
        string value = llList2String(config, i+1);
        if (type == "color") color = (vector)value;
        else if (type == "glow") glow = (float)value;
        else if (type == "specGloss") gloss = (integer)value;
        else if (type == "fullbright") fullBright = (integer)value;
        else if (type == "alphaMode") alphaMode = (integer)value;
    }

    COLOR_PICKER_LINK = -1;
    GLOW_PICKER_LINK = -1;
    SHINY_PICKER_LINK = -1;
    FULLBRIGHT_PICKER_LINK = -1;
    ALPHAMODE_PICKER_LINK = -1;

    for (i = 0; i <= llGetNumberOfPrims(); i++) {
        string linkName = llGetLinkName(i);
        if (linkName == COLOR_PICKER_LINK_NAME) {
            COLOR_PICKER_LINK = i;
            getColor(); // cache it
            if (color.x != -999) setColor(color);
        } else if (linkName == GLOW_PICKER_LINK_NAME) {
            GLOW_PICKER_LINK = i;
            getGlow(); // cache it
            if (glow != -999) setGlow(glow);
        } else if (linkName == SHINY_PICKER_LINK_NAME) {
            SHINY_PICKER_LINK = i;
            getGloss(); // cache it
            if (gloss != -999) setGloss(gloss);
        } else if (linkName == FULLBRIGHT_PICKER_LINK_NAME) {
            FULLBRIGHT_PICKER_LINK = i;
            getFullBright(); // cache it
            if (fullBright != -999) setFullBright(fullBright);
        } else if (linkName == ALPHAMODE_PICKER_LINK_NAME) {
            ALPHAMODE_PICKER_LINK = i;
            getAlphaMode(); // cache it
            if (alphaMode != -999) setAlphaMode(alphaMode);
        }
    }

    return COLOR_PICKER_LINK != -1;
}

////////////////////////////////////////////////////////////////////
////////////////////////// User Interface //////////////////////////
////////////////////////////////////////////////////////////////////

integer touchStartLink = -1;
integer touchStartFace = -1;
float   touchStartTime;

onPaletteTouched(integer linkNum, integer face, vector rawInput) {
    COLOR_PICKER_LINK = linkNum; // activate this picker
    // behave sensibly when out of bounds drags happen
    if (touchStartFace == face) {
        // normal case; do nothing
    } else if (touchStartFace == HUE_SAT_INDICATOR_FACE &&
            face == VALUE_INDICATOR_FACE) {
        rawInput.x = 1.0;
    } else if (touchStartFace == VALUE_INDICATOR_FACE &&
            face == HUE_SAT_INDICATOR_FACE) {
        rawInput.x = 0.0;
    } else if (touchStartFace != face) {
        return;
    }
    face = touchStartFace;

    vector input;
    vector hsv = getColorHSV();
    if (face == HUE_SAT_INDICATOR_FACE) {
        input = getTouchValue(rawInput, HUE_SAT_RECT);
        hsv.x = input.x;
        hsv.y = input.y;
    } else if (face == VALUE_INDICATOR_FACE) {
        input = getTouchValue(rawInput, VALUE_RECT);
        hsv.z = input.y;
    }
    setColorHSV(hsv);
    notifyColorChanged();

//  uncomment this to stress test the rgb conversion functions by transforming
//  to rgb and back on every touch event
//    setColor(hsv2rgb(hsv));
}

onGlowTouched(integer linkNum, integer face, vector rawInput) {
    GLOW_PICKER_LINK = linkNum; // activate this picker
    vector input = getTouchValue(rawInput, GLOW_RECT);
    basicSetGlowSlider(input.x);
    getGlow();
    notifyColorChanged();
}

//onShinyTouched(integer linkNum, integer face, vector rawInput) {
//    SHINY_PICKER_LINK = linkNum; // activate this picker
//    integer shiny = point2GridIndex(getTouchValue(rawInput, GLOW_RECT), 4, 1);
//    setShiny(shiny);
//    notifyColorChanged();
//}

onShinyTouched(integer linkNum, integer face, vector rawInput) {
    SHINY_PICKER_LINK = linkNum; // activate this picker
    vector input = getTouchValue(rawInput, SHINY_RECT); // ???
//debug("onShinyTouched " + (string)input.x);
    basicSetGlossSlider(input.x);
    getGloss();
    notifyColorChanged();
}

onColorSaverTouched(integer link, integer face) {
    if (link != touchStartLink) return;
    if (face != touchStartFace) return;
    if (llGetTime() < touchStartTime + SAVE_HOLD_TIME) return;
    
    llSetLinkColor(link, getColor(), face);
    llRegionSayTo(llDetectedKey(0), 0, "color saved");
    
    touchStartLink = -1; // disallow another event handler later
}

onColorSaverTouchEnd(integer link, integer face) {
    if (link != touchStartLink) return;
    if (face != touchStartFace) return;
    
    vector color = llGetLinkColor(link, face);
    setColor(color);
    notifyColorChanged();
}

onHelpTouched() {
    llRegionSayTo(llDetectedKey(0), 0, "To tint: Select the body part from the buttons above, then choose a color from the swatch or the palette below.
\nTo save to color palette: click and hold a button for 3 seconds or more.
\nTo enter a color numerically: select the face on an unused dot on the palette and use the edit tool to tint it
\nCan't read buttons? Go to Avatar, Preferences, Graphics, Hardware settings and check Anisotropic Filtering");
}

default {
    on_rez(integer param) {
        llResetScript();
    }

    state_entry () {
        lastNotifyColorChanged = "X";
        //llOwnerSay(llGetScriptName() + " Free memory: " + (string)llGetFreeMemory());
    }

    changed (integer change) {
        if (change & (CHANGED_OWNER | CHANGED_INVENTORY | CHANGED_LINK)) {
            llResetScript();
        }
    }

    touch_start (integer total_number) {
        integer linkNum = llDetectedLinkNumber(0);
        touchStartLink = linkNum;

        string linkName = llGetLinkName(linkNum);
        integer faceNum = llDetectedTouchFace(0);
        vector rawInput = llDetectedTouchST(0);
        touchStartFace = faceNum;
        
        touchStartTime = llGetTime();

        if (linkName == COLOR_PICKER_LINK_NAME) {
            onPaletteTouched(linkNum, faceNum, rawInput);
        } else if (linkName == GLOW_PICKER_LINK_NAME) {
            onGlowTouched(linkNum, faceNum, rawInput);
        } else if (linkName == SHINY_PICKER_LINK_NAME) {
            onShinyTouched(linkNum, faceNum, rawInput);
        } else if (linkName == FULLBRIGHT_PICKER_LINK_NAME) {
            FULLBRIGHT_PICKER_LINK = linkNum; // activate this picker
            setFullBright(!getFullBright());
            notifyColorChanged();
        } else if (linkName == ALPHAMODE_PICKER_LINK_NAME) {
            ALPHAMODE_PICKER_LINK = linkNum; // activate this picker
            setAlphaMode((getAlphaMode()+1)%4);
            notifyColorChanged();
        } else if (linkName == COLOR_HELP) {
            onHelpTouched();
        }
    }

    touch (integer total_number) {
        integer linkNum = llDetectedLinkNumber(0);
        if (linkNum != touchStartLink) return;

        string linkName = llGetLinkName(linkNum);
        integer faceNum = llDetectedTouchFace(0);
        vector rawInput = llDetectedTouchST(0);
        if (rawInput == TOUCH_INVALID_TEXCOORD) return;

        if (linkName == COLOR_PICKER_LINK_NAME) {
            onPaletteTouched(linkNum, faceNum, rawInput);
        } else if (linkName == GLOW_PICKER_LINK_NAME) {
            onGlowTouched(linkNum, faceNum, rawInput);
        } else if (linkName == SHINY_PICKER_LINK_NAME) {
            onShinyTouched(linkNum, faceNum, rawInput);
        } else if (linkName == COLOR_SAVER) {
            onColorSaverTouched(linkNum, faceNum);
        }
    }

    touch_end (integer total_number) {
        integer linkNum = llDetectedLinkNumber(0);
        if (linkNum != touchStartLink) return;

        string linkName = llGetLinkName(linkNum);
        integer faceNum = llDetectedTouchFace(0);
        vector rawInput = llDetectedTouchST(0);
        if (rawInput == TOUCH_INVALID_TEXCOORD) return;

        if (linkName == COLOR_PICKER_LINK_NAME) {
            onPaletteTouched(linkNum, faceNum, rawInput);
        } else if (linkName == GLOW_PICKER_LINK_NAME) {
            onGlowTouched(linkNum, faceNum, rawInput);
        } else if (linkName == SHINY_PICKER_LINK_NAME) {
            onShinyTouched(linkNum, faceNum, rawInput);
        } else if (linkName == COLOR_SAVER) {
            onColorSaverTouchEnd(linkNum, faceNum);
        }
    }

    timer () {
        notifyColorChanged();
    }

    link_message (integer sender_num, integer num, string str, key id) {
        if (num == SET_COLOR || num == SET_COLOR_SYNC) {
//debug("sliders set_color " + str);
            lastNotifyColorChanged = "X";
            list config = llParseString2List(str, [";", ":"], []);
            if (setAllColorPickers(config)) {
                if (num == SET_COLOR) notifyColorChanged();
            } else {
                llSay(DEBUG_CHANNEL, "Color Picker prim is missing from the linkset");
            }
        }
    }
}
