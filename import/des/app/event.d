module des.app.event;

public import des.math.linear;

import std.traits;
import std.string;

/++ keyboard event wrap
 +/
struct KeyboardEvent
{
    /// scan code (based on SDL2)
    enum Scan
    {
        UNKNOWN = 0, /// 0

        A = 4,  /// 4
        B = 5,  /// 5
        C = 6,  /// 6
        D = 7,  /// 7
        E = 8,  /// 8
        F = 9,  /// 9
        G = 10, /// 10
        H = 11, /// 11
        I = 12, /// 12
        J = 13, /// 13
        K = 14, /// 14
        L = 15, /// 15
        M = 16, /// 16
        N = 17, /// 17
        O = 18, /// 18
        P = 19, /// 19
        Q = 20, /// 20
        R = 21, /// 21
        S = 22, /// 22
        T = 23, /// 23
        U = 24, /// 24
        V = 25, /// 25
        W = 26, /// 26
        X = 27, /// 27
        Y = 28, /// 28
        Z = 29, /// 29

        NUMBER_1     = 30, /// 30
        NUMBER_2     = 31, /// 31
        NUMBER_3     = 32, /// 32
        NUMBER_4     = 33, /// 33
        NUMBER_5     = 34, /// 34
        NUMBER_6     = 35, /// 35
        NUMBER_7     = 36, /// 36
        NUMBER_8     = 37, /// 37
        NUMBER_9     = 38, /// 38
        NUMBER_0     = 39, /// 39

        RETURN       = 40, /// 40
        ESCAPE       = 41, /// 41
        BACKSPACE    = 42, /// 42
        TAB          = 43, /// 43
        SPACE        = 44, /// 44

        MINUS        = 45, /// 45
        EQUALS       = 46, /// 46
        LEFTBRACKET  = 47, /// 47
        RIGHTBRACKET = 48, /// 48
        BACKSLASH    = 49, /// 49
        NONUSHASH    = 50, /// 50
        SEMICOLON    = 51, /// 51
        APOSTROPHE   = 52, /// 52
        GRAVE        = 53, /// 53
        COMMA        = 54, /// 54
        PERIOD       = 55, /// 55
        SLASH        = 56, /// 56

        CAPSLOCK     = 57, /// 57

        F1  = 58, /// 58
        F2  = 59, /// 59
        F3  = 60, /// 60
        F4  = 61, /// 61
        F5  = 62, /// 62
        F6  = 63, /// 63
        F7  = 64, /// 64
        F8  = 65, /// 65
        F9  = 66, /// 66
        F10 = 67, /// 67
        F11 = 68, /// 68
        F12 = 69, /// 69

        PRINTSCREEN  = 70, /// 70
        SCROLLLOCK   = 71, /// 71
        PAUSE        = 72, /// 72
        INSERT       = 73, /// 73
        HOME         = 74, /// 74
        PAGEUP       = 75, /// 75
        DELETE       = 76, /// 76
        END          = 77, /// 77
        PAGEDOWN     = 78, /// 78
        RIGHT        = 79, /// 79
        LEFT         = 80, /// 80
        DOWN         = 81, /// 81
        UP           = 82, /// 82

        NUMLOCKCLEAR = 83, /// 83
        KP_DIVIDE    = 84, /// 84
        KP_MULTIPLY  = 85, /// 85
        KP_MINUS     = 86, /// 86
        KP_PLUS      = 87, /// 87
        KP_ENTER     = 88, /// 88

        KP_1 = 89, /// 89
        KP_2 = 90, /// 90
        KP_3 = 91, /// 91
        KP_4 = 92, /// 92
        KP_5 = 93, /// 93
        KP_6 = 94, /// 94
        KP_7 = 95, /// 95
        KP_8 = 96, /// 96
        KP_9 = 97, /// 97
        KP_0 = 98, /// 98

        KP_PERIOD = 99, /// 99

        NONUSBACKSLASH = 100, /// 100
        APPLICATION    = 101, /// 101
        POWER          = 102, /// 102
        KP_EQUALS      = 103, /// 103

        F13 = 104, /// 104
        F14 = 105, /// 105
        F15 = 106, /// 106
        F16 = 107, /// 107
        F17 = 108, /// 108
        F18 = 109, /// 109
        F19 = 110, /// 110
        F20 = 111, /// 111
        F21 = 112, /// 112
        F22 = 113, /// 113
        F23 = 114, /// 114
        F24 = 115, /// 115

        EXECUTE        = 116, /// 116
        HELP           = 117, /// 117
        MENU           = 118, /// 118
        SELECT         = 119, /// 119
        STOP           = 120, /// 120
        AGAIN          = 121, /// 121
        UNDO           = 122, /// 122
        CUT            = 123, /// 123
        COPY           = 124, /// 124
        PASTE          = 125, /// 125
        FIND           = 126, /// 126
        MUTE           = 127, /// 127
        VOLUMEUP       = 128, /// 128
        VOLUMEDOWN     = 129, /// 129
        KP_COMMA       = 133, /// 133
        KP_EQUALSAS400 = 134, /// 134

