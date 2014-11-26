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
import std.file : readText;
import std.string;
import std.exception;

import des.math.linear;

import derelict.opengl3.gl3;

import des.util.logger;

import des.gl.util.ext;

@property private string castArgsString(S,string data,T...)()
{
    string ret = "";
    foreach( i, type; T )
        ret ~= format( "cast(%s)%s[%d],", 
                S.stringof, data, i );

    return ret[0 .. $-1];
}

@property pure string glPostfix(S)()
{
         static if( is( S == float ) ) return "f";
    else static if( is( S == int ) )   return "i";
    else static if( is( S == uint ) )  return "ui";
    else return "";
}

unittest
{
    assert( glPostfix!float  == "f" );
    assert( glPostfix!int    == "i" );
    assert( glPostfix!uint   == "ui");
    assert( glPostfix!double == ""  );
}

@property pure bool checkUniform(S,T...)()
{
    if( glPostfix!S == "" || 
            T.length == 0 || 
            T.length >  4 ) return false;
    foreach( t; T ) 
        if( !is( t : S ) ) 
            return false;
    return true;
}

unittest
{
    string getFloats(string data,T...)( in T vals )
    { return castArgsString!(float,data,vals)(); }

    assert( getFloats!"v"( 1.0f, 2u, -3 ) == "cast(float)v[0],cast(float)v[1],cast(float)v[2]" );
}

struct ShaderSource
{
    string name;
    string vert, geom, frag;

pure:
    this( string v, string f="" ) { this("",v,"",f); }

    this( string v, string g, string f ) { this("",v,g,f); }

    this( string n, string v, string g, string f )
    {
        name = n;
        vert = v;
        geom = g;
        frag = f;
    }
}

@property ShaderSource staticLoadShaderSource(string name)()
{ return parseShaderSource( name, import(name) ); }

ShaderSource loadShaderSource( string name )
{ return parseShaderSource( name, readText( name ) ); }

ShaderSource parseShaderSource( string name, string src )
{
    string[3] sep;

    string sepLineStart = "//###";
    size_t cur = 0;

    foreach( ln; src.splitLines() )
        if( ln.startsWith(sepLineStart) )
        {
            auto section = ln.chompPrefix(sepLineStart).strip().toLower;
            switch( section )
            {
                case "vert":
                case "vertex":
                    cur = 0;
                    break;
                case "geom":
                case "geometry":
                    cur = 1;
                    break;
                case "frag":
                case "fragment":
                    cur = 2;
                    break;
                default:
                    throw new GLShaderException( "parse shader source: unknown section '" ~ section ~ "'" );
            }
        }
        else sep[cur] ~= ln ~ '\n';

    return ShaderSource(name,sep[0],sep[1],sep[2]);
}

class GLShaderException : DesGLException 
{ 
    @safe pure nothrow this( string msg, string file=__FILE__, size_t line=__LINE__ )
    { super( msg, file, line ); } 
}

class BaseShaderProgram : ExternalMemoryManager
{
    mixin DirectEMM;
    mixin AnywayLogger;
private:
    static GLint inUse = -1;

protected:

    GLuint vert_sh = 0,
           geom_sh = 0,
           frag_sh = 0;

    GLuint program = 0;

    enum ShaderType
    {
        VERTEX   = GL_VERTEX_SHADER,
        GEOMETRY = GL_GEOMETRY_SHADER,
        FRAGMENT = GL_FRAGMENT_SHADER
    };

    final nothrow @property 
    {
        bool thisInUse() const { return inUse == program; }
        void thisInUse( bool u )
        {
            if( ( thisInUse && u ) || ( !thisInUse && !u ) ) return;
            GLint np = 0;
            if( !thisInUse && u ) np = program;
            glUseProgram( np );
            inUse = np;
            debug checkGL;
        }
    }

    static GLuint makeShader( ShaderType type, string src )
    {
        GLuint shader = glCreateShader( cast(GLenum)type );
        debug log_trace( "[%s] with type [%s]", shader, type ); 
        auto srcptr = src.toStringz;
        glShaderSource( shader, 1, &(srcptr), null );
        glCompileShader( shader );

        int res;
        glGetShaderiv( shader, GL_COMPILE_STATUS, &res );
        if( res == GL_FALSE )
        {
            int logLen;
            glGetShaderiv( shader, GL_INFO_LOG_LENGTH, &logLen );
            if( logLen > 0 )
            {
                auto chlog = new char[logLen];
                glGetShaderInfoLog( shader, logLen, &logLen, chlog.ptr );
                throw new GLShaderException( "shader compile error: \n" ~ chlog.idup );
            }
        }

        debug checkGL;
        return shader;
    }

    static void checkProgram( GLuint prog )
    {
        int res;
        glGetProgramiv( prog, GL_LINK_STATUS, &res );
        if( res == GL_FALSE )
        {
            int logLen;
            glGetProgramiv( prog, GL_INFO_LOG_LENGTH, &logLen );
            if( logLen > 0 )
            {
                auto chlog = new char[logLen];
                glGetProgramInfoLog( prog, logLen, &logLen, chlog.ptr );
                throw new GLShaderException( "program link error: \n" ~ chlog.idup );
            }
        }
        debug checkGL;
    }

