
import libSRWWL
export KeyboardKey, isKeyDown, isKeyUp, windowShouldClose
import vectors
import algorithm
import times
import std/locks
import std/typedthreads

var frameTime*: float
var frameStart: float
var
    lockA, lockB, lockC, lockD: Lock
    condA, condB, condC, condD: Cond
    jobReadyA, jobReadyB, jobReadyC, jobReadyD: bool
    jobDoneA, jobDoneB, jobDoneC, jobDoneD: bool
var tA, tB, tC, tD: Thread[pointer]
var logging: bool = false
var backfaceCulling: bool = true

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
        screenLeft, screenRight, screenTop, screenBottom: uint32
        denom, al1, al2, be1, be2: float32
        alpha0, dxAlpha, dyAlpha, beta0, dxBeta, dyBeta: float32
        v0, v1, v2: Vector2
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
    COLOUR: pointer
    COLOURS: array[2, pointer]
    currentCol: int = 0
    DEPTH: pointer
    WIDTH: int32
    HEIGHT: int32
    vertexShadingQueue: seq[tri]
    clippingQueue: seq[tri]
    rasterisationFragmentShadingQueue: seq[tri]
    rasterisationFragmentShadingQueueMM: (int, pointer)


var
    vertexShaders: seq[vertexShader]
    fragmentShaders: seq[fragmentShader]
    fragmentShadersMM: pointer

proc registerVertexShader*(shader: vertexShader)=
    vertexShaders.add(shader)

proc registerFragmentShader*(shader: fragmentShader)=
    fragmentShaders.add(shader)
    
    if fragmentShadersMM != nil: dealloc(fragmentShadersMM)
    fragmentShadersMM = alloc(fragmentShaders.len() * sizeof(fragmentShader))
    for i in 0..fragmentShaders.high:
        cast[ptr UncheckedArray[fragmentShader]](fragmentShadersMM)[][i] = fragmentShaders[i]

proc queueTri*(triangle: tri)=
    vertexShadingQueue.add(triangle)

proc clearScreen*(colour: uint32) =
    let colourBuffer = cast[ptr UncheckedArray[uint32]](COLOUR)
    let depthBuffer  = cast[ptr UncheckedArray[float32]](DEPTH)
  
    # Fill the first line
    for x in 0..<WIDTH:
        colourBuffer[x] = colour
        depthBuffer[x] = 1.0'f32
  
    # Copy that line into the rest
    for y in 1..<HEIGHT:
        let dstColour = addr colourBuffer[y * WIDTH]
        let dstDepth  = addr depthBuffer[y * WIDTH]
        copyMem(dstColour, addr colourBuffer[0], WIDTH * sizeof(uint32))
        copyMem(dstDepth,  addr depthBuffer[0],  WIDTH * sizeof(float32))

