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

module desgl.base.shader;

import std.conv;
import std.string;
import std.exception;

import desmath.linear;

import derelict.opengl3.gl3;

import desutil.logger;
mixin( PrivateLoggerMixin );

import desgl.util.ext;

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

struct ShaderSource { string vert, frag, geom; }

class ShaderException : DesGLException 
{ 
    @safe pure nothrow this( string msg, string file=__FILE__, size_t line=__LINE__ )
    { super( msg, file, line ); } 
}

class BaseShaderProgram : ExternalMemoryManager
{
    mixin( getMixinChildEMM );
private:
    static GLint inUse = -1;

protected:

    GLuint vert_sh = 0,
           geom_sh = 0,
           frag_sh = 0;

    GLuint program = 0;

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

    static GLuint makeShader( GLenum type, string src )
    {
        GLuint shader = glCreateShader( type );
        debug log_info( "create shader %s with type %s", shader, type ); 
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
                throw new ShaderException( "shader compile error: \n" ~ chlog.idup );
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
                throw new ShaderException( "program link error: \n" ~ chlog.idup );
            }
        }
        debug checkGL;
    }

    void construct( in ShaderSource src )
    {
        if( src.vert.length == 0 ) 
            throw new ShaderException( "vertex shader source is empty" );

        program = glCreateProgram();

        vert_sh = makeShader( GL_VERTEX_SHADER, src.vert );

        if( src.geom.length )
            geom_sh = makeShader( GL_GEOMETRY_SHADER, src.geom );
        if( src.frag.length )
            frag_sh = makeShader( GL_FRAGMENT_SHADER, src.frag );

        glAttachShader( program, vert_sh );

        if( geom_sh )
            glAttachShader( program, geom_sh );
        if( frag_sh )
            glAttachShader( program, frag_sh );

        glLinkProgram( program );
        checkProgram( program );

        debug checkGL;
    }

    void checkLocation( int loc )
    { enforce( loc >= 0, new ShaderException( format( "bad location: '%d'", loc ) ) ); }

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

        debug checkGL;
    }

public:
    this( in ShaderSource src ) { construct( src ); }

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
        enforce( ret >= 0, new ShaderException( format( "bad attribute name: '%s'", name ) ) );
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
        enforce( ret >= 0, new ShaderException( format( "bad uniform name: '%s'", name ) ) );
        return ret;
    }

    void setUniform(S,T...)( int loc, T vals ) 
        if( checkUniform!(S,T) )
    {
        checkLocation( loc ); use();
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
    { setUniform!S( getUniformLocation( name ), vals ); }

    void setUniformArr(size_t sz,T)( int loc, in T[] vals )
        if( sz > 0 && sz < 5 && (glPostfix!T).length != 0 )
    {
        checkLocation( loc );
        auto cnt = vals.length / sz;
        use();
        mixin( "glUniform" ~ to!string(sz) ~ glPostfix!T ~ 
                "v( loc, cast(int)cnt, vals.ptr );" );
        debug checkGL;
    }

    void setUniformArr(size_t sz,T)( string name, in T[] vals )
        if( sz > 0 && sz < 5 && (glPostfix!T).length != 0 )
    { setUniformArr!sz( getUniformLocation( name ), vals ); }

    void setUniformVec(size_t N,T,string AS)( int loc, vec!(N,T,AS)[] vals... )
        if( N > 0 && N < 5 && (glPostfix!T).length != 0 )
    {
        checkLocation( loc ); 
        use();

        T[] data;
        foreach( v; vals ) data ~= v.data;

        mixin( "glUniform" ~ to!string(N) ~ glPostfix!T ~ 
                "v( loc, cast(int)(data.length / N), cast(" ~ T.stringof ~ "*)data.ptr );" );
        debug checkGL;
    }

    void setUniformVec(size_t N,T,string AS)( string name, vec!(N,T,AS)[] vals... )
        if( N > 0 && N < 5 && (glPostfix!T).length != 0 )
    { setUniformVec( getUniformLocation( name ), vals ); }
    
    void setUniformMat(size_t h, size_t w)( int loc, in mat!(h,w,float)[] mtr... )
        if( h <= 4 && w <= 4 )
    {
        checkLocation( loc );
        use();
        static if( w == h )
            mixin( "glUniformMatrix" ~ to!string(w) ~ 
                    "fv( loc, cast(int)mtr.length, GL_TRUE, cast(float*)mtr.ptr ); " );
        else
            mixin( "glUniformMatrix" ~ to!string(h) ~ "x" ~ to!string(w) ~
                    "fv( loc, cast(int)mtr.length GL_TRUE, cast(float*)mtr.ptr ); " );
        debug checkGL;
    }

    void setUniformMat(size_t h, size_t w)( string name, in mat!(h,w,float)[] mtr... )
        if( h <= 4 && w <= 4 )
    { setUniformMat( getUniformLocation( name ), mtr ); }
}