    void construct( in ShaderSource src )
    {
        if( src.vert.length == 0 ) 
            throw new GLShaderException( "vertex shader source is empty" );

        program = glCreateProgram();

        vert_sh = makeShader( ShaderType.VERTEX, src.vert );

        if( src.geom.length )
            geom_sh = makeShader( ShaderType.GEOMETRY, src.geom );
        if( src.frag.length )
            frag_sh = makeShader( ShaderType.FRAGMENT, src.frag );

        glAttachShader( program, vert_sh );

        if( geom_sh )
            glAttachShader( program, geom_sh );
        if( frag_sh )
            glAttachShader( program, frag_sh );

        glLinkProgram( program );
        checkProgram( program );

        debug checkGL;
    }

    void selfDestroy()
    {
        thisInUse = false;

        if( frag_sh ) glDetachShader( program, frag_sh );
        if( geom_sh ) glDetachShader( program, geom_sh );

        glDetachShader( program, vert_sh );

        glDeleteProgram( program );

        if( frag_sh ) glDeleteShader( frag_sh );
        if( geom_sh ) glDeleteShader( geom_sh );

        glDeleteShader( vert_sh );

        debug logger.Debug( "[%d]", program );

        debug checkGL;
    }

public:
    this( in ShaderSource src )
    {
        construct( src );
        debug logger.Debug( "[%d] from source [%s]", program, src.name );
    }

    final nothrow void use() { thisInUse = true; }
}

class CommonShaderProgram : BaseShaderProgram
{
public:
    this( in ShaderSource src ) { super( src ); }

    int getAttribLocation( string name )
    { 
        auto ret = glGetAttribLocation( program, name.toStringz ); 
        debug checkGL;
        debug if(ret<0) logger.warn( "[%d] bad attribute name: '%s'", program, name );
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
    {
        auto ret = glGetUniformLocation( program, name.toStringz ); 
        debug checkGL;
        return ret;
    }

    void setUniform(S,T...)( int loc, T vals ) 
        if( checkUniform!(S,T) )
    {
        if( loc < 0 )
        {
            logger.warn( "[%d] bad uniform location: '%s'", program, loc );
            return;
        }
        use();
        mixin( "glUniform" ~ to!string(T.length) ~ glPostfix!S ~ "( loc, " ~ 
                castArgsString!(S,"vals",T) ~ " );" );
        /* workaround: 
           before glUniform glGetError return 0x0501 errcode, 
           ignore it force */ 
        glGetError();
        debug checkGL;
    }

    void setUniform(S,T...)( string name, T vals ) 
        if( checkUniform!(S,T) )
    {
        auto loc = getUniformLocation( name );
        if( loc < 0 )
        {
            logger.warn( "[%d] bad uniform name: '%s'", program, name );
            return;
        }
        setUniform!S( loc, vals );
    }

    void setUniformArr(size_t sz,T)( int loc, in T[] vals )
        if( sz > 0 && sz < 5 && (glPostfix!T).length != 0 )
    {
        if( loc < 0 )
        {
            logger.warn( "[%d] bad uniform location: '%s'", program, loc );
            return;
        }
        auto cnt = vals.length / sz;
        use();
        mixin( "glUniform" ~ to!string(sz) ~ glPostfix!T ~ 
                "v( loc, cast(int)cnt, vals.ptr );" );
        debug checkGL;
    }

    void setUniformArr(size_t sz,T)( string name, in T[] vals )
        if( sz > 0 && sz < 5 && (glPostfix!T).length != 0 )
    {
        auto loc = getUniformLocation( name );
        if( loc < 0 )
        {
            logger.warn( "[%d] bad uniform name: '%s'", program, name );
            return;
        }
        setUniformArr!sz( loc, vals );
    }

    void setUniformVec(size_t N,T,string AS)( int loc, Vector!(N,T,AS)[] vals... )
        if( N > 0 && N < 5 && (glPostfix!T).length != 0 )
    {
        if( loc < 0 )
        {
            logger.warn( "[%d] bad uniform location: '%s'", program, loc );
            return;
        }
        use();

        T[] data;
        foreach( v; vals ) data ~= v.data;

        mixin( "glUniform" ~ to!string(N) ~ glPostfix!T ~ 
                "v( loc, cast(int)(data.length / N), cast(" ~ T.stringof ~ "*)data.ptr );" );
        debug checkGL;
    }

    void setUniformVec(size_t N,T,string AS)( string name, Vector!(N,T,AS)[] vals... )
        if( N > 0 && N < 5 && (glPostfix!T).length != 0 )
    {
        auto loc = getUniformLocation( name );
        if( loc < 0 )
        {
            logger.warn( "[%d] bad uniform name: '%s'", program, name );
            return;
        }
        setUniformVec( loc, vals );
    }
    
    void setUniformMat(size_t h, size_t w)( int loc, in Matrix!(h,w,float)[] mtr... )
        if( h <= 4 && w <= 4 )
    {
        if( loc < 0 )
        {
            logger.warn( "[%d] bad uniform location: '%s'", program, loc );
            return;
        }
        use();
        static if( w == h )
            mixin( "glUniformMatrix" ~ to!string(w) ~ 
                    "fv( loc, cast(int)mtr.length, GL_TRUE, cast(float*)mtr.ptr ); " );
        else
            mixin( "glUniformMatrix" ~ to!string(h) ~ "x" ~ to!string(w) ~
                    "fv( loc, cast(int)mtr.length, GL_TRUE, cast(float*)mtr.ptr ); " );
        debug checkGL;
    }

    void setUniformMat(size_t h, size_t w)( string name, in Matrix!(h,w,float)[] mtr... )
        if( h <= 4 && w <= 4 )
    {
        auto loc = getUniformLocation( name );
        if( loc < 0 )
        {
            logger.warn( "[%d] bad uniform name: '%s'", program, name );
            return;
        }
        setUniformMat( loc, mtr );
    }
}