module des.gl.texture;

import std.string;

import des.gl.general;

public import des.il;

import std.algorithm;
import des.util.stdext.algorithm;

///
class GLTextureException : DesGLException
{
    ///
    this( string msg, string file=__FILE__, size_t line=__LINE__ ) @safe pure nothrow
    { super( msg, file, line ); }
}

///
abstract class GLTexture : GLObject!("Texture",false)
{
    mixin DES;
    mixin ClassLogger;

protected:

    ///
    InternalFormat liformat;
    ///
    Format lformat;
    ///
    Type ltype;

    /// texture unit
    uint _unit;

    uivec3 _size;

public:

    ///
    enum InternalFormat
    {
        COMPRESSED_RED        = GL_COMPRESSED_RED,        /// `GL_COMPRESSED_RED`
        COMPRESSED_RG         = GL_COMPRESSED_RG,         /// `GL_COMPRESSED_RG`
        COMPRESSED_RGB        = GL_COMPRESSED_RGB,        /// `GL_COMPRESSED_RGB`
        COMPRESSED_RGBA       = GL_COMPRESSED_RGBA,       /// `GL_COMPRESSED_RGBA`
        COMPRESSED_SRGB       = GL_COMPRESSED_SRGB,       /// `GL_COMPRESSED_SRGB`
        COMPRESSED_SRGB_ALPHA = GL_COMPRESSED_SRGB_ALPHA, /// `GL_COMPRESSED_SRGB_ALPHA`
        DEPTH                 = GL_DEPTH_COMPONENT,       /// `GL_DEPTH_COMPONENT`
        DEPTH16               = GL_DEPTH_COMPONENT16,     /// `GL_DEPTH_COMPONENT16`
        DEPTH24               = GL_DEPTH_COMPONENT24,     /// `GL_DEPTH_COMPONENT24`
        DEPTH32               = GL_DEPTH_COMPONENT32,     /// `GL_DEPTH_COMPONENT32`
        DEPTH32F              = GL_DEPTH_COMPONENT32F,    /// `GL_DEPTH_COMPONENT32F`
        DEPTH_STENCIL         = GL_DEPTH_STENCIL,         /// `GL_DEPTH_STENCIL`
        R3_G3_B2              = GL_R3_G3_B2,              /// `GL_R3_G3_B2`
        RED                   = GL_RED,                   /// `GL_RED`
        RG                    = GL_RG,                    /// `GL_RG`
        RGB                   = GL_RGB,                   /// `GL_RGB`
        RGB4                  = GL_RGB4,                  /// `GL_RGB4`
        RGB5                  = GL_RGB5,                  /// `GL_RGB5`
        RGB8                  = GL_RGB8,                  /// `GL_RGB8`
        RGB10                 = GL_RGB10,                 /// `GL_RGB10`
        RGB12                 = GL_RGB12,                 /// `GL_RGB12`
        RGB16                 = GL_RGB16,                 /// `GL_RGB16`
        RGBA                  = GL_RGBA,                  /// `GL_RGBA`
        RGBA2                 = GL_RGBA2,                 /// `GL_RGBA2`
        RGBA4                 = GL_RGBA4,                 /// `GL_RGBA4`
        RGB5_A1               = GL_RGB5_A1,               /// `GL_RGB5_A1`
        RGBA8                 = GL_RGBA8,                 /// `GL_RGBA8`
        RGB10_A2              = GL_RGB10_A2,              /// `GL_RGB10_A2`
        RGBA12                = GL_RGBA12,                /// `GL_RGBA12`
        RGBA16                = GL_RGBA16,                /// `GL_RGBA16`
        SRGB                  = GL_SRGB,                  /// `GL_SRGB`
        SRGB8                 = GL_SRGB8,                 /// `GL_SRGB8`
        SRGB_ALPHA            = GL_SRGB_ALPHA,            /// `GL_SRGB_ALPHA`
        SRGB8_ALPHA8          = GL_SRGB8_ALPHA8           /// `GL_SRGB8_ALPHA8`
    }

