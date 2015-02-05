module des.il.io;

import des.math.linear.vector;

import derelict.devil.il;
import derelict.devil.ilu;

public import des.il;
import des.util.stdext.string;

import std.string;

import std.conv : to;

///
Image!2 imLoad( string fname, bool flip=true )
{
    loadIL();

    ILuint im;
    ilGenImages( 1, &im );
    scope(exit) ilDeleteImages( 1, &im );
    ilBindImage( im );

    if( ilLoadImage( fname.toStringz ) == false )
        throw new ImageException( "ilLoadImage fails with '" ~ fname ~ "': " ~ 
                                    toDString( iluErrorString( ilGetError() ) ) );

    int w = ilGetInteger( IL_IMAGE_WIDTH );
    int h = ilGetInteger( IL_IMAGE_HEIGHT );
    int c = ilGetInteger( IL_IMAGE_BYTES_PER_PIXEL );

    if( flip ) iluFlipImage();

    ubyte* raw = ilGetData();
    ubyte[] data;
    data.length = w * h * c;
    
    foreach( i, ref d; data ) d = raw[i];

    return Image!2( ivec2(w,h), DataType.UBYTE, cast(ubyte)(c), data );
}

///
void imSave( in Image!2 img, string fname )
{
    loadIL();

    ILenum format, type;

    switch( img.info.channels )
    {
        case 1: format = IL_COLOUR_INDEX; break;
        case 3: format = IL_RGB; break;
        case 4: format = IL_RGBA; break;
        default: throw new ImageException( "Bad image channels count for saving" );
    }

    switch( img.info.comp )
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

    if( IL_TRUE != ilTexImage( cast(uint)(img.size.w), cast(uint)(img.size.h), 
                1, cast(ubyte)(img.info.channels), format, type, cast(void*)img.data.ptr ) )
        throw new ImageException( "ilTexImage fails: " ~ toDString( iluErrorString(ilGetError()) ) );

    iluFlipImage();
    
    import std.string;
    if( IL_TRUE != ilSave( IL_JPG, fname.toStringz ) )
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
