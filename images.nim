
import streams

import cols


type
    Image* = object
        width, height: uint32
        widthf, heightf: float32
        #data: seq[Colour]
        data: pointer
    SampleType* = enum
        NEAREST
        BILINEAR
        BICUBIC

proc freeImg*(img: Image)=
    img.data.dealloc()

proc sampleQOI*(sampleType: SampleType, img: Image, u, v: float32): Colour {.gcsafe.}=
    let
        x: float32 = u*img.widthf
        y: float32 = (1-v)*img.heightf
        imgData = cast[ptr UncheckedArray[Colour]](img.data)
    case sampleType:
        of NEAREST:
            return imgData[uint32(y+0.5) * img.width + uint32(x+0.5)]
        of BILINEAR:
            let
                tl = imgData[uint32(y) * img.width + uint32(x)]
                tr = imgData[uint32(y) * img.width + uint32(x+1.0)]
                bl = imgData[uint32(y+0.9999) * img.width + uint32(x)]
                br = imgData[uint32(y+0.9999) * img.width + uint32(x + 1.0)]
                xmod = x - float(int(x))
                ymod = y - float(int(y))
                t = Colour(r: uint8(tl.r.float32*(1-xmod) + tr.r.float32*xmod), g: uint8(tl.g.float32*(1-xmod) + tr.g.float32*xmod), b: uint8(tl.b.float32*(1-xmod) + tr.b.float32*xmod), a: uint8(tl.a.float32*(1-xmod) + tr.a.float32*xmod))
                b = Colour(r: uint8(bl.r.float32*(1-xmod) + br.r.float32*xmod), g: uint8(bl.g.float32*(1-xmod) + br.g.float32*xmod), b: uint8(bl.b.float32*(1-xmod) + br.b.float32*xmod), a: uint8(bl.a.float32*(1-xmod) + br.a.float32*xmod))
            return Colour(r: uint8(b.r.float32*ymod + t.r.float32*(1-ymod)), g: uint8(b.g.float32*ymod + t.g.float32*(1-ymod)), b: uint8(b.b.float32*(1-ymod) + t.b.float32*(ymod)), a: uint8(b.a.float32*(1-ymod) + t.a.float32*(ymod)))
        of BICUBIC:
            echo "WARNING: bicubic filtering not yet supported, falling back to bilinear"
            return sampleQOI(BILINEAR, img, u, v)

proc decodeQOI*(filename: string): Image=
    let dataStream = newFileStream(filename, fmRead)        # open file stream
    if dataStream.isNil:
        raise newException(IOError, "Cannot open file: " & filename)
    defer: dataStream.close()
    
    assert dataStream.readChar() == 'q'
    assert dataStream.readChar() == 'o'
    assert dataStream.readChar() == 'i'
    assert dataStream.readChar() == 'f'

    var
        width, height: uint32
    for _ in 0..<4:
        width = width shl 8
        width += dataStream.readUint8().uint32
    for _ in 0..<4:
        height = height shl 8
        height += dataStream.readUint8().uint32
    
    discard dataStream.readUint8() #ignore channels
    discard dataStream.readUint8() #ignore colourspace

    var
        output = Image(
            width: width,
            height: height,
            widthf: width.float32,
            heightf: height.float32,
            data: alloc(width*height*sizeof(Colour).uint32)
        )
        index: uint32 = 0
        seenCols: array[64, Colour]
        lastCol: Colour = Colour(r: 0, g: 0, b: 0, a: 255)
    
    let outputData = cast[ptr UncheckedArray[Colour]](output.data)
    
    func hash(col: Colour): int = (col.r*3 + col.g*5 + col.b*7 + col.a*11).int mod 64
    proc writeCol(col: Colour) = outputData[index] = col; index += 1; seenCols[hash(col)] = col

    while index < width*height:
        let b = dataStream.readUint8()                      # read 1 byte
        if b == 0xFE:
            lastCol.r = dataStream.readUint8()
            lastCol.g = dataStream.readUint8()
            lastCol.b = dataStream.readUint8()
            writeCol(lastCol)
        elif b == 0xFF:
            lastCol.r = dataStream.readUint8()
            lastCol.g = dataStream.readUint8()
            lastCol.b = dataStream.readUint8()
            lastCol.a = dataStream.readUint8()
            writeCol(lastCol)
        elif (b shr 6) == 0b00:
            lastCol = seenCols[b and 0b00111111]
            writeCol(lastCol)
        elif (b shr 6) == 0b01:
            lastCol.r += ((b and 0b00110000) shr 4) - 2
            lastCol.g += ((b and 0b00001100) shr 2) - 2
            lastCol.b += (b and 0b00000011) - 2
            writeCol(lastCol)
        elif (b shr 6) == 0b10:
            let b2 = dataStream.readUint8()
            lastCol.r += (b and 0b00111111) + ((b2 and 0b11110000) shr 4) - 40
            lastCol.g += (b and 0b00111111) - 32
            lastCol.b += (b and 0b00111111) + (b2 and 0b00001111) - 40
            writeCol(lastCol)
        elif (b shr 6) == 0b11:
            for _ in 0..<((b and 0b00111111).int + 1):
                writeCol(lastCol)

    for _ in 0..<7:
        assert dataStream.readUint8() == 0
    assert dataStream.readUint8() == 1
    return output