    enum Side
    {
        PX = GL_TEXTURE_CUBE_MAP_POSITIVE_X, /// `GL_TEXTURE_CUBE_MAP_POSITIVE_X`
        NX = GL_TEXTURE_CUBE_MAP_NEGATIVE_X, /// `GL_TEXTURE_CUBE_MAP_NEGATIVE_X`
        PY = GL_TEXTURE_CUBE_MAP_POSITIVE_Y, /// `GL_TEXTURE_CUBE_MAP_POSITIVE_Y`
        NY = GL_TEXTURE_CUBE_MAP_NEGATIVE_Y, /// `GL_TEXTURE_CUBE_MAP_NEGATIVE_Y`
        PZ = GL_TEXTURE_CUBE_MAP_POSITIVE_Z, /// `GL_TEXTURE_CUBE_MAP_POSITIVE_Z`
        NZ = GL_TEXTURE_CUBE_MAP_NEGATIVE_Z  /// `GL_TEXTURE_CUBE_MAP_NEGATIVE_Z`
    }

    ///
    enum Format
    {
        RED  = GL_RED,  /// `GL_RED`
        RG   = GL_RG,   /// `GL_RG`
        RGB  = GL_RGB,  /// `GL_RGB`
        RGBA = GL_RGBA, /// `GL_RGBA`

        BGR  = GL_BGR,  /// `GL_BGR`
        BGRA = GL_BGRA, /// `GL_BGRA`

        DEPTH = GL_DEPTH_COMPONENT, /// `GL_DEPTH_COMPONENT`
        DEPTH_STENCIL = GL_DEPTH_STENCIL /// `GL_DEPTH_STENCIL`
    }

    ///
    enum Type
    {
        UNSIGNED_BYTE  = GL_UNSIGNED_BYTE,  /// `GL_UNSIGNED_BYTE`
        BYTE           = GL_BYTE,           /// `GL_BYTE`
        UNSIGNED_SHORT = GL_UNSIGNED_SHORT, /// `GL_UNSIGNED_SHORT`
        SHORT          = GL_SHORT,          /// `GL_SHORT`
        UNSIGNED_INT   = GL_UNSIGNED_INT,   /// `GL_UNSIGNED_INT`
        INT            = GL_INT,            /// `GL_INT`
        HALF_FLOAT     = GL_HALF_FLOAT,     /// `GL_HALF_FLOAT`
        FLOAT          = GL_FLOAT,          /// `GL_FLOAT`

        UNSIGNED_BYTE_3_3_2             = GL_UNSIGNED_BYTE_3_3_2,           /// `GL_UNSIGNED_BYTE_3_3_2`
        UNSIGNED_BYTE_2_3_3_REV         = GL_UNSIGNED_BYTE_2_3_3_REV,       /// `GL_UNSIGNED_BYTE_2_3_3_REV`
        UNSIGNED_SHORT_5_6_5            = GL_UNSIGNED_SHORT_5_6_5,          /// `GL_UNSIGNED_SHORT_5_6_5`
        UNSIGNED_SHORT_5_6_5_REV        = GL_UNSIGNED_SHORT_5_6_5_REV,      /// `GL_UNSIGNED_SHORT_5_6_5_REV`
        UNSIGNED_SHORT_4_4_4_4          = GL_UNSIGNED_SHORT_4_4_4_4,        /// `GL_UNSIGNED_SHORT_4_4_4_4`
        UNSIGNED_SHORT_4_4_4_4_REV      = GL_UNSIGNED_SHORT_4_4_4_4_REV,    /// `GL_UNSIGNED_SHORT_4_4_4_4_REV`
        UNSIGNED_SHORT_5_5_5_1          = GL_UNSIGNED_SHORT_5_5_5_1,        /// `GL_UNSIGNED_SHORT_5_5_5_1`
        UNSIGNED_SHORT_1_5_5_5_REV      = GL_UNSIGNED_SHORT_1_5_5_5_REV,    /// `GL_UNSIGNED_SHORT_1_5_5_5_REV`
        UNSIGNED_INT_8_8_8_8            = GL_UNSIGNED_INT_8_8_8_8,          /// `GL_UNSIGNED_INT_8_8_8_8`
        UNSIGNED_INT_8_8_8_8_REV        = GL_UNSIGNED_INT_8_8_8_8_REV,      /// `GL_UNSIGNED_INT_8_8_8_8_REV`
        UNSIGNED_INT_10_10_10_2         = GL_UNSIGNED_INT_10_10_10_2,       /// `GL_UNSIGNED_INT_10_10_10_2`
        UNSIGNED_INT_2_10_10_10_REV     = GL_UNSIGNED_INT_2_10_10_10_REV,   /// `GL_UNSIGNED_INT_2_10_10_10_REV`
        UNSIGNED_INT_24_8               = GL_UNSIGNED_INT_24_8,             /// `GL_UNSIGNED_INT_24_8`
        UNSIGNED_INT_10F_11F_11F_REV    = GL_UNSIGNED_INT_10F_11F_11F_REV,  /// `GL_UNSIGNED_INT_10F_11F_11F_REV`
        UNSIGNED_INT_5_9_9_9_REV        = GL_UNSIGNED_INT_5_9_9_9_REV,      /// `GL_UNSIGNED_INT_5_9_9_9_REV`
        FLOAT_32_UNSIGNED_INT_24_8_REV  = GL_FLOAT_32_UNSIGNED_INT_24_8_REV /// `GL_FLOAT_32_UNSIGNED_INT_24_8_REV`
    }

