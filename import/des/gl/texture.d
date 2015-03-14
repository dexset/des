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

    ///
    enum Parameter
    {
        DEPTH_STENCIL_TEXTURE_MODE = GL_DEPTH_STENCIL_TEXTURE_MODE, /// `GL_DEPTH_STENCIL_TEXTURE_MODE`
        BASE_LEVEL                 = GL_TEXTURE_BASE_LEVEL,         /// `GL_TEXTURE_BASE_LEVEL`
        MAX_LEVEL                  = GL_TEXTURE_MAX_LEVEL,          /// `GL_TEXTURE_MAX_LEVEL`
        BORDER_COLOR               = GL_TEXTURE_BORDER_COLOR,       /// `GL_TEXTURE_BORDER_COLOR`
        COMPARE_FUNC               = GL_TEXTURE_COMPARE_FUNC,       /// `GL_TEXTURE_COMPARE_FUNC`
        COMPARE_MODE               = GL_TEXTURE_COMPARE_MODE,       /// `GL_TEXTURE_COMPARE_MODE`
        LOD_BIAS                   = GL_TEXTURE_LOD_BIAS,           /// `GL_TEXTURE_LOD_BIAS`
        MIN_LOD                    = GL_TEXTURE_MIN_LOD,            /// `GL_TEXTURE_MIN_LOD`
        MAX_LOD                    = GL_TEXTURE_MAX_LOD,            /// `GL_TEXTURE_MAX_LOD`
        SWIZZLE_R                  = GL_TEXTURE_SWIZZLE_R,          /// `GL_TEXTURE_SWIZZLE_R`
        SWIZZLE_G                  = GL_TEXTURE_SWIZZLE_G,          /// `GL_TEXTURE_SWIZZLE_G`
        SWIZZLE_B                  = GL_TEXTURE_SWIZZLE_B,          /// `GL_TEXTURE_SWIZZLE_B`
        SWIZZLE_A                  = GL_TEXTURE_SWIZZLE_A,          /// `GL_TEXTURE_SWIZZLE_A`
        SWIZZLE_RGBA               = GL_TEXTURE_SWIZZLE_RGBA,       /// `GL_TEXTURE_SWIZZLE_RGBA`
        WRAP_S                     = GL_TEXTURE_WRAP_S,             /// `GL_TEXTURE_WRAP_S`
        WRAP_T                     = GL_TEXTURE_WRAP_T,             /// `GL_TEXTURE_WRAP_T`
        WRAP_R                     = GL_TEXTURE_WRAP_R              /// `GL_TEXTURE_WRAP_R`
    }

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

        abstract bool mipmapable();
        abstract bool isArray();
        abstract Dim imageDim();
        abstract Dim allocDim();
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
        setParam( Parameter.WRAP_S, wrap );
        logger.Debug( "to [%s]", wrap );
    }

    ///
    void setWrapT( Wrap wrap )
    {
        setParam( Parameter.WRAP_T, wrap );
        logger.Debug( "to [%s]", wrap );
    }

    ///
    void setWrapR( Wrap wrap )
    {
        setParam( Parameter.WRAP_R, wrap );
        logger.Debug( "to [%s]", wrap );
    }

    ///
    void setMinLOD( float v )
    {
        setParam( Parameter.MIN_LOD, v );
        logger.Debug( "to [%f]", v );
    }

    ///
    void setMaxLOD( float v )
    {
        setParam( Parameter.MAX_LOD, v );
        logger.Debug( "to [%f]", v );
    }

    ///
    void setLODBais( float v )
    {
        setParam( Parameter.LOD_BIAS, v );
        logger.Debug( "to [%f]", v );
    }

    ///
    void setBaseLevel( int v )
    {
        setParam( Parameter.BASE_LEVEL, v );
        logger.Debug( "to [%d]", v );
    }

    ///
    void setMaxLevel( int v )
    {
        setParam( Parameter.MAX_LEVEL, v );
        logger.Debug( "to [%d]", v );
    }

    ///
    void setBorderColor( vec4 clr )
    {
        setParam( Parameter.BORDER_COLOR, clr.data );
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
        setParam( Parameter.COMPARE_FUNC, cf );
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
        setParam( Parameter.COMPARE_MODE, cm );
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
        setParam( Parameter.SWIZZLE_R, s );
        logger.Debug( "to [%s]", s );
    }

    ///
    void setSwizzleG( Swizzle s )
    {
        setParam( Parameter.SWIZZLE_G, s );
        logger.Debug( "to [%s]", s );
    }

    ///
    void setSwizzleB( Swizzle s )
    {
        setParam( Parameter.SWIZZLE_B, s );
        logger.Debug( "to [%s]", s );
    }

    ///
    void setSwizzleA( Swizzle s )
    {
        setParam( Parameter.SWIZZLE_A, s );
        logger.Debug( "to [%s]", s );
    }

    ///
    void setSwizzleRGBA( Swizzle[4] s )
    {
        setParam( Parameter.SWIZZLE_RGBA, to!(int[])(s) );
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
        setParam( Parameter.DEPTH_STENCIL_TEXTURE_MODE, dstm );
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

    protected static
    {
        ///
        size_t formatElemCount( Format fmt )
        {
            final switch(fmt)
            {
                case Format.RED: return 1;
                case Format.RG:  return 2;

                case Format.RGB:
                case Format.BGR:
                    return 3;

                case Format.RGBA:
                case Format.BGRA:
                    return 4;

                case Format.DEPTH:
                    return 1;

                case Format.DEPTH_STENCIL:
                    return 2;
            }
        }

        ///
        size_t sizeofType( Type type )
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

        ///
        auto imageElemInfo( Format fmt, Type type )
        {
            auto cnt = formatElemCount(fmt);
            auto ict = imageDataType(type);
            if( ict == DataType.RAWBYTE )
                return ElemInfo( sizeofType(type) * cnt );
            else
                return ElemInfo( ict, cnt );
        }

        ///
        DataType imageDataType( Type type )
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
        Type typeFromImageDataType( DataType ctype )
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
        auto formatFromImageChanelsCount( size_t channels )
        {
            switch( channels )
            {
                case 1: return tuple(InternalFormat.RED,  Format.RED  );
                case 2: return tuple(InternalFormat.RG,   Format.RG   );
                case 3: return tuple(InternalFormat.RGB,  Format.RGB  );
                case 4: return tuple(InternalFormat.RGBA, Format.RGBA );
                default:
                    throw new GLTextureException( "uncompatible image chanels count" );
            }
        }
    }
}

