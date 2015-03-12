module des.gl.base.general;

public
{
    import std.exception;
    import std.string;
    import std.conv : to;

    import derelict.opengl3.gl3;

    import des.math.linear;

    import des.util.arch;
    import des.util.logsys;
    import des.util.data.type;
    import des.util.helpers : packBitMask;
    import des.util.stdext.string;

    import des.gl.base.type;
    import des.gl.base.error;
    import des.gl.base.object;
}

///
class DesGLException : Exception
{
    ///
    this( string msg, string file=__FILE__, size_t line=__LINE__ ) pure nothrow @safe
    { super( msg, file, line ); }
}
