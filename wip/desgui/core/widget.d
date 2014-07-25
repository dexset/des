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

module desgui.core.widget;

public import desutil.signal;
public import desgui.core.event;
public import desgui.core.context;

import desutil.helpers;

alias ref const(ivec2) in_ivec2;
alias ref const(DiKeyboardEvent) in_DiKeyboardEvent;
alias ref const(DiTextEvent) in_DiTextEvent;
alias ref const(DiMouseEvent) in_DiMouseEvent;
alias ref const(DiJoyEvent) in_DiJoyEvent;

alias vrect!int irect;
alias ref const(irect) in_irect;

alias ConditionSignal!(in_ivec2, in_DiKeyboardEvent) CondDiKeyboardSignal;
alias ConditionSignal!(in_ivec2, in_DiTextEvent )    CondDiTextSignal;
alias ConditionSignal!(in_ivec2, in_DiMouseEvent)    CondDiMouseSignal;
alias ConditionSignal!(in_ivec2, in_DiJoyEvent)      CondDiJoySignal;
alias Signal!(in_irect) ReshapeSignal;

class DiWidgetException : DiException 
{ 
    this( string msg, string file=__FILE__, int ln=__LINE__ ) @safe pure nothrow
    { super( msg, file, ln ); } 
}

interface DiLayout { void opCall( in irect, DiWidget[] ); }

struct size_lim_t(T) if( isNumeric!T )
{
    lim_t!T w, h;
    auto opCall(A,B)( in A old, in B nval ) const
        if( isCompVector!(2,T,A) && isCompVector!(2,T,B) )
    { return vec!(2,T)( w( old[0], nval[0] ), h( old[1], nval[1] ) ); }
}

interface DiArea
{
    bool containts( in vec2 pnt ) const;
    final bool opBinaryRight(string op)( in vec2 pnt ) const 
        if( op == "in" )
    { return containts( pnt ); }
}

class DiWidget : DiViewport
{
private:
    irect bbox;

    /++ область отрисовки в собственных координатах +/
    irect draw_rect;
    
    class ActiveArea : DiArea
    {
        bool containts( in vec2 pnt ) const
        { return ( ivec2(pnt) in draw_rect ); }
    }

    /++ захват фокуса +/
    bool focus_grab = false;

    void prepare()
    {
        if( parent !is null ) parent.addChild( this );
        else if( ctx !is null )
        {
            // TODO
            //ctx.makeWindow( this );
        }
        else throw new DiWidgetException( "no parent and no context" );

        act_area = new ActiveArea;

        changeChildsList.connect({ relayout(); update(); });

        reshape.connect( (r) 
        {
            auto old_bbox_size = bbox.size;
            bbox.pos = r.pos;
            bbox.size = size_lim( bbox.size, r.size );
            if( old_bbox_size != bbox.size ) relayout();
            draw_rect = irect(0,0,bbox.size);
        });

        draw.addBegin({ draw_rect = ctx.drawStack.push( this ); });

        draw.addEnd(
        { 
            if( draw_rect.area > 0 )
                foreach_reverse( ch; childs ) 
                    if( ch !is null && !ch.isDestructed && ch.visible ) 
                        ch.draw();
            ctx.drawStack.pull();
        });

        static string prepareCond( string name )
        {
            import std.string, std.conv;
            enum fmt = `
            %1$s.addCondition( (mpos, ev) 
            {
                auto ff = find( mapToLocal( mpos ), EventCode.%2$s );
                if( cur != ff ) 
                {
                    if( cur !is null ) cur.release();
                    cur = ff;
                    if( cur !is null ) cur.activate();
                }
                return cur !is null;
            }, false );
            %1$s.connectAlt( (mpos, ev) 
            {
                if( cur !is null )
                    cur.%1$s( ivec2( mapToLocal( mpos ) ), ev );
            });`;
            return format( fmt, name, toUpper(name) );
        }

        mixin( prepareCond( "keyboard" ) );
        mixin( prepareCond( "mouse" ) );
        mixin( prepareCond( "joystick" ) );
        mixin( prepareCond( "evtext" ) );

        release.connect(
        {
            if( cur !is null ) cur.release(); 
            if( parent !is null && focus ) focus = false;
        });

        idle.connect({ foreach( ch; childs ) ch.idle(); });
        activate.connect({ if( cur !is null ) cur.activate(); });
        update.connect({ foreach( ch; childs ) ch.update(); });

        relayout.connect({ if( layout ) layout( rect, childs ); });
    }

protected:

    /+ область реакции в собственных координатах +/
    DiArea act_area;

    final void setContext( DiContext nctx )
    {
        ctx = nctx;
        foreach( ch; childs )
            ch.setContext( ctx );
    }

