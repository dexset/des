module des.gui.widget;

import des.gui.shape;
import des.gui.base;
import des.gui.context;
import des.gui.canvas;
import des.gui.event;
import des.gui.layout;

import des.util.stdext.algorithm : amap;

///
class DiWidget : DesObject, TNode!(DiWidget,"diw_",""), DiLayoutItem
{
    mixin DES;
    mixin diw_TNodeHelper!(true,true);
    mixin ClassLogger;

private:

    bool base_ctor_finish, start_destroy;

protected:

    ///
    DiShape _shape;

    ///
    DiContext _context;
    ///
    DiCanvas _canvas;

    ///
    DiWidget current;

    ///
    DiLayout layout;

    /// create childs widgets, set params, etc
    void prepare() {}

    /// call when context is changed
    void updateContextDeps() {}

    /// create shape object (default rect)
    DiShape createShape() { return new DiRectShape; }

    ///
    bool _visible, _enable, _active, _focus;

public:

    dstring name;

    Signal!DiWidget onChangeVisible;
    Signal!DiWidget onChangeEnable;
    Signal!DiWidget onChangeActive;
    Signal!DiWidget onChangeFocus;

    invariant()
    {
        if( !base_ctor_finish || start_destroy ) return;

        enforce( _shape !is null );

        enforce( ( _canvas is null && _context is null ) ||
                ( _canvas !is null && _context !is null ) );

        enforce( ( _context is null && __diw_parent_node !is null ) ||
                ( _context !is null && __diw_parent_node is null ) );
    }

    ///
    this( DiWidget par )
    in { assert( par !is null ); } body
    {
        _shape = registerChildEMM( createShape );
        diw_parent = par;

        base_ctor_finish = true;

        prepare();
        updateContextDeps();
    }

    ///
    this( DiContext ctx )
    in { assert( ctx !is null ); } body
    {
        _context = ctx;
        _shape = registerChildEMM( createShape );
        _canvas = _context.createTop( this );

        prepare();
        updateContextDeps();

        base_ctor_finish = true;
    }

    ///
    void setContext( DiContext ctx )
    in { assert( ctx !is null ); } body
    {
        auto old_context = context;

        diw_parent = null;

        if( _context !is null )
            _context.removeTop( this );

        _context = ctx;

        _canvas = _context.createTop( this );

        if( old_context != context )
            updateContextDeps();
    }

    ///
    void setParent( DiWidget par )
    in { assert( par !is null ); } body
    {
        auto old_context = context;

        if( _context !is null )
        {
            _context.removeTop( this );
            _context = null;
            _canvas = null;
        }

        diw_parent = par;

        if( old_context != context )
            updateContextDeps();
    }

    @property
    {
        ///
        DiContext context()
        {
            if( diw_parent is null ) return _context;
            else return diw_parent.context;
        }

        ///
        DiCanvas canvas()
        {
            if( diw_parent is null ) return _canvas;
            else return diw_parent.canvas;
        }

        ///
        DiShape shape() { return _shape; }
        ///
        const(DiShape) shape() const { return _shape; }

        /// easy access to shape pos
        DiVec pos() const { return shape.pos; }
        /// ditto
        DiVec pos( in DiVec p )
        {
            shape.rect = DiRect( p, shape.size );
            return p;
        }

        /// easy access to shape size
        DiVec size() const { return shape.size; }
        /// ditto
        DiVec size( in DiVec s )
        {
            shape.rect = DiRect( shape.pos, s );
            return s;
        }
    }

    ///
    void update()
    {
        selfUpdate();
        foreach( ch; diw_childs )
            ch.update();
    }

    ///
    void render()
    in{ assert( canvas !is null ); } body
    {
        auto visible_rect = canvas.pushDrawRect( shape.rect );
        selfRender();
        foreach( ch; diw_childs )
            if( ch.shape.intersect( visible_rect ) )
                ch.render();
        canvas.popDrawRect();
    }

    ///
    void relayout()
    {
        if( layout && diw_childs.length )
            layout( shape, cast(DiLayoutItem[])diw_childs );
    }

    ///
    void processInput( in DiInputEvent ev )
    {
        if( actionOnEvent( ev ) ) return;

        setCurrent( findChildByEvent( ev ) );

        if( current !is null )
            current.processInput( ev );
    }

    @property
    {
        ///
        bool visible() const { return _visible; }
        ///
        bool visible( bool nc )
        {
            _visible = nc;
            onChangeVisible( this );
            return nc;
        }

        ///
        bool enable() const { return _enable; }
        ///
        bool enable( bool nc )
        {
            _enable = nc;
            onChangeEnable( this );
            return nc;
        }

        ///
        bool active() const { return _active; }
        ///
        bool active( bool nc )
        {
            _active = nc;
            onChangeActive( this );
            return nc;
        }

        ///
        bool focus() const { return _focus; }
        ///
        bool focus( bool nc )
        {
            _focus = nc;
            onChangeFocus( this );
            return nc;
        }
    }

protected:

    ///
    void selfUpdate() { }

    /// draw something on canvas or direct GL calls
    void selfRender() { }

    /// if do some action return true, false otherwise
    bool actionOnEvent( in DiInputEvent ev )
    { return false; }

    ///
    DiWidget findChildByEvent( in DiInputEvent ev )
    {
        // TODO
        return null;
    }

    override void selfDestroy()
    {
        start_destroy = true;
        diw_detachChilds( diw_childs );
    }

    override void diw_attachCallback( DiWidget[] list )
    { relayout(); }

    override void diw_detachCallback( DiWidget[] list )
    { relayout(); }

private:

    void setCurrent( DiWidget new_current )
    {
        if( current == new_current ) return; // do nothing

        if( current !is null ) current.active = false;

        current = new_current;

        if( current !is null ) current.active = true;
    }
}