    ///
    this( GLenum tg, uint tu = 0 )
    in
    {
        int max_tu;
        checkGLCall!glGetIntegerv( GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS, &max_tu );
        assert( tu < max_tu );
    }
    body
    {
        _unit = tu;
        super( tg );
        logger.Debug( "with target [%s] texture unit [%d]", toGLTextureTarget(target), tu );
        setMinFilter( Filter.NEAREST );
        setMagFilter( Filter.NEAREST );
    }

    enum Dim { ONE=1, TWO=2, THREE=3 }

    pure nothrow @nogc @property
    {
        final
        {
            ///
            uint unit() const { return _unit; }
            ///
            void unit( uint tu ) { _unit = tu; }
        }

        uivec3 size() const
        {
            final switch( allocDim )
            {
                case Dim.ONE: return uivec3( _size.x, 1, 1 );
                case Dim.TWO: return uivec3( _size.xy, 1 );
                case Dim.THREE: return _size;
            }
        }

        const
        {
            abstract bool mipmapable();
            abstract bool isArray();
            abstract Dim imageDim();
            abstract Dim allocDim();
        }
    }

    ///
    void genMipmap()
    {
        if( !mipmapable ) throw new GLTextureException( this.toString ~ " is not mipmapable" );
        bind();
        checkGLCall!glGenerateMipmap(target);
        logger.Debug( "with target [%s]", target );
    }

    ///
    void setParam( GLenum param, int val )
    {
        bind();
        checkGLCall!glTexParameteri( target, param, val );
    }

    ///
    void setParam( GLenum param, int[] val )
    {
        bind();
        checkGLCall!glTexParameteriv( target, param, val.ptr );
    }

    ///
    void setParam( GLenum param, float val )
    {
        bind();
        checkGLCall!glTexParameterf( target, param, val );
    }

    ///
    void setParam( GLenum param, float[] val )
    {
        bind();
        checkGLCall!glTexParameterfv( target, param, val.ptr );
    }

    ///
    enum Filter
    {
        NEAREST                = GL_NEAREST,                /// `GL_NEAREST`
        LINEAR                 = GL_LINEAR,                 /// `GL_LINEAR`
        NEAREST_MIPMAP_NEAREST = GL_NEAREST_MIPMAP_NEAREST, /// `GL_NEAREST_MIPMAP_NEAREST`
        LINEAR_MIPMAP_NEAREST  = GL_LINEAR_MIPMAP_NEAREST,  /// `GL_LINEAR_MIPMAP_NEAREST`
        NEAREST_MIPMAP_LINEAR  = GL_NEAREST_MIPMAP_LINEAR,  /// `GL_NEAREST_MIPMAP_LINEAR`
        LINEAR_MIPMAP_LINEAR   = GL_LINEAR_MIPMAP_LINEAR    /// `GL_LINEAR_MIPMAP_LINEAR`
    }

    ///
    void setMinFilter( Filter filter )
    {
        setParam( GL_TEXTURE_MIN_FILTER, filter );
        logger.Debug( "to [%s]", filter );
    }

