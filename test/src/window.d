module window;

import des.app;
import des.gl;
import des.il.region;
import des.util.helpers;
import des.util.timer;

import tester;

class MainWindow : DesWindow
{
protected:

    FPSCounter fps_counter;

    BaseLineTextBox fps_output;
    BaseLineTextBox info_log;
    BaseLineTextBox info;

    Tester tester;

public:

    this()
    {
        super( "example", ivec2(800,600), false );//title, win_size, fullscreen
    }

protected:

    override void prepare()
    {
        prepareTextOutput();
        prepareTester();

        connect( draw,
        {
            tester.draw();

            fps_output.draw( _size );
            info_log.draw( _size );
            info.draw( _size );
        });

        connect( idle,
        {
            tester.idle();

            fps_output.text = format( "fps: %5.1f\nres: %dx%d",
                    fps_counter.update(), _size.x, _size.y );

            fps_output.position = vec2( _size.x - fps_output.rectangle.size.x - 10, 24 );
            info.position = vec2( 10, _size.y - info.rectangle.size.y - 4 );
            info_log.position = vec2( 10, _size.y - info_log.rectangle.size.y - 38 );
        });

        connect( key, ( in KeyboardEvent ke )
        {
            if( ke.scan == ke.Scan.ESCAPE ) app.quit();
        });
    }

    void prepareTextOutput()
    {
        fps_output = newEMM!BaseLineTextBox( appPath( "..", "data", "default.ttf" ), 16u );
        fps_output.color = vec3(1);

        info = newEMM!BaseLineTextBox( appPath( "..", "data", "default.ttf" ), 16u );
        info.text = ""w;
        info.color = vec3(1);

        info_log = newEMM!BaseLineTextBox( appPath( "..", "data", "default.ttf" ), 14u );
        info_log.text = ""w;
        info_log.color = vec3(.5);

        fps_counter = newEMM!FPSCounter( 300 );

        glEnable( GL_BLEND );
        checkGLCall!glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
        checkGLCall!glPixelStorei( GL_UNPACK_ALIGNMENT, 1 );
        checkGLCall!glPixelStorei( GL_PACK_ALIGNMENT, 1 );
    }

    void prepareTester()
    {
        tester = newEMM!Tester;

        connect( key, &(tester.keyReaction) );
        connect( mouse, &(tester.mouseReaction) );
        connect( event.resized, &(tester.resize) );

        connect( tester.changeInfo, (wstring txt) { info.text = txt; });
        connect( tester.changeInfoLog, (wstring txt) { info_log.text = txt; });
    }
}

class FPSCounter : DesObject
{
    mixin DES;

protected:
    import des.math.method.stat.moment;

    Timer timer;
    alias MovingTimeAverage = MovingAverage!float;
    MovingTimeAverage ma;

public:

    this( size_t mlen=60 )
    {
        timer = newEMM!Timer;
        ma = newEMM!MovingTimeAverage(mlen);
    }

    float update()
    {
        ma.append( 1.0f / timer.cycle() );
        return ma.avg;
    }
}
