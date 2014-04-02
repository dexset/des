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

module desgl.ready.factory;

import std.string;
import std.exception;

import derelict.opengl3.gl3;

public import desmath.linear;

public import desgl.base;
import desgl.util.ext;

// Shader Permited Data Type
enum SPDType { NONE, FLOAT, VEC2, VEC3, VEC4, MAT2, MAT3, MAT4, 
    MAT3x2, MAT4x2, MAT2x3, MAT2x4, MAT3x4, MAT4x3, INT, IVEC2, IVEC3, IVEC4 }

struct ShaderVar
{
    alias ShaderVar self;

    enum Type { NONE, FLOAT, INT }
    Type type = Type.NONE;

    enum Form { SINGLE, VEC, MAT }
    Form form;

    enum Size { s1=1u, s2, s3, s4 } 
    Size h, w;

    @property static self as(T)()
    {
        self ret;
        enum unsupstr = "unsupported shader data type: '" ~ T.stringof ~ "'";
        static if( isVector!T )
        {
                 static if( is( T.datatype == float ) ) ret.type = Type.FLOAT;
            else static if( is( T.datatype == int ) ) ret.type = Type.INT;
            else static assert(0, unsupstr);
            ret.form = Form.VEC;
            static if( T.length > 1 && T.length < 5 ) 
                mixin( format( "ret.h = Size.s%d;", T.length ) );
            else static assert(0, unsupstr);
            ret.w = Size.s1;
        }
        else static if( isMatrix!T )
        {
            static if( is( T.datatype == float ) ) ret.type = Type.FLOAT;
            else static assert(0, unsupstr);
            ret.form = Form.MAT;
            static if( T.h > 1 && T.h < 5 ) mixin( format( "ret.h = Size.s%d;", T.h ) );
            else static assert(0, unsupstr);
            static if( T.w > 1 && T.w < 5 ) mixin( format( "ret.w = Size.s%d;", T.w ) );
            else static assert(0, unsupstr);
        }
        else static if( is( T == float ) || is( T == int ) )
        {
            mixin( format( "ret.type = Type.%s;", T.stringof.toUpper ) );
            ret.form = Form.SINGLE;
            ret.w = ret.h = Size.s1;
        }
        else static assert(0, unsupstr);
        return ret;
    }

    @property string glUniformSuffix() const
    {
        string ret;
        if( form == Form.MAT ) 
        {
            ret ~= "Matrix";
            if( h != w ) 
                ret ~= format( "%dx%d", cast(int)h, cast(int)w );
            else ret ~= format( "%d", cast(int)h );
        }
        else ret ~= format( "%d", cast(int)h );
        final switch( type )
        {
            case Type.NONE:  throw new ShaderException( "bad variable type" );
            case Type.FLOAT: ret ~= "f"; break;
            case Type.INT:   ret ~= "i"; break;
        }
        return ret;
    }

    @property bool isMat() const { return form == Form.MAT; }
    @property string strType() const 
    { 
        final switch( type )
        {
            case Type.NONE:  throw new ShaderException( "bad variable type" );
            case Type.FLOAT: return "float";
            case Type.INT: return "int";
        }
    }
    @property GLenum glType() const 
    { 
        final switch( type )
        {
            case Type.NONE:  throw new ShaderException( "bad variable type" );
            case Type.FLOAT: return GL_FLOAT;
            case Type.INT: return GL_INT;
        }
    }
    @property string glslType() const
    {
        final switch( form )
        {
            case Form.SINGLE: return type != Type.FLOAT ? "int" : "float";
            case Form.VEC: return format( "%svec%d", type != Type.FLOAT ? "i" : "", cast(int)h );
            case Form.MAT: return format( "mat%s", ( h==w ? format( "%d", cast(int)h ) :
                                       format( "%dx%d", cast(int)h, cast(int)w ) ) );
        }
    }

    @property int fullSize() const { return cast(int)h * cast(int)w; }
}

struct AttribSpec
{
    string name;
    ShaderVar vt;
}

struct AttribSpecInner
{
    int loc;
    ShaderVar vt;
}

struct UniformSpec
{
    string name;
    size_t count;
    ShaderVar vt;
}

alias UniformSpec VaryingSpec;

struct UniformSpecInner
{
    int loc;
    size_t count;
    ShaderVar vt;
}

class SpecShaderProgram: BaseShaderProgram
{
protected:

    AttribSpecInner[string] attribs;
    UniformSpecInner[string] uniforms;

