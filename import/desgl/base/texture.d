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

module desgl.base.texture;

import std.string : format;

public import derelict.opengl3.gl3;

import desgl.base.type;
import desgl.util.ext;

import desmath.linear.vector;
import desil;

import std.algorithm;
import desutil.algo;

class TextureException : DesGLException 
{ 
    @safe pure nothrow this( string msg, string file=__FILE__, size_t line=__LINE__ )
    { super( msg, file, line ); } 
}

class GLTexture : ExternalMemoryManager
{
mixin( getMixinChildEMM );
private:
    uint _id;

protected:
    texsize_t img_size;

    void selfDestroy()
    {
        unbind();
        glDeleteTextures( 1, &_id );
        debug checkGL;
    }

    Target _type;

    nothrow @property GLenum gltype() const { return cast(GLenum)_type; }

public:

    alias vec!(3,size_t,"whd") texsize_t; 
    @property Target type() const { return _type; }

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
        BGRA = GL_BGRA
    }

    this( Target tp )
    in { assert( isBase(tp) ); } body
    {
        glGenTextures( 1, &_id );
        debug checkGL;
        _type = tp;
    }

    final pure const @property uint id() { return _id; }

    void genMipmap()
    in { assert( isMipmapable(_type) ); } body
    {
        bind();
        glGenerateMipmap(gltype);
    }

    void setParameter(T)( Parameter pname, T[] val... )
        if( is(T==int) || is(T==float) )
    in
    {
        assert( val.length > 0 );
        assert( isParametric(_type) );
        assert( checkPosibleParamValues( pname, val ) );
    }
    body
    {
        bind();
        auto ts = is(T==int) ? "i" : "f";
        if( val.length == 1 )
            mixin( format("glTexParameter%s( gltype, cast(GLenum)pname, val[0] );", ts) );
        else 
            mixin( format("glTexParameter%sv( gltype, cast(GLenum)pname, val.ptr );", ts) ); 

        debug checkGL;
    }

    final nothrow
    {
        void bind() { glBindTexture( gltype, _id ); }
        void unbind() { glBindTexture( gltype, 0 ); }
        texsize_t size() const { return img_size; }
    }

    void image(T)( in T sz, InternalFormat internal_format, 
            Format data_format, GLType data_type, in void* data=null )
        if( isCompVector!(1,size_t,T) || isCompVector!(2,size_t,T) || isCompVector!(3,size_t,T) )
    {
        enum N = sz.length;
        img_size = texsize_t( sz, [1,1][0 .. 3-N] );

        bind();
        mixin( format(`
        glTexImage%1dD( gltype, 0, cast(int)internal_format, %s, 0,
                        cast(GLenum)data_format, cast(GLenum)data_type, data );
        `, N, accessVecFields!(sz) ) );

        debug checkGL;
    }

    final void getImage( ref Image img, uint level=0, Format fmt=Format.RGB, GLBaseType rtype=GLBaseType.UNSIGNED_BYTE )
    in { assert( _type == Target.T2D ); } body
    {
        bind();
        if( level ) glGenerateMipmap(GL_TEXTURE_2D);
        debug checkGL;
        int w, h;
        glGetTexLevelParameteriv( GL_TEXTURE_2D, level, GL_TEXTURE_WIDTH, &(w));
        debug checkGL;
        glGetTexLevelParameteriv( GL_TEXTURE_2D, level, GL_TEXTURE_HEIGHT, &(h));
        debug checkGL;

        import std.string;

        size_t elemSize = 1;

        final switch(fmt)
        {
            case Format.RED: break;
            case Format.RG:  elemSize = 2; break;

            case Format.RGB:
            case Format.BGR:
                elemSize = 3; break;

            case Format.RGBA:
            case Format.BGRA:
                elemSize = 4; break;
        }

        elemSize *= sizeofGLBaseType(rtype);

        auto dsize = w * h * elemSize;

        if( img.size != imsize_t(w,h) || img.type.bpp != elemSize )
            img.allocate( imsize_t(w,h), ImageType( elemSize ) );

        glGetTexImage( GL_TEXTURE_2D, level, cast(GLenum)fmt, cast(GLenum)rtype, img.data.ptr );
        debug checkGL;
        unbind();
        debug checkGL;
    }

    final void image( in Image img )
    in { assert( type == Target.T2D ); } body
    {
        GLenum fmt, type;
        switch( img.type.comp )
        {
            case ImCompType.RAWBYTE: case ImCompType.UBYTE:
                type = GL_UNSIGNED_BYTE; break;
            case ImCompType.FLOAT: case ImCompType.NORM_FLOAT:
                type = GL_FLOAT; break;
            default:
                throw new TextureException( "uncompatible image component type" );
        }
        switch( img.type.channels )
        {
            case 1: fmt = GL_RED;  break;
            case 2: fmt = GL_RG;   break;
            case 3: fmt = GL_RGB;  break;
            case 4: fmt = GL_RGBA; break;
            default:
                throw new TextureException( "uncompatible image chanels count" );
        }
        image( img.size, cast(InternalFormat)img.type.channels, 
                cast(Format)fmt, cast(GLType)type, img.data.ptr );
    }

    final void image( in ImageReadAccess ira )
    in { assert( type == Target.T2D ); } body
    { 
        if( ira !is null ) image( ira.selfImage() ); 
        else image( ivec2(1,1), InternalFormat.RGB, Format.RGB, GLType.UNSIGNED_BYTE );
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

        bool checkPosibleParamValues( Parameter pname, int[] valbuf... )
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

        bool checkPosibleParamValues( Parameter pname, float[] valbuf... )
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
    }
}

private @property string accessVecFields(alias T)()
{
    string[] ret;
    foreach( i; 0 .. T.length )
        ret ~= format( "cast(int)(%s[%d])", T.stringof, i );
    return ret.join(",");
}
