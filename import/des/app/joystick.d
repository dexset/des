module des.app.joystick;

import std.conv : to;

import derelict.sdl2.sdl;

import des.util.arch;
import des.util.logsys;
import des.util.stdext.string;
import des.app.evproc;

import des.app.base : DesAppException;

///
class Joystick : DesObject
{
    mixin DES;
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
        CENTERED  = SDL_HAT_CENTERED,  /// `SDL_HAT_CENTERED`
        UP        = SDL_HAT_UP,        /// `SDL_HAT_UP`
        RIGHT     = SDL_HAT_RIGHT,     /// `SDL_HAT_RIGHT`
        DOWN      = SDL_HAT_DOWN,      /// `SDL_HAT_DOWN`
        LEFT      = SDL_HAT_LEFT,      /// `SDL_HAT_LEFT`
        RIGHTUP   = SDL_HAT_RIGHTUP,   /// `SDL_HAT_RIGHTUP`
        RIGHTDOWN = SDL_HAT_RIGHTDOWN, /// `SDL_HAT_RIGHTDOWN`
        LEFTUP    = SDL_HAT_LEFTUP,    /// `SDL_HAT_LEFTUP`
        LEFTDOWN  = SDL_HAT_LEFTDOWN,  /// `SDL_HAT_LEFTDOWN`
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

        logger.Debug( "joy opened: ", dev );

        joy_name = SDL_JoystickName( dev ).toDString;

        createVals();
        setVals();

        is_open = true;
        logger.Debug( "pass" );
    }

    ///
    void createVals()
    {
        axis_vals = new short[]( SDL_JoystickNumAxes( dev ) );
        logger.trace( "axis vals created: ", axis_vals.length );
        ball_vals = new ivec2[]( SDL_JoystickNumBalls( dev ) );
        logger.trace( "ball vals created: ", ball_vals.length );
        button_vals = new bool[]( SDL_JoystickNumButtons( dev ) );
        logger.trace( "ball vals setted: ", button_vals.length );
        hat_vals = to!(HatState[])( new byte[]( SDL_JoystickNumHats( dev ) ) );
        logger.trace( "hat vals setted: ", hat_vals.length );
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

    /// number of joystick in `devlist`
    Signal!( uint ) added;
    /// number of joystick in `devlist`
    Signal!( uint ) removed;

    /// number of joystick in `devlist`, number of axis, value
    Signal!( uint, uint, short ) axisChange;
    /// number of joystick in `devlist`, number of ball, relative move
    Signal!( uint, uint, ivec2 ) ballChange;
    /// number of joystick in `devlist`, number of button, pressed
    Signal!( uint, uint, bool ) buttonChange;
    /// number of joystick in `devlist`, number of hat, state
    Signal!( uint, uint, Joystick.HatState ) hatChange;


    /// list of registred devices
    Joystick[uint] devlist;

    this()
    {
        if( SDL_InitSubSystem( SDL_INIT_JOYSTICK ) < 0 )
            throw new DesAppException( "Error initializing SDL joystick subsystem: " ~ toDString( SDL_GetError() ) );

        SDL_JoystickEventState( SDL_ENABLE );

        int num_joys = SDL_NumJoysticks();
        foreach( index; 0 .. num_joys )
            addJoystick( index );

        logger.Debug( "pass" );
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
        if( auto j = devlist.get( ind, null ) )
            j.updateAxis( axis, value );
        else
            logger.warn( "no joystick device in list: ", ind );
        axisChange( ind, axis, value );
    }

    void updateBall( uint ind, uint ball, ivec2 rel )
    {
        if( auto j = devlist.get( ind, null ) )
            j.updateBall( ball, rel );
        else
            logger.warn( "no joystick device in list: ", ind );
        ballChange( ind, ball, rel );
    }

    void updateHat( uint ind, uint hat, uint value )
    {
        if( auto j = devlist.get( ind, null ) )
            j.updateHat( hat, value );
        else
            logger.warn( "no joystick device in list: ", ind );
        hatChange( ind, hat, cast(Joystick.HatState)value );
    }

    void updateButton( uint ind, uint btn, bool value )
    {
        if( auto j = devlist.get( ind, null ) )
            j.updateButton( btn, value );
        else
            logger.warn( "no joystick device in list: ", ind );
        buttonChange( ind, btn, value );
    }

    void addJoystick( uint ind )
    {
        auto j = newEMM!Joystick(ind);
        auto i = SDL_JoystickInstanceID( j.dev );
        devlist[i] = j;
        added( i );
        logger.Debug( "[%d]", i );
    }

    void removeJoystick( uint ind )
    {
        if( ind in devlist )
        {
            auto j = devlist[ind];
            devlist.remove(ind);
            j.destroy();
            removed( ind );
            logger.Debug( "[%d]", ind );
        }
    }
}
