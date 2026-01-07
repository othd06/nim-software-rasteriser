
import libSRWWL
export KeyboardKey, isKeyDown, isKeyUp, windowShouldClose
import cols
import vectors
import math
import algorithm
import times

var frameTime*: float
var frameStart: float

func getXYZ*(vec: Vector4): Vector3 {.inline.} =
    return Vector3(x: vec.x, y: vec.y, z: vec.z)

func addW*(vec: Vector3, w: float): Vector4 {.inline.} =
    return Vector4(x: vec.x, y: vec.y, z: vec.z, w: w)

func `*`*[T](x: array[T, float32], y: float32): array[T, float32] {.inline.} =
    for i in 0..<x.len:
        result[i] = x[i] * y

func `+`*[T](x: array[T, float32], y: array[T, float32]): array[T, float32] {.inline.} =
    for i in 0..<x.len:
        result[i] = x[i] + y[i]

const
    maxAttribs = 16

type
    tri* = object
        vertexShader*: uint32
        fragmentShader*: uint32
        positions*: array[3, Vector4]
        uintAttribs*: array[3, array[maxAttribs, uint32]]
        intAttribs*: array[3, array[maxAttribs, int32]]
        floatAttribs*: array[3, array[maxAttribs, float32]]
    vert* = object
        position*: Vector4
        uintAttribs*: array[maxAttribs, uint32]
        intAttribs*: array[maxAttribs, int32]
        floatAttribs*: array[maxAttribs, float32]
    frag* = object
        fragmentShader*: uint32
        screenX*: uint32
        screenY*: uint32
        uintAttribs*: array[maxAttribs, uint32]
        intAttribs*: array[maxAttribs, int32]
        floatAttribs*: array[maxAttribs, float32]
    pixel* = object
        col*: uint32
    vertexShader = proc(v: vert): vert {.nimcall.}
    fragmentShader = proc(f: frag): pixel {.nimcall, gcsafe.}

var
    COLOUR: pointer#array[WIDTH*HEIGHT, uint32]
    COLOURS: array[2, pointer]
    currentCol: int = 0
    DEPTH: pointer#array[WIDTH*HEIGHT, float32]
    WIDTH: int32
    HEIGHT: int32
    vertexShadingQueue: seq[tri]
    clippingQueue: seq[tri]
    rasterisationFragmentShadingQueue: seq[tri]
    colourData: seq[Colour] #= newSeq[Colour](WIDTH * HEIGHT)
    

#const
#    vertexShaders: array[1, vertexShader] = [vertexShader0]
#    fragmentShaders: array[1, fragmentShader] = [fragShader0]
var
    vertexShaders: seq[vertexShader]
    fragmentShaders: seq[fragmentShader]

proc registerVertexShader*(shader: vertexShader)=
    vertexShaders.add(shader)

proc registerFragmentShader*(shader: fragmentShader)=
    fragmentShaders.add(shader)

proc queueTri*(triangle: tri)=
    vertexShadingQueue.add(triangle)

proc clearScreen*(colour: uint32)=
    let
        colourBuffer = cast[ptr UncheckedArray[uint32]](COLOUR)
        depthBuffer = cast[ptr UncheckedArray[float32]](DEPTH)
    for i in 0..(WIDTH*HEIGHT-1):
        colourBuffer[][i] = colour
        depthBuffer[i] = 1.0

var
    hWIDTH: int32# = WIDTH shr 1
    hHEIGHT: int32# = HEIGHT shr 1
    hWIDTHf: float# = hWIDTH.float
    hHEIGHTf: float# = hHEIGHT.float

proc initRendering*(width: int32, height: int32) =
    WIDTH = width
    HEIGHT = height

    hWIDTH = WIDTH shr 1
    hHEIGHT = HEIGHT shr 1
    hWIDTHf = hWIDTH.float
    hHEIGHTf = hHEIGHT.float
    frameStart = epochTime()

    #colourData = newSeq[Colour](WIDTH * HEIGHT)
    for i in 0..<(WIDTH*HEIGHT):
        colourData.add(Colour(r: 0, g: 0, b: 0, a: 255))
    COLOURS[0] = alloc(WIDTH * HEIGHT * sizeof(uint32))
    COLOURS[1] = alloc(WIDTH * HEIGHT * sizeof(uint32))
    COLOUR = COLOURS[currentCol]
    DEPTH = alloc(WIDTH * HEIGHT * sizeof(float32))

    #initialise the window
    createWindow(WIDTH, HEIGHT, "Software Rasteriser")

    #initialise the screen texture
    setBuffer(cast[ptr uint8](COLOUR))

    

