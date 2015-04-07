module mwidget;

import des.gui;

class MainWidget : DiWidget
{
    this( DiContext ctx )
    {
        name = "test gui"d;
        super( ctx );
    }

protected:

    override void prepare()
    {
        diw_attachChilds( newEMM!ChildWidget( this ) );
    }

    override void selfUpdate()
    {
    }

    override bool actionOnEvent( in DiInputEvent ev )
    {
        switch( ev.type )
        {
            case SDL_KEYDOWN:
                if( ev.key.keysym.sym == SDLK_ESCAPE )
                    context.quit();
                return true;
            default: return false;
        }
    }

    override DiWidget findChildByEvent( in DiInputEvent ev )
    {
        switch( ev.type )
        {
            case SDL_MOUSEMOTION:
                auto e = ev.motion;
                foreach( ch; diw_childs )
                    if( ch.shape.contains( ivec2( e.x, e.y ) ) )
                        return ch;
                return null;
            default: return current;
        }
    }

    override void selfRender()
    {
        glClearColor( 0,0,0,0 );
        glClear( GL_COLOR_BUFFER_BIT );
    }
}

class ChildWidget : DiWidget
{
    this( DiWidget par )
    {
        name = "test child"d;
        super( par );
    }

protected:

    override void prepare()
    {
        shape.rect = DiRect( 10, 10, 40, 40 );
    }

    override void selfUpdate()
    {
    }

    override DiWidget findChildByEvent( in DiInputEvent ev )
    {
        switch( ev.type )
        {
            case SDL_MOUSEBUTTONDOWN:
                context.quit();
                goto default;
            default: return current;
        }
    }

    override void selfRender()
    {
        if( active )
            glClearColor( 1,0,0,1 );
        else
            glClearColor( 1,1,0,1 );
        glClear( GL_COLOR_BUFFER_BIT );
    }
}
