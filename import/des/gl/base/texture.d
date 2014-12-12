/+
The MIT License (MIT)

    Copyright (c) <2013> <Oleg Butko (deviator), Anton Akzhigitov (Akzwar)>

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
+/

module des.gl.base.texture;

import std.string;

public import derelict.opengl3.gl3;

import des.util.logsys;

import des.gl.base.type;
import des.gl.util.ext;

import des.math.linear.vector;
import des.il;

import std.algorithm;
import des.util.algo;

class GLTextureException : DesGLException 
{ 
    @safe pure nothrow this( string msg, string file=__FILE__, size_t line=__LINE__ )
    { super( msg, file, line ); } 
}

class GLTexture : ExternalMemoryManager
{
    mixin DirectEMM;
    mixin ClassLogger;
private:
    uint _id;

protected:
    texsize_t img_size;

    void selfDestroy()
    {
        unbind();
        checkGLCall!glDeleteTextures( 1, &_id );
    }

    Target _target;

    nothrow @property GLenum gltype() const { return cast(GLenum)_target; }

    InternalFormat liformat;
    Format lformat;
    Type ltype;

public:

    alias Vector!(3,size_t,"w h d") texsize_t; 
    @property Target target() const { return _target; }

    enum Target
    {
        T1D                   = GL_TEXTURE_1D,
        T2D                   = GL_TEXTURE_2D,
        T3D                   = GL_TEXTURE_3D,
        T1D_ARRAY             = GL_TEXTURE_1D_ARRAY,
        T2D_ARRAY             = GL_TEXTURE_2D_ARRAY,
        RECTANGLE             = GL_TEXTURE_RECTANGLE,
        CUBE_MAP              = GL_TEXTURE_CUBE_MAP,
        CUBE_MAP_ARRAY        = GL_TEXTURE_CUBE_MAP_ARRAY,

        BUFFER                = GL_TEXTURE_BUFFER,
        T2D_MULTISAMPLE       = GL_TEXTURE_2D_MULTISAMPLE,
        T2D_MULTISAMPLE_ARRAY = GL_TEXTURE_2D_MULTISAMPLE_ARRAY,

        CUBE_MAP_POSITIVE_X = GL_TEXTURE_CUBE_MAP_POSITIVE_X,
        CUBE_MAP_NEGATIVE_X = GL_TEXTURE_CUBE_MAP_NEGATIVE_X,
        CUBE_MAP_POSITIVE_Y = GL_TEXTURE_CUBE_MAP_POSITIVE_Y,
        CUBE_MAP_NEGATIVE_Y = GL_TEXTURE_CUBE_MAP_NEGATIVE_Y,
        CUBE_MAP_POSITIVE_Z = GL_TEXTURE_CUBE_MAP_POSITIVE_Z,
        CUBE_MAP_NEGATIVE_Z = GL_TEXTURE_CUBE_MAP_NEGATIVE_Z
    }

    enum Parameter
    {
        DEPTH_STENCIL_TEXTURE_MODE = GL_DEPTH_STENCIL_TEXTURE_MODE,
        BASE_LEVEL = GL_TEXTURE_BASE_LEVEL,
        BORDER_COLOR = GL_TEXTURE_BORDER_COLOR,
        COMPARE_FUNC = GL_TEXTURE_COMPARE_FUNC,
        COMPARE_MODE = GL_TEXTURE_COMPARE_MODE,
        LOD_BIAS = GL_TEXTURE_LOD_BIAS,
        MIN_FILTER = GL_TEXTURE_MIN_FILTER,
        MAG_FILTER = GL_TEXTURE_MAG_FILTER,
        MIN_LOD = GL_TEXTURE_MIN_LOD,
        MAX_LOD = GL_TEXTURE_MAX_LOD,
        MAX_LEVEL = GL_TEXTURE_MAX_LEVEL,
        SWIZZLE_R = GL_TEXTURE_SWIZZLE_R,
        SWIZZLE_G = GL_TEXTURE_SWIZZLE_G,
        SWIZZLE_B = GL_TEXTURE_SWIZZLE_B,
        SWIZZLE_A = GL_TEXTURE_SWIZZLE_A,
        SWIZZLE_RGBA = GL_TEXTURE_SWIZZLE_RGBA,
        WRAP_S = GL_TEXTURE_WRAP_S,
        WRAP_T = GL_TEXTURE_WRAP_T,
        WRAP_R = GL_TEXTURE_WRAP_R
    }