abstract class GLTextureBase(uint N) : GLTexture
    if( N == 1 || N == 2 || N == 3 )
{
    ///
    static if( N==1 ) alias texsize_t = uint;
    else alias texsize_t = Vector!(N,uint);

protected:
    ///
    texsize_t _size;

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

        ///
        texsize_t size() const pure nothrow { return _size; }

        //void size( in texsize_t sz ) { setImage( sz, target, liformat, lformat, ltype, null, 0 ); }
    }

protected:

    ///
    void setImageTrg( GLenum trg, in texsize_t sz, InternalFormat store_format,
                   Format input_format, Type input_type, in void* data=null, uint level=0 )
    in{ assertNotCubeMap(trg); } body
    {
        _size = sz;

        liformat = store_format;
        lformat = input_format;
        ltype = input_type;

        bind();

        mixin( format( q{
            checkGLCall!glTexImage%1$dD( trg, level, store_format, %2$s, 0,
                                        input_format, input_type, data );
            }, N, accessComponents!N("sz") ) );

        logger.Debug( "to [%s], size %s, internal format [%s], format [%s], type [%s], with data [%s]",
                toGLTextureTarget(trg), sz, store_format, input_format, input_type, data?true:false );
    }

    ///
    void setImageTrg( GLenum trg, in Image!N img, uint level=0 )
    in{ assertNotCubeMap(trg); } body
    {
        Type type = typeFromImageDataType( img.info.comp );
        auto fmt = formatFromImageChanelsCount( img.info.channels );
        texsize_t sz;
        static if( N == 1 ) sz = cast(uint)( img.size[0] );
        else sz = texsize_t( img.size );
        setImageTrg( trg, sz, fmt[0], fmt[1], type, img.data.ptr, level );
    }

    ///
    void getImageTrg( GLenum trg, ref Image!N img, Type type, uint level=0 )
    in{ assertNotCubeMap(trg); } body
    {
        bind();
        int[3] sz;

        checkGLCall!glGetTexLevelParameteriv( trg, level, GL_TEXTURE_WIDTH,  sz.ptr+0 );
        checkGLCall!glGetTexLevelParameteriv( trg, level, GL_TEXTURE_HEIGHT, sz.ptr+1 );
        checkGLCall!glGetTexLevelParameteriv( trg, level, GL_TEXTURE_DEPTH,  sz.ptr+2 );

        enforce( sz[0] > 0 );
        static if( N > 1 ) enforce( sz[1] > 0 );
        static if( N > 2 ) enforce( sz[2] > 0 );

        auto elemSize = formatElemCount(lformat) * sizeofType(type);

        int cnt = sz[0];
        static if( N > 1 ) cnt *= sz[1];
        static if( N > 2 ) cnt *= sz[2];

        auto dsize = cnt * elemSize;

        if( img.size != CrdVector!N(sz[0..N]) || img.info.bpe != elemSize )
        {
            img.size = CrdVector!N(sz[0..N]);
            img.info = imageElemInfo( lformat, type );
        }

        checkGLCall!glGetTexImage( trg, level, lformat, type, img.data.ptr );

        debug logger.trace( "from [%s], size %s, format [%s], type [%s]",
                toGLTextureTarget(trg), sz.dup, lformat, type );
    }