    ///
    void setMagFilter( Filter filter )
    {
        setParam( GL_TEXTURE_MAG_FILTER, filter );
        logger.Debug( "to [%s]", filter );
    }

    ///
    enum Wrap
    {
        CLAMP_TO_EDGE   = GL_CLAMP_TO_EDGE,   /// `GL_CLAMP_TO_EDGE`
        CLAMP_TO_BORDER = GL_CLAMP_TO_BORDER, /// `GL_CLAMP_TO_BORDER`
        MIRRORED_REPEAT = GL_MIRRORED_REPEAT, /// `GL_MIRRORED_REPEAT`
        REPEAT          = GL_REPEAT           /// `GL_REPEAT`
    }

    ///
    void setWrapS( Wrap wrap )
    {
        setParam( GL_TEXTURE_WRAP_S, wrap );
        logger.Debug( "to [%s]", wrap );
    }

    ///
    void setWrapT( Wrap wrap )
    {
        setParam( GL_TEXTURE_WRAP_T, wrap );
        logger.Debug( "to [%s]", wrap );
    }

    ///
    void setWrapR( Wrap wrap )
    {
        setParam( GL_TEXTURE_WRAP_R, wrap );
        logger.Debug( "to [%s]", wrap );
    }

    ///
    void setMinLOD( float v )
    {
        setParam( GL_TEXTURE_MIN_LOD, v );
        logger.Debug( "to [%f]", v );
    }

    ///
    void setMaxLOD( float v )
    {
        setParam( GL_TEXTURE_MAX_LOD, v );
        logger.Debug( "to [%f]", v );
    }

    ///
    void setLODBais( float v )
    {
        setParam( GL_TEXTURE_LOD_BIAS, v );
        logger.Debug( "to [%f]", v );
    }

    ///
    void setBaseLevel( int v )
    {
        setParam( GL_TEXTURE_BASE_LEVEL, v );
        logger.Debug( "to [%d]", v );
    }

    ///
    void setMaxLevel( int v )
    {
        setParam( GL_TEXTURE_MAX_LEVEL, v );
        logger.Debug( "to [%d]", v );
    }

    ///
    void setBorderColor( vec4 clr )
    {
        setParam( GL_TEXTURE_BORDER_COLOR, clr.data );
        logger.Debug( "to [%f,%f,%f,%f]", clr.r, clr.g, clr.b, clr.a );
    }

    ///
    enum CompareFunc
    {
        LEQUAL   = GL_LEQUAL,   /// `GL_LEQUAL`
        GEQUAL   = GL_GEQUAL,   /// `GL_GEQUAL`
        LESS     = GL_LESS,     /// `GL_LESS`
        GREATER  = GL_GREATER,  /// `GL_GREATER`
        EQUAL    = GL_EQUAL,    /// `GL_EQUAL`
        NOTEQUAL = GL_NOTEQUAL, /// `GL_NOTEQUAL`
        ALWAYS   = GL_ALWAYS,   /// `GL_ALWAYS`
        NEVER    = GL_NEVER     /// `GL_NEVER`
    }

    ///
    void setCompareFunc( CompareFunc cf )
    {
        setParam( GL_TEXTURE_COMPARE_FUNC, cf );
        logger.Debug( "to [%s]", cf );
    }

    ///
    enum CompareMode
    {
        REF_TO_TEXTURE = GL_COMPARE_REF_TO_TEXTURE, /// `GL_COMPARE_REF_TO_TEXTURE`
        NONE = GL_NONE /// `GL_NONE`
    }

    ///
    void setCompareMode( CompareMode cm )
    {
        setParam( GL_TEXTURE_COMPARE_MODE, cm );
        logger.Debug( "to [%s]", cm );
    }

    ///
    enum Swizzle
    {
        RED   = GL_RED,  /// `GL_RED`
        GREEN = GL_GREEN,/// `GL_GREEN`
        BLUE  = GL_BLUE, /// `GL_BLUE`
        ALPHA = GL_ALPHA,/// `GL_ALPHA`
        ONE   = GL_ONE,  /// `GL_ONE`
        ZERO  = GL_ZERO  /// `GL_ZERO`
    }

    ///
    void setSwizzleR( Swizzle s )
    {
        setParam( GL_TEXTURE_SWIZZLE_R, s );
        logger.Debug( "to [%s]", s );
    }