    this( in ShaderSource src, in AttribSpec[] attrs, in UniformSpec[] uforms )
    {
        super(src);

        foreach( a; attrs )
        {
            enforce( a.vt.type != ShaderVar.Type.NONE,
                    new ShaderException( "attribute data type 'NONE' must " ~
                        "not be used in ctor for shader" ) );
            auto loc = glGetAttribLocation( program, a.name.toStringz );
            checkLocation( loc );
            attribs[a.name] = AttribSpecInner( loc, a.vt );
        }

        foreach( u; uforms )
        {
            enforce( u.vt.type != ShaderVar.Type.NONE,
                    new ShaderException( "uniform data type 'NONE' must " ~
                        "not be used in ctor for shader" ) );
            enforce( u.count > 0, new ShaderException( "shader data count " ~
                        "must be > 0" ) );

            auto loc = glGetUniformLocation( program, u.name.toStringz );
            checkLocation( loc );
            uniforms[u.name] = UniformSpecInner( loc, u.count, u.vt );
        }
    }

public:

    @property const(AttribSpecInner[string]) attr() const { return attribs; }
    @property const(UniformSpecInner[string]) uniform() const { return uniforms; }

    void setUniform(Arg)( string name, in Arg[] args )
        if( is( typeof( ShaderVar.as!Arg ) == ShaderVar ) )
    {
        auto uniform = uniforms.get( name, UniformSpecInner(-1) );
        enforce( uniform.loc != -1, 
                new ShaderException( format( "no uniform '%s' found", name ) ) );
        enforce( args.length == uniform.count, 
                new ShaderException( format( "bad data array size (%d) for uniform '%s', must be %d", 
                        args.length, name, uniform.count ) ) );
        enum sv = ShaderVar.as!Arg;
        mixin( "glUniform" ~ sv.glUniformSuffix ~ "v( uniform.loc, cast(int)args.length, " 
                ~ ( sv.isMat ? "1," : "" ) ~ " cast(" ~ sv.strType ~ "*)args.ptr );" );
    }

    void setUniform(Arg)( string name, in Arg arg ) { setUniform( name, [arg] ); }

    @property auto opDispatch(string name, Arg)( in Arg[] args )
        if( is( typeof( ShaderVar.as!Arg ) == ShaderVar ) )
    {
        setUniform( name, args );
        return args;
    }

    @property auto opDispatch(string name, Arg)( in Arg arg )
        if( is( typeof( ShaderVar.as!Arg ) == ShaderVar ) )
    { 
        setUniform( name, arg ); 
        return arg;
    }
}

class GLSpecObj : GLObj
{
protected:
    final void setAttribSpec( GLVBO buffer, in AttribSpecInner spec )
    { setAttribPointer( buffer, spec.loc, spec.vt.fullSize, spec.vt.glType ); }
}

class ShaderFactory
{
protected:
    this() { }
public:

    SpecShaderProgram getCustom( in AttribSpec[] attrs, in UniformSpec[] uforms, 
            in VaryingSpec[] vars, string vert, string frag="", string geom="" )
    {
        string attribStrList( in AttribSpec[] attrs )
        {
            string ret;
            foreach( attr; attrs )
                ret ~= format( "attribute %s %s;\n", attr.vt.glslType, attr.name );
            return ret;
        }

        string uniformStrList( in UniformSpec[] uforms )
        {
            string ret;
            foreach( uf; uforms )
                ret ~= format( "uniform %s%s %s;\n", uf.vt.glslType, 
                        ( uf.count > 1 ? format("[%d]", uf.count) : "" ), uf.name );
            return ret;
        }

        string varyingStrList( in VaryingSpec[] vars )
        {
            string ret;
            foreach( v; vars )
                ret ~= format( "varying %s%s %s;\n", v.vt.glslType, 
                        ( v.count > 1 ? format("[%d]", v.count) : "" ), v.name );
            return ret;
        }


        ShaderSource src;

        auto ufsl = uniformStrList(uforms);
        auto vrsl = varyingStrList(vars);

        src.vert = format(
                `#version 120
                %s
                %s
                %s

                void main(void)
                {
                    %s
                }`, attribStrList(attrs), ufsl, vrsl, vert );

        src.frag = format(
                `#version 120
                %s
                %s
                void main(void)
                {
                    %s
                }`, ufsl, vrsl, frag );

        return new SpecShaderProgram( src, attrs, uforms );
    }

    //SpecShaderProgram getSimple()
    //{

    //}
}

private static ShaderFactory sf;

@property ShaderFactory shaderFactory()
{
    if( sf is null ) 
        sf = new ShaderFactory();
    return sf;
}
