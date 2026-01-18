

#A wrapper for libSRWWL at: https://github.com/othd06/SRWWL when using Linux
#A wrapper for libSRWinWL at: https://github.com/othd06/SRWinWL when using Windows

when defined(windows):
    {.passL: "-Llib -lSRWinWL -mconsole -lgdi32".}
    {.passC: "-Iinclude".}
    type
        KeyboardKey* = enum
            KEY_NULL            = 0        # Key: NULL, used for no key pressed
            # Alphanumeric keys
            KEY_APOSTROPHE      = 192      # Key: '
            KEY_COMMA           = 188      # Key: ,
            KEY_MINUS           = 189      # Key: -
            KEY_PERIOD          = 190      # Key: .
            KEY_SLASH           = 191      # Key: /
            KEY_ZERO            = 48       # Key: 0
            KEY_ONE             = 49       # Key: 1
            KEY_TWO             = 50       # Key: 2
            KEY_THREE           = 51       # Key: 3
            KEY_FOUR            = 52       # Key: 4
            KEY_FIVE            = 53       # Key: 5
            KEY_SIX             = 54       # Key: 6
            KEY_SEVEN           = 55       # Key: 7
            KEY_EIGHT           = 56       # Key: 8
            KEY_NINE            = 57       # Key: 9
            KEY_SEMICOLON       = 186      # Key: ;
            KEY_EQUAL           = 187      # Key: =
            KEY_A               = 65       # Key: A | a
            KEY_B               = 66       # Key: B | b
            KEY_C               = 67       # Key: C | c
            KEY_D               = 68       # Key: D | d
            KEY_E               = 69       # Key: E | e
            KEY_F               = 70       # Key: F | f
            KEY_G               = 71       # Key: G | g
            KEY_H               = 72       # Key: H | h
            KEY_I               = 73       # Key: I | i
            KEY_J               = 74       # Key: J | j
            KEY_K               = 75       # Key: K | k
            KEY_L               = 76       # Key: L | l
            KEY_M               = 77       # Key: M | m
            KEY_N               = 78       # Key: N | n
            KEY_O               = 79       # Key: O | o
            KEY_P               = 80       # Key: P | p
            KEY_Q               = 81       # Key: Q | q
            KEY_R               = 82       # Key: R | r
            KEY_S               = 83       # Key: S | s
            KEY_T               = 84       # Key: T | t
            KEY_U               = 85       # Key: U | u
            KEY_V               = 86       # Key: V | v
            KEY_W               = 87       # Key: W | w
            KEY_X               = 88       # Key: X | x
            KEY_Y               = 89       # Key: Y | y
            KEY_Z               = 90       # Key: Z | z
            KEY_LEFT_BRACKET    = 219      # Key: [
            KEY_BACKSLASH       = 220      # Key: '\'
            KEY_RIGHT_BRACKET   = 221      # Key: ]
            KEY_GRAVE           = 223      # Key: `
            # Function keys
            KEY_SPACE           = 32       # Key: Space
            KEY_ESCAPE          = 27       # Key: Esc
            KEY_ENTER           = 13       # Key: Enter
            KEY_TAB             =  9       # Key: Tab
            KEY_BACKSPACE       =  8       # Key: Backspace
            KEY_DELETE          = 46       # Key: Del
            KEY_RIGHT           = 39       # Key: Cursor right
            KEY_LEFT            = 37       # Key: Cursor left
            KEY_DOWN            = 40       # Key: Cursor down
            KEY_UP              = 38       # Key: Cursor up
            KEY_F1              = 112      # Key: F1
            KEY_F2              = 113      # Key: F2
            KEY_F3              = 114      # Key: F3
            KEY_F4              = 115      # Key: F4
            KEY_F5              = 116      # Key: F5
            KEY_F6              = 117      # Key: F6
            KEY_F7              = 118      # Key: F7
            KEY_F8              = 119      # Key: F8
            KEY_F9              = 120      # Key: F9
            KEY_F10             = 121      # Key: F10
            KEY_F11             = 122      # Key: F11
            KEY_F12             = 123      # Key: F12
            KEY_LEFT_SHIFT      = 16       # Key: Shift left
            KEY_LEFT_CONTROL    = 17       # Key: Control left
            KEY_LEFT_SUPER      = 91       # Key: Super left
            #KEY_RIGHT_SHIFT     = 16       # Key: Shift right
            #KEY_RIGHT_CONTROL   = 17       # Key: Control right
            KEY_RIGHT_ALT       = 18       # Key: Alt right
    const
        KEY_RIGHT_SHIFT* = KEY_LEFT_SHIFT
        KEY_RIGHT_CONTROL* = KEY_LEFT_CONTROL
    
    proc frameDropped*(): bool = false #libSRWinWL does not have API support for this yet
