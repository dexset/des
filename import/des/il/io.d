module des.il.io;

import des.math.linear.vector;

import derelict.devil.il;
import derelict.devil.ilu;

public import des.il;
import des.util.stdext.string;

import std.string;

import std.conv : to;

///
Image imLoad( string fname, bool flip=true )
{
    loadIL();

    ILuint im;
    ilGenImages( 1, &im );
    scope(exit) ilDeleteImages( 1, &im );
    ilBindImage( im );

    if( ilLoadImage( fname.toStringz ) == false )
        throw new ImageException( "'ilLoadImage' fails with '" ~ fname ~ "': " ~ 
                                    toDString( iluErrorString( ilGetError() ) ) );

    int w = ilGetInteger( IL_IMAGE_WIDTH );
    int h = ilGetInteger( IL_IMAGE_HEIGHT );
    int c = ilGetInteger( IL_IMAGE_BYTES_PER_PIXEL );

    if( flip ) iluFlipImage();

    ubyte* raw = ilGetData();

    return Image( ivec2(w,h), cast(ubyte)(c), DataType.UBYTE, raw[0..w*h*c] );
}

///
void imSave( in Image img, string fname )
{
    loadIL();

    ILenum format, type;

    switch( img.info.comp )
    {
        case 1: format = IL_COLOUR_INDEX; break;
        case 3: format = IL_RGB; break;
        case 4: format = IL_RGBA; break;
        default: throw new ImageException( "Bad image channels count for saving" );
    }

    switch( img.info.type )
    {
        case DataType.BYTE:       type = IL_BYTE;           break;
        case DataType.UBYTE:      type = IL_UNSIGNED_BYTE;  break;
        case DataType.SHORT:      type = IL_SHORT;          break;
        case DataType.USHORT:     type = IL_UNSIGNED_SHORT; break;
        case DataType.INT:        type = IL_INT;            break;
        case DataType.UINT:       type = IL_UNSIGNED_INT;   break;
        case DataType.FLOAT:      type = IL_FLOAT;          break;
        case DataType.DOUBLE:     type = IL_DOUBLE;         break;
        default:
            throw new ImageException( "Bad image type for saving (" ~
                    to!string(img.info.comp) ~
                    "), please retype image" );
    }

    ILuint im;
    ilGenImages( 1, &im );
    scope(exit) ilDeleteImages( 1, &im );
    ilBindImage( im );

    auto size = uivec2( redimSize( 2, img.size ) );

    if( IL_TRUE != ilTexImage( size.w, size.h, 1, cast(ubyte)(img.info.comp), format, type, cast(void*)img.data.ptr ) )
        throw new ImageException( "ilTexImage fails: " ~ toDString( iluErrorString(ilGetError()) ) );

    iluFlipImage();

    import std.string;
    if( IL_TRUE != ilSaveImage( fname.toStringz ) )
        throw new ImageException( "ilSaveImage fails: " ~ toDString( iluErrorString(ilGetError()) ) );
}

private void loadIL()
{
    if( DerelictIL.isLoaded ) return;

    DerelictIL.load();
    DerelictILU.load();
    ilInit();
    iluInit();
    ilEnable( IL_FILE_OVERWRITE );
}