proc getScreenshot*(): seq[uint8]=
    let screenImage = cast[ptr UncheckedArray[uint32]](COLOURS[currentCol])
    var
        output: seq[uint8] = @['q'.uint8, 'o'.uint8, 'i'.uint8, 'f'.uint8]
        index = 0
        lastCol: uint32 = 0xFF000000'u32
        seen: array[64, uint32]

    for i in 0..<4:
        output.add(uint8((WIDTH shr (8*(3-i))) and 0x000000FF))
    for i in 0..<4:
        output.add(uint8((HEIGHT shr (8*(3-i))) and 0x000000FF))
    output.add(4)
    output.add(1)

    func hash(col: uint32): uint8=
        return uint8(((col and 0x00FF0000) shr 16)*3 + ((col and 0x0000FF00) shr 8)*5 + (col and 0x000000FF)*7 + ((col and 0xFF000000'u32) shr 24)*11) mod 64

    while index < WIDTH * HEIGHT:
        if screenImage[index] == lastCol:
            var numSeen: int = -1
            while index < WIDTH * HEIGHT and screenImage[index] == lastCol and numSeen < 61:
                numSeen += 1
                index += 1
            output.add(0b11000000'u8 or (numSeen.uint8 and 0b00111111'u8))
        elif seen[hash(screenImage[index])] == screenImage[index]:
            lastCol = screenImage[index]
            output.add(hash(screenImage[index]))
            index += 1
        else:
            let
                newCol = screenImage[index]
                dr: uint8 = (((newCol and 0x00FF0000) shr 16).uint8 - ((lastCol and 0x00FF0000) shr 16).uint8)
                dg: uint8 = (((newCol and 0x0000FF00) shr 8 ).uint8 - ((lastCol and 0x0000FF00) shr 8 ).uint8)
                db: uint8 = (((newCol and 0x000000FF) shr 0 ).uint8 - ((lastCol and 0x000000FF) shr 0 ).uint8)
            if (newCol and 0xFF000000'u32) != (lastCol and 0xFF000000'u32):
                output.add(0xFF'u8)
                output.add(uint8((newCol and 0x00FF0000) shr 16))
                output.add(uint8((newCol and 0x0000FF00) shr 8))
                output.add(uint8(newCol and 0x000000FF))
                output.add(uint8((newCol and 0xFF000000'u32) shr 24))
                seen[hash(newCol)] = newCol
                lastCol = newCol
                index += 1
            elif cast[int8](dr) >= -2 and cast[int8](dr) <= 1 and cast[int8](dg) >= -2 and cast[int8](dg) <= 1 and cast[int8](db) >= -2 and cast[int8](db) <= 1:
                output.add(0b01000000'u8 or uint8((dr + 2) shl 4) or uint8((dg + 2) shl 2) or uint8(db + 2))
                seen[hash(newCol)] = newCol
                lastCol = newCol
                index += 1
            elif cast[int8](dg) >= -32 and cast[int8](dg) <= 31 and cast[int8](dr-dg) >= -8 and cast[int8](dr-dg) <= 7 and cast[int8](db-dg) >= -8 and cast[int8](db-dg) <= 7:
                output.add(0b10000000'u8 or uint8(dg.uint8+32))
                output.add(uint8((dr.uint8-dg.uint8+8) shl 4) or uint8(db.uint8-dg.uint8+8))
                seen[hash(newCol)] = newCol
                lastCol = newCol
                index += 1
            else:
                output.add(0xFE'u8)
                output.add(uint8((newCol and 0x00FF0000) shr 16))
                output.add(uint8((newCol and 0x0000FF00) shr 8))
                output.add(uint8(newCol and 0x000000FF))
                seen[hash(newCol)] = newCol
                lastCol = newCol
                index += 1
    for i in 0..<7:
        output.add(0)
    output.add(1)

    return output

var
    hWIDTH: int32# = WIDTH shr 1
    hHEIGHT: int32# = HEIGHT shr 1
    hWIDTHf: float# = hWIDTH.float
    hHEIGHTf: float# = hHEIGHT.float


proc rasterisationFragmentShading(line, lineMod: uint8) {.inline, gcsafe.}

proc doWorkA() {.gcsafe.} = rasterisationFragmentShading(0, 4)

proc doWorkB() {.gcsafe.} = rasterisationFragmentShading(1, 4)

proc doWorkC() {.gcsafe.} = rasterisationFragmentShading(2, 4)

proc doWorkD() {.gcsafe.} = rasterisationFragmentShading(3, 4)

proc workerA(arg: pointer) {.thread.} =
    while true:
        lockA.acquire()
        while not jobReadyA:
            condA.wait(lockA)
        jobReadyA = false
        lockA.release()

        doWorkA()

        lockA.acquire()
        jobDoneA = true
        condA.signal()
        lockA.release()

proc workerB(arg: pointer) {.thread.} =
    while true:
        lockB.acquire()
        while not jobReadyB:
            condB.wait(lockB)
        jobReadyB = false
        lockB.release()

        doWorkB()

        lockB.acquire()
        jobDoneB = true
        condB.signal()
        lockB.release()

proc workerC(arg: pointer) {.thread.} =
    while true:
        lockC.acquire()
        while not jobReadyC:
            condC.wait(lockC)
        jobReadyC = false
        lockC.release()

        doWorkC()

        lockC.acquire()
        jobDoneC = true
        condC.signal()
        lockC.release()

proc workerD(arg: pointer) {.thread.} =
    while true:
        lockD.acquire()
        while not jobReadyD:
            condD.wait(lockD)
        jobReadyD = false
        lockD.release()

        doWorkD()

        lockD.acquire()
        jobDoneD = true
        condD.signal()
        lockD.release()

proc initRendering*(width: int32, height: int32) =
    WIDTH = width
    HEIGHT = height

    hWIDTH = WIDTH shr 1
    hHEIGHT = HEIGHT shr 1
    hWIDTHf = hWIDTH.float
    hHEIGHTf = hHEIGHT.float
    frameStart = epochTime()

    initLock(lockA)
    initLock(lockB)
    initLock(lockC)
    initLock(lockD)
    initCond(condA)
    initCond(condB)
    initCond(condC)
    initCond(condD)
    createThread(tA, workerA, nil)
    createThread(tB, workerB, nil)
    createThread(tC, workerC, nil)
    createThread(tD, workerD, nil)

    fragmentShadersMM = alloc(fragmentShaders.len() * sizeof(fragmentShader))
    for i in 0..fragmentShaders.high:
        cast[ptr UncheckedArray[fragmentShader]](fragmentShadersMM)[][i] = fragmentShaders[i]

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

proc preRasterisation()=
    for newTri in mitems(rasterisationFragmentShadingQueue):
        for i in 0..2:
            newTri.positions[i].x /= newTri.positions[i].w
            newTri.positions[i].y /= newTri.positions[i].w
            newTri.positions[i].z /= newTri.positions[i].w
        let
            topRight = Vector2(x: max(newTri.positions[0].x, max(newTri.positions[1].x, newTri.positions[2].x)), y: max(newTri.positions[0].y, max(newTri.positions[1].y, newTri.positions[2].y)))
            bottomLeft = Vector2(x: min(newTri.positions[0].x, min(newTri.positions[1].x, newTri.positions[2].x)), y: min(newTri.positions[0].y, min(newTri.positions[1].y, newTri.positions[2].y)))
        newTri.screenLeft = max((bottomLeft.x*(hWIDTH).float).int32 + (hWIDTH).int32, 0).uint32
        newTri.screenRight = min((topRight.x*(hWIDTH).float).int32 + (hWIDTH).int32, WIDTH-1).uint32
        newTri.screenTop = min((topRight.y*(hHEIGHT).float).int32 + (hHEIGHT).int32, HEIGHT-1).uint32
        newTri.screenBottom = max((bottomLeft.y*(hHEIGHT).float).int32 + (hHEIGHT).int32, 0).uint32
        
        newTri.v0 = Vector2(
            x: newTri.positions[0].x,
            y: newTri.positions[0].y
        )
        newTri.v1 = Vector2(
            x: newTri.positions[1].x,
            y: newTri.positions[1].y
        )
        newTri.v2 = Vector2(
            x: newTri.positions[2].x,
            y: newTri.positions[2].y
        )
        newTri.denom = ( (newTri.v1.y - newTri.v2.y) * (newTri.v0.x - newTri.v2.x) + (newTri.v2.x - newTri.v1.x) * (newTri.v0.y - newTri.v2.y) )
        newTri.al1 = (newTri.v1.y - newTri.v2.y)
        newTri.al2 = (newTri.v2.x - newTri.v1.x)
        newTri.be1 = (newTri.v2.y - newTri.v0.y)
        newTri.be2 = (newTri.v0.x - newTri.v2.x)

        # preRasterisation: compute derivatives in NDC per pixel
        let dxNdc = 2.0'f32 / WIDTH.float
        let dyNdc = 2.0'f32 / HEIGHT.float
        
        newTri.dxAlpha = newTri.al1 * dxNdc / newTri.denom
        newTri.dyAlpha = newTri.al2 * dyNdc / newTri.denom
        newTri.dxBeta  = newTri.be1 * dxNdc / newTri.denom
        newTri.dyBeta  = newTri.be2 * dyNdc / newTri.denom
        
        # seed alpha0/beta0 at the exact NDC of (screenLeft, screenBottom)
        let ndcPos0 = Vector2(
          x: (newTri.screenLeft.float / hWIDTHf) - 1.0'f32,
          y: (newTri.screenBottom.float / hHEIGHTf) - 1.0'f32
        )
        newTri.alpha0 = (newTri.al1 * (ndcPos0.x - newTri.v2.x) + newTri.al2 * (ndcPos0.y - newTri.v2.y)) / newTri.denom
        newTri.beta0  = (newTri.be1 * (ndcPos0.x - newTri.v2.x) + newTri.be2 * (ndcPos0.y - newTri.v2.y)) / newTri.denom
        
proc backFace(triangle: tri): bool =
    return (triangle.v0.x-triangle.v2.x)*(triangle.v1.y-triangle.v0.y)<=(triangle.v0.x-triangle.v1.x)*(triangle.v2.y-triangle.v0.y)

proc rasterisationFragmentShading(line, lineMod: uint8) {.inline, gcsafe.} =
    let
        colourBuffer = cast[ptr UncheckedArray[uint32]](COLOUR)
        depthBuffer = cast[ptr UncheckedArray[float32]](DEPTH)
    #for newTri in mitems(rasterisationFragmentShadingQueue):
    for i in 0..rasterisationFragmentShadingQueueMM[0]:
        var newTri = cast[ptr UncheckedArray[tri]](rasterisationFragmentShadingQueueMM[1])[][i]
        let triFragmentShader = (cast[ptr UncheckedArray[fragmentShader]](fragmentShadersMM)[])[newTri.fragmentShader]
        if backfaceCulling and newTri.backFace(): continue
        if newTri.denom == 0: continue
        {.push checks:off.}
        var
            alphaY = newTri.alpha0 - newTri.dyAlpha
            betaY = newTri.beta0 - newTri.dyBeta
        for y in newTri.screenBottom..newTri.screenTop:
            alphaY += newTri.dyAlpha
            betaY += newTri.dyBeta

            if y mod lineMod != line: continue
            
            var
                alpha = alphaY - newTri.dxAlpha
                beta = betaY - newTri.dxBeta
                gamma = 1 - alpha - beta
            for x in newTri.screenLeft..newTri.screenRight:
                alpha += newTri.dxAlpha
                beta += newTri.dxBeta
                gamma = 1 - alpha - beta
                
                #reject fragments outside triangle
                if alpha < 0.0 or beta < 0.0 or gamma < 0.0:
                    continue
                #compute weights
                var
                    w0 = alpha/newTri.positions[0].w
                    w1 = beta/newTri.positions[1].w
                    w2 = gamma/newTri.positions[2].w
                    sum = w0+w1+w2
                w0 /= sum
                w1 /= sum
                w2 /= sum
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
                    newPix = triFragmentShader(newFrag)
                colourBuffer[][y.int*WIDTH + x.int] = newPix.col
        {.pop.}

proc updateScreen() =
    setBuffer(cast[ptr uint8](COLOURS[currentCol]))
    currentCol = 1-currentCol
    COLOUR = COLOURS[currentCol]
    waitForFrame()

proc enableLogging*()= logging = true

proc setBackfaceCulling*(v: bool)= backfaceCulling=v

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
    preRasterisation()
    let preRasterisationTime = (epochTime()-startTime)*1000
    startTime = epochTime()
    #rasterisationFragmentShading(0, 2)
    #rasterisationFragmentShading(1, 2)

    #create a manual memory rasterisationFragmentShadingQueue()
    rasterisationFragmentShadingQueueMM[0] = rasterisationFragmentShadingQueue.high
    rasterisationFragmentShadingQueueMM[1] = alloc(rasterisationFragmentShadingQueue.len() * sizeof(tri))
    for i in 0..rasterisationFragmentShadingQueue.high:
        cast[ptr UncheckedArray[tri]](rasterisationFragmentShadingQueueMM[1])[][i] = rasterisationFragmentShadingQueue[i]
    # Wake workers
    lockA.acquire()
    jobDoneA = false
    jobReadyA = true
    condA.signal()
    lockA.release()

    lockB.acquire()
    jobDoneB = false
    jobReadyB = true
    condB.signal()
    lockB.release()

    lockC.acquire()
    jobDoneC = false
    jobReadyC = true
    condC.signal()
    lockC.release()

    lockD.acquire()
    jobDoneD = false
    jobReadyD = true
    condD.signal()
    lockD.release()

    # Wait for all
    lockA.acquire()
    while not jobDoneA:
        condA.wait(lockA)
    lockA.release()

    lockB.acquire()
    while not jobDoneB:
        condB.wait(lockB)
    lockB.release()

    lockC.acquire()
    while not jobDoneC:
        condC.wait(lockC)
    lockC.release()

    lockD.acquire()
    while not jobDoneD:
        condD.wait(lockD)
    lockD.release()

    #free manual memory rasterisationFragmentShadingQueue
    dealloc(rasterisationFragmentShadingQueueMM[1])

    let rasterisationFragmentShadingTime = (epochTime()-startTime)*1000
    rasterisationFragmentShadingQueue = @[]
    startTime = epochTime()
    updateScreen()
    let blitTime = (epochTime()-startTime)*1000
    #endDrawing()
    frameTime = epochTime() - frameStart
    frameStart = epochTime()
    #while not frameDropped(): waitForFrame()
    if isKeyDown(KEY_L) and logging:
        echo("Vertex Shading Time: ", $vertexShadingTime, " ms")
        echo("Clipping Time: ", $clippingTime, " ms")
        echo("PreRasterisation Time: ", $preRasterisationTime, " ms")
        echo("RasterisationFragmentShading Time: ", $rasterisationFragmentShadingTime, " ms")
        echo("Blit Time: ", $blitTime, " ms")
    if logging and frameDropped():
        echo "Frame Dropped"


proc deInit*() =
    dealloc(fragmentShadersMM)
    dealloc(DEPTH)
    dealloc(COLOURS[0])
    dealloc(COLOURS[1])
    destroyWindow()