        INTERNATIONAL1 = 135, /// 135
        INTERNATIONAL2 = 136, /// 136
        INTERNATIONAL3 = 137, /// 137
        INTERNATIONAL4 = 138, /// 138
        INTERNATIONAL5 = 139, /// 139
        INTERNATIONAL6 = 140, /// 140
        INTERNATIONAL7 = 141, /// 141
        INTERNATIONAL8 = 142, /// 142
        INTERNATIONAL9 = 143, /// 143

        LANG1 = 144, /// 144
        LANG2 = 145, /// 145
        LANG3 = 146, /// 146
        LANG4 = 147, /// 147
        LANG5 = 148, /// 148
        LANG6 = 149, /// 149
        LANG7 = 150, /// 150
        LANG8 = 151, /// 151
        LANG9 = 152, /// 152

        ALTERASE   = 153, /// 153
        SYSREQ     = 154, /// 154
        CANCEL     = 155, /// 155
        CLEAR      = 156, /// 156
        PRIOR      = 157, /// 157
        RETURN2    = 158, /// 158
        SEPARATOR  = 159, /// 159
        OUT        = 160, /// 160
        OPER       = 161, /// 161
        CLEARAGAIN = 162, /// 162
        CRSEL      = 163, /// 163
        EXSEL      = 164, /// 164

        KP_00  = 176, /// 176
        KP_000 = 177, /// 177

        THOUSANDSSEPARATOR = 178, /// 178
        DECIMALSEPARATOR   = 179, /// 179
        CURRENCYUNIT       = 180, /// 180
        CURRENCYSUBUNIT    = 181, /// 181
        KP_LEFTPAREN       = 182, /// 182
        KP_RIGHTPAREN      = 183, /// 183
        KP_LEFTBRACE       = 184, /// 184
        KP_RIGHTBRACE      = 185, /// 185
        KP_TAB             = 186, /// 186
        KP_BACKSPACE       = 187, /// 187
        KP_A = 188, /// 188
        KP_B = 189, /// 189
        KP_C = 190, /// 190
        KP_D = 191, /// 191
        KP_E = 192, /// 192
        KP_F = 193, /// 193
        KP_XOR            = 194, /// 194
        KP_POWER          = 195, /// 195
        KP_PERCENT        = 196, /// 196
        KP_LESS           = 197, /// 197
        KP_GREATER        = 198, /// 198
        KP_AMPERSAND      = 199, /// 199
        KP_DBLAMPERSAND   = 200, /// 200
        KP_VERTICALBAR    = 201, /// 201
        KP_DBLVERTICALBAR = 202, /// 202
        KP_COLON          = 203, /// 203
        KP_HASH           = 204, /// 204
        KP_SPACE          = 205, /// 205
        KP_AT             = 206, /// 206
        KP_EXCLAM         = 207, /// 207
        KP_MEMSTORE       = 208, /// 208
        KP_MEMRECALL      = 209, /// 209
        KP_MEMCLEAR       = 210, /// 210
        KP_MEMADD         = 211, /// 211
        KP_MEMSUBTRACT    = 212, /// 212
        KP_MEMMULTIPLY    = 213, /// 213
        KP_MEMDIVIDE      = 214, /// 214
        KP_PLUSMINUS      = 215, /// 215
        KP_CLEAR          = 216, /// 216
        KP_CLEARENTRY     = 217, /// 217
        KP_BINARY         = 218, /// 218
        KP_OCTAL          = 219, /// 219
        KP_DECIMAL        = 220, /// 220
        KP_HEXADECIMAL    = 221, /// 221

        LCTRL  = 224, /// 224
        LSHIFT = 225, /// 225
        LALT   = 226, /// 226
        LGUI   = 227, /// 227
        RCTRL  = 228, /// 228
        RSHIFT = 229, /// 229
        RALT   = 230, /// 230
        RGUI   = 231, /// 231

        MODE = 257, /// 257

        AUDIONEXT    = 258, /// 258
        AUDIOPREV    = 259, /// 259
        AUDIOSTOP    = 260, /// 260
        AUDIOPLAY    = 261, /// 261
        AUDIOMUTE    = 262, /// 262
        MEDIASELECT  = 263, /// 263
        WWW          = 264, /// 264
        MAIL         = 265, /// 265
        CALCULATOR   = 266, /// 266
        COMPUTER     = 267, /// 267
        AC_SEARCH    = 268, /// 268
        AC_HOME      = 269, /// 269
        AC_BACK      = 270, /// 270
        AC_FORWARD   = 271, /// 271
        AC_STOP      = 272, /// 272
        AC_REFRESH   = 273, /// 273
        AC_BOOKMARKS = 274, /// 274

