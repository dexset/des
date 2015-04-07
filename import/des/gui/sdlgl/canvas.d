module des.gui.sdlgl.canvas;

import des.gui.sdlgl.base;

alias iRect=Region!(2,int);

struct ViewPair
{
    iRect crd;
    iRect vis;
}

class DiGLCanvas : DiCanvas
{
    DrawRectControl drc;

    this() { drc = new DrawRectControl; }

    void prepare()
    {
        glEnable( GL_SCISSOR_TEST );
    }

    void resize( ivec2 sz ) { drc.setOrigin( sz ); }

    void preDraw()
    {
        auto w = drc.origin.size.w;
        auto h = drc.origin.size.h;
        glClearColor( 0,0,0,0 );
        setView( drc.stack[0] );
        glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    }

    void postDraw() { }

    DiRect pushDrawRect( DiRect r )
    {
        auto ret = drc.push( iRect( r ) );
        setInvView( drc.last );
        return ret;
    }

    void popDrawRect()
    {
        drc.pop();
        //setInvView( drc.last );
    }

protected:

    void setInvView( in ViewPair np )
    {
        auto p = invYCoord( np );
        setView( p );
    }

    ViewPair invYCoord( in ViewPair vp )
    { return ViewPair( invYCoord(vp.crd), invYCoord(vp.vis) ); }

    iRect invYCoord( in iRect r )
    {
        auto h = drc.origin.size.y;
        return iRect( r.pos.x, h - r.pos.y - r.size.y, r.size );
    }

    void setView( in ViewPair p )
    {
        glViewport( p.crd.pos.x, p.crd.pos.y, p.crd.size.w, p.crd.size.h );
        glScissor( p.vis.pos.x, p.vis.pos.y, p.vis.size.w, p.vis.size.h  );
    }
}

class DrawRectControl
{
    iRect origin;

    ViewPair[] stack;

    this() { origin.pos = ivec2(0); }

    void setOrigin( ivec2 sz )
    {
        origin.size = sz;
        stack.length = 0;
        stack ~= ViewPair( origin, origin );
    }

    iRect push( in iRect rr )
    {
        auto r = iRect( rr.pos + last.crd.pos, rr.size );
        auto o = last.vis.overlap(r);
        stack ~= ViewPair( r, o );
        return iRect( o.pos - last.crd.pos, o.size );
    }

    void pop() { stack.length--; }

    ref const(ViewPair) last() const @property
    { return stack[$-1]; }
}
