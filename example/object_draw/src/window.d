module window;

import des.app;
import des.util.logsys;

import camera;
import draw;

class MainWindow : DesWindow
{
protected:
    MCamera cam;
    Sphere obj;

    override void prepare()
    {
        cam = new MCamera;

        obj = newEMM!Sphere( 1, 12, 12 );

        connect( draw, { obj.draw( cam ); } );
        connect( key, &keyControl );
        connect( mouse, &(cam.mouseReaction) );

        connect( event.resized, (ivec2 sz)
        { cam.ratio = cast(float)sz.w / sz.h; } );
    }

    void keyControl( in KeyboardEvent ke )
    { if( ke.scan == ke.Scan.ESCAPE ) app.quit(); }

public:
    this() { super( "example", ivec2(800,600), false ); }
}