    enum DepthStencilTextureMode
    {
        DEPTH   = GL_DEPTH_COMPONENT,
        STENCIL = GL_STENCIL_COMPONENTS
    }

    enum CompareFunc
    {
        LEQUAL   = GL_LEQUAL,
        GEQUAL   = GL_GEQUAL,
        LESS     = GL_LESS,
        GREATER  = GL_GREATER,
        EQUAL    = GL_EQUAL,
        NOTEQUAL = GL_NOTEQUAL,
        ALWAYS   = GL_ALWAYS,
        NEVER    = GL_NEVER
    }

    enum CompareMode
    {
        REF_TO_TEXTURE = GL_COMPARE_REF_TO_TEXTURE,
        NONE = GL_NONE
    }

    enum Filter
    {
        NEAREST                = GL_NEAREST,
        LINEAR                 = GL_LINEAR,
        NEAREST_MIPMAP_NEAREST = GL_NEAREST_MIPMAP_NEAREST,
        LINEAR_MIPMAP_NEAREST  = GL_LINEAR_MIPMAP_NEAREST,
        NEAREST_MIPMAP_LINEAR  = GL_NEAREST_MIPMAP_LINEAR,
        LINEAR_MIPMAP_LINEAR   = GL_LINEAR_MIPMAP_LINEAR
    }

    enum Swizzle
    {
        RED   = GL_RED,
        GREEN = GL_GREEN,
        BLUE  = GL_BLUE,
        ALPHA = GL_ALPHA,
        ZERO  = GL_ZERO
    }

    enum Wrap
    {
        CLAMP_TO_EDGE = GL_CLAMP_TO_EDGE,
        CLAMP_TO_BORDER = GL_CLAMP_TO_BORDER,
        MIRRORED_REPEAT = GL_MIRRORED_REPEAT,
        REPEAT = GL_REPEAT
    }

    enum InternalFormat
    {
        COMPRESSED_RED        = GL_COMPRESSED_RED,
        COMPRESSED_RG         = GL_COMPRESSED_RG,
        COMPRESSED_RGB        = GL_COMPRESSED_RGB,
        COMPRESSED_RGBA       = GL_COMPRESSED_RGBA,
        COMPRESSED_SRGB       = GL_COMPRESSED_SRGB,
        COMPRESSED_SRGB_ALPHA = GL_COMPRESSED_SRGB_ALPHA,
        DEPTH_COMPONENT       = GL_DEPTH_COMPONENT,
        DEPTH_COMPONENT16     = GL_DEPTH_COMPONENT16,
        DEPTH_COMPONENT24     = GL_DEPTH_COMPONENT24,
        DEPTH_COMPONENT32     = GL_DEPTH_COMPONENT32,
        DEPTH_COMPONENT32F    = GL_DEPTH_COMPONENT32F,
        R3_G3_B2              = GL_R3_G3_B2,
        RED                   = GL_RED,
        RG                    = GL_RG,
        RGB                   = GL_RGB,
        RGB4                  = GL_RGB4,
        RGB5                  = GL_RGB5,
        RGB8                  = GL_RGB8,
        RGB10                 = GL_RGB10,
        RGB12                 = GL_RGB12,
        RGB16                 = GL_RGB16,
        RGBA                  = GL_RGBA,
        RGBA2                 = GL_RGBA2,
        RGBA4                 = GL_RGBA4,
        RGB5_A1               = GL_RGB5_A1,
        RGBA8                 = GL_RGBA8,
        RGB10_A2              = GL_RGB10_A2,
        RGBA12                = GL_RGBA12,
        RGBA16                = GL_RGBA16,
        SRGB                  = GL_SRGB,
        SRGB8                 = GL_SRGB8,
        SRGB_ALPHA            = GL_SRGB_ALPHA,
        SRGB8_ALPHA8          = GL_SRGB8_ALPHA8
    }

    enum Format
    {
        RED  = GL_RED,
        RG   = GL_RG,
        RGB  = GL_RGB,
        RGBA = GL_RGBA,

        BGR  = GL_BGR,
        BGRA = GL_BGRA,

        DEPTH = GL_DEPTH_COMPONENT,
        DEPTH_STENCIL = GL_DEPTH_STENCIL
    }

