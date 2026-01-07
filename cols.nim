

type 
    Colour* = object ## Colour, 4 components, R8G8B8A8 (32bit)
        r*: uint8 ## Colour red value
        g*: uint8 ## Colour green value
        b*: uint8 ## Colour blue value
        a*: uint8 ## Colour alpha value

const
    LightGray* = Colour(r: 200, g: 200, b: 200, a: 255)
    Gray* = Colour(r: 130, g: 130, b: 130, a: 255)
    DarkGray* = Colour(r: 80, g: 80, b: 80, a: 255)
    Yellow* = Colour(r: 253, g: 249, b: 0, a: 255)
    Gold* = Colour(r: 255, g: 203, b: 0, a: 255)
    Orange* = Colour(r: 255, g: 161, b: 0, a: 255)
    Pink* = Colour(r: 255, g: 109, b: 194, a: 255)
    Red* = Colour(r: 230, g: 41, b: 55, a: 255)
    Maroon* = Colour(r: 190, g: 33, b: 55, a: 255)
    Green* = Colour(r: 0, g: 228, b: 48, a: 255)
    Lime* = Colour(r: 0, g: 158, b: 47, a: 255)
    DarkGreen* = Colour(r: 0, g: 117, b: 44, a: 255)
    SkyBlue* = Colour(r: 102, g: 191, b: 255, a: 255)
    Blue* = Colour(r: 0, g: 121, b: 241, a: 255)
    DarkBlue* = Colour(r: 0, g: 82, b: 172, a: 255)
    Purple* = Colour(r: 200, g: 122, b: 255, a: 255)
    Violet* = Colour(r: 135, g: 60, b: 190, a: 255)
    DarkPurple* = Colour(r: 112, g: 31, b: 126, a: 255)
    Beige* = Colour(r: 211, g: 176, b: 131, a: 255)
    Brown* = Colour(r: 127, g: 106, b: 79, a: 255)
    DarkBrown* = Colour(r: 76, g: 63, b: 47, a: 255)
    White* = Colour(r: 255, g: 255, b: 255, a: 255)
    Black* = Colour(r: 0, g: 0, b: 0, a: 255)
    Blank* = Colour(r: 0, g: 0, b: 0, a: 0)
    Magenta* = Colour(r: 255, g: 0, b: 255, a: 255)
    RayWhite* = Colour(r: 245, g: 245, b: 245, a: 255)