elif defined(linux):
    # Tell Nim to link against your static library and Wayland
    {.passL: "-Llib -lSRWWL -lwayland-client".}
    {.passC: "-Iinclude".}
    type
        KeyboardKey* = enum
            KEY_NULL            = 0        # Key: NULL, used for no key pressed
            # Alphanumeric keys
            KEY_APOSTROPHE      = 40       # Key: '
            KEY_COMMA           = 51       # Key: ,
            KEY_MINUS           = 12       # Key: -
            KEY_PERIOD          = 52       # Key: .
            KEY_SLASH           = 53       # Key: /
            KEY_ZERO            = 11       # Key: 0
            KEY_ONE             =  2       # Key: 1
            KEY_TWO             =  3       # Key: 2
            KEY_THREE           =  4       # Key: 3
            KEY_FOUR            =  5       # Key: 4
            KEY_FIVE            =  6       # Key: 5
            KEY_SIX             =  7       # Key: 6
            KEY_SEVEN           =  8       # Key: 7
            KEY_EIGHT           =  9       # Key: 8
            KEY_NINE            = 10       # Key: 9
            KEY_SEMICOLON       = 39       # Key: ;
            KEY_EQUAL           = 13       # Key: =
            KEY_A               = 30       # Key: A | a
            KEY_B               = 48       # Key: B | b
            KEY_C               = 46       # Key: C | c
            KEY_D               = 32       # Key: D | d
            KEY_E               = 18       # Key: E | e
            KEY_F               = 33       # Key: F | f
            KEY_G               = 34       # Key: G | g
            KEY_H               = 35       # Key: H | h
            KEY_I               = 23       # Key: I | i
            KEY_J               = 36       # Key: J | j
            KEY_K               = 37       # Key: K | k
            KEY_L               = 38       # Key: L | l
            KEY_M               = 50       # Key: M | m
            KEY_N               = 49       # Key: N | n
            KEY_O               = 24       # Key: O | o
            KEY_P               = 25       # Key: P | p
            KEY_Q               = 16       # Key: Q | q
            KEY_R               = 19       # Key: R | r
            KEY_S               = 31       # Key: S | s
            KEY_T               = 20       # Key: T | t
            KEY_U               = 22       # Key: U | u
            KEY_V               = 47       # Key: V | v
            KEY_W               = 17       # Key: W | w
            KEY_X               = 45       # Key: X | x
            KEY_Y               = 21       # Key: Y | y
            KEY_Z               = 44       # Key: Z | z
            KEY_LEFT_BRACKET    = 26       # Key: [
            KEY_BACKSLASH       = 86       # Key: '\'
            KEY_RIGHT_BRACKET   = 27       # Key: ]
            KEY_GRAVE           = 41       # Key: `
            # Function keys
            KEY_SPACE           = 57       # Key: Space
            KEY_ESCAPE          =  1       # Key: Esc
            KEY_ENTER           = 28       # Key: Enter
            KEY_TAB             = 15       # Key: Tab
            KEY_BACKSPACE       = 14       # Key: Backspace
            KEY_DELETE          = 111      # Key: Del
            KEY_RIGHT           = 106      # Key: Cursor right
            KEY_LEFT            = 105      # Key: Cursor left
            KEY_DOWN            = 108      # Key: Cursor down
            KEY_UP              = 103      # Key: Cursor up
            KEY_F1              = 59       # Key: F1
            KEY_F2              = 60       # Key: F2
            KEY_F3              = 61       # Key: F3
            KEY_F4              = 62       # Key: F4
            KEY_F5              = 63       # Key: F5
            KEY_F6              = 64       # Key: F6
            KEY_F7              = 65       # Key: F7
            KEY_F8              = 66       # Key: F8
            KEY_F9              = 67       # Key: F9
            KEY_F10             = 68       # Key: F10
            KEY_F11             = 69       # Key: F11
            KEY_F12             = 70       # Key: F12
            KEY_LEFT_SHIFT      = 42       # Key: Shift left
            KEY_LEFT_CONTROL    = 29       # Key: Control left
            KEY_LEFT_ALT        = 56       # Key: Alt left
            KEY_LEFT_SUPER      = 125       # Key: Super left
            KEY_RIGHT_SHIFT     = 54       # Key: Shift right
            KEY_RIGHT_CONTROL   = 97       # Key: Control right
            KEY_RIGHT_ALT       = 100      # Key: Alt right
    
    proc frameDropped*(): bool {.importc.}
else:
    {.error: "Unsupported platform".}


proc createWindow*(w: cint, h: cint, title: cstring) {.importc.}
proc destroyWindow*() {.importc.}

proc setBuffer*(buf: ptr uint8) {.importc.}
proc setImageResizeCallback*(cb: proc(w, h: uint32) {.cdecl.}) {.importc.}

proc isKeyDown*(key: KeyboardKey): bool {.importc.}
proc isKeyUp*(key: KeyboardKey): bool {.importc.}

proc windowShouldClose*(): bool {.importc.}
proc waitForFrame*() {.importc.}