    final void addChild( DiWidget e )
    {
        if( e is null ) throw new DiWidgetException( "null child added" );

        void checkThis( DiWidget w )
        {
            if( w is this ) throw new DiWidgetException( "cycle parents" );
            foreach( ch; w.childs ) checkThis( ch );
        }
        checkThis( e );

        if( e.parent !is null ) e.parent.removeChilds( e );

        e.setContext( ctx );
        e.parent = this;
        childs ~= e;

        changeChildsList();
    }

    debug static DiWidget[] garbage;

    // удаляет из списка дочерних элементов елементы переданного списка
    final auto removeChilds( DiWidget[] list... )
    {
        DiWidget[] buf;
        DiWidget[] rem;

        m1:
        foreach( w; childs ) 
        {
            foreach( e; list )
                if( w is e || w is null || w.isDestructed ) 
                {
                    rem ~= w;
                    continue m1;
                }
            buf ~= w;
        }

        childs = buf;

        foreach( ref e; rem )
            if( e !is null ) 
                e.parent = null;

        if( rem.length ) 
            changeChildsList();

        debug garbage ~= rem;

        return rem;
    }

    EmptySignal changeChildsList;

    /++ пределы для размера bbox +/
    size_lim_t!int size_lim;

    /++ принудительное изменение размера bbox, вне зависимости от фиксированности +/
    final void forceReshape( in irect r )
    {
        bool fw = size_lim.w.fix;
        bool fh = size_lim.h.fix;
        size_lim.w.fix = false;
        size_lim.h.fix = false;
        reshape( r );
        size_lim.w.fix = fw;
        size_lim.h.fix = fh;
    }

    /++ обрабатывает ли элемент события +/
    ubyte processEventMask = EventCode.ALL;

    /++ контекст +/
    DiContext ctx;

    /++ родительский элемент +/
    DiWidget parent;

    /++ список дочерних элементов +/
    DiWidget[] childs;

    /++ текущий дочерний элемент +/
    DiWidget cur;

    /++ внутреннее смещение области для дочерних элементов +/
    ivec2 inner_offset = ivec2(0,0);

    vec2 inner_scale = vec2(1,1);

    final @property
    {
        bool focus() const { return focus_grab; }
        void focus( bool g )
        {
            if( focus_grab == g ) return;
            focus_grab = g;
            if( parent ) parent.focus = g;
        }
    }

    enum EventCode
    {
        NONE = cast(ubyte)0,
        KEYBOARD    = 0b0001,
        MOUSE       = 0b0010,
        JOYSTICK    = 0b0100,
        EVTEXT      = 0b1000,
        ALL         = ubyte.max
    }

    /++ поиск дочернего элемента по локальному положению мыши и коду события +/
    DiWidget find( in vec2 mpos, ubyte evcode=EventCode.ALL )
    {
        /+ если фокус захвачен, поиск не производится +/
        if( focus_grab ) return cur;

        foreach( v; childs )
        {
            if( v !is null && (v.processEventMask & evcode) && 
                v.is_visible && vec2(mpos-v.rect.pos) in v.activeArea )
                return v;
        }

        return null;
    }

    bool is_visible = true;

public:

    this( DiWidget par )
    {
        parent = par;
        prepare();
    }

    this( DiContext context )
    {
        parent = null;
        ctx = context;
        prepare();
    }

    @property
    {
        nothrow bool visible() const { return is_visible; }

        void visible( bool vis ) 
        {
            if( is_visible != vis )
            {
                is_visible = vis; 
                if( parent ) parent.relayout();
                if( !vis ) release(); 
            }
        }

        nothrow irect drawRect() const { return draw_rect; }

        vec2 offset() const { return vec2(inner_offset); }
        void offset( in vec2 o ) { inner_offset = ivec2(o); }

        vec2 scale() const { return inner_scale; }
        void scale( in vec2 s ) { inner_scale = s; }

        const(DiArea) activeArea() const { return act_area; }

        final
        {
            /++ возвращает копию прямоугольника +/
            irect rect() const { return bbox; }

            /++ вызывает сигнал reshape +/
            void rect( in irect r ) { reshape( r ); }

            /++ возвращает копию пределов размера прямоугольника +/
            nothrow size_lim_t!int lims() const { return size_lim; }
        }
    }

    void reparent( DiWidget npar )
    {
        parent.removeChilds( this );
        npar.addChild( this );
    }

    ReshapeSignal reshape;

    DiLayout layout;
    EmptySignal relayout;
                             
    EmptySignal activate;
    EmptySignal release;
    EmptySignal update;

    EmptySignal idle;

    SignalBoxNoArgs draw;

