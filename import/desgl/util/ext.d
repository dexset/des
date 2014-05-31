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

module desgl.util.ext;

import std.stdio;
import std.string;

import derelict.opengl3.gl3;

import desmath.linear.vector;

public import desutil.helpers: ExternalMemoryManager;
import desutil.logger;

mixin( PrivateLoggerMixin );

nothrow void checkGL( bool except=false, string md=__FILE__, int ln=__LINE__ )
{
    auto err = glGetError();
    try 
    {
        if( err != GL_NO_ERROR )
        {
            auto errstr = format( " ## GL ERROR ## %s at line: %s: 0x%04x", md, ln, err );
            if( except ) throw new Exception( errstr );
            else stderr.writefln( errstr );
        }
        else{ log( "GL OK %s at line: %s", md, ln ); }
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
