module des.gui.base;

public
{
    import des.math.linear;

    import des.util.arch;
    import des.util.helpers;
    import des.util.logsys;
    import des.util.localization;
    import des.util.testsuite;
    import des.il.region;
}

alias DiRect=Region!(2,int);
alias DiVec=Vector!(2,int);

///
class DiException : Exception
{
    ///
    this( string msg, string file=__FILE__, size_t line=__LINE__ ) pure nothrow @safe
    { super( msg, file, line ); }
}

/// add binary flag
T binAdd(T)( in T a, in T b ) if( isIntegral!T ) { return a | b; }

/// remove binary flag
T binRemove(T)( in T a, in T b ) if( isIntegral!T ) { return a ^ ( a & b ); }

/// find binary flag ( b in a )
bool binFind(T)( in T a, in T b ) if( isIntegral!T ) { return ( a & b ) == b; }

unittest
{
    auto a = 0b0001;
    auto b = 0b0010;
    auto c = binAdd(a,b);
    assertEq( c, 0b0011 );
    assertEq( binRemove(c,a), b );
    assertEq( binRemove(c,b), a );
    assert( binFind(c,a) );
    assert( binFind(c,b) );
    auto x = 0b0100;
    assert( !binFind(c,x) );
}
