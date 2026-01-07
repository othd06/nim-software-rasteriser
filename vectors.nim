
type
    Vector2* = object ## Vector2, 2 components
        x*: float32 ## Vector x component
        y*: float32 ## Vector y component

    Vector3* = object ## Vector3, 3 components
        x*: float32 ## Vector x component
        y*: float32 ## Vector y component
        z*: float32 ## Vector z component

    Vector4* = object ## Vector4, 4 components
        x*: float32 ## Vector x component
        y*: float32 ## Vector y component
        z*: float32 ## Vector z component
        w*: float32 ## Vector w component


proc `+`*(a, b: Vector2): Vector2 = return Vector2(x: a.x + b.x, y: a.y + b.y)
proc `+`*(a, b: Vector3): Vector3 = return Vector3(x: a.x + b.x, y: a.y + b.y, z: a.z + b.z)
proc `+`*(a, b: Vector4): Vector4 = return Vector4(x: a.x + b.x, y: a.y + b.y, z: a.z + b.z, w: a.w + b.w)

proc `+=`*(a: var Vector2, b: Vector2) =
    a = a+b;
proc `+=`*(a: var Vector3, b: Vector3) =
    a = a+b;
proc `+=`*(a: var Vector4, b: Vector4) =
    a = a+b;

proc `-`*(a, b: Vector2): Vector2 = return Vector2(x: a.x - b.x, y: a.y - b.y)
proc `-`*(a, b: Vector3): Vector3 = return Vector3(x: a.x - b.x, y: a.y - b.y, z: a.z - b.z)
proc `-`*(a, b: Vector4): Vector4 = return Vector4(x: a.x - b.x, y: a.y - b.y, z: a.z - b.z, w: a.w - b.w)

proc `-=`*(a: var Vector2, b: Vector2) =
    a = a-b;
proc `-=`*(a: var Vector3, b: Vector3) =
    a = a-b;
proc `-=`*(a: var Vector4, b: Vector4) =
    a = a-b;

proc `*`*(a: Vector2, b: float): Vector2 = return Vector2(x: a.x*b, y: a.y*b)
proc `*`*(a: Vector3, b: float): Vector3 = return Vector3(x: a.x*b, y: a.y*b, z: a.z*b)
proc `*`*(a: Vector4, b: float): Vector4 = return Vector4(x: a.x*b, y: a.y*b, z: a.z*b, w: a.w*b)

proc `/`*(a: Vector2, b: float): Vector2 = return Vector2(x: a.x/b, y: a.y/b)
proc `/`*(a: Vector3, b: float): Vector3 = return Vector3(x: a.x/b, y: a.y/b, z: a.z/b)
proc `/`*(a: Vector4, b: float): Vector4 = return Vector4(x: a.x/b, y: a.y/b, z: a.z/b, w: a.w/b)

proc dotProduct*(a, b: Vector2): float32 = return a.x*b.x + a.y*b.y
proc dotProduct*(a, b: Vector3): float32 = return a.x*b.x + a.y*b.y + a.z*b.z
proc dotProduct*(a, b: Vector4): float32 = return a.x*b.x + a.y*b.y + a.z*b.z + a.w*b.w

proc crossProduct*(a, b: Vector3): Vector3 =
    result.x = a.y * b.z - a.z * b.y
    result.y = a.z * b.x - a.x * b.z
    result.z = a.x * b.y - a.y * b.x

