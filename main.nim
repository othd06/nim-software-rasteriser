
import renderer
import cols
import images
import vectors
import math

const
    WIDTH = 960
    HEIGHT = 540
    PI = 3.14159
    near = 0.05
    far = 100.0

type
    Cam = object
        pos : Vector4
        forward : Vector4
        right : Vector4
        up : Vector4
        pitch: float
        yaw: float

var
    camera = Cam(
        pos: Vector4(x: 0, y: 0, z: 0, w: 0),
        forward: Vector4(x: 0, y: 0, z: 1, w: 0),
        right: Vector4(x: 1, y: 0, z: 0, w: 0),
        up: Vector4(x: 0, y: 1, z: 0, w: 0),
        pitch: 0,
        yaw: 0
    )

let
    texture = decodeQOI("awesomeface.qoi")

proc vertexShader0(v: vert): vert =
    var outV = v

    # camera-relative
    outV.position -= camera.pos
    let camPos = outV.position

    # camera space
    outV.position.x = dotProduct(camPos, camera.right)
    outV.position.y = dotProduct(camPos, camera.up)
    outV.position.z = dotProduct(camPos, camera.forward)

    # projection → clip space
    outV.position.w = outV.position.z      # perspective factor
    let
        A = (far + near) / (far - near)
        B = -2 * near * far / (far - near)
    outV.position.z = A * outV.position.z + B
    outV.position.y /= HEIGHT.float / WIDTH.float  # aspect baked into clip.y

    return outV


proc fragShader0(f: frag): pixel =
    let
        rFloat = f.floatAttribs[0]
        gFloat = f.floatAttribs[1]
        bFloat = f.floatAttribs[2]
        r : uint8 = int(rFloat*255.0).uint8
        g : uint8 = int(gFloat*255.0).uint8
        b : uint8 = int(bFloat*255.0).uint8
    return pixel(col: 0xFF shl 24 + r.uint32 shl 16 + g.uint32 shl 8 + b.uint32)