    ///
    void setSwizzleG( Swizzle s )
    {
        setParam( GL_TEXTURE_SWIZZLE_G, s );
        logger.Debug( "to [%s]", s );
    }

    ///
    void setSwizzleB( Swizzle s )
    {
        setParam( GL_TEXTURE_SWIZZLE_B, s );
        logger.Debug( "to [%s]", s );
    }

    ///
    void setSwizzleA( Swizzle s )
    {
        setParam( GL_TEXTURE_SWIZZLE_A, s );
        logger.Debug( "to [%s]", s );
    }

    ///
    void setSwizzleRGBA( Swizzle[4] s )
    {
        setParam( GL_TEXTURE_SWIZZLE_RGBA, to!(int[])(s) );
        logger.Debug( "to %s", s );
    }

    ///
    enum DepthStencilTextureMode
    {
        DEPTH   = GL_DEPTH_COMPONENT,   /// `GL_DEPTH_COMPONENT`
        STENCIL = GL_STENCIL_COMPONENTS /// `GL_STENCIL_COMPONENTS`
    }

    ///
    void setDepthStencilTextureMode( DepthStencilTextureMode dstm )
    {
        setParam( GL_DEPTH_STENCIL_TEXTURE_MODE, dstm );
        logger.Debug( "to [%s]", dstm );
    }

    final
    {
        /// glActiveTexture, glBindTexture
        override void bind()
        {
            checkGLCall!glActiveTexture( GL_TEXTURE0 + _unit );
            checkGLCall!glBindTexture( target, id );
            debug logger.trace( "pass" );
        }

        ///
        override void unbind()
        {
            checkGLCall!glActiveTexture( GL_TEXTURE0 + _unit );
            checkGLCall!glBindTexture( target, 0 );
            debug logger.trace( "pass" );
        }
    }

protected:

    ///
    void setImageTrg( ubyte N, GLenum trg, in uivec3 sz, InternalFormat store_format,
                   Format input_format, Type input_type, in void* data=null, uint level=0 )
    in
    {
        assert( N == 1 || N == 2 || N == 3 );
        assertNotCubeMap(trg);
    }
    body
    {
        bind();

        auto nsz = uivec3( redimSize( 3, N, sz.data ) );

        if( N == 1 )
            checkGLCall!glTexImage1D( trg, level, store_format, nsz.x, 0,
                                        input_format, input_type, data );
        else if( N == 2 )
            checkGLCall!glTexImage2D( trg, level, store_format, nsz.x, nsz.y, 0,
                                        input_format, input_type, data );
        else if( N == 3 )
            checkGLCall!glTexImage3D( trg, level, store_format, nsz.x, nsz.y, nsz.z, 0,
                                        input_format, input_type, data );

        logger.Debug( "to [%s], size %s, internal format [%s], format [%s], type [%s], with data [%s]",
                toGLTextureTarget(trg), sz, store_format, input_format, input_type, data?true:false );

        liformat = store_format;
        lformat = input_format;
        ltype = input_type;

        _size = nsz;
    }

    ///
    void setImageTrg( ubyte N, GLenum trg, in Image img, uint level=0 )
    in
    {
        assert( N == 1 || N == 2 || N == 3 );
        assertNotCubeMap(trg);
    }
    body
    {
        Type type = typeFromImageDataType( img.info.type );
        auto fmt = formatFromImageCompCount( img.info.comp );
        auto sz = uivec3( redimSize( 3, N, img.size ) );
        setImageTrg( N, trg, sz, fmt[0], fmt[1], type, img.data.ptr, level );
    }

    ///
    Image getImageTrg( GLenum trg, Type type, uint level=0 )
    {
        bind();

        int w,h,d;

        checkGLCall!glGetTexLevelParameteriv( trg, level, GL_TEXTURE_WIDTH,  &w );
        checkGLCall!glGetTexLevelParameteriv( trg, level, GL_TEXTURE_HEIGHT, &h );
        checkGLCall!glGetTexLevelParameteriv( trg, level, GL_TEXTURE_DEPTH,  &d );

        w = max( 1, w );
        h = max( 1, h );
        d = max( 1, d );

        auto ret = Image( ivec3(w,h,d), imageElemInfo( lformat, type ) );

        checkGLCall!glGetTexImage( trg, level, lformat, type, ret.data.ptr );

        debug logger.trace( "from [%s], size %s, format [%s], type [%s]",
                toGLTextureTarget(trg), [w,h,d], lformat, type );

        return ret;
    }