proc vertexShading() =
    while vertexShadingQueue.len > 0:
        let
            oldTri = vertexShadingQueue.pop()
            vertexOne = vertexShaders[oldTri.vertexShader](vert(
                position: oldTri.positions[0],
                uintAttribs: oldTri.uintAttribs[0],
                intAttribs: oldTri.intAttribs[0],
                floatAttribs: oldTri.floatAttribs[0]
            ))
            vertexTwo = vertexShaders[oldTri.vertexShader](vert(
                position: oldTri.positions[1],
                uintAttribs: oldTri.uintAttribs[1],
                intAttribs: oldTri.intAttribs[1],
                floatAttribs: oldTri.floatAttribs[1]
            ))
            vertexThree = vertexShaders[oldTri.vertexShader](vert(
                position: oldTri.positions[2],
                uintAttribs: oldTri.uintAttribs[2],
                intAttribs: oldTri.intAttribs[2],
                floatAttribs: oldTri.floatAttribs[2]
            ))
            newTri = tri(
                vertexShader: oldTri.vertexShader,
                fragmentShader: oldTri.fragmentShader,
                positions: [vertexOne.position, vertexTwo.position, vertexThree.position],
                uintAttribs: [vertexOne.uintAttribs, vertexTwo.uintAttribs, vertexThree.uintAttribs],
                intAttribs: [vertexOne.intAttribs, vertexTwo.intAttribs, vertexThree.intAttribs],
                floatAttribs: [vertexOne.floatAttribs, vertexTwo.floatAttribs, vertexThree.floatAttribs]
            )
        clippingQueue.add(newTri)

