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

module des.gl.base.shader;

import std.conv;
import std.string;
import std.exception;

import des.math.linear;

import derelict.opengl3.gl3;

import des.gl.base.type;

class ShaderException : DesGLException
{ 
    this( string msg, string file=__FILE__, size_t line=__LINE__ )
    { super( msg, file, line ); } 
}

class Shader : DesObject
{
    mixin DES;
    mixin ClassLogger;

protected:
    Type _type;
    string _source;
    uint _id;
    bool _compiled;

public:

    pure @property
    {
        nothrow const
        {
            uint id() { return _id; }
            string source() { return _source; }
            Type type() { return _type; }
            bool compiled() { return _compiled; }
        }

        string source( string s ) { _source = s; return _source; }
    }

    enum Type
    {
        VERTEX   = GL_VERTEX_SHADER,
        GEOMETRY = GL_GEOMETRY_SHADER,
        FRAGMENT = GL_FRAGMENT_SHADER,
    }

    this( Type tp, string src )
    {
        logger = new InstanceLogger(this);
        _type = tp;
        _source = src;
    }

    void make()
    {
        _id = checkGLCall!glCreateShader( cast(GLenum)_type );

        if( auto il = cast(InstanceLogger)logger )
            il.instance = format( "%d", _id );

        logger.Debug( "[%s] with type [%s]", _id, _type ); 

        auto src = _source.toStringz;
        checkGLCall!glShaderSource( _id, 1, &src, null );
        checkGLCall!glCompileShader( _id );

        int res;
        checkGLCall!glGetShaderiv( _id, GL_COMPILE_STATUS, &res );

        if( res == GL_FALSE )
        {
            int logLen;
            checkGLCall!glGetShaderiv( _id, GL_INFO_LOG_LENGTH, &logLen );
            if( logLen > 0 )
            {
                auto chlog = new char[logLen];
                checkGLCall!glGetShaderInfoLog( _id, logLen, &logLen, chlog.ptr );
                throw new ShaderException( "shader compile error: \n" ~ chlog.idup );
            }
        }

        _compiled = true;
        logger.trace( "pass" );
    }

protected:

    override void selfConstruct() { make(); }

    override void selfDestroy()
    {
        if( _compiled )
            checkGLCall!glDeleteShader( _id );
        logger.Debug( "pass" );
    }
}

auto parseShaderSource( string src, string separator = "//###" )
{
    Shader[] ret;

    foreach( ln; src.splitLines() )
    {
        if( ln.startsWith(separator) )
        {
            auto str_type = ln.chompPrefix(separator).strip().toLower;
            Shader.Type type;
            switch( str_type )
            {
                case "vert":
                case "vertex":
                    type = Shader.Type.VERTEX;
                    break;
                case "geom":
                case "geometry":
                    type = Shader.Type.GEOMETRY;
                    break;
                case "frag":
                case "fragment":
                    type = Shader.Type.FRAGMENT;
                    break;
                default:
                    throw new ShaderException( "parse shader source: unknown section '" ~ str_type ~ "'" );
            }
            ret ~= new Shader( type, "" );
        }
        else
        {
            if( ret.length == 0 )
                throw new ShaderException( "parse shader source: no section definition" );
            ret[$-1].source = ret[$-1].source ~ ln ~ '\n';
        }
    }

    return ret;
}

class ShaderProgram : DesObject
{
    mixin DES;
    mixin ClassLogger;

protected:

    uint _id = 0;

    private static uint inUse = 0;
    final @property 
    {
        bool thisInUse() const { return inUse == _id; }
        void thisInUse( bool u )
        {
            if( ( thisInUse && u ) || ( !thisInUse && !u ) ) return;
            uint np = 0;
            if( !thisInUse && u ) np = _id;
            checkGLCall!glUseProgram( np );
            inUse = np;
        }
    }

    Shader[] shaders;

public:
    this( Shader[] shs )
    {
        logger = new InstanceLogger(this);
        foreach( sh; shs )
            enforce( sh !is null, new ShaderException( "shader is null" ) );
        shaders = registerChildsEMM( shs );
        create();
    }

    uint id() pure nothrow const @property { return _id; }

    final void use() { thisInUse = true; }

protected:

    void create()
    {
        foreach( sh; shaders ) if( !sh.compiled ) sh.make();

        _id = checkGLCall!glCreateProgram();

        if( auto il = cast(InstanceLogger)logger )
            il.instance = format( "%d", _id );

        foreach( sh; shaders ) 
            checkGLCall!glAttachShader( _id, sh.id );

        checkGLCall!glLinkProgram( _id );
        check();

        logger.Debug( "pass" );
    }

    void check()
    {
        int res;
        checkGLCall!glGetProgramiv( _id, GL_LINK_STATUS, &res );
        if( res == GL_FALSE )
        {
            int logLen;
            checkGLCall!glGetProgramiv( _id, GL_INFO_LOG_LENGTH, &logLen );
            if( logLen > 0 )
            {
                auto chlog = new char[logLen];
                checkGLCall!glGetProgramInfoLog( _id, logLen, &logLen, chlog.ptr );
                throw new ShaderException( "program link error: \n" ~ chlog.idup );
            }
        }
    }

