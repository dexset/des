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
module desgui.core.layout;

import desgui.core.widget;
import desutil.helpers : lim_t;

class DiLineLayout : DiLayout
{
    enum Type { HORISONTAL, VERTICAL }
    enum Align { START, CENTER, END }

    Align alignDirect = Align.START; 
    Align alignInderect = Align.CENTER;

    Type type;
    int border;
    int space;

    bool stretchDirect = true;
    bool stretchInderect = true;

    pure this( Type t = Type.HORISONTAL ) { type = t; }

    void opCall( in irect pr, DiWidget[] wlist )
    {
        import std.stdio;
        DiWidget[] nl;
        foreach( w; wlist ) 
            if( w !is null && w.visible )
                nl ~= w;
        wlist = nl;

        bool hor = type == Type.HORISONTAL;
        int full_size = hor ? pr.w : pr.h;

        int ind_size = hor ? pr.h : pr.w;

        int dim_dir( DiWidget z ) { return hor ? z.rect.w : z.rect.h; }
        int dim_ind( DiWidget z ) { return hor ? z.rect.h : z.rect.w; }

        lim_t!int lim_dir( DiWidget z ) { return hor ? z.lims.w : z.lims.h; }
        lim_t!int lim_ind( DiWidget z ) { return hor ? z.lims.h : z.lims.w; }

        void new_rect( DiWidget widget, int dir_p, int dir_s )
        {
            int b2 = border * 2;
            auto li = lim_ind(widget);
            int ind_s = stretchInderect ? ind_size - b2 : dim_ind(widget);

            ind_s = li( dim_ind(widget), ind_s );

            auto size = hor ? ivec2( dir_s, ind_s ) : ivec2( ind_s, dir_s );
            int ind_p;
            final switch( alignInderect ) 
            {
                case Align.START:  ind_p = border; break;
                case Align.CENTER: ind_p = ( ind_size - ind_s ) / 2; break;
                case Align.END:    ind_p = ind_size - ind_s - border; break; 
            }
            auto pos = hor ? ivec2( dir_p, ind_p ) : ivec2( ind_p, dir_p );

            widget.reshape( irect( pos, size ) );
        }

        int calcStartOffset( int summ_size )
        {
            final switch( alignDirect )
            {
                case Align.START:  return border;
                case Align.CENTER: return ( full_size - summ_size ) / 2;
                case Align.END:    return full_size - summ_size - border;
            }
        }

        int summ_size = full_size;
        int sess; // single element stretch size
        int space_size = space * (cast(int)wlist.length - 1);

        if( stretchDirect )
        {
            int fix_size = 0;
            int fix_cnt = 0;

            foreach( widget; wlist )
            {
                int fix = cast(int)( lim_dir(widget).fix );
                fix_cnt += fix;
                fix_size += dim_dir( widget ) * fix;
            }

            summ_size = space_size + fix_size;

            int stretch_cnt = cast(int)( wlist.length - fix_cnt );
            int stretch_size_base = full_size - fix_size - space_size - border*2;

            int[2][size_t] limit_sizes;

            bool calcFunc( bool recalcSESS=false )
            {
                int limit_size = 0;
                foreach( key, val; limit_sizes )
                    limit_size += val[0];

                int stretch_size = stretch_size_base - limit_size;

                if( stretch_size < 0 ) 
                {
                    sess = 0;
                    return true;
                }

                int limit_cnt = cast(int)(limit_sizes.length);

                if( (stretch_cnt - limit_cnt) > 0 ) 
                    sess = stretch_size / (stretch_cnt - limit_cnt);
                else return true;

                if( recalcSESS ) return true; 

                summ_size = space_size;

                bool ok = true;
                foreach( i, widget; wlist )
                {
                    int dir_s = (lim_dir(widget))( dim_dir(widget), sess );
                    summ_size += dir_s;
                    if( !( lim_dir(widget).fix ) )
                    {
                        auto diff = sess - dir_s;
                        if( i in limit_sizes && diff == limit_sizes[i][1] )
                            continue;
                        if( diff != 0 )
                        {
                            limit_sizes[i] = [ dir_s, diff ];
                            ok = false;
                        }
                    }
                }
                if( limit_sizes.length == stretch_cnt ) return true;
                return ok;
            }

            while( !calcFunc() ){}
        }
        else
        {
            summ_size = space_size;
            foreach( widget; wlist ) 
                summ_size += dim_dir(widget);
        }

        int offset = calcStartOffset( summ_size );
        foreach( widget; wlist )
        {
            new_rect( widget, offset, 
                    ( !stretchDirect || lim_dir(widget).fix ) ? 
                                              dim_dir(widget) : sess );
            offset += space + dim_dir(widget);
        }
    }
}