private:

    static void assertNotCubeMap( GLenum trg ) pure nothrow
    {
        assert( trg != GL_TEXTURE_CUBE_MAP &&
                trg != GL_TEXTURE_CUBE_MAP_ARRAY,
                "is not cube map assert" );
    }

    static string accessComponents(size_t N)( string name ) pure
    {
        static if( N == 1 ) return name;
        else
        {
            string[] ret;
            foreach( i; 0 .. N ) ret ~= format( "%s[%d]", name, i );
            return ret.join(",");
        }
    }
}

abstract class GLTextureImgBase(uint N) : GLTextureBase!N
{
    ///
    this( GLenum trg, uint tu ) { super( trg, tu ); }

    void size( in texsize_t sz ) @property { setImage( sz, liformat, lformat, ltype, null, 0 ); }

    ///
    void setImage( in texsize_t sz, InternalFormat store_format,
                   Format input_format, Type input_type, in void* data=null, uint level=0 )
    { setImageTrg( target, sz, store_format, input_format, input_type, data, level ); }

    ///
    void setImage( in Image!N img, uint level=0 ) { setImageTrg( target, img, level ); }

    ///
    void getImage( ref Image!N img, Type type, uint level=0 )
    { getImageTrg( target, img, type, level ); }

    ///
    void getImage( ref Image!N img, uint level=0 )
    { getImageTrg( target, img, ltype, level ); }
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
    void setImage( Side side, in texsize_t sz, InternalFormat store_format,
                   Format input_format, Type input_type, in void* data=null, uint level=0 )
    { setImageTrg( side, sz, store_format, input_format, input_type, data, level ); }

    ///
    void setImage( Side side, in Image!CubeDim img, uint level=0 )
    { setImageTrg( side, img, level ); }

    ///
    void setImages( in Image!CubeDim[6] imgs, uint level=0 )
    {
        setImage( Side.PX, imgs[0], level );
        setImage( Side.NX, imgs[1], level );
        setImage( Side.PY, imgs[2], level );
        setImage( Side.NY, imgs[3], level );
        setImage( Side.PZ, imgs[4], level );
        setImage( Side.NZ, imgs[5], level );
    }

    ///
    void setImages( in Image!CubeDim img, uint width, uivec2[6] pos,
                    ImRepack[6] tr, uint level=0 )
    {
        auto getRegion( uivec2 p, uint w )
        {
            static if( CubeDim == 2 ) return Region!(2,uint)( p, uivec2(w) );
            else return Region!(3,uint)( p, img.size.z, uivec2(w), img.size.z );
        }

        static if( CubeDim == 2 )
        {
        setImage( Side.PX, imCopy( img, getRegion( pos[0], width ), tr[0] ), level );
        setImage( Side.NX, imCopy( img, getRegion( pos[1], width ), tr[1] ), level );
        setImage( Side.PY, imCopy( img, getRegion( pos[2], width ), tr[2] ), level );
        setImage( Side.NY, imCopy( img, getRegion( pos[3], width ), tr[3] ), level );
        setImage( Side.PZ, imCopy( img, getRegion( pos[4], width ), tr[4] ), level );
        setImage( Side.NZ, imCopy( img, getRegion( pos[5], width ), tr[5] ), level );
        } else assert(0);
    }

    ///
    void getImage( Side side, ref Image!CubeDim img, Type type, uint level=0 )
    { getImageTrg( side, img, type, level ); }

    ///
    void getImage( Side side, ref Image!CubeDim img, uint level=0 )
    { getImageTrg( side, img, ltype, level ); }
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

///
abstract class GLMultisampleTexture : GLTexture
{
    ///
    this( GLenum trg, uint tu ) { super( trg, tu ); }

    final override const pure nothrow @nogc @property
    {
        ///
        bool mipmapable() { return false; }
        ///
        Dim imageDim() { return Dim.TWO; }
    }
}

///
class GLTexture2DMultisample : GLMultisampleTexture
{
    ///
    this( uint tu ) { super( GL_TEXTURE_2D_MULTISAMPLE, tu ); }

    final override const pure nothrow @nogc @property
    {
        ///
        bool isArray() { return false; }
        ///
        Dim allocDim() { return Dim.TWO; }
    }
}

///
class GLTexture2DMultisampleArray : GLMultisampleTexture
{
    ///
    this( uint tu ) { super( GL_TEXTURE_2D_MULTISAMPLE_ARRAY, tu ); }

    final override const pure nothrow @nogc @property
    {
        ///
        bool isArray() { return true; }
        ///
        Dim allocDim() { return Dim.THREE; }
    }
}