    override void selfConstruct() { create(); }

    override void preChildsDestroy()
    {
        thisInUse = false;

        foreach( sh; shaders )
            checkGLCall!glDetachShader( _id, sh.id );
    }

    override void selfDestroy()
    {
        checkGLCall!glDeleteProgram( _id );
        debug logger.Debug( "pass" );
    }
}

class CommonShaderProgram : ShaderProgram
{
public:
    this( Shader[] shs ) { super(shs); }

    int getAttribLocation( string name )
    { 
        auto ret = checkGLCall!glGetAttribLocation( _id, name.toStringz ); 
        debug if( ret < 0 ) logger.warn( "bad attribute name: '%s'", name );
        return ret;
    }

    int[] getAttribLocations( string[] names... )
    { 
        int[] ret;
        foreach( name; names )
            ret ~= getAttribLocation( name );
        return ret;
    }

    int getUniformLocation( string name )
    { return checkGLCall!glGetUniformLocation( _id, name.toStringz ); }

    void setUniform(T)( int loc, in T[] vals... ) 
        if( isAllowType!T || isAllowVector!T || isAllowMatrix!T )
    {
        if( loc < 0 )
        {
            logger.error( "bad uniform location" );
            return;
        }

        use();

        enum fnc = "checkGLCall!glUniform";

        static if( isAllowMatrix!T )
        {
            enum args_str = "loc, cast(int)vals.length, GL_TRUE, cast(float*)vals.ptr";
            static if( T.width == T.height )
                mixin( format( "%sMatrix%dfv( %s );", fnc, T.height, args_str ) );
            else
                mixin( format( "%sMatrix%dx%dfv( %s );", fnc, T.height, T.width, args_str ) );
        }
        else
        {
            static if( isAllowVector!T )
            {
                alias X = T.datatype;
                enum sz = T.length;
            }
            else
            {
                alias X = T;
                enum sz = 1;
            }
            enum pf = glPostfix!X;
            enum cs = X.stringof;

            mixin( format( "%s%d%sv( loc, cast(int)vals.length, cast(%s*)vals.ptr );", fnc, sz, pf, cs ) );
        }
    }

    void setUniform(T)( string name, in T[] vals... ) 
        if( is( typeof( setUniform!T( 0, vals ) ) ) )
    {
        auto loc = getUniformLocation( name );
        if( loc < 0 )
        {
            logger.error( "bad uniform name: '%s'", name );
            return;
        }
        setUniform!T( loc, vals );
    }
}

private pure @property
{
    bool isAllowType(T)() { return is( T == int ) || is( T == uint ) || is( T == float ); }

    bool isAllowVector(T)()
    {
        static if( !isStaticVector!T ) return false;
        else return isAllowType!(T.datatype) && T.length <= 4;
    }

    unittest
    {
        static assert( isAllowVector!vec2 );
        static assert( isAllowVector!ivec4 );
        static assert( isAllowVector!uivec3 );
        static assert( !isAllowVector!dvec3 );
        static assert( !isAllowVector!rvec3 );
        static assert( !isAllowVector!(Vector!(5,float)) );
    }

    bool isAllowMatrix(T)()
    {
        static if( !isStaticMatrix!T ) return false;
        else return is( T.datatype == float ) &&
            T.width >= 2 && T.width <= 4 &&
            T.height >= 2 && T.height <= 4;
    }

    unittest
    {
        static assert( isAllowMatrix!mat4 );
        static assert( isAllowMatrix!mat2x3 );
        static assert( !isAllowMatrix!rmat2x3 );
        static assert( !isAllowMatrix!dmat2x3 );
        static assert( !isAllowMatrix!(Matrix!(5,2,float)) );
    }
}

private string castArgsString(S,string data,T...)() @property
{
    string ret = "";
    foreach( i, type; T )
        ret ~= format( "cast(%s)%s[%d],", 
                S.stringof, data, i );

    return ret[0 .. $-1];
}

unittest
{
    string getFloats(string data,T...)( in T vals )
    { return castArgsString!(float,data,vals)(); }

    assert( getFloats!"v"( 1.0f, 2u, -3 ) == "cast(float)v[0],cast(float)v[1],cast(float)v[2]" );
}

string glPostfix(T)() pure @property
{
         static if( is( T == float ) ) return "f";
    else static if( is( T == int ) )   return "i";
    else static if( is( T == uint ) )  return "ui";
    else static if( isStaticVector!T ) return glPostfix!(T.datatype);
    else static if( isStaticMatrix!T ) return glPostfix!(T.datatype);
    else return "";
}

unittest
{
    assert( glPostfix!float  == "f" );
    assert( glPostfix!int    == "i" );
    assert( glPostfix!uint   == "ui");
    assert( glPostfix!double == ""  );
}

bool isAllConv(S,Args...)() pure @property
{
    foreach( t; Args )
        if( !is( t : S ) )
            return false;
    return true;
}