version( unittest )
{
    private class MyWidget: DiWidget
    {
        this( DiWidget par )
        {
            super( par );
            reshape(irect( 0, 0, 20, 25 ));
            size_lim.h.fix = true; 
        }
    }
}

unittest
{
    auto ctx = new TestContext;
    auto l = new DiLineLayout();
    scope par = new DiWidget( ctx );
    par.reshape( irect( 0, 0, 500, 50 ) );

    par.layout = l;

    DiWidget[5] ch;
    foreach( ref c; ch )
        c = new DiWidget( par );

    assert( ch[0].rect == irect(   0, 0, 100, 50 ) );
    assert( ch[1].rect == irect( 100, 0, 100, 50 ) );
    assert( ch[2].rect == irect( 200, 0, 100, 50 ) );
    assert( ch[3].rect == irect( 300, 0, 100, 50 ) );

    import std.string;
    pragma( msg, format( "%s at %s #%d", "breaking tests", __FILE__, __LINE__ ) );
    //assert( ch[4].rect == irect( 400, 0, 100, 50 ) );

    l.type = l.Type.VERTICAL;
    par.reshape( irect( 0, 0, 50, 500 ) );

    assert( ch[0].rect == irect( 0,   0, 50, 100 ) );
    assert( ch[1].rect == irect( 0, 100, 50, 100 ) );
    assert( ch[2].rect == irect( 0, 200, 50, 100 ) );
    assert( ch[3].rect == irect( 0, 300, 50, 100 ) );
    assert( ch[4].rect == irect( 0, 400, 50, 100 ) );

    foreach( c; ch )
        c.reshape( irect( 0, 0, 10, 15 ) );

    l.stretchDirect = false;
    l.stretchInderect = false;

    l.alignInderect = l.Align.START;
    l.alignDirect = l.Align.START;
    par.relayout();

    assert( ch[0].rect == irect( 0,  0, 10, 15 ) );
    assert( ch[1].rect == irect( 0, 15, 10, 15 ) );
    assert( ch[2].rect == irect( 0, 30, 10, 15 ) );
    assert( ch[3].rect == irect( 0, 45, 10, 15 ) );
    assert( ch[4].rect == irect( 0, 60, 10, 15 ) );

    l.alignInderect = l.Align.CENTER;
    l.alignDirect = l.Align.CENTER;
    par.relayout();

    assert( ch[0].rect == irect( 20, 212, 10, 15 ) );
    assert( ch[1].rect == irect( 20, 227, 10, 15 ) );
    assert( ch[2].rect == irect( 20, 242, 10, 15 ) );
    assert( ch[3].rect == irect( 20, 257, 10, 15 ) );
    assert( ch[4].rect == irect( 20, 272, 10, 15 ) );

    l.alignInderect = l.Align.END;
    l.alignDirect = l.Align.END;
    par.relayout();

    assert( ch[0].rect == irect( 40, 425, 10, 15 ) );
    assert( ch[1].rect == irect( 40, 440, 10, 15 ) );
    assert( ch[2].rect == irect( 40, 455, 10, 15 ) );
    assert( ch[3].rect == irect( 40, 470, 10, 15 ) );
    assert( ch[4].rect == irect( 40, 485, 10, 15 ) );

    l.space = 2;
    par.relayout();

    assert( ch[0].rect == irect( 40, 417, 10, 15 ) );
    assert( ch[1].rect == irect( 40, 434, 10, 15 ) );
    assert( ch[2].rect == irect( 40, 451, 10, 15 ) );
    assert( ch[3].rect == irect( 40, 468, 10, 15 ) );
    assert( ch[4].rect == irect( 40, 485, 10, 15 ) );

    l.border = 2;
    par.relayout();

    assert( ch[0].rect == irect( 38, 415, 10, 15 ) );
    assert( ch[1].rect == irect( 38, 432, 10, 15 ) );
    assert( ch[2].rect == irect( 38, 449, 10, 15 ) );
    assert( ch[3].rect == irect( 38, 466, 10, 15 ) );
    assert( ch[4].rect == irect( 38, 483, 10, 15 ) );

    l.stretchDirect = true;
    l.stretchInderect = true;
    l.space = 0;
    l.border = 0;

    clear( ch[0] );
    clear( ch[2] );
    clear( ch[4] );

    ch[0] = new MyWidget( par );
    ch[2] = new MyWidget( par );
    ch[4] = new MyWidget( par );

    par.relayout();

    assert( ch[1].rect == irect( 0,   1, 50, 212 ) );
    assert( ch[3].rect == irect( 0, 213, 50, 212 ) );
    assert( ch[0].rect == irect( 0, 425, 50, 25 ) );
    assert( ch[2].rect == irect( 0, 450, 50, 25 ) );
    assert( ch[4].rect == irect( 0, 475, 50, 25 ) );
}