proc nearClip(triangle: tri): bool =
    ## Clip triangle against near plane f(V)=V.z + V.w = 0
    var clipNum: int = 0
    for i in 0..triangle.positions.high:
        if triangle.positions[i].z < -triangle.positions[i].w:
            clipNum += 1
    if clipNum == 0:
        return false
    if clipNum == 3:
        return true

    # helper: build vert from triangle index
    proc makeVertFromIndex(i: int): vert =
        result.position = triangle.positions[i]
        result.uintAttribs = triangle.uintAttribs[i]
        result.intAttribs = triangle.intAttribs[i]
        result.floatAttribs = triangle.floatAttribs[i]

    # intersect edge a -> b where f(V)=V.z+V.w ; solve f(a + t*(b-a)) == 0
    proc intersectEdge(a: vert, b: vert): vert =
        let fa = a.position.z + a.position.w
        let fb = b.position.z + b.position.w
        var t: float32 = 0.0'f32
        if (fa - fb) != 0.0'f32:
            t = fa / (fa - fb)
        if t < 0.0'f32: t = 0.0'f32
        if t > 1.0'f32: t = 1.0'f32
        # interpolate full Vector4 (including w)
        result.position = a.position * (1.0'f32 - t) + b.position * t
        # force the intersection onto the exact plane to avoid re-clipping due to tiny FP error
        result.position.z = -result.position.w + 1e-5
        for i in 0..<maxAttribs:
            result.floatAttribs[i] = a.floatAttribs[i] * (1.0'f32 - t) + b.floatAttribs[i] * t
            # pick closest endpoint for integer/uint attrs (simple, consistent)
            if t < 0.5'f32:
                result.intAttribs[i] = a.intAttribs[i]
                result.uintAttribs[i] = a.uintAttribs[i]
            else:
                result.intAttribs[i] = b.intAttribs[i]
                result.uintAttribs[i] = b.uintAttribs[i]

    if clipNum == 2:
        # one vertex in front, two behind -> produce one new triangle
        var inFrontIndex: int = -1
        for i in 0..2:
            if triangle.positions[i].z >= -triangle.positions[i].w:
                inFrontIndex = i
                break
        if inFrontIndex == -1: return true
        let A = inFrontIndex
        let B = (A + 1) mod 3
        let C = (A + 2) mod 3
        let vertA = makeVertFromIndex(A)
        let vertB = makeVertFromIndex(B)
        let vertC = makeVertFromIndex(C)
        let vertAB = intersectEdge(vertA, vertB)
        let vertAC = intersectEdge(vertA, vertC)
        let newTri = tri(
            vertexShader: triangle.vertexShader,
            fragmentShader: triangle.fragmentShader,
            positions: [vertA.position, vertAB.position, vertAC.position],
            uintAttribs: [vertA.uintAttribs, vertAB.uintAttribs, vertAC.uintAttribs],
            intAttribs: [vertA.intAttribs, vertAB.intAttribs, vertAC.intAttribs],
            floatAttribs: [vertA.floatAttribs, vertAB.floatAttribs, vertAC.floatAttribs]
        )
        clippingQueue.add(newTri)
        return true

    if clipNum == 1:
        # two vertices in front, one behind -> produce two new triangles
        var outIndex: int = -1
        for i in 0..2:
            if triangle.positions[i].z < -triangle.positions[i].w:
                outIndex = i
                break
        if outIndex == -1: return true
        let in1 = (outIndex + 1) mod 3
        let in2 = (outIndex + 2) mod 3
        let Vout = makeVertFromIndex(outIndex)
        let Vin1 = makeVertFromIndex(in1)
        let Vin2 = makeVertFromIndex(in2)
        let P1 = intersectEdge(Vin1, Vout) # intersection on edge Vin1->Vout
        let P2 = intersectEdge(Vin2, Vout) # intersection on edge Vin2->Vout
        # triangle A: Vin1, Vin2, P2
        let tri1 = tri(
            vertexShader: triangle.vertexShader,
            fragmentShader: triangle.fragmentShader,
            positions: [Vin1.position, Vin2.position, P2.position],
            uintAttribs: [Vin1.uintAttribs, Vin2.uintAttribs, P2.uintAttribs],
            intAttribs: [Vin1.intAttribs, Vin2.intAttribs, P2.intAttribs],
            floatAttribs: [Vin1.floatAttribs, Vin2.floatAttribs, P2.floatAttribs]
        )
        # triangle B: Vin1, P2, P1
        let tri2 = tri(
            vertexShader: triangle.vertexShader,
            fragmentShader: triangle.fragmentShader,
            positions: [Vin1.position, P2.position, P1.position],
            uintAttribs: [Vin1.uintAttribs, P2.uintAttribs, P1.uintAttribs],
            intAttribs: [Vin1.intAttribs, P2.intAttribs, P1.intAttribs],
            floatAttribs: [Vin1.floatAttribs, P2.floatAttribs, P1.floatAttribs]
        )
        clippingQueue.add(tri1)
        clippingQueue.add(tri2)
        return true

    # fallback discard
    return true

proc farClip(triangle: tri): bool =
    var clipNum: int = 0
    for i in 0..triangle.positions.high:
        if triangle.positions[i].z > triangle.positions[i].w:
            clipNum += 1
    if clipNum == 0:
        return false
    if clipNum == 3:
        return true
    if clipNum == 1:
        return false #A bit hacky but should just work because of how the rasterisationFragmentShading stage works
    if clipNum == 2:
        return false #A bit hacky but should just work because of how the rasterisationFragmentShading stage works

proc leftClip(triangle: tri): bool =
    var clipNum: int = 0
    for i in 0..triangle.positions.high:
        if triangle.positions[i].x < -triangle.positions[i].w:
            clipNum += 1
    if clipNum == 0:
        return false
    if clipNum == 3:
        return true
    if clipNum == 1:
        return false #A bit hacky but should just work because of how the rasterisationFragmentShading stage works
    if clipNum == 2:
        return false #A bit hacky but should just work because of how the rasterisationFragmentShading stage works

proc rightClip(triangle: tri): bool =
    var clipNum: int = 0
    for i in 0..triangle.positions.high:
        if triangle.positions[i].x > triangle.positions[i].w:
            clipNum += 1
    if clipNum == 0:
        return false
    if clipNum == 3:
        return true
    if clipNum == 1:
        return false #A bit hacky but should just work because of how the rasterisationFragmentShading stage works
    if clipNum == 2:
        return false #A bit hacky but should just work because of how the rasterisationFragmentShading stage works

proc topClip(triangle: tri): bool =
    var clipNum: int = 0
    for i in 0..triangle.positions.high:
        if triangle.positions[i].y > triangle.positions[i].w:
            clipNum += 1
    if clipNum == 0:
        return false
    if clipNum == 3:
        return true
    if clipNum == 1:
        return false #A bit hacky but should just work because of how the rasterisationFragmentShading stage works
    if clipNum == 2:
        return false #A bit hacky but should just work because of how the rasterisationFragmentShading stage works

proc bottomClip(triangle: tri): bool =
    var clipNum: int = 0
    for i in 0..triangle.positions.high:
        if triangle.positions[i].y < -triangle.positions[i].w:
            clipNum += 1
    if clipNum == 0:
        return false
    if clipNum == 3:
        return true
    if clipNum == 1:
        return false #A bit hacky but should just work because of how the rasterisationFragmentShading stage works
    if clipNum == 2:
        return false #A bit hacky but should just work because of how the rasterisationFragmentShading stage works

proc clipping() =
    while clippingQueue.len > 0:
        let newTri = clippingQueue.pop()
        if nearClip(newTri): continue
        if farClip(newTri): continue
        if leftClip(newTri): continue
        if rightClip(newTri): continue
        if topClip(newTri): continue
        if bottomClip(newTri): continue
        rasterisationFragmentShadingQueue.add(newTri)

proc rasterisationFragmentShading() =
    let
        colourBuffer = cast[ptr UncheckedArray[uint32]](COLOUR)
        depthBuffer = cast[ptr UncheckedArray[float32]](DEPTH)
    while rasterisationFragmentShadingQueue.len > 0:
        var newTri = rasterisationFragmentShadingQueue.pop()
        for i in 0..2:
            newTri.positions[i].x /= newTri.positions[i].w
            newTri.positions[i].y /= newTri.positions[i].w
            newTri.positions[i].z /= newTri.positions[i].w
        let
            topRight = Vector2(x: max(newTri.positions[0].x, max(newTri.positions[1].x, newTri.positions[2].x)), y: max(newTri.positions[0].y, max(newTri.positions[1].y, newTri.positions[2].y)))
            bottomLeft = Vector2(x: min(newTri.positions[0].x, min(newTri.positions[1].x, newTri.positions[2].x)), y: min(newTri.positions[0].y, min(newTri.positions[1].y, newTri.positions[2].y)))
            screenLeft: uint32 = max((bottomLeft.x*(hWIDTH).float).int32 + (hWIDTH).int32, 0).uint32
            screenRight: uint32 = min((topRight.x*(hWIDTH).float).int32 + (hWIDTH).int32, WIDTH-1).uint32
            screenTop: uint32 = min((topRight.y*(hHEIGHT).float).int32 + (hHEIGHT).int32, HEIGHT-1).uint32
            screenBottom: uint32 = max((bottomLeft.y*(hHEIGHT).float).int32 + (hHEIGHT).int32, 0).uint32
        
        let
            v0 = Vector2(
                x: newTri.positions[0].x,
                y: newTri.positions[0].y
            )
            v1 = Vector2(
                x: newTri.positions[1].x,
                y: newTri.positions[1].y
            )
            v2 = Vector2(
                x: newTri.positions[2].x,
                y: newTri.positions[2].y
            )
            denom = ( (v1.y - v2.y) * (v0.x - v2.x) + (v2.x - v1.x) * (v0.y - v2.y) )
            al1 = (v1.y - v2.y)
            al2 = (v2.x - v1.x)
            be1 = (v2.y - v0.y)
            be2 = (v0.x - v2.x)
        if denom == 0: continue
        {.push checks:off.}
        for y in screenBottom..screenTop:
            for x in screenLeft..screenRight:
                #compute NDC position
                let ndcPos: Vector2 = Vector2(
                    x: (x.float / hWIDTHf) - 1,
                    y: (y.float / hHEIGHTf) - 1
                )
                #compute barycentrics
                let
                    alpha: float32 = ( al1 * (ndcPos.x - v2.x) + al2 * (ndcPos.y - v2.y) ) / denom
                    beta: float32 = ( be1 * (ndcPos.x - v2.x) + be2 * (ndcPos.y - v2.y) ) / denom
                    gamma: float32 = 1 - alpha - beta
                #reject fragments outside triangle
                if alpha < 0.0 or beta < 0.0 or gamma < 0.0:
                    continue
                #compute weights
                let
                    w0 = alpha
                    w1 = beta
                    w2 = gamma
                #calculate depth
                let
                    depth = w0*newTri.positions[0].z + w1*newTri.positions[1].z + w2*newTri.positions[2].z
                #reject fragments behind depth buffer
                if depth > depthBuffer[][y.int*WIDTH + x.int]:
                    continue
                #update depth buffer
                depthBuffer[][y.int*WIDTH + x.int] = depth
                #calculate attributes
                var
                    floatAttrs: array[maxAttribs, float32]
                    intAttrs: array[maxAttribs, int32]
                    uintAttrs: array[maxAttribs, uint32]
                for i in 0..<maxAttribs:
                    floatAttrs[i] = newTri.floatAttribs[0][i]*w0 + newTri.floatAttribs[1][i]*w1 + newTri.floatAttribs[2][i]*w2
                    if w0 > w1 and w0 > w2:
                        intAttrs[i] = newTri.intAttribs[0][i]
                        uintAttrs[i] = newTri.uintAttribs[0][i]
                    elif w1 > w2:
                        intAttrs[i] = newTri.intAttribs[1][i]
                        uintAttrs[i] = newTri.uintAttribs[1][i]
                    else:
                        intAttrs[i] = newTri.intAttribs[2][i]
                        uintAttrs[i] = newTri.uintAttribs[2][i]
                #generate fragment
                let
                    newFrag = frag(
                        fragmentShader: newTri.fragmentShader,
                        screenX: x,
                        screenY: y,
                        floatAttribs: floatAttrs,
                        intAttribs: intAttrs,
                        uintAttribs: uintAttrs
                    )
                    newPix = fragmentShaders[newFrag.fragmentShader](newFrag)
                colourBuffer[][y.int*WIDTH + x.int] = newPix.col
        {.pop.}

proc updateScreen() =
    setBuffer(cast[ptr uint8](COLOURS[currentCol]))
    currentCol = 1-currentCol
    COLOUR = COLOURS[currentCol]
    waitForFrame()
    #[
    let
        colourBuffer = cast[ptr UncheckedArray[uint32]](COLOUR)
        depthBuffer = cast[ptr UncheckedArray[float32]](DEPTH)
    ## Convert uint32 RGBA → Image → Texture2D
    # Convert to seq[Colour] for Raylib
    if isKeyDown(L):
        for i in 0..<WIDTH * HEIGHT:
            let px = depthBuffer[][i]
            colourData[i] = Colour(
                r: uint8(min((px / 100).float*255, 255.0)),
                g: uint8(min((px / 100).float*255, 255.0)),
                b: uint8(min((px / 100).float*255, 255.0)),
                a: 255 # ignore provided alpha
            )
    else:
        for i in 0 ..< WIDTH * HEIGHT:
            let px = colourBuffer[][i]
            colourData[i] = Colour(
                r: uint8((px shr 24) and 0xFF),
                g: uint8((px shr 16) and 0xFF),
                b: uint8((px shr 8) and 0xFF),
                a: 255 # ignore provided alpha
            )
    updateTexture(screenTex, colourData)
    
    drawTexture(screenTex, 0, 0, White)
    ]#

proc render*() =
    #beginDrawing()
    #clearBackground(RayWhite)
    var startTime = epochTime()
    startTime = epochTime()
    vertexShading()
    let vertexShadingTime = (epochTime()-startTime)*1000
    startTime = epochTime()
    clipping()
    let clippingTime = (epochTime()-startTime)*1000
    startTime = epochTime()
    rasterisationFragmentShading()
    let rasterisationFragmentShadingTime = (epochTime()-startTime)*1000
    startTime = epochTime()
    updateScreen()
    let blitTime = (epochTime()-startTime)*1000
    #endDrawing()
    frameTime = epochTime() - frameStart
    frameStart = epochTime()
    if isKeyDown(KEY_L):
        echo("Vertex Shading Time: ", $vertexShadingTime, " ms")
        echo("Clipping Time: ", $clippingTime, " ms")
        echo("RasterisationFragmentShading Time: ", $rasterisationFragmentShadingTime, " ms")
        echo("Blit Time: ", $blitTime, " ms")


proc deInit*() =
    dealloc(DEPTH)
    dealloc(COLOUR)
    destroyWindow()