    ///
    static Type typeFromImageDataType( DataType ctype )
    {
        switch( ctype )
        {
            case DataType.BYTE:     return Type.BYTE;
            case DataType.UBYTE:
            case DataType.RAWBYTE:  return Type.UNSIGNED_BYTE;
            case DataType.SHORT:    return Type.SHORT;
            case DataType.USHORT:   return Type.UNSIGNED_SHORT;
            case DataType.INT:      return Type.INT;
            case DataType.UINT:     return Type.UNSIGNED_INT;
            case DataType.NORM_FIXED: return Type.INT;
            case DataType.UNORM_FIXED: return Type.UNSIGNED_INT;
            case DataType.FLOAT:    return Type.FLOAT;
            default:
                throw new GLTextureException( "uncompatible image component type" );
        }
    }

    ///
    static auto formatFromImageCompCount( size_t channels )
    {
        switch( channels )
        {
            case 1: return tuple( InternalFormat.RED,  Format.RED  );
            case 2: return tuple( InternalFormat.RG,   Format.RG   );
            case 3: return tuple( InternalFormat.RGB,  Format.RGB  );
            case 4: return tuple( InternalFormat.RGBA, Format.RGBA );
            default:
                throw new GLTextureException( "uncompatible image chanels count" );
        }
    }

    ///
    static auto imageElemInfo( Format fmt, Type type )
    {
        auto cnt = formatElemCount(fmt);
        auto ict = imageDataType(type);
        if( ict == DataType.RAWBYTE )
            return ElemInfo( sizeofType( type ) * cnt );
        else
            return ElemInfo( cnt, ict );
    }

    ///
    static size_t formatElemCount( Format fmt )
    {
        final switch(fmt)
        {
            case Format.RED: return 1;
            case Format.RG: return 2;
            case Format.RGB: case Format.BGR: return 3;
            case Format.RGBA: case Format.BGRA: return 4;
            case Format.DEPTH: return 1;
            case Format.DEPTH_STENCIL: return 2;
        }
    }

    ///
    static DataType imageDataType( Type type )
    {
        switch( type )
        {
            case Type.BYTE:           return DataType.BYTE;
            case Type.UNSIGNED_BYTE:  return DataType.UBYTE;
            case Type.SHORT:          return DataType.SHORT;
            case Type.UNSIGNED_SHORT: return DataType.USHORT;
            case Type.INT:            return DataType.INT;
            case Type.UNSIGNED_INT:   return DataType.UINT;
            case Type.FLOAT:          return DataType.FLOAT;
            default:                  return DataType.RAWBYTE;
        }
    }

    ///
    static size_t sizeofType( Type type )
    {
        final switch(type)
        {
        case Type.BYTE:
        case Type.UNSIGNED_BYTE:
        case Type.UNSIGNED_BYTE_3_3_2:
        case Type.UNSIGNED_BYTE_2_3_3_REV:
            return byte.sizeof;

        case Type.SHORT:
        case Type.UNSIGNED_SHORT:
        case Type.UNSIGNED_SHORT_5_6_5:
        case Type.UNSIGNED_SHORT_5_6_5_REV:
        case Type.UNSIGNED_SHORT_4_4_4_4:
        case Type.UNSIGNED_SHORT_4_4_4_4_REV:
        case Type.UNSIGNED_SHORT_5_5_5_1:
        case Type.UNSIGNED_SHORT_1_5_5_5_REV:
            return short.sizeof;

        case Type.INT:
        case Type.UNSIGNED_INT:
        case Type.UNSIGNED_INT_8_8_8_8:
        case Type.UNSIGNED_INT_8_8_8_8_REV:
        case Type.UNSIGNED_INT_10_10_10_2:
        case Type.UNSIGNED_INT_2_10_10_10_REV:
        case Type.UNSIGNED_INT_24_8:
        case Type.UNSIGNED_INT_10F_11F_11F_REV:
        case Type.UNSIGNED_INT_5_9_9_9_REV:
        case Type.FLOAT_32_UNSIGNED_INT_24_8_REV:
            return int.sizeof;

        case Type.HALF_FLOAT: return float.sizeof / 2;
        case Type.FLOAT: return float.sizeof;
        }
    }

