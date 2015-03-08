module tester;

import des.gl;
public import des.app.event;
import des.util.arch;
import des.util.timer;

import tests;

class Tester : DesObject
{
    mixin DES;
protected:

    Timer timer;

    Test[] tests;
    Test current;
    size_t curno;

    wstring info_log;

    void prepareTests()
    {
        tests ~= newEMM!EmptyTest( "empty test"w, 100 );
        current = tests[0];
        tests ~= registerChildEMM( getAllTests() );
    }

public:

    Signal!wstring changeInfoLog;
    Signal!wstring changeInfo;

    this()
    {
        timer = newEMM!Timer;
        prepareTests();
    }

    void idle()
    {
        if( current is null ) return;

        current.idle();

        changeInfo( wformat( "[%s] %s", current.name, current.info ) );

        if( current.complite )
        {
            info_log ~= wformat( "\n[%s] complite [%s]", current.name,
                                 current.success ? "success" : "fails" );
            changeInfoLog( info_log );
            current.clear();
            nextTest();
        }
    }

    void draw() { if( current !is null ) current.draw(); }

    void keyReaction( in KeyboardEvent ke )
    { if( current !is null ) current.keyReaction(ke); }

    void mouseReaction( in MouseEvent me )
    { if( current !is null ) current.mouseReaction(me); }

    void resize( ivec2 sz )
    { if( current !is null ) current.resize(sz); }

protected:

    void nextTest()
    {
        curno++;
        if( curno >= tests.length )
        {
            changeInfo( "all tests complited" );
            current = null;
        }
        else
        {
            current = tests[curno%$];
            current.init();
        }
    }
}

class EmptyTest : Test
{
    uint counter, limit;
    wstring _name;

    this( wstring n, uint l=1000 )
    {
        _name = n;
        limit = l;
    }

    void init() {}
    void clear() {}

    void idle() {}
    void draw() {}

    void keyReaction( in KeyboardEvent ) {}
    void mouseReaction( in MouseEvent ) {}
    void resize( ivec2 ) {}

    @property
    {
        wstring name() { return _name; }
        wstring info() { return wformat( "%d/%d", counter, limit ); }
        bool complite() { return counter++ > limit; }
        bool success() { return true; }
    }
}