    CondDiKeyboardSignal keyboard;
    CondDiMouseSignal mouse;
    CondDiJoySignal joystick;
    CondDiTextSignal evtext;

    EmptySignal onDestruct;

    final void destruct()
    {
        onDestruct();

        release();
        if( focus ) focus = 0;

        foreach( ref ch; childs ) ch.parent = null;
        childs.length = 0;

        if( parent ) parent.removeChilds( this );

        reshape.clear();
        relayout.clear();
        activate.clear();
        release.clear();
        update.clear();
        idle.clear();
        draw.clear();
        keyboard.clear();
        mouse.clear();
        joystick.clear();
        evtext.clear();
        changeChildsList.clear();
        onDestruct.clear();

        parent = null;
        destructed = true;
    }

    private bool destructed = false;
    final @property bool isDestructed() const { return destructed; }
}

unittest
{
    auto ctx = new TestContext;
    scope par = new DiWidget( ctx );
    par.reshape( irect(0,0,100,100) );
    assert( par.rect == irect(0,0,100,100) );
    par.reshape( irect(8,5,20,14) );
    assert( par.rect == irect(8,5,20,14) );

    assert( par.visible );
    par.reshape( irect(0,0,0,0) );
    assert( par.visible );

    par.reshape( irect(0,0,100,100) );

    assert( par.drawRect == par.rect );
    assert( par.offset == vec2(0,0) );

    par.draw();
    assert( par.drawRect == par.rect );

    bool resh = false;
    par.reshape.connect((r){ resh = true; });
    assert( !resh );
    par.rect = par.rect;
    assert( resh );

    par.visible = false;
    assert( !par.visible );
    par.visible = true;

    scope ch1 = new DiWidget( par );
    assert( ch1.visible );
    assert( par.childs.length == 1 );
    assert( ch1.parent is par );

    par.removeChilds( ch1 );
    assert( par.childs.length == 0 );
    assert( ch1.parent is null );

    par.addChild( ch1 );
    assert( par.childs.length == 1 );
    assert( ch1.parent is par );

    scope ctx2 = new TestContext;
    scope par2 = new DiWidget( ctx2 );

    ch1.reparent( par2 );
    assert( par.childs.length == 0 );
    assert( par2.childs.length == 1 );
    assert( ch1.parent is par2 );

    foreach( i; 0 .. 100 )
        auto cc = new DiWidget( par );

    void sig()
    {
        par.activate();
        par.update();
        par.idle();
        par.draw();
        par.release();
    }

    sig();

    par.removeChilds( par.childs );
    assert( par.childs.length == 0 );

    sig();

    DiWidget[] list;
    DiKeyboardEvent check;
    auto origin = DiKeyboardEvent( true, false, 0, 1, 2 );
    ivec2 mpos;
    foreach( i; 0 .. 100 )
    {
        auto cc = new DiWidget( par );
        if( i == 33 ) 
        {
            cc.keyboard.connect((m,e){ mpos = m; check = e; });
            cc.reshape( irect(10,10,10,10) );
        }
        list ~= cc;
    }
    assert( par.childs.length == 100 );

    par.keyboard( ivec2( 15, 15 ), origin );
    assert( check == origin );
    assert( mpos == ivec2(15,15) );
    mpos = ivec2( 666,666 );
    check = DiKeyboardEvent( true, false, 2, 0, 1 );

    foreach( i; 50 .. 100 )
        list[i].reparent( par2 );

    par.offset = vec2(5,5);
    par.keyboard( ivec2( 15, 15 ), origin );
    assert( check == origin );
    assert( mpos == ivec2(10,10) );
    mpos = ivec2( 666,666 );
    check = DiKeyboardEvent( true, false, 2, 0, 1 );

    par.reshape( irect(-2,-2,100,100) );
    par.keyboard( ivec2( 15, 15 ), origin );
    assert( check == origin );
    assert( mpos == ivec2(12,12) );
    mpos = ivec2( 666,666 );
    check = DiKeyboardEvent( true, false, 2, 0, 1 );

    sig();

    par.removeChilds( par.childs );
    par.keyboard( ivec2( 15, 15 ), origin );
    assert( check != origin );

    assert( par.childs.length == 0 );
    assert( par2.childs.length == 51 );
}

unittest
{
    auto ctx = new TestContext;
    scope par = new DiWidget( ctx );
    par.reshape( irect(20,20,100,40) );
    par.scale = vec2(0.5,0.5);
    ivec2 mpos = ivec2(24,29);
    assert( par.mapToLocal(mpos) == vec2(8,18) );
    par.offset = vec2(18,32);
    assert( par.mapToLocal(mpos) == vec2(-28,-46) );
}