    enum Type
    {
        UNSIGNED_BYTE  = GL_UNSIGNED_BYTE,
        BYTE           = GL_BYTE,
        UNSIGNED_SHORT = GL_UNSIGNED_SHORT,
        SHORT          = GL_SHORT,
        UNSIGNED_INT   = GL_UNSIGNED_INT,
        INT            = GL_INT,
        HALF_FLOAT     = GL_HALF_FLOAT,
        FLOAT          = GL_FLOAT,

        UNSIGNED_BYTE_3_3_2             = GL_UNSIGNED_BYTE_3_3_2,
        UNSIGNED_BYTE_2_3_3_REV         = GL_UNSIGNED_BYTE_2_3_3_REV,
        UNSIGNED_SHORT_5_6_5            = GL_UNSIGNED_SHORT_5_6_5,
        UNSIGNED_SHORT_5_6_5_REV        = GL_UNSIGNED_SHORT_5_6_5_REV,
        UNSIGNED_SHORT_4_4_4_4          = GL_UNSIGNED_SHORT_4_4_4_4,
        UNSIGNED_SHORT_4_4_4_4_REV      = GL_UNSIGNED_SHORT_4_4_4_4_REV,
        UNSIGNED_SHORT_5_5_5_1          = GL_UNSIGNED_SHORT_5_5_5_1,
        UNSIGNED_SHORT_1_5_5_5_REV      = GL_UNSIGNED_SHORT_1_5_5_5_REV,
        UNSIGNED_INT_8_8_8_8            = GL_UNSIGNED_INT_8_8_8_8,
        UNSIGNED_INT_8_8_8_8_REV        = GL_UNSIGNED_INT_8_8_8_8_REV,
        UNSIGNED_INT_10_10_10_2         = GL_UNSIGNED_INT_10_10_10_2,
        UNSIGNED_INT_2_10_10_10_REV     = GL_UNSIGNED_INT_2_10_10_10_REV,
        UNSIGNED_INT_24_8               = GL_UNSIGNED_INT_24_8,
        UNSIGNED_INT_10F_11F_11F_REV    = GL_UNSIGNED_INT_10F_11F_11F_REV,
        UNSIGNED_INT_5_9_9_9_REV        = GL_UNSIGNED_INT_5_9_9_9_REV,
        FLOAT_32_UNSIGNED_INT_24_8_REV  = GL_FLOAT_32_UNSIGNED_INT_24_8_REV
    }

    this( Target tg )
    in { assert( isBase(tg) ); } body
    {
        checkGLCall!glGenTextures( 1, &_id );
        logger = new InstanceLogger( this, format( "%d", _id ) );
        _target = tg;
        logger.Debug( "with target [%s]", _target );
    }

    final pure const @property uint id() { return _id; }

    void genMipmap()
    in { assert( isMipmapable(_target) ); } body
    {
        bind();
        checkGLCall!glGenerateMipmap(gltype);
        logger.Debug( "with target [%s]", _target );
    }

    void setParameter(T)( Parameter pname, T[] val... )
        if( is(T==int) || is(T==float) || isParameterEnum!T )
    in
    {
        assert( val.length > 0 );
        assert( isParametric(_target) );
        static if( !is(T==float) )
            assert( checkPosibleIntParamValues( pname, amap!(a=>cast(int)(a))(val) ) );
        else
            assert( checkPosibleFloatParamValues( pname, val ) );
    }
    body
    {
        bind();
        enum ts = is(T==float) ? "f" : "i";
        enum cs = is(T==float) ? "float" : "int";
        if( val.length == 1 )
            mixin( format("glTexParameter%s( gltype, cast(GLenum)pname, cast(%s)val[0] );", ts, cs) );
        else 
            mixin( format("glTexParameter%sv( gltype, cast(GLenum)pname, cast(%s*)val.ptr );", ts, cs) ); 

        debug checkGL;
        logger.Debug( "[%s]: %s", pname, val );
    }

    final nothrow
    {
        void bind( ubyte n=0 )
        {
            ntCheckGLCall!glActiveTexture( GL_TEXTURE0 + n );
            ntCheckGLCall!glBindTexture( gltype, _id );
            debug logger.trace( "pass" );
        }

        void unbind()
        {
            ntCheckGLCall!glBindTexture( gltype, 0 );
            debug logger.trace( "pass" );
        }
        texsize_t size() const { return img_size; }
    }

