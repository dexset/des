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

/+
 + TEST TEST TEST
 +/

module desgui.ready.droplist;

import desgui.core.widget;
import desgui.core.label;
import desgui.core.layout;
import desgui.ready.button;

void log(size_t line=__LINE__,T...)( string fmt, T args )
{
    import std.stdio, std.string;
    stderr.writefln( "line % 4d: %s", line, format( fmt, args ) );
}

struct InertionChange(G=float)
{
    G cur, next;
    float T = 1.0f;

    void init( in G v, float t )
    { init(v), T = t; }

    void init( in G v )
    { cur = v; next = v; }

    auto opCall( float dt )
    {
        float cT = T;
        if( dt / cT > 1.0f ) cT = dt;
        cur += ( next - cur ) * ( dt / cT );
        return cur;
    }
}

class DataButton(Type): DiButton
{
    Type val;
    Signal!Type onClickData;

    this( DiWidget par, in irect r, wstring str, Type v )
    {
        super( par, r, str, { onClickData(val); } );
        val = v;
    }
}

class DiDropList: DiWidget
{
    size_t cur_selected = 0;

    bool drop = false;

    size_t base_height;
    size_t full_height;

    InertionChange!float in_h, h;

    void animUpdate( float dt )
    {
        h.next = drop ? full_height : base_height;
        in_h.next = drop ? 0 : cur_selected * base_height;
        bool check( in InertionChange!float ic, float v )
        {
            import std.math;
            return abs( ic.cur - ic.next ) >= v;
        }
        if( check( h, 1 ) )
            forceReshape( irect( rect.pos, rect.w, h(dt) ) );
        if( check( in_h, 1 ) )
            inner_offset.y = cast(int)-in_h(dt);

        parent.relayout();
    }

    Signal!size_t onSelect;

    this( DiWidget par, in irect r, wstring[] list )
    {
        super( par );

        reshape( r );
        size_lim.h.fix = true;
        base_height = r.h;
        full_height = r.h * list.length;

        in_h.init( 0, .1f );
        h.init( base_height, .1f );

        auto react = ( size_t v ) 
        { 
            cur_selected = v; 
            drop = !drop;
            if( !drop ) onSelect( cur_selected );
        };

        foreach( i, item; list )
        {
            auto buf = new DataButton!size_t( this, irect( 0, i*r.h, r.w, r.h ), item, i );
            buf.onClickData.connect( react );
        }

        auto ll = new DiLineLayout(DiLineLayout.Type.VERTICAL);
        ll.stretchDirect = false;
        layout = ll;

        import desutil.timer;
        auto tm = new Timer;
        idle.connect({ animUpdate( tm.cycle() ); });
        update();
    }
}
