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
        logger.Debug( "with target [%s] texture unit [%d]", target, tu );
    }

    enum Dim { ONE, TWO, THREE }

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

abstract class GLTexture1DBase : GLTexture
{
protected:
    uint _size;

public:

    this( GLenum trg, uint tu ) { super( trg, tu ); }

    @property
    {
        final override const pure nothrow @nogc
        {
            ///
            Dim allocDim() { return Dim.ONE; }
        }

        uint size() const pure nothrow { return _size; }

        void size( uint sz ) { setImage( sz, liformat, lformat, ltype, null, 0 ); }
    }

    void setImage( uint sz, InternalFormat store_format, Format input_format,
                   Type input_type, in void* data=null, uint level=0 )
    {
        _size = sz;

        liformat = store_format;
        lformat = input_format;
        ltype = input_type;

        bind();
        checkGLCall!glTexImage1D( target, level, store_format, sz, 0,
                                  input_format, input_type, data );

        logger.Debug( "size %s, internal format [%s], format [%s], type [%s], with data [%s]",
                sz, store_format, input_format, input_type, data?true:false );
    }

    void setImage( in Image!1 img, uint level=0 )
    {
        Type type = typeFromImageDataType( img.info.comp );
        auto fmt = formatFromImageChanelsCount( img.info.channels );
        setImage( cast(uint)(img.size[0]), fmt[0], fmt[1], type, img.data.ptr, level );
    }

    void getImage( ref Image!1 img, uint level=0 ) { getImage( img, ltype, level ); }

    void getImage( ref Image!1 img, Type type, uint level=0 )
    {
        bind();
        int w;
        checkGLCall!glGetTexLevelParameteriv( target, level, GL_TEXTURE_WIDTH, &(w));

        auto elemSize = formatElemCount(lformat) * sizeofType(type);

        auto dsize = w * elemSize;

        if( img.size != CrdVector!1(w) || img.info.bpe != elemSize )
        {
            img.size = CrdVector!1(w);
            img.info = imageElemInfo( lformat, type );
        }

        glGetTexImage( target, level, lformat, type, img.data.ptr );

        unbind();

        debug logger.trace( "size [%d], format [%s], type [%s]", w, lformat, type );
    }
}

abstract class GLTexture2DBase : GLTexture
{
protected:

    uivec2 _size;

public:

    this( GLenum trg, uint tu ) { super( trg, tu ); }

    @property
    {
        final override const pure nothrow @nogc
        {
            ///
            Dim allocDim() { return Dim.TWO; }
        }

        uivec2 size() const pure nothrow { return _size; }

        void size( uivec2 sz ) { setImage( sz, liformat, lformat, ltype, null, 0 ); }
    }

    void setImage( uivec2 sz, InternalFormat store_format, Format input_format,
                   Type input_type, in void* data=null, uint level=0 )
    {
        _size = sz;

        liformat = store_format;
        lformat = input_format;
        ltype = input_type;

        bind();
        checkGLCall!glTexImage2D( target, level, store_format, sz.x, sz.y, 0,
                                  input_format, input_type, data );

        logger.Debug( "size %s, internal format [%s], format [%s], type [%s], with data [%s]",
                sz.data.dup, store_format, input_format, input_type, data?true:false );
    }

    void setImage( in Image!2 img, uint level=0 )
    {
        Type type = typeFromImageDataType( img.info.comp );
        auto fmt = formatFromImageChanelsCount( img.info.channels );
        setImage( uivec2( img.size ), fmt[0], fmt[1], type, img.data.ptr, level );
    }

    void getImage( ref Image!2 img, uint level=0 ) { getImage( img, ltype, level ); }

    void getImage( ref Image!2 img, Type type, uint level=0 )
    {
        bind();
        int w,h;
        checkGLCall!glGetTexLevelParameteriv( target, level, GL_TEXTURE_WIDTH, &(w));
        checkGLCall!glGetTexLevelParameteriv( target, level, GL_TEXTURE_HEIGHT, &(h));

        auto elemSize = formatElemCount(lformat) * sizeofType(type);

        auto dsize = w * h * elemSize;

        if( img.size != uivec2(w,h) || img.info.bpe != elemSize )
        {
            img.size = uivec2(w,h);
            img.info = imageElemInfo( lformat, type );
        }

        glGetTexImage( target, level, lformat, type, img.data.ptr );

        unbind();

        debug logger.trace( "size [%d,%d], format [%s], type [%s]", w,h, lformat, type );
    }
}

abstract class GLTexture3DBase : GLTexture
{
protected:

    uivec3 _size;

public:

    this( GLenum trg, uint tu ) { super( trg, tu ); }

    @property
    {
        final override const pure nothrow @nogc
        {
            ///
            Dim allocDim() { return Dim.THREE; }
        }

        uivec3 size() const pure nothrow { return _size; }

        void size( uivec3 sz ) { setImage( sz, liformat, lformat, ltype, null, 0 ); }
    }

    void setImage( uivec3 sz, InternalFormat store_format, Format input_format,
                   Type input_type, in void* data=null, uint level=0 )
    {
        _size = sz;

        liformat = store_format;
        lformat = input_format;
        ltype = input_type;

        bind();
        checkGLCall!glTexImage3D( target, level, store_format, sz.x, sz.y, sz.z, 0,
                                  input_format, input_type, data );

        logger.Debug( "size %s, internal format [%s], format [%s], type [%s], with data [%s]",
                sz, store_format, input_format, input_type, data?true:false );
    }

    void setImage( in Image!3 img, uint level=0 )
    {
        Type type = typeFromImageDataType( img.info.comp );
        auto fmt = formatFromImageChanelsCount( img.info.channels );
        setImage( uivec3( img.size ), fmt[0], fmt[1], type, img.data.ptr, level );
    }

    void getImage( ref Image!3 img, uint level=0 ) { getImage( img, ltype, level ); }

    void getImage( ref Image!3 img, Type type, uint level=0 )
    {
        bind();
        int w,h,d;
        if( target == GL_TEXTURE_CUBE_MAP )
        {
            checkGLCall!glGetTexLevelParameteriv( GL_TEXTURE_CUBE_MAP_POSITIVE_X, level, GL_TEXTURE_WIDTH, &(w));
            d = h = w;
        }
        else
        {
            checkGLCall!glGetTexLevelParameteriv( target, level, GL_TEXTURE_WIDTH, &(w));
            checkGLCall!glGetTexLevelParameteriv( target, level, GL_TEXTURE_HEIGHT, &(h));
            checkGLCall!glGetTexLevelParameteriv( target, level, GL_TEXTURE_DEPTH, &(d));
        }

        auto elemSize = formatElemCount(lformat) * sizeofType(type);

        auto dsize = w * h * d * elemSize;

        if( img.size != uivec3(w,h,d) || img.info.bpe != elemSize )
        {
            img.size = uivec3(w,h,d);
            img.info = imageElemInfo( lformat, type );
        }

        glGetTexImage( target, level, lformat, type, img.data.ptr );

        unbind();

        debug logger.trace( "size [%d,%d,%d], format [%s], type [%s]",
                            w,h,d, lformat, type );
    }
}

///
class GLTexture1D : GLTexture1DBase
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
class GLTexture1DArray : GLTexture2DBase
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
class GLTexture2D : GLTexture2DBase
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
class GLTexture2DArray : GLTexture3DBase
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
class GLTextureRectangle : GLTexture2DBase
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
class GLTexture3D : GLTexture3DBase
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

///
class GLTextureCubeMap : GLTexture2DBase
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
class GLTextureCubeMapArray : GLTexture3DBase
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
