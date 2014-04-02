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

module desutil.pdata;

import std.traits;
import std.string;

alias immutable(ubyte)[] imbyte;

private pure imbyte pureDumpData(T)( in T val )
{
    static if( is( T == PData ) || is( T == shared PData ) )
        return val.data.idup;
    else static if( isArray!T )
        return cast(imbyte)val.idup;
    else static if( !hasUnsharedAliasing!T )
        return cast(imbyte)[val].idup;
    else static assert( 0, format( "unsupported type '%s' for pure read data", T.stringof ) );
}

@property @safe pure nothrow isPureDump(T)()
{ return is( typeof( pureDumpData( T.init ) ) ); }

unittest
{
    static assert( isPureDump!(imbyte) );
    static assert( isPureDump!(string) );
    static assert( isPureDump!(double) );
    static assert( isPureDump!(PData) );
    static assert( isPureDump!(double[]) );
    static assert( !isPureDump!(int[string]) );

    static struct TS { int[string] val; }
    static assert( !isPureDump!(TS) );
}

private T conv(T)( in imbyte data )
{
    static if( isArray!T )
        return cast(T)data.dup;
    else static if( !hasUnsharedAliasing!T )
        return (cast(T[])data.dup)[0];
    else static if( __traits(compiles, T.load(data)) )
        return T.load(data);
    else static assert( 0, format( "unsupported type '%s'", T.stringof ) );
}

struct PData
{
    imbyte data;

    private void readData(T)( in T val )
    {
        static if( isPureDump!T ) 
            data = pureDumpData( val );
        else static if( __traits(compiles, val.dump()) )
            data = val.dump().idup;
        else static assert( 0, format( "unsupported type '%s'", T.stringof ) );
    }

    pure this( in ubyte[] dd ) { data = dd.idup; }

    pure this(T)( in T val ) if( isPureDump!T ) 
    { data = pureDumpData( val ); }

    this(T)( in T val ) if( !isPureDump!T ) 
    { readData( val ); }

    T opAssign(T)( in T val )
    {
        readData( val );
        return val;
    }

    @property
    {
        T as(T)() const { return conv!T( data ); }
        T as(T)() shared const { return conv!T( data ); }
        T as(T)() immutable { return conv!T( data ); }
    }
}

unittest
{
    auto a = PData( [ .1, .2, .3 ] );
    assert( a.as!(double[]) == [ .1, .2, .3 ] );
    a = "hello";
    assert( a.as!string == "hello" );

    static struct TestStruct 
    { double x, y; string info; immutable(int)[] data; }
    auto ts = TestStruct( 10.1, 12.3, "hello", [1,2,3,4] );

    auto xx = PData( ts );

    auto xa = shared PData( xx );
    auto xb = const PData( xx );
    auto xc = shared const PData( xx );
    auto xd = immutable PData( xx );
    auto xe = shared immutable PData( xx );

    assert( xx == xa );
    assert( xx == xb );
    assert( xx == xc );
    assert( xx == xd );
    assert( xx == xe );

    assert( xa.as!TestStruct == ts );
    assert( xb.as!TestStruct == ts );
    assert( xc.as!TestStruct == ts );
    assert( xd.as!TestStruct == ts );
    assert( xe.as!TestStruct == ts );

    auto ax = PData( xa );
    auto bx = PData( xb );
    auto cx = PData( xc );
    auto dx = PData( xd );
    auto ex = PData( xe );

    assert( xx == ax, "xx != ax" );
    assert( xx == bx, "xx != bx" );
    assert( xx == cx, "xx != cx" );
    assert( xx == dx, "xx != dx" );
    assert( xx == ex, "xx != ex" );

    assert( ax.as!TestStruct == ts );
    assert( bx.as!TestStruct == ts );
    assert( cx.as!TestStruct == ts );
    assert( dx.as!TestStruct == ts );
    assert( ex.as!TestStruct == ts );
}

unittest
{
    import std.conv;
    static class TestClass
    {
        int[string] info;

        static auto load( in ubyte[] data )
        {
            auto str = cast(string)data.dup;
            auto elems = str.split(",");
            int[string] buf;
            foreach( elem; elems )
            {
                auto key = elem.split(":")[0];
                auto val = to!int( elem.split(":")[1] );
                buf[key] = val;
            }
            return new TestClass( buf );
        }

        this( in int[string] I ) 
        { 
            foreach( key, val; I )
                info[key] = val;
            info.rehash();
        }

        auto dump() const
        {
            string[] buf;
            foreach( key, val; info ) buf ~= format( "%s:%s", key, val );
            return cast(ubyte[])( buf.join(",").dup );
        }
    }

    auto tc = new TestClass( [ "ok":1, "no":3, "yes":5 ] );

    auto a = PData( tc );
    auto ta = a.as!TestClass;
    assert( ta.info == tc.info );

    auto b = a;
    b = "ok:1,no:3";
    auto tb = b.as!TestClass;
    tc.info.remove( "yes" );

    assert( tb.info == tc.info );

    tc.info["yes"] = 5;
    b = a;
    tb = b.as!TestClass;
    assert( tb.info == tc.info );
}

unittest
{
    auto fnc_a() { return cast(immutable(ubyte)[])("hello_a".idup); }
    auto fnc_b() { return cast(ubyte[])("hello_b".dup); }
    auto a = PData( fnc_a() );
    assert( a.as!string == "hello_a" );
    auto b = PData( fnc_b() );
    assert( b.as!string == "hello_b" );

    auto ca = const PData( fnc_a() );
    assert( ca.as!string == "hello_a" );
    auto cb = const PData( fnc_b() );
    assert( cb.as!string == "hello_b" );

    auto ia = immutable PData( fnc_a() );
    assert( ia.as!string == "hello_a" );
    auto ib = immutable PData( fnc_b() );
    assert( ib.as!string == "hello_b" );

    auto sa = shared PData( fnc_a() );
    assert( sa.as!string == "hello_a" );
    auto sb = shared PData( fnc_b() );
    assert( sb.as!string == "hello_b" );

    auto sca = shared const PData( fnc_a() );
    assert( sca.as!string == "hello_a" );
    auto scb = shared const PData( fnc_b() );
    assert( scb.as!string == "hello_b" );

    auto sia = shared immutable PData( fnc_a() );
    assert( sia.as!string == "hello_a" );
    auto sib = shared immutable PData( fnc_b() );
    assert( sib.as!string == "hello_b" );
}
