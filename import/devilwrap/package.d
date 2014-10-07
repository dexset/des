module devilwrap;

import desmath.linear.vector;

import derelict.devil.il;
import derelict.devil.ilu;

import desil.image;
import desutil.string;

import std.string;

static this()
{
    DerelictIL.load();
    DerelictILU.load();
    ilInit();
    iluInit();
    ilEnable( IL_FILE_OVERWRITE );
}

Image!2 loadImageFromFile( string fname )
{
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

        ubyte* raw = ilGetData();
        ubyte[] data;
        data.length = w * h * c;
        
        foreach( i, ref d; data ) d = raw[i];

        return Image!2( ivec2(w,h), PixelType( ComponentType.UBYTE, cast(ubyte)(c) ), data );
}

void saveImageToFile( in Image!2 img, string fname )
{
    ILenum format, type;

    switch( img.type.channels )
    {
        case 1: format = IL_COLOUR_INDEX; break;
        case 3: format = IL_RGB; break;
        case 4: format = IL_RGBA; break;
        default: throw new ImageException( "Bad image channels count for saving" );
    }

    final switch( img.type.comp )
    {
        case ComponentType.BYTE: type = IL_BYTE; break;
        case ComponentType.UBYTE: type = IL_UNSIGNED_BYTE; break;
        case ComponentType.SHORT: type = IL_SHORT; break;
        case ComponentType.USHORT: type = IL_UNSIGNED_SHORT; break;
        case ComponentType.INT: type = IL_INT; break;
        case ComponentType.UINT: type = IL_UNSIGNED_INT; break;
        case ComponentType.FLOAT: type = IL_FLOAT; break;
        case ComponentType.NORM_FLOAT: type = IL_FLOAT; break;
        case ComponentType.DOUBLE: type = IL_DOUBLE; break;
        case ComponentType.NORM_DOUBLE: type = IL_DOUBLE; break;
        case ComponentType.RAWBYTE: 
            throw new ImageException( "Bad image type for saving (rawbyte), please retype image" );
    }

    ILuint im;
    ilGenImages( 1, &im );
    scope(exit) ilDeleteImages( 1, &im );
    ilBindImage( im );

    if( IL_TRUE != ilTexImage( cast(uint)(img.size.w), cast(uint)(img.size.h), 
                1, cast(ubyte)(img.type.channels), format, type, cast(void*)img.data.ptr ) )
        throw new ImageException( "ilTexImage fails: " ~ toDString( iluErrorString(ilGetError()) ) );

    iluFlipImage();
    
    import std.string;
    if( IL_TRUE != ilSave( IL_JPG, fname.toStringz ) )
        throw new ImageException( "ilSaveImage fails: " ~ toDString( iluErrorString(ilGetError()) ) );
}
