module tests.iface;

public
{
    import des.math.linear;
    import des.space;
    import des.assimp;
    import des.il;
    import des.il.io;
    import des.app.event;
    import des.util.arch;
    import des.util.logsys;
    import des.util.helpers;
    import des.util.timer;
    import des.util.testsuite;
    import des.util.stdext.algorithm;
    import des.gl;
}

class TestException : Exception
{
    this( string msg, string file=__FILE__, size_t line=__LINE__ ) pure nothrow @safe
    { super( msg, file, line ); }
}

interface Test
{
    void init();
    void clear();

    void idle();
    void draw();

    void keyReaction( in KeyboardEvent );
    void mouseReaction( in MouseEvent );
    void resize( ivec2 );

    @property
    {
        wstring name();
        wstring info();
        bool complite();
        bool success();
    }
}

class TestCase
{
    wstring info;
    bool delegate() func;

    this( wstring info, bool delegate() func )
    in{ assert( func !is null ); }
    body
    {
        this.info = info;
        this.func = func;
    }

    bool check() { return func(); }

    TestCase next;
}

abstract class AutoTestWithCases : DesObject, Test
{
    mixin DES;
    mixin ClassLogger;

    wstring current_info;

    TestCase subtest;

    this() { logger = new InstanceLogger(this); }

    void clear() { destroy(); }

    void idle()
    {
        if( subtest is null ) current_info = ""w;
        else current_info = wformat( "check '%s'"w, subtest.info );
    }

    void draw()
    {
        if( subtest is null ) return;

        if( subtest.check() ) nextSubTest();
        else fail( "[%s] '%s' fails", name, to!string(subtest.info) );
    }

    void keyReaction( in KeyboardEvent ke ) {}
    void mouseReaction( in MouseEvent me ) {}
    void resize( ivec2 sz ) {}

    @property
    {
        wstring info() { return current_info; }
        bool complite() { return subtest is null; }
        bool success() { return complite; }
    }

protected:

    void addSubTest( wstring info, bool delegate() func )
    {
        auto buf = new TestCase( info, func );
        if( subtest is null ) subtest = buf;
        else subtest = subtest.next = buf;
    }

    void nextSubTest() { subtest = subtest.next; }

    void fail(Args...)( string fmt, Args args )
    { throw new TestException( format( fmt, args ) ); }
}
