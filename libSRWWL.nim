#A wrapper for libSRWWL at: https://github.com/othd06/SRWWL


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

proc createWindow*(w: cint, h: cint, title: cstring) {.importc.}
proc destroyWindow*() {.importc.}

proc setBuffer*(buf: ptr uint8) {.importc.}
proc setImageResizeCallback*(cb: proc() {.cdecl.}) {.importc.}

proc isKeyDown*(key: KeyboardKey): bool {.importc.}
proc isKeyUp*(key: KeyboardKey): bool {.importc.}

proc windowShouldClose*(): bool {.importc.}
proc waitForFrame*() {.importc.}