    void resize(T)( in T sz )
        if( isCompatibleVector!(1,size_t,T) || isCompatibleVector!(2,size_t,T) || isCompatibleVector!(3,size_t,T) )
    { image( sz, liformat, lformat, ltype ); }

    void image(T)( in T sz, InternalFormat internal_format, 
            Format data_format, Type data_type, in void* data=null )
        if( isCompatibleVector!(1,size_t,T) || isCompatibleVector!(2,size_t,T) || isCompatibleVector!(3,size_t,T) )
    {
        enum N = sz.length;
        img_size = texsize_t( sz, [1,1][0 .. 3-N] );

        liformat = internal_format;
        lformat = data_format;
        ltype = data_type;

        bind();
        mixin( format(`
        glTexImage%1dD( gltype, 0, cast(int)internal_format, %s, 0,
                        cast(GLenum)data_format, cast(GLenum)data_type, data );
        `, N, accessVecFields!(sz) ) );

        debug checkGL;
        debug logger.trace( "[%d]: size %s, internal format [%s], format [%s], type [%s], with data [%s]",
                _id, sz.data.dup, internal_format, data_format, data_type, data?true:false );
    }
    final void getImage( ref Image!2 img )
    in { assert( _target == Target.T2D ); } body
    { getImage( img, ltype ); }

    final void getImage( ref Image!2 img, Type type )
    in { assert( _target == Target.T2D ); } body
    {
        enum uint level = 0;

        bind();
        debug checkGL;
        int w, h;
        glGetTexLevelParameteriv( GL_TEXTURE_2D, level, GL_TEXTURE_WIDTH, &(w));
        debug checkGL;
        glGetTexLevelParameteriv( GL_TEXTURE_2D, level, GL_TEXTURE_HEIGHT, &(h));
        debug checkGL;

        auto elemSize = formatElemCount(lformat) * sizeofType(type);

        auto dsize = w * h * elemSize;

        if( img.size != img.imsize_t(w,h) || img.type.bpp != elemSize )
        {
            img.size = ivec2( w, h );
            img.type = imagePixelType( lformat, type );
        }

        glGetTexImage( GL_TEXTURE_2D, level, cast(GLenum)lformat, cast(GLenum)type, img.data.ptr );
        debug checkGL;
        unbind();
        debug checkGL;
        debug logger.trace( "[%d] size [%d,%d], format [%s], type [%s]", _id, w,h, lformat, type );
    }

    final void image(size_t N)( in Image!N img ) if( N >= 1 && N <= 3 )
    in
    {
        switch( N )
        {
            case 1: assert( target == Target.T1D ); break;
            case 2: assert( target == Target.T2D ); break;
            case 3: assert( target == Target.T3D ); break;
            default: assert(0);
        }
    }
    body
    {
        Type type = typeFromImageComponentType( img.type.comp );
        auto fmt = formatFromImageChanelsCount( img.type.channels );
        image( img.size, fmt[0], fmt[1], type, img.data.ptr );
    }

