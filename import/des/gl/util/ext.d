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

module des.gl.util.ext;

import std.stdio;
import std.string;

import derelict.opengl3.gl3;

import des.math.linear.vector;

public import des.util.emm;
import des.util.logsys;

class DesGLException : Exception 
{ 
    this( string msg, string file=__FILE__, size_t line=__LINE__ ) pure nothrow @safe
    { super( msg, file, line ); } 
}

enum GLError
{
    NO                = GL_NO_ERROR,
    INVALID_ENUM      = GL_INVALID_ENUM,
    INVALID_VALUE     = GL_INVALID_VALUE,
    INVALID_OPERATION = GL_INVALID_OPERATION,
    STACK_OVERFLOW    = 0x0503,
    STACK_UNDERFLOW   = 0x0504,
    OUT_OF_MEMORY     = GL_OUT_OF_MEMORY,
    INVALID_FRAMEBUFFER_OPERATION = 0x0506
}

void checkGL( string file=__FILE__, size_t line=__LINE__ )()
{
    GLError err = cast(GLError)glGetError();

    if( err != GLError.NO )
        throw new DesGLException( format("%s", err), file, line );
}

void ntCheckGL( string file=__FILE__, size_t line=__LINE__ )() nothrow
{
    try checkGL!(file,line);
    catch( DesGLException e )
        logger.error( toMessage( "GL ERROR at [%s:%d] %s", e.file, e.line, e.msg ) );
    catch( Exception e )
        logger.error( toMessage( "[%s:%d] %s", e.file, e.line, e.msg ) );
}

template checkGLCall(alias fnc, string file=__FILE__, size_t line=__LINE__, Args...)
{
    auto checkGLCall(Args...)( Args args )
    {
        scope(exit) debug checkGL!(file,line);
        static if( is( typeof(fnc(args)) == void ) ) fnc( args );
        else return fnc( args );
    }
}

template ntCheckGLCall(alias fnc, string file=__FILE__, size_t line=__LINE__, Args...)
{
    auto ntCheckGLCall(Args...)( Args args ) nothrow
    {
        scope(exit) debug ntCheckGL!(file,line);
        static if( is( typeof(fnc(args)) == void ) ) fnc( args );
        else return fnc( args );
    }
}
