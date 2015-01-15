module des.app.joystick;

import std.conv : to;

import derelict.sdl2.sdl;

import des.util.arch;
import des.app.evproc;

import des.app.app;

///
class Joystick : DesObject
{
private:
    bool is_open;

protected:
    ///
    int index;
    ///
    SDL_Joystick *dev;

    string joy_name;

    ///
    short[] axis_vals;
    ///
    ivec2[] ball_vals;
    ///
    bool[] button_vals;
    ///
    HatState[] hat_vals;

public:

    ///
    Signal!( uint, short ) axisChange;
    ///
    Signal!( uint, ivec2 ) ballChange;
    ///
    Signal!( uint, bool ) buttonChange;
    ///
    Signal!( uint, HatState ) hatChange;

    ///
    enum HatState
    {
        CENTERED  = SDL_HAT_CENTERED,  /// SDL_HAT_CENTERED
        UP        = SDL_HAT_UP,        /// SDL_HAT_UP
        RIGHT     = SDL_HAT_RIGHT,     /// SDL_HAT_RIGHT
        DOWN      = SDL_HAT_DOWN,      /// SDL_HAT_DOWN
        LEFT      = SDL_HAT_LEFT,      /// SDL_HAT_LEFT
        RIGHTUP   = SDL_HAT_RIGHTUP,   /// SDL_HAT_RIGHTUP
        RIGHTDOWN = SDL_HAT_RIGHTDOWN, /// SDL_HAT_RIGHTDOWN
        LEFTUP    = SDL_HAT_LEFTUP,    /// SDL_HAT_LEFTUP
        LEFTDOWN  = SDL_HAT_LEFTDOWN,  /// SDL_HAT_LEFTDOWN
    };

    ///
    this( int index )
    {
        this.index = index;
        open();
    }

    ///
    void open() { if( !isOpen ) selfConstruct(); }

    pure
    {
        const
        {
            @property
            {
                ///
                string name() { return joy_name; }
                ///
                bool isOpen() { return is_open; }
            }

            ///
            short axis( uint i ) { return axis_vals[i]; }
            ///
            ivec2 ball( uint i ) { return ball_vals[i]; }
            ///
            bool button( uint i ) { return button_vals[i]; }
            ///
            HatState hat( uint i ) { return hat_vals[i]; }
        }
    }

package:
    ///
    void updateAxis( uint i, short v )
    {
        axis_vals[i] = v;
        axisChange( i, v );
    }
    ///
    void updateBall( uint i, in ivec2 v )
    {
        ball_vals[i] = v;
        ballChange( i, v );
    }
    ///
    void updateButton( uint i, bool v )
    {
        button_vals[i] = v;
        buttonChange( i, v );
    }
    ///
    void updateHat( uint i, uint v )
    {
        auto vv = cast(HatState)v;
        hat_vals[i] = vv;
        hatChange( i, vv );
    }

protected:

    ///
    override void selfConstruct()
    {
        dev = SDL_JoystickOpen( index );
        if( !dev )
            throw new DesAppException( "Error open joystick: " ~ toDString( SDL_GetError() ) );

        joy_name = toDString( SDL_JoystickName( dev ) );

        createVals();
        setVals();

        is_open = true;
    }

    ///
    void createVals()
    {
        axis_vals = new short[]( SDL_JoystickNumAxes( dev ) );
        ball_vals = new ivec2[]( SDL_JoystickNumBalls( dev ) );
        button_vals = new bool[]( SDL_JoystickNumButtons( dev ) );
        hat_vals = to!(HatState[])( new byte[]( SDL_JoystickNumHats( dev ) ) );
    }

    /// without calling change signals
    void setVals()
    {
        setAxes();
        setBalls();
        setButtons();
        setHats();
    }

    ///
    void setAxes()
    {
        foreach( int i, ref axis; axis_vals )
            axis = SDL_JoystickGetAxis( dev, i );
    }

    ///
    void setBalls()
    {
        foreach( int i, ref ball; ball_vals )
            SDL_JoystickGetBall( dev, i, ball.data.ptr, ball.data.ptr+1 );
    }

    ///
    void setButtons()
    {
        foreach( int i, ref button; button_vals )
            button = cast(bool)SDL_JoystickGetButton( dev, i );
    }

    ///
    void setHats()
    {
        foreach( int i, ref hat; hat_vals )
            hat = cast(HatState)SDL_JoystickGetHat( dev, i );
    }

    ///
    override void selfDestroy()
    {
        SDL_JoystickClose( dev );
        is_open = false;
    }
}

///
class JoyEventProcessor : BaseSDLEventProcessor
{
    mixin DES;
    ///
    Signal!( Joystick ) added;
    ///
    Signal!( int ) removed;

    ///
    Joystick[int] joy;

    this()
    {
        if( SDL_InitSubSystem( SDL_INIT_JOYSTICK ) < 0 )
            throw new DesAppException( "Error initializing SDL joystick subsystem: " ~ toDString( SDL_GetError() ) );

        SDL_JoystickEventState( SDL_ENABLE );

        int num_joys = SDL_NumJoysticks();
        foreach( index; 0 .. num_joys )
            addJoystick( index );
    }

    bool procSDLEvent( in SDL_Event ev )
    {
        switch( ev.type )
        {
            case SDL_JOYAXISMOTION:
                with( ev.jaxis )
                    updateAxis( which, axis, value );
                return true;

            case SDL_JOYBALLMOTION: 
                with( ev.jball )
                    updateBall( which, ball, ivec2( xrel, yrel ) );
                return true;

            case SDL_JOYHATMOTION:
                with( ev.jhat )
                    updateHat( which, hat, value );
                return true;

            case SDL_JOYBUTTONDOWN:
            case SDL_JOYBUTTONUP: 
                with( ev.jbutton )
                    updateButton( which, button, cast(bool)state );
                return true;

            case SDL_JOYDEVICEADDED:
                addJoystick( ev.jdevice.which );
                return true;

            case SDL_JOYDEVICEREMOVED:
                removeJoystick( ev.jdevice.which );
                return true;

            default: return false;
        }
    }

protected:

    void updateAxis( uint ind, uint axis, short value )
    {
        if( auto j = joy.get( ind, null ) )
            j.updateAxis( axis, value );
    }

    void updateBall( uint ind, uint ball, ivec2 rel )
    {
        if( auto j = joy.get( ind, null ) )
            j.updateBall( ball, rel );
    }

    void updateHat( uint ind, uint hat, uint value )
    {
        if( auto j = joy.get( ind, null ) )
            j.updateHat( hat, value );
    }

    void updateButton( uint ind, uint btn, bool value )
    {
        if( auto j = joy.get( ind, null ) )
            j.updateButton( btn, value );
    }

    void addJoystick( uint ind )
    {
        auto j = newEMM!Joystick(ind);
        joy[ind] = j;
        added( j );
    }

    void removeJoystick( uint ind )
    {
        if( ind in joy )
        {
            joy[ind].destroy();
            joy.remove(ind);
            removed( ind );
        }
    }
}
