module des.gl.type;

import std.stdio;
import std.string;

import des.gl.general;

///
enum GLType
{
    UBYTE  = GL_UNSIGNED_BYTE,  /// `GL_UNSIGNED_BYTE`
    BYTE   = GL_BYTE,           /// `GL_BYTE`
    USHORT = GL_UNSIGNED_SHORT, /// `GL_UNSIGNED_SHORT`
    SHORT  = GL_SHORT,          /// `GL_SHORT`
    UINT   = GL_UNSIGNED_INT,   /// `GL_UNSIGNED_INT`
    INT    = GL_INT,            /// `GL_INT`
    FLOAT  = GL_FLOAT,          /// `GL_FLOAT`
    DOUBLE = GL_DOUBLE,         /// `GL_DOUBLE`
}

///
size_t sizeofGLType( GLType type ) pure nothrow
{
    final switch(type)
    {
    case GLType.BYTE:
    case GLType.UBYTE:
        return byte.sizeof;

    case GLType.SHORT:
    case GLType.USHORT:
        return short.sizeof;

    case GLType.INT:
    case GLType.UINT:
        return int.sizeof;

    case GLType.FLOAT:
        return float.sizeof;

    case GLType.DOUBLE:
        return double.sizeof;
    }
}

///
GLType toGLType(T)() nothrow pure @nogc @safe @property
{
    static if( is( T == ubyte ) )
        return GLType.UBYTE;
    else static if( is( T == byte ) )
        return GLType.BYTE;
    else static if( is( T == ushort ) )
        return GLType.USHORT;
    else static if( is( T == short ) )
        return GLType.SHORT;
    else static if( is( T == uint ) )
        return GLType.UINT;
    else static if( is( T == int ) )
        return GLType.INT;
    else static if( is( T == float ) )
        return GLType.FLOAT;
    else static if( is( T == double ) )
        return GLType.DOUBLE;
    else
    {
        pragma(msg, "no GLType for ", T );
        static assert(0);
    }
}

///
unittest
{
    assert( toGLType!ubyte  == GLType.UBYTE );
    assert( toGLType!byte   == GLType.BYTE );
    assert( toGLType!ushort == GLType.USHORT );
    assert( toGLType!short  == GLType.SHORT );
    assert( toGLType!uint   == GLType.UINT );
    assert( toGLType!int    == GLType.INT );
    assert( toGLType!float  == GLType.FLOAT );
    assert( toGLType!double == GLType.DOUBLE );
}

import std.traits : EnumMembers;

///
enum GLBufferTarget
{
    UNKNOWN            = 0,                            /// equals zero
    ARRAY              = GL_ARRAY_BUFFER,              /// `GL_ARRAY_BUFFER`
    ATOMIC_COUNTER     = GL_ATOMIC_COUNTER_BUFFER,     /// `GL_ATOMIC_COUNTER_BUFFER`
    DISPATCH_INDIRECT  = GL_DISPATCH_INDIRECT_BUFFER,  /// `GL_DISPATCH_INDIRECT_BUFFER`
    DRAW_INDIRECT      = GL_DRAW_INDIRECT_BUFFER,      /// `GL_DRAW_INDIRECT_BUFFER`
    ELEMENT_ARRAY      = GL_ELEMENT_ARRAY_BUFFER,      /// `GL_ELEMENT_ARRAY_BUFFER`
    PIXEL_PACK         = GL_PIXEL_PACK_BUFFER,         /// `GL_PIXEL_PACK_BUFFER`
    PIXEL_UNPACK       = GL_PIXEL_UNPACK_BUFFER,       /// `GL_PIXEL_UNPACK_BUFFER`
    QUERY              = GL_QUERY_BUFFER,              /// `GL_QUERY_BUFFER`
    SHADER_STORAGE     = GL_SHADER_STORAGE_BUFFER,     /// `GL_SHADER_STORAGE_BUFFER`
    TEXTURE            = GL_TEXTURE_BUFFER,            /// `GL_TEXTURE_BUFFER`
    TRANSFORM_FEEDBACK = GL_TRANSFORM_FEEDBACK_BUFFER, /// `GL_TRANSFORM_FEEDBACK_BUFFER`
    UNIFORM            = GL_UNIFORM_BUFFER,            /// `GL_UNIFORM_BUFFER`
}

///
GLBufferTarget toGLBufferTarget( GLenum trg ) pure nothrow @nogc
{
    foreach( e; [EnumMembers!GLBufferTarget] )
        if( cast(GLenum)e == trg ) return e;
    return GLBufferTarget.UNKNOWN;
}

///
enum GLTextureTarget
{
    UNKNOWN               = 0,                               /// equals zero
    T1D                   = GL_TEXTURE_1D,                   /// `GL_TEXTURE_1D`
    T1D_ARRAY             = GL_TEXTURE_1D_ARRAY,             /// `GL_TEXTURE_1D_ARRAY`
    T2D                   = GL_TEXTURE_2D,                   /// `GL_TEXTURE_2D`
    T2D_ARRAY             = GL_TEXTURE_2D_ARRAY,             /// `GL_TEXTURE_2D_ARRAY`
    T2D_MULTISAMPLE       = GL_TEXTURE_2D_MULTISAMPLE,       /// `GL_TEXTURE_2D_MULTISAMPLE`
    T2D_MULTISAMPLE_ARRAY = GL_TEXTURE_2D_MULTISAMPLE_ARRAY, /// `GL_TEXTURE_2D_MULTISAMPLE_ARRAY`
    T3D                   = GL_TEXTURE_3D,                   /// `GL_TEXTURE_3D`
    CUBE_MAP              = GL_TEXTURE_CUBE_MAP,             /// `GL_TEXTURE_CUBE_MAP`
    CUBE_MAP_ARRAY        = GL_TEXTURE_CUBE_MAP_ARRAY,       /// `GL_TEXTURE_CUBE_MAP_ARRAY`
    RECTANGLE             = GL_TEXTURE_RECTANGLE,            /// `GL_TEXTURE_RECTANGLE`
    CUBE_MAP_POSITIVE_X   = GL_TEXTURE_CUBE_MAP_POSITIVE_X,  /// `GL_TEXTURE_CUBE_MAP_POSITIVE_X`
    CUBE_MAP_NEGATIVE_X   = GL_TEXTURE_CUBE_MAP_NEGATIVE_X,  /// `GL_TEXTURE_CUBE_MAP_NEGATIVE_X`
    CUBE_MAP_POSITIVE_Y   = GL_TEXTURE_CUBE_MAP_POSITIVE_Y,  /// `GL_TEXTURE_CUBE_MAP_POSITIVE_X`
    CUBE_MAP_NEGATIVE_Y   = GL_TEXTURE_CUBE_MAP_NEGATIVE_Y,  /// `GL_TEXTURE_CUBE_MAP_NEGATIVE_X`
    CUBE_MAP_POSITIVE_Z   = GL_TEXTURE_CUBE_MAP_POSITIVE_Z,  /// `GL_TEXTURE_CUBE_MAP_POSITIVE_X`
    CUBE_MAP_NEGATIVE_Z   = GL_TEXTURE_CUBE_MAP_NEGATIVE_Z,  /// `GL_TEXTURE_CUBE_MAP_NEGATIVE_X`
}

///
GLTextureTarget toGLTextureTarget( GLenum trg ) pure nothrow @nogc
{
    foreach( e; [EnumMembers!GLTextureTarget] )
        if( cast(GLenum)e == trg ) return e;
    return GLTextureTarget.UNKNOWN;
}
