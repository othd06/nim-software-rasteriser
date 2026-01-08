
#include <stdint.h>

#ifndef SRWinWL
#define SRWinWL

typedef enum {
    KEY_NULL            = 0,        // Key: NULL, used for no key pressed
    // Alphanumeric keys
    KEY_APOSTROPHE      = 192,      // Key: '
    KEY_COMMA           = 188,      // Key: ,
    KEY_MINUS           = 189,      // Key: -
    KEY_PERIOD          = 190,      // Key: .
    KEY_SLASH           = 191,      // Key: /
    KEY_ZERO            = 48,       // Key: 0
    KEY_ONE             = 49,       // Key: 1
    KEY_TWO             = 50,       // Key: 2
    KEY_THREE           = 51,       // Key: 3
    KEY_FOUR            = 52,       // Key: 4
    KEY_FIVE            = 53,       // Key: 5
    KEY_SIX             = 54,       // Key: 6
    KEY_SEVEN           = 55,       // Key: 7
    KEY_EIGHT           = 56,       // Key: 8
    KEY_NINE            = 57,       // Key: 9
    KEY_SEMICOLON       = 186,      // Key: ;
    KEY_EQUAL           = 187,      // Key: =
    KEY_A               = 65,       // Key: A | a
    KEY_B               = 66,       // Key: B | b
    KEY_C               = 67,       // Key: C | c
    KEY_D               = 68,       // Key: D | d
    KEY_E               = 69,       // Key: E | e
    KEY_F               = 70,       // Key: F | f
    KEY_G               = 71,       // Key: G | g
    KEY_H               = 72,       // Key: H | h
    KEY_I               = 73,       // Key: I | i
    KEY_J               = 74,       // Key: J | j
    KEY_K               = 75,       // Key: K | k
    KEY_L               = 76,       // Key: L | l
    KEY_M               = 77,       // Key: M | m
    KEY_N               = 78,       // Key: N | n
    KEY_O               = 79,       // Key: O | o
    KEY_P               = 80,       // Key: P | p
    KEY_Q               = 81,       // Key: Q | q
    KEY_R               = 82,       // Key: R | r
    KEY_S               = 83,       // Key: S | s
    KEY_T               = 84,       // Key: T | t
    KEY_U               = 85,       // Key: U | u
    KEY_V               = 86,       // Key: V | v
    KEY_W               = 87,       // Key: W | w
    KEY_X               = 88,       // Key: X | x
    KEY_Y               = 89,       // Key: Y | y
    KEY_Z               = 90,       // Key: Z | z
    KEY_LEFT_BRACKET    = 219,      // Key: [
    KEY_BACKSLASH       = 220,      // Key: '\'
    KEY_RIGHT_BRACKET   = 221,      // Key: ]
    KEY_GRAVE           = 223,      // Key: `
    // Function keys
    KEY_SPACE           = 32,       // Key: Space
    KEY_ESCAPE          = 27,       // Key: Esc
    KEY_ENTER           = 13,       // Key: Enter
    KEY_TAB             =  9,       // Key: Tab
    KEY_BACKSPACE       =  8,       // Key: Backspace
    KEY_DELETE          = 46,       // Key: Del
    KEY_RIGHT           = 39,       // Key: Cursor right
    KEY_LEFT            = 37,       // Key: Cursor left
    KEY_DOWN            = 40,       // Key: Cursor down
    KEY_UP              = 38,       // Key: Cursor up
    KEY_F1              = 112,      // Key: F1
    KEY_F2              = 113,      // Key: F2
    KEY_F3              = 114,      // Key: F3
    KEY_F4              = 115,      // Key: F4
    KEY_F5              = 116,      // Key: F5
    KEY_F6              = 117,      // Key: F6
    KEY_F7              = 118,      // Key: F7
    KEY_F8              = 119,      // Key: F8
    KEY_F9              = 120,      // Key: F9
    KEY_F10             = 121,      // Key: F10
    KEY_F11             = 122,      // Key: F11
    KEY_F12             = 123,      // Key: F12
    KEY_LEFT_SHIFT      = 16,       // Key: Shift left
    KEY_LEFT_CONTROL    = 17,       // Key: Control left
    KEY_LEFT_SUPER      = 91,       // Key: Super left
    KEY_RIGHT_SHIFT     = 16,       // Key: Shift right
    KEY_RIGHT_CONTROL   = 17,       // Key: Control right
    KEY_RIGHT_ALT       = 18,       // Key: Alt right
} KeyboardKey;

void createWindow(int W, int H, const char* title);
void destroyWindow();

void setBuffer(uint8_t*); //tells SRWinWL which buffer to copy into pixl every frame callback (but does not transfer ownership to SRWinWL)
void setImageResizeCallback(void (*resize_callback)());

//events are automatically polled every input event by callbacks called from WnAPI
bool isKeyDown(KeyboardKey key);
bool isKeyUp(KeyboardKey key);

bool windowShouldClose();

void waitForFrame();

#endif

