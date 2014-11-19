module window;

import des.app;
import des.gl.simple;
import des.util.helpers;
import des.il.region;

class UsableWindow : GLWindow
{
protected:
    KeyboardEventProcessor keyproc;
    WindowEventProcessor   winproc;
    MouseEventProcessor    mouseproc;

    override void prepare()
    {
        idle.connect({ glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT ); });

        keyproc.key.connect( ( in KeyboardEvent ev )
        { if( ev.scan == ev.Scan.ESCAPE ) app.quit(); });

        winproc.resized.connect(( ivec2 sz )
        { 
            _size = sz;
            glViewport( 0, 0, sz.x, sz.y ); 
        });
    }

public:

    this( string title, ivec2 sz, bool fs = false )
    {
        super( title, sz, fs );
        keyproc   = addEventProcessor( new KeyboardEventProcessor );
        winproc   = addEventProcessor( new WindowEventProcessor );
        mouseproc = addEventProcessor( new MouseEventProcessor );
    }
}

class MainWindow : UsableWindow
{
protected:
    override void prepare()
    { 
        auto text_box = newEMM!TextBox( appPath( "default.ttf" ) );
        text_box.text = "Hello world"w;
        text_box.setRect( fRegion2( 0, 0, 200, 100 ) );
        text_box.setColor( col4( 1.0, 0.0, 0.0, 1.0 ), col4( 1.0, 1.0, 0.0, 1.0 ),
                           col4( 1.0, 1.0, 0.0, 1.0 ), col4( 0.0, 1.0, 0.0, 1.0 ) );
        //text_box.isStretched( true );

        draw.connect( 
        {
            text_box.draw( _size );
        });

        super.prepare(); 
    }

public:
    this()
    { 
        super( "example", ivec2(800,600), false );//title, win_size, fullscreen 
    }
}
