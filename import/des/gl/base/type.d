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

module des.gl.base.type;

import derelict.opengl3.gl3;

enum GLType
{
    UNSIGNED_BYTE  = GL_UNSIGNED_BYTE,
    BYTE           = GL_BYTE,
    UNSIGNED_SHORT = GL_UNSIGNED_SHORT,
    SHORT          = GL_SHORT,
    UNSIGNED_INT   = GL_UNSIGNED_INT,
    INT            = GL_INT,
    FLOAT          = GL_FLOAT,
}

size_t sizeofGLType( GLType type )
{
    final switch(type)
    {
    case GLType.BYTE:
    case GLType.UNSIGNED_BYTE:
        return byte.sizeof;

    case GLType.SHORT:
    case GLType.UNSIGNED_SHORT:
        return short.sizeof;

    case GLType.INT:
    case GLType.UNSIGNED_INT:
        return int.sizeof;

    case GLType.FLOAT:
        return float.sizeof;
    }
}

@property GLType toGLType(T)()
{
    static if( is( T == ubyte ) )
        return GLType.UNSIGNED_BYTE;
    else static if( is( T == byte ) )
        return GLType.BYTE;
    else static if( is( T == ushort ) )
        return GLType.UNSIGNED_SHORT;
    else static if( is( T == short ) )
        return GLType.SHORT;
    else static if( is( T == uint ) )
        return GLType.UNSIGNED_INT;
    else static if( is( T == int ) )
        return GLType.INT;
    else static if( is( T == float ) )
        return GLType.FLOAT;
    else
    {
        pragma(msg, "no GLType for ", T );
        static assert(0);
    }
}

unittest
{
    assert( toGLType!ubyte == GLType.UNSIGNED_BYTE );
    assert( toGLType!byte == GLType.BYTE );
    assert( toGLType!ushort == GLType.UNSIGNED_SHORT );
    assert( toGLType!short == GLType.SHORT );
    assert( toGLType!uint == GLType.UNSIGNED_INT );
    assert( toGLType!int == GLType.INT );
    assert( toGLType!float == GLType.FLOAT );
}