    protected static
    {
        bool isBase( Target trg )
        {
            switch(trg)
            {
            case Target.T1D:
            case Target.T2D:
            case Target.T3D:
            case Target.T1D_ARRAY:
            case Target.T2D_ARRAY:
            case Target.RECTANGLE:
            case Target.CUBE_MAP:
            case Target.CUBE_MAP_ARRAY: return true;
            default: return false;
            }
        }

        bool isParametric( Target trg )
        {
            switch(trg)
            {
            case Target.T1D:
            case Target.T2D:
            case Target.T3D:
            case Target.T1D_ARRAY:
            case Target.T2D_ARRAY:
            case Target.RECTANGLE:
            case Target.CUBE_MAP: return true;
            default: return false;
            }
        }

        bool isMipmapable( Target trg )
        {
            switch(trg)
            {
            case Target.T1D:
            case Target.T2D:
            case Target.T3D:
            case Target.T1D_ARRAY:
            case Target.T2D_ARRAY:
            case Target.CUBE_MAP: return true;
            default: return false;
            }
        }

        bool checkPosibleIntParamValues( Parameter pname, int[] valbuf... )
        {
            if( valbuf.length == 0 ) return false;

            size_t count = valbuf.length;
            bool single = count == 1;
            auto val = valbuf[0];

            final switch(pname)
            {
            case Parameter.DEPTH_STENCIL_TEXTURE_MODE: return single && oneOf!DepthStencilTextureMode(val);
            case Parameter.BASE_LEVEL:   return single && val >= 0;
            case Parameter.BORDER_COLOR: return count == 4 && all!(a=>a>=0)(valbuf);
            case Parameter.COMPARE_FUNC: return single && oneOf!CompareFunc(val);
            case Parameter.COMPARE_MODE: return single && oneOf!CompareMode(val);
            case Parameter.LOD_BIAS:     return false; // is float
            case Parameter.MIN_FILTER:   return single && oneOf!Filter(val);
            case Parameter.MAG_FILTER:   return single && oneOf( [Filter.NEAREST,Filter.LINEAR], val );
            case Parameter.MIN_LOD:      return false; // is float
            case Parameter.MAX_LOD:      return false; // is float
            case Parameter.MAX_LEVEL:    return single;  // initial is 1000, no info in documentation

            case Parameter.SWIZZLE_R: 
            case Parameter.SWIZZLE_G: 
            case Parameter.SWIZZLE_B: 
            case Parameter.SWIZZLE_A:
                return single && oneOf!Swizzle(val);

            case Parameter.SWIZZLE_RGBA: return count == 4 && all!(a=>oneOf!Swizzle(a))(valbuf);

            case Parameter.WRAP_S:
            case Parameter.WRAP_T:
            case Parameter.WRAP_R:
                return single && oneOf!Wrap(val);
            }
        }

        bool checkPosibleFloatParamValues( Parameter pname, float[] valbuf... )
        {
            if( valbuf.length == 0 ) return false;

            size_t count = valbuf.length;
            bool single = count == 1;
            auto val = valbuf[0];

            switch(pname)
            {
            case Parameter.LOD_BIAS:
            case Parameter.MIN_LOD:
            case Parameter.MAX_LOD:
                return single;
            case Parameter.BORDER_COLOR: return count == 4;
            default: return false; // is integer;
            }
        }

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

        auto imagePixelType( Format fmt, Type type )
        {
            auto cnt = formatElemCount(fmt);
            auto ict = imageComponentType(type);
            if( ict == ComponentType.RAWBYTE )
                return PixelType( sizeofType(type) * cnt );
            else
                return PixelType( ict, cnt );
        }

        ComponentType imageComponentType( Type type )
        {
            switch( type )
            {
                case Type.BYTE:           return ComponentType.BYTE;
                case Type.UNSIGNED_BYTE:  return ComponentType.UBYTE;
                case Type.SHORT:          return ComponentType.SHORT;
                case Type.UNSIGNED_SHORT: return ComponentType.USHORT;
                case Type.INT:            return ComponentType.INT;
                case Type.UNSIGNED_INT:   return ComponentType.UINT;
                case Type.FLOAT:          return ComponentType.FLOAT;
                default:                  return ComponentType.RAWBYTE;
            }
        }

        @property bool isParameterEnum(T)()
        {
            return is(T==DepthStencilTextureMode) ||
                   is(T==CompareFunc) ||
                   is(T==CompareMode) ||
                   is(T==Filter) ||
                   is(T==Swizzle) ||
                   is(T==Wrap);
        }

        Type typeFromImageComponentType( ComponentType ctype )
        {
            switch( ctype )
            {
                case ComponentType.BYTE:     return Type.BYTE;
                case ComponentType.UBYTE:
                case ComponentType.RAWBYTE:  return Type.UNSIGNED_BYTE;
                case ComponentType.SHORT:    return Type.SHORT;
                case ComponentType.USHORT:   return Type.UNSIGNED_SHORT;
                case ComponentType.INT:      return Type.INT;
                case ComponentType.UINT:     return Type.UNSIGNED_INT;
                case ComponentType.FLOAT:
                case ComponentType.NORM_FLOAT: return Type.FLOAT;
                default:
                    throw new GLTextureException( "uncompatible image component type" );
            }
        }

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

private @property string accessVecFields(alias T)()
{
    string[] ret;
    foreach( i; 0 .. T.length )
        ret ~= format( "cast(int)(%s[%d])", T.stringof, i );
    return ret.join(",");
}
