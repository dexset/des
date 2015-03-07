module des.gl.base.error;

import des.gl.base.general;

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

/// `glGetError`, if has error throw exception
void checkGL( string file=__FILE__, size_t line=__LINE__ )
{
    debug
    {
        GLError err = cast(GLError)glGetError();
        if( err != GLError.NO )
            throw new DesGLException( format("%s", err), file, line );
    }
    else pragma(msg,"warning: no check GL errors");
}

/// `glGetError`, no throw exception, output to logger error
void ntCheckGL( string file=__FILE__, size_t line=__LINE__ ) nothrow
{
    debug
    {
        try checkGL(file,line);
        catch( DesGLException e )
            logger.error( ntFormat( "GL ERROR at [%s:%d] %s", e.file, e.line, e.msg ) );
        catch( Exception e )
            logger.error( ntFormat( "[%s:%d] %s", e.file, e.line, e.msg ) );
    } else return;
}

/// call `checkGL` after function call
template checkGLCall(alias fnc, string file=__FILE__, size_t line=__LINE__, Args...)
{
    auto checkGLCall(Args...)( Args args )
    {
        debug scope(exit) checkGL(file,line);
        static if( is( typeof(fnc(args)) == void ) ) fnc( args );
        else return fnc( args );
    }
}

/// call `ntCheckGL` after function call
template ntCheckGLCall(alias fnc, string file=__FILE__, size_t line=__LINE__, Args...)
{
    auto ntCheckGLCall(Args...)( Args args ) nothrow
    {
        debug scope(exit) ntCheckGL(file,line);
        static if( is( typeof(fnc(args)) == void ) ) fnc( args );
        else return fnc( args );
    }
}