        BRIGHTNESSDOWN = 275, /// 275
        BRIGHTNESSUP   = 276, /// 276
        DISPLAYSWITCH  = 277, /// 277
        KBDILLUMTOGGLE = 278, /// 278
        KBDILLUMDOWN   = 279, /// 279
        KBDILLUMUP     = 280, /// 280
        EJECT          = 281, /// 281
        SLEEP          = 282, /// 282

        APP1 = 283, /// 283
        APP2 = 284, /// 284

        NUM_SCANCODES = 512 /// 512
    }

    /// Modificators (SHIFT, ALT etc)
    enum Mod
    {
        NONE   = 0x0000,          /// 0x0000
        LSHIFT = 0x0001,          /// 0x0001
        RSHIFT = 0x0002,          /// 0x0002
        LCTRL  = 0x0040,          /// 0x0040
        RCTRL  = 0x0080,          /// 0x0080
        LALT   = 0x0100,          /// 0x0100
        RALT   = 0x0200,          /// 0x0200
        LGUI   = 0x0400,          /// 0x0400
        RGUI   = 0x0800,          /// 0x0800
        NUM    = 0x1000,          /// 0x1000
        CAPS   = 0x2000,          /// 0x2000
        MODE   = 0x4000,          /// 0x4000
        CTRL   = (LCTRL|RCTRL),   /// (LCTRL|RCTRL)
        SHIFT  = (LSHIFT|RSHIFT), /// (LSHIFT|RSHIFT)
        ALT    = (LALT|RALT),     /// (LALT|RALT)
        GUI    = (LGUI|RGUI),     /// (LGUI|RGUI)
    }

    /// is key pressed
    bool pressed;

    /// is this a repeat
    bool repeat;

    ///
    Scan scan;

    /// 
    uint key;

    ///
    Mod mod;
}

/// input text event
struct TextEvent { dchar ch; }

/// add binary flag
T binAdd(T)( in T a, in T b ) if( isIntegral!T ) { return a | b; }

/// remove binary flag
T binRemove(T)( in T a, in T b ) if( isIntegral!T ) { return a ^ ( a & b ); }

/// find binary flag
bool binHas(T)( in T a, in T b ) if( isIntegral!T ) { return ( a & b ) == b; }

unittest
{
    auto a = 0b0001;
    auto b = 0b0010;
    auto c = binAdd(a,b);
    assert( c == 0b0011 );
    assert( binRemove(c,a) == b );
    assert( binRemove(c,b) == a );
    assert( binHas(c,a) );
    assert( binHas(c,b) );
    auto x = 0b0100;
    assert( !binHas(c,x) );
}

///
struct MouseEvent
{
    ///
    enum Type
    {
        PRESSED, ///
        RELEASED,///
        MOTION,  ///
        WHEEL    ///
    };

    ///
    enum Button
    {
        NONE   = 0,    /// 0
        LEFT   = 1<<0, /// 1
        MIDDLE = 1<<1, /// 2
        RIGHT  = 1<<2, /// 4
        X1     = 1<<3, /// 8
        X2     = 1<<4, /// 16
    }

    ///
    Type type; 

    /// mouse button
    Button btn = Button.NONE;

    /// mask for motion, button for pressed/released, 0 for wheel
    uint mask;

    /// current pos
    ivec2 pos;
    /// different between last and current pos
    ivec2 rel;

    /// pressed button motion pos
    ivec2[[EnumMembers!Button].length-1] posPress;
    /// pressed button relative motion (different between last and current)
    ivec2[[EnumMembers!Button].length-1] relPress;

    /// wheel
    ivec2 whe;

    ///
    ivec2 getPosPress( Button b ) const
    {
        if( b == Button.NONE ) return pos;
        return posPress[buttonIndex(b)];
    }

    ///
    ivec2 getRelPress( Button b ) const
    {
        if( b == Button.NONE ) return ivec2(0,0);
        return relPress[buttonIndex(b)];
    }

    /// is button pressed
    bool isPressed( Button b ) const
    { return binHas( mask, b ); }

    /// append button to mask
    void appendButton( uint b ) { mask = binAdd( mask, b ); }

    /// remove button to mask
    void removeButton( uint b ) { mask = binRemove( mask, b ); }

    /// index in `posPress` and `relPress`
    static size_t buttonIndex( Button b )
    {
        foreach( i, lb; [EnumMembers!Button][1..$] )
            if( lb == b ) return i;
        assert(0,format("%s has no index",b));
    }
}

/// joystick
struct JoyEvent
{
    /// joy id
    uint id;

    ///
    enum Type
    {
        AXIS,   ///
        BUTTON, ///
        BALL,   ///
        HAT     ///
    };

    ///
    Type type;

    /// change element number (in array of states)
    size_t no;

    /// all axis state
    float[] axis;

    /// all buttons state ( true - pressed )
    bool[] buttons;

    /// all trackballs state
    ivec2[] balls;

    /// all hats state
    byte[] hats;
}
