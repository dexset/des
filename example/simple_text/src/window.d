module window;

import des.app;
import des.gl.simple;
import des.util.helpers;
import des.il.region;

class MainWindow : DesWindow
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

        connect( draw, 
        {
            text_box.draw( _size );
        });
    }

public:
    this()
    { 
        super( "example", ivec2(800,600), false );//title, win_size, fullscreen 
    }
}
