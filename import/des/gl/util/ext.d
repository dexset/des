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
import des.util.logger;

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

nothrow void checkGL(string fnc=__FUNCTION__)( bool except=false, string md=__FILE__, size_t ln=__LINE__ )
{
    auto err = cast(GLError)glGetError();
    try 
    {
        if( err != GLError.NO )
        {
            auto errstr = format( " ## GL ERROR ## [%s:%d]: %s", md, ln, err );
            if( except ) throw new Exception( errstr );
            else log_error!fnc( errstr );
        }
        else{ log_trace!fnc( "GL OK" ); }
    } 
    catch( Exception e )
    {
        try stderr.writeln( e );
        catch( Exception ee ) {}
    }
}

class DesGLException : Exception 
{ 
    @safe pure nothrow this( string msg, string file=__FILE__, size_t line=__LINE__ )
    { super( msg, file, line ); } 
}