    static void assertNotCubeMap( GLenum trg ) pure nothrow
    {
        assert( trg != GL_TEXTURE_CUBE_MAP &&
                trg != GL_TEXTURE_CUBE_MAP_ARRAY,
                "is not cube map assert" );
    }
}

abstract class GLTextureBase(uint N) : GLTexture
    if( N == 1 || N == 2 || N == 3 )
{
public:

    ///
    this( GLenum trg, uint tu ) { super( trg, tu ); }

    @property
    {
        final override const pure nothrow @nogc
        {
            ///
            Dim allocDim()
            {
                     static if( N == 1 ) return Dim.ONE;
                else static if( N == 2 ) return Dim.TWO;
                else static if( N == 3 ) return Dim.THREE;
                else static assert(0,"unsuported texture size");
            }
        }
    }
}

abstract class GLTextureImgBase(uint N) : GLTextureBase!N
{
    ///
    this( GLenum trg, uint tu ) { super( trg, tu ); }

    void size( in uivec3 sz ) @property { setImage( sz, liformat, lformat, ltype, null, 0 ); }

    ///
    void setImage( in uivec3 sz, InternalFormat store_format,
                   Format input_format, Type input_type, in void* data=null, uint level=0 )
    { setImageTrg( N, target, sz, store_format, input_format, input_type, data, level ); }

    ///
    void setImage( in Image img, uint level=0 ) { setImageTrg( N, target, img, level ); }

    ///
    Image getImage( Type type, uint level=0 )
    { return getImageTrg( target, type, level ); }

    ///
    Image getImage( uint level=0 ) { return getImage( ltype, level ); }
}

///
class GLTexture1D : GLTextureImgBase!1
{
    ///
    this( uint tu ) { super( GL_TEXTURE_1D, tu ); }

    final override const pure nothrow @nogc @property
    {
        ///
        bool mipmapable() { return true; }
        ///
        bool isArray() { return false; }
        ///
        Dim imageDim() { return Dim.ONE; }
    }
}

///
class GLTexture1DArray : GLTextureImgBase!2
{
    ///
    this( uint tu ) { super( GL_TEXTURE_1D_ARRAY, tu ); }

    final override const pure nothrow @nogc @property
    {
        ///
        bool mipmapable() { return true; }
        ///
        bool isArray() { return true; }
        ///
        Dim imageDim() { return Dim.ONE; }
    }
}

///
class GLTexture2D : GLTextureImgBase!2
{
    ///
    this( uint tu ) { super( GL_TEXTURE_2D, tu ); }

    final override const pure nothrow @nogc @property
    {
        ///
        bool mipmapable() { return true; }
        ///
        bool isArray() { return false; }
        ///
        Dim imageDim() { return Dim.TWO; }
    }
}

///
class GLTexture2DArray : GLTextureImgBase!3
{
    ///
    this( uint tu ) { super( GL_TEXTURE_2D_ARRAY, tu ); }

    final override const pure nothrow @nogc @property
    {
        ///
        bool mipmapable() { return true; }
        ///
        bool isArray() { return true; }
        ///
        Dim imageDim() { return Dim.TWO; }
    }
}

///
class GLTextureRectangle : GLTextureImgBase!2
{
    ///
    this( uint tu ) { super( GL_TEXTURE_RECTANGLE, tu ); }

    final override const pure nothrow @nogc @property
    {
        ///
        bool mipmapable() { return false; }
        ///
        bool isArray() { return false; }
        ///
        Dim imageDim() { return Dim.TWO; }
    }
}

///
class GLTexture3D : GLTextureImgBase!3
{
    ///
    this( uint tu ) { super( GL_TEXTURE_3D, tu ); }

    final override const pure nothrow @nogc @property
    {
        ///
        bool mipmapable() { return true; }
        ///
        bool isArray() { return false; }
        ///
        Dim imageDim() { return Dim.THREE; }
    }
}

abstract class GLTextureCubeBase(bool array) : GLTextureBase!(2+cast(uint)array)
{
    protected enum CubeDim = 2u + cast(uint)array;

