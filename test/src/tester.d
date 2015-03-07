module tester;

import des.gl;
import des.util.arch;
import des.util.timer;

import tests;

interface Test
{
    void idle();
    void draw();

    @property
    {
        wstring name();
        wstring info();
        bool complite();
    }
}

class Tester : DesObject
{
    mixin DES;
protected:

    Timer timer;

    Test[] test;
    size_t cur;

    wstring info_log;

    void prepareTests()
    {
        test ~= newEMM!EmptyTest( "empty test"w );
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
        if( cur >= test.length ) return;

        test[cur%$].idle();

        changeInfo( wformat( "[%s] %s", test[cur%$].name, test[cur%$].info ) );

        if( test[cur%$].complite )
        {
            info_log ~= wformat( "\n[%s] complite", test[cur%$].name );
            changeInfoLog( info_log );
            cur++;
        }

        if( cur >= test.length ) changeInfo( "all tests complited" );
    }

    void draw() { test[cur%$].draw(); }
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

    void idle() { }
    void draw() { }

    @property
    {
        wstring name() { return _name; }
        wstring info() { return wformat( "%d/%d", counter, limit ); }
        bool complite() { return counter++ > limit; }
    }
}