proc fragShader1(f: frag): pixel {.gcsafe.} =
    let
        u = f.floatAttribs[0]
        v = f.floatAttribs[1]
        col = sampleQOI(NEAREST, texture, u, v)
    if col.a == 0: return pixel(col: 0xFFFFFFFF'u32)
    return pixel(col: 0xFF shl 24 + col.r.uint32 shl 16 + col.g.uint32 shl 8 + col.b.uint32)

proc doButtons() =
    func flattenY(vec: Vector4): Vector4=
        result = Vector4(x: vec.x, y: 0, z: vec.z, w: vec.w)
        result.x /= sqrt(result.x*result.x + result.z*result.z)
        result.z /= sqrt(result.x*result.x + result.z*result.z)
    if isKeyDown(Key_W):
        camera.pos += camera.forward.flattenY()*7*frameTime
    if isKeyDown(Key_S):
        camera.pos -= camera.forward.flattenY()*7*frameTime
    if isKeyDown(Key_D):
        camera.pos += camera.right.flattenY()*7*frameTime
    if isKeyDown(Key_A):
        camera.pos -= camera.right.flattenY()*7*frameTime
    if isKeyDown(KEY_SPACE):
        camera.pos.y += 7*frameTime
    if isKeyDown(KEY_LEFT_CONTROL):
        camera.pos.y -= 7*frameTime
    if isKeyDown(KEY_RIGHT):
        camera.yaw += PI/3*3*frameTime
    if isKeyDown(KEY_LEFT):
        camera.yaw -= PI/3*3*frameTime
    if isKeyDown(KEY_UP):
        camera.pitch -= PI/3*3*frameTime
    if isKeyDown(KEY_DOWN):
        camera.pitch += PI/3*3*frameTime
    
    while camera.yaw > PI:
        camera.yaw -= 2*PI
    while camera.yaw < -PI:
        camera.yaw += 2*PI
    if camera.pitch > PI * 0.8:
        camera.pitch = PI * 0.8
    if camera.pitch < -PI:
        camera.pitch = -PI
    
    camera.right = Vector4(x: cos(camera.yaw), y: 0, z: sin(-camera.yaw), w: 0)
    camera.forward = Vector4(x: sin(camera.yaw)*cos(-camera.pitch), y: sin(-camera.pitch), z: cos(camera.yaw)*cos(-camera.pitch), w: 0)
    camera.up = crossProduct(camera.right.getXYZ(), camera.forward.getXYZ()).addW(0)

proc setVertexColour(triangle: var tri, col: Colour, vert: int, r: int, g: int, b: int)=
    triangle.floatAttribs[vert][r] = col.r.float/255
    triangle.floatAttribs[vert][g] = col.g.float/255
    triangle.floatAttribs[vert][b] = col.b.float/255

proc setUV(triangle: var tri, uv: (float32, float32), vert: int, u: int, v: int)=
    triangle.floatAttribs[vert][u] = uv[0]
    triangle.floatAttribs[vert][v] = uv[1]

proc application() =

    doButtons()

    clearScreen(0xff3c4c24'u32)
    
    var
        tri1 = tri(
            vertexShader: 0,
            fragmentShader: 1,
            positions: [Vector4(x: -1, y: -1, z: 9, w: 1), Vector4(x: -1, y: 1, z: 9, w: 1), Vector4(x: 1, y: -1, z: 9, w: 1)]
        )
        tri2 = tri(
            vertexShader: 0,
            fragmentShader: 1,
            positions: [Vector4(x: -1, y: 1, z: 9, w: 1), Vector4(x: 1, y: 1, z: 9, w: 1), Vector4(x: 1, y: -1, z: 9, w: 1)]
        )
        tri3 = tri(
            vertexShader: 0,
            fragmentShader: 0,
            positions: [Vector4(x: -1, y: 1, z: 11, w: 1), Vector4(x: -1, y: -1, z: 11, w: 1), Vector4(x: 1, y: -1, z: 11, w: 1)]
        )
        tri4 = tri(
            vertexShader: 0,
            fragmentShader: 0,
            positions: [Vector4(x: 1, y: 1, z: 11, w: 1), Vector4(x: -1, y: 1, z: 11, w: 1), Vector4(x: 1, y: -1, z: 11, w: 1)]
        )
        tri5 = tri(
            vertexShader: 0,
            fragmentShader: 0,
            positions: [Vector4(x: -1, y: -1, z: 9, w: 1), Vector4(x: -1, y: -1, z: 11, w: 1), Vector4(x: -1, y: 1, z: 11, w: 1)]
        )
        tri6 = tri(
            vertexShader: 0,
            fragmentShader: 0,
            positions: [Vector4(x: -1, y: 1, z: 11, w: 1), Vector4(x: -1, y: 1, z: 9, w: 1), Vector4(x: -1, y: -1, z: 9, w: 1)]
        )
        tri7 = tri(
            vertexShader: 0,
            fragmentShader: 0,
            positions: [Vector4(x: 1, y: -1, z: 11, w: 1), Vector4(x: 1, y: -1, z: 9, w: 1), Vector4(x: 1, y: 1, z: 11, w: 1)]
        )
        tri8 = tri(
            vertexShader: 0,
            fragmentShader: 0,
            positions: [Vector4(x: 1, y: 1, z: 9, w: 1), Vector4(x: 1, y: 1, z:11, w: 1), Vector4(x: 1, y: -1, z: 9, w: 1)]
        )
        tri9 = tri(
            vertexShader: 0,
            fragmentShader: 0,
            positions: [Vector4(x: -1, y: 1, z: 9, w: 1), Vector4(x: -1, y: 1, z: 11, w: 1), Vector4(x: 1, y: 1, z: 11, w: 1)]
        )
        tri10 = tri(
            vertexShader: 0,
            fragmentShader: 0,
            positions: [Vector4(x: -1, y: 1, z: 9, w: 1), Vector4(x: 1, y: 1, z: 11, w: 1), Vector4(x: 1, y: 1, z: 9, w: 1)]
        )
        tri11 = tri(
            vertexShader: 0,
            fragmentShader: 0,
            positions: [Vector4(x: -1, y: -1, z: 11, w: 1), Vector4(x: -1, y: -1, z: 9, w: 1), Vector4(x: 1, y: -1, z: 11, w: 1)]
        )
        tri12 = tri(
            vertexShader: 0,
            fragmentShader: 0,
            positions: [Vector4(x: -1, y: -1, z: 9, w: 1), Vector4(x: 1, y: -1, z: 9, w: 1), Vector4(x: 1, y: -1, z: 11, w: 1)]
        )
    tri1.setUV((0'f32, 0'f32), 0, 0, 1)
    tri1.setUV((0'f32, 1'f32), 1, 0, 1)
    tri1.setUV((1'f32, 0'f32), 2, 0, 1)
    tri2.setUV((0'f32, 1'f32), 0, 0, 1)
    tri2.setUV((1'f32, 1'f32), 1, 0, 1)
    tri2.setUV((1'f32, 0'f32), 2, 0, 1)

    #tri1.setVertexColour(Green, 0, 0, 1, 2)
    #tri1.setVertexColour(Green, 1, 0, 1, 2)
    #tri1.setVertexcolour(Green, 2, 0, 1, 2)
    #tri2.setVertexColour(Green, 0, 0, 1, 2)
    #tri2.setVertexColour(Green, 1, 0, 1, 2)
    #tri2.setVertexcolour(Green, 2, 0, 1, 2)
    tri3.setVertexColour(Blue, 0, 0, 1, 2)
    tri3.setVertexColour(Blue, 1, 0, 1, 2)
    tri3.setVertexcolour(Blue, 2, 0, 1, 2)
    tri4.setVertexColour(Blue, 0, 0, 1, 2)
    tri4.setVertexColour(Blue, 1, 0, 1, 2)
    tri4.setVertexcolour(Blue, 2, 0, 1, 2)
    tri5.setVertexColour(Orange, 0, 0, 1, 2)
    tri5.setVertexColour(Orange, 1, 0, 1, 2)
    tri5.setVertexcolour(Orange, 2, 0, 1, 2)
    tri6.setVertexColour(Orange, 0, 0, 1, 2)
    tri6.setVertexColour(Orange, 1, 0, 1, 2)
    tri6.setVertexcolour(Orange, 2, 0, 1, 2)
    tri7.setVertexColour(Red, 0, 0, 1, 2)
    tri7.setVertexColour(Red, 1, 0, 1, 2)
    tri7.setVertexcolour(Red, 2, 0, 1, 2)
    tri8.setVertexColour(Red, 0, 0, 1, 2)
    tri8.setVertexColour(Red, 1, 0, 1, 2)
    tri8.setVertexcolour(Red, 2, 0, 1, 2)
    tri9.setVertexColour(Yellow, 0, 0, 1, 2)
    tri9.setVertexColour(Yellow, 1, 0, 1, 2)
    tri9.setVertexcolour(Yellow, 2, 0, 1, 2)
    tri10.setVertexColour(Yellow, 0, 0, 1, 2)
    tri10.setVertexColour(Yellow, 1, 0, 1, 2)
    tri10.setVertexcolour(Yellow, 2, 0, 1, 2)
    tri11.setVertexColour(White, 0, 0, 1, 2)
    tri11.setVertexColour(White, 1, 0, 1, 2)
    tri11.setVertexcolour(White, 2, 0, 1, 2)
    tri12.setVertexColour(White, 0, 0, 1, 2)
    tri12.setVertexColour(White, 1, 0, 1, 2)
    tri12.setVertexcolour(White, 2, 0, 1, 2)
    

    queueTri(tri1)
    queueTri(tri2)
    queueTri(tri3)
    queueTri(tri4)
    queueTri(tri5)
    queueTri(tri6)
    queueTri(tri7)
    queueTri(tri8)
    queueTri(tri9)
    queueTri(tri10)
    queueTri(tri11)
    queueTri(tri12)


registerVertexShader(vertexShader0)
registerFragmentShader(fragShader0)
registerFragmentShader(fragShader1)
initRendering(WIDTH, HEIGHT)
enableLogging()
echo "initialised"
while not windowShouldClose():
    application()
    render()

deInit()
freeImg(texture)