    ///
    this( GLenum trg, uint tu ) { super( trg, tu ); }

    ///
    void setImage( Side side, in uivec2 sz, InternalFormat store_format,
                   Format input_format, Type input_type, in void* data=null, uint level=0 )
    { setImageTrg( CubeDim, side, uivec3( sz, 1 ), store_format, input_format, input_type, data, level ); }

    ///
    void setImage( Side side, in Image img, uint level=0 )
    { setImageTrg( CubeDim, side, img, level ); }

    ///
    void setImages( in Image[6] imgs, uint level=0 )
    {
        setImage( Side.PX, imgs[0], level );
        setImage( Side.NX, imgs[1], level );
        setImage( Side.PY, imgs[2], level );
        setImage( Side.NY, imgs[3], level );
        setImage( Side.PZ, imgs[4], level );
        setImage( Side.NZ, imgs[5], level );
    }

    ///
    void setImages( in Image img, uint width, uivec2[6] pos,
                    ImRepack[6] tr, uint level=0 )
    {
        auto sssz = redimSize( 3, img.size );

        auto getRegion( uivec2 p, uint w )
        {
            static if( CubeDim == 2 ) return Region!(2,uint)( p, uivec2(w) );
            else return Region!(3,uint)( p, sssz[2], uivec2(w), sssz[2] );
        }

        setImage( Side.PX, imGetCopy( img, getRegion( pos[0], width ), tr[0] ), level );
        setImage( Side.NX, imGetCopy( img, getRegion( pos[1], width ), tr[1] ), level );
        setImage( Side.PY, imGetCopy( img, getRegion( pos[2], width ), tr[2] ), level );
        setImage( Side.NY, imGetCopy( img, getRegion( pos[3], width ), tr[3] ), level );
        setImage( Side.PZ, imGetCopy( img, getRegion( pos[4], width ), tr[4] ), level );
        setImage( Side.NZ, imGetCopy( img, getRegion( pos[5], width ), tr[5] ), level );
    }

    ///
    Image getImages( Type type, uint level=0 )
    { return getImageTrg( target, type, level ); }

    ///
    Image getImages( uint level=0 )
    { return getImages( ltype, level ); }
}

///
class GLTextureCubeMap : GLTextureCubeBase!false
{
    ///
    this( uint tu ) { super( GL_TEXTURE_CUBE_MAP, tu ); }

    final override const pure nothrow @nogc @property
    {
        ///
        bool mipmapable() { return true; }
        ///
        bool isArray() { return false; }
        ///
        Dim imageDim() { return Dim.TWO; }
    }
}

///
class GLTextureCubeMapArray : GLTextureCubeBase!true
{
    ///
    this( uint tu ) { super( GL_TEXTURE_CUBE_MAP_ARRAY, tu ); }

    final override const pure nothrow @nogc @property
    {
        ///
        bool mipmapable() { return true; }
        ///
        bool isArray() { return true; }
        ///
        Dim imageDim() { return Dim.TWO; }
    }
}

/////
//abstract class GLMultisampleTexture : GLTexture
//{
//    ///
//    this( GLenum trg, uint tu ) { super( trg, tu ); }
//
//    final override const pure nothrow @nogc @property
//    {
//        ///
//        bool mipmapable() { return false; }
//        ///
//        Dim imageDim() { return Dim.TWO; }
//    }
//}
//
/////
//class GLTexture2DMultisample : GLMultisampleTexture
//{
//    ///
//    this( uint tu ) { super( GL_TEXTURE_2D_MULTISAMPLE, tu ); }
//
//    final override const pure nothrow @nogc @property
//    {
//        ///
//        bool isArray() { return false; }
//        ///
//        Dim allocDim() { return Dim.TWO; }
//    }
//}
//
/////
//class GLTexture2DMultisampleArray : GLMultisampleTexture
//{
//    ///
//    this( uint tu ) { super( GL_TEXTURE_2D_MULTISAMPLE_ARRAY, tu ); }
//
//    final override const pure nothrow @nogc @property
//    {
//        ///
//        bool isArray() { return true; }
//        ///
//        Dim allocDim() { return Dim.THREE; }
//    }
//}
