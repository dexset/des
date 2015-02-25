module des.gl.base.type;

import std.stdio;
import std.string;

import derelict.opengl3.gl3;

public import des.math.linear.vector;
public import des.util.arch;
public import des.util.logsys;

///
class DesGLException : Exception
{
    ///
    this( string msg, string file=__FILE__, size_t line=__LINE__ ) pure nothrow @safe
    { super( msg, file, line ); }
}

///
enum GLType
{
    UNSIGNED_BYTE  = GL_UNSIGNED_BYTE,  /// `GL_UNSIGNED_BYTE`
    BYTE           = GL_BYTE,           /// `GL_BYTE`
    UNSIGNED_SHORT = GL_UNSIGNED_SHORT, /// `GL_UNSIGNED_SHORT`
    SHORT          = GL_SHORT,          /// `GL_SHORT`
    UNSIGNED_INT   = GL_UNSIGNED_INT,   /// `GL_UNSIGNED_INT`
    INT            = GL_INT,            /// `GL_INT`
    FLOAT          = GL_FLOAT,          /// `GL_FLOAT`
}

///
size_t sizeofGLType( GLType type ) pure nothrow
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

///
GLType toGLType(T)() @property
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

///
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

///
enum GLError
{
    NO                = GL_NO_ERROR,          /// `GL_NO_ERROR`
    INVALID_ENUM      = GL_INVALID_ENUM,      /// `GL_INVALID_ENUM`
    INVALID_VALUE     = GL_INVALID_VALUE,     /// `GL_INVALID_VALUE`
    INVALID_OPERATION = GL_INVALID_OPERATION, /// `GL_INVALID_OPERATION`
    STACK_OVERFLOW    = 0x0503,               /// `0x0503`
    STACK_UNDERFLOW   = 0x0504,               /// `0x0504`
    OUT_OF_MEMORY     = GL_OUT_OF_MEMORY,     /// `GL_OUT_OF_MEMORY`
    INVALID_FRAMEBUFFER_OPERATION = 0x0506    /// `0x0506`
}

/// glGetError, if has error throw exception
void checkGL( string file=__FILE__, size_t line=__LINE__ )()
{
    GLError err = cast(GLError)glGetError();

    if( err != GLError.NO )
        throw new DesGLException( format("%s", err), file, line );
}

/// glGetError, no throw exception, output to logger error
void ntCheckGL( string file=__FILE__, size_t line=__LINE__ )() nothrow
{
    try checkGL!(file,line);
    catch( DesGLException e )
        logger.error( ntFormat( "GL ERROR at [%s:%d] %s", e.file, e.line, e.msg ) );
    catch( Exception e )
        logger.error( ntFormat( "[%s:%d] %s", e.file, e.line, e.msg ) );
}

/// call `checkGL` after function call
template checkGLCall(alias fnc, string file=__FILE__, size_t line=__LINE__, Args...)
{
    auto checkGLCall(Args...)( Args args )
    {
        scope(exit) debug checkGL!(file,line);
        static if( is( typeof(fnc(args)) == void ) ) fnc( args );
        else return fnc( args );
    }
}

/// call `ntCheckGL` after function call
template ntCheckGLCall(alias fnc, string file=__FILE__, size_t line=__LINE__, Args...)
{
    auto ntCheckGLCall(Args...)( Args args ) nothrow
    {
        scope(exit) debug ntCheckGL!(file,line);
        static if( is( typeof(fnc(args)) == void ) ) fnc( args );
        else return fnc( args );
    }
}
