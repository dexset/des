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

module desgui.base.app;

import std.conv;

import derelict.sdl2.sdl;
import derelict.opengl3.gl3;

import desgui.core.event;
import desgui.core.widget;
import desgui.base.glcontext;

import desgl;
import desil;

import desmath.linear.vector;

import desutil.signal;
import desutil.helpers;

import desutil.logger;
mixin( PrivateLoggerMixin );

class DiAppException: Exception 
{ @safe pure nothrow this( string msg, string file=__FILE__, int line=__LINE__ ){ super( msg, file, line ); } }

class DiAppWindow
{
package:
    SDL_Window *window = null;
    SDL_GLContext context;
    DiWidget widget;
    void delegate( in irect ) setClear;

    ivec2 mpos;

    void makeCurrent()
    {
        // TODO: add checking of current window and context
        if( SDL_GL_MakeCurrent( window, context ) < 0 )
            throw new DiAppException( "SDL fails with make current: " ~ toDString( SDL_GetError() ) );
    }

    DiGLDrawStack gldrawstack;

    void process()
    {
        makeCurrent();

        widget.idle();

        setClear( widget.rect );
        glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
        widget.draw();

        SDL_GL_SwapWindow( window );
    }

    void window_eh( in SDL_WindowEvent ev )
    {
        makeCurrent();

        switch( ev.event ) 
        {
            case SDL_WINDOWEVENT_NONE:         break;
            case SDL_WINDOWEVENT_SHOWN:        
                widget.activate();
                break;
            case SDL_WINDOWEVENT_HIDDEN:       
                widget.release();
                break;
            case SDL_WINDOWEVENT_EXPOSED:      break;
            case SDL_WINDOWEVENT_MOVED:        break;
            case SDL_WINDOWEVENT_RESIZED:      break;
            case SDL_WINDOWEVENT_SIZE_CHANGED: 
                auto rr = irect( ivec2(0,0), ivec2(ev.data1,ev.data2) );
                widget.reshape( rr ); 
                break;
            case SDL_WINDOWEVENT_MINIMIZED:    break;
            case SDL_WINDOWEVENT_MAXIMIZED:    break;
            case SDL_WINDOWEVENT_RESTORED:     break;
            case SDL_WINDOWEVENT_ENTER:        
                widget.activate();
                break;
            case SDL_WINDOWEVENT_LEAVE:        
                widget.release();
                break;
            case SDL_WINDOWEVENT_FOCUS_GAINED: break;
            case SDL_WINDOWEVENT_FOCUS_LOST:   
                widget.release();
                break;
            case SDL_WINDOWEVENT_CLOSE:        
                widget.release();
                break;
            default: break;
        }
    }

    void keyboard_eh( in SDL_KeyboardEvent ev ) 
    { 
        makeCurrent();
        DiKeyboardEvent oev;
        oev.pressed = (ev.state == SDL_PRESSED);
        oev.scan = ev.keysym.scancode;
        oev.key = ev.keysym.sym;
        oev.repeat = cast(bool)ev.repeat;
        
        oev.mod = 
                  ( ev.keysym.mod & KMOD_LSHIFT ? DiKeyboardEvent.Mod.LSHIFT : 0 ) |
                  ( ev.keysym.mod & KMOD_RSHIFT ? DiKeyboardEvent.Mod.RSHIFT : 0 ) |
                  ( ev.keysym.mod & KMOD_LCTRL  ? DiKeyboardEvent.Mod.LCTRL  : 0 ) |
                  ( ev.keysym.mod & KMOD_RCTRL  ? DiKeyboardEvent.Mod.RCTRL  : 0 ) | 
                  ( ev.keysym.mod & KMOD_LALT   ? DiKeyboardEvent.Mod.LALT   : 0 ) |
                  ( ev.keysym.mod & KMOD_RALT   ? DiKeyboardEvent.Mod.RALT   : 0 ) |
                  ( ev.keysym.mod & KMOD_LGUI   ? DiKeyboardEvent.Mod.LGUI   : 0 ) |
                  ( ev.keysym.mod & KMOD_RGUI   ? DiKeyboardEvent.Mod.RGUI   : 0 ) |
                  ( ev.keysym.mod & KMOD_NUM    ? DiKeyboardEvent.Mod.NUM    : 0 ) |
                  ( ev.keysym.mod & KMOD_CAPS   ? DiKeyboardEvent.Mod.CAPS   : 0 ) |
                  ( ev.keysym.mod & KMOD_MODE   ? DiKeyboardEvent.Mod.MODE   : 0 ) |
                  ( ev.keysym.mod & KMOD_CTRL   ? DiKeyboardEvent.Mod.CTRL   : 0 ) |
                  ( ev.keysym.mod & KMOD_SHIFT  ? DiKeyboardEvent.Mod.SHIFT  : 0 ) |
                  ( ev.keysym.mod & KMOD_ALT    ? DiKeyboardEvent.Mod.ALT    : 0 ) |
                  ( ev.keysym.mod & KMOD_GUI    ? DiKeyboardEvent.Mod.GUI    : 0 );

        widget.keyboard( mpos, oev );
    }

    void textinput_eh( in SDL_TextInputEvent ev )
    {
        import std.utf : toUTF32;
        auto str = toUTF32( ev.text[0 .. 4].dup );
        widget.evtext( mpos, DiTextEvent( str[0] ) );
    }

    void mouse_button_eh( in SDL_MouseButtonEvent ev ) 
    { 
        makeCurrent();
        mpos.x = ev.x;
        mpos.y = ev.y;

        auto me = DiMouseEvent( ev.state == SDL_PRESSED ? DiMouseEvent.Type.PRESSED : 
                                DiMouseEvent.Type.RELEASED, 0 );
        switch( ev.button )
        {
            case SDL_BUTTON_LEFT:   me.btn = DiMouseEvent.Button.LEFT; break;
            case SDL_BUTTON_MIDDLE: me.btn = DiMouseEvent.Button.MIDDLE; break;
            case SDL_BUTTON_RIGHT:  me.btn = DiMouseEvent.Button.RIGHT; break;
            case SDL_BUTTON_X1:     me.btn = DiMouseEvent.Button.X1; break;
            case SDL_BUTTON_X2:     me.btn = DiMouseEvent.Button.X2; break;
            default: 
                throw new DiAppException( "Undefined mouse button: " ~ to!string( ev.button ) );
        }

        me.data = mpos;
        widget.mouse( mpos, me );
    }

    void mouse_motion_eh( in SDL_MouseMotionEvent ev ) 
    { 
        makeCurrent();
        mpos.x = ev.x;
        mpos.y = ev.y;

        auto me = DiMouseEvent( DiMouseEvent.Type.MOTION, 0 );
        me.btn = 
          ( ev.state & SDL_BUTTON_LMASK  ? DiMouseEvent.Button.LEFT : 0 ) |
          ( ev.state & SDL_BUTTON_MMASK  ? DiMouseEvent.Button.MIDDLE : 0 ) |
          ( ev.state & SDL_BUTTON_RMASK  ? DiMouseEvent.Button.RIGHT : 0 ) |
          ( ev.state & SDL_BUTTON_X1MASK ? DiMouseEvent.Button.X1 : 0 ) |
          ( ev.state & SDL_BUTTON_X2MASK ? DiMouseEvent.Button.X2 : 0 );
        me.data = mpos;
        widget.mouse( mpos, me );
    }

    void mouse_wheel_eh( in SDL_MouseWheelEvent ev )
    {
        makeCurrent();
        auto me = DiMouseEvent( DiMouseEvent.Type.WHEEL, 0 );
        me.data = ivec2( ev.x, ev.y );
        widget.mouse( mpos, me );
    }

    void joystick_eh( in DiJoyEvent je ) 
    { 
        widget.joystick( mpos, je ); 
    }

public:
    EmptySignal show;
    EmptySignal hide;

    this( string title, string fontname, DiWidget delegate(DiContext) createWidget )
    {
        window = SDL_CreateWindow( title.ptr,
                                   SDL_WINDOWPOS_UNDEFINED,
                                   SDL_WINDOWPOS_UNDEFINED,
                                   800, 600,
                                   SDL_WINDOW_OPENGL | 
                                   SDL_WINDOW_HIDDEN |
                                   SDL_WINDOW_RESIZABLE );

        if( window is null )
            throw new DiAppException( "Couldn't create SDL window: " ~ toDString( SDL_GetError() ) );

        context = SDL_GL_CreateContext( window );

        if( context is null )
            throw new DiAppException( "Couldn't create SDL context: " ~ toDString( SDL_GetError() ) );

        DerelictGL3.reload();

        SDL_GL_SetSwapInterval(1);

        glEnable( GL_BLEND );
        glEnable( GL_SCISSOR_TEST );

        glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
        glPixelStorei( GL_UNPACK_ALIGNMENT, 1 );

        DiApplication.singleton.windows[window] = this;

        show.connect({ SDL_ShowWindow( window ); });
        hide.connect({ SDL_HideWindow( window ); });

        auto ctx = new DiGLContext( fontname );

        setClear = &((cast(DiGLDrawStack)(ctx.drawStack)).setClear);

        widget = createWidget(ctx);

        if( widget is null )
            throw new DiAppException( "Couldn't create DiWidget" );
    }

    ~this()
    {
        clear(widget);

        if( context !is null ) SDL_GL_DeleteContext( context );
        if( window !is null ) SDL_DestroyWindow( window );
    }
}


class DiApplication
{
package:
    static DiApplication singleton;

    DiAppWindow[SDL_Window*] windows;

private:
    SDL_Joystick *joy_dev = null;

    this()
    {
        DerelictSDL2.load();
        DerelictGL3.load();

        if( SDL_Init( SDL_INIT_VIDEO | SDL_INIT_AUDIO | SDL_INIT_JOYSTICK ) < 0 )
            throw new DiAppException( "Couldn't init SDL: " ~ toDString( SDL_GetError() ) );

        string joy_name = "any";

        int num_joys = SDL_NumJoysticks();
        if( num_joys > 0 && joy_name.length )
        {
            SDL_JoystickEventState( SDL_ENABLE );
            int dev_index = 0;
            if( num_joys != 1 || joy_name != "any" )
                while( joy_name != toDString( SDL_JoystickNameForIndex( dev_index ) ) )
                {
                    dev_index++;
                    if( dev_index > num_joys )
                    {
                        dev_index = 0;
                        break;
                    }
                }

            joy_dev = SDL_JoystickOpen( dev_index );
            debug log_info( "enable joy: %s", SDL_JoystickName(joy_dev) );
        }

        SDL_GL_SetAttribute( SDL_GL_BUFFER_SIZE, 32 );
        SDL_GL_SetAttribute( SDL_GL_DEPTH_SIZE,  24 );
        SDL_GL_SetAttribute( SDL_GL_DOUBLEBUFFER, 1 );
    }

    ~this()
    {
        if( SDL_JoystickClose !is null && joy_dev !is null )
            SDL_JoystickClose( joy_dev );

        if( SDL_Quit !is null ) SDL_Quit();
    }

    DiAppWindow w; // last selected

    void joystick_eh( uint joy, DiJoyEvent.Type type, size_t no )
    {
        DiJoyEvent je;

        je.joy = joy;
        je.type = type;
        je.no = no;

        foreach( i; 0 .. SDL_JoystickNumAxes( joy_dev ) )
            je.axis ~= SDL_JoystickGetAxis( joy_dev, i ) / 32768.0; 

        foreach( i; 0 .. SDL_JoystickNumBalls( joy_dev ) )
        {
            ivec2 d;
            if( SDL_JoystickGetBall( joy_dev, i, d.data.ptr, d.data.ptr+1 ) )
                je.balls ~= d;
        }

        foreach( i; 0 .. SDL_JoystickNumButtons( joy_dev ) )
            je.buttons ~= cast(bool)SDL_JoystickGetButton( joy_dev, i );

        foreach( i; 0 .. SDL_JoystickNumHats( joy_dev ) )
            je.hats ~= SDL_JoystickGetHat( joy_dev, i );

        if( w ) w.joystick_eh( je );
    }

    bool work()
    {
        SDL_Event event;

        DiAppWindow selectWindow( uint id )
        {
            auto wid = SDL_GetWindowFromID( event.window.windowID ) in windows;
            if( wid ) return *wid;
            else return null;
        }

        while( SDL_PollEvent(&event) )
        {
            switch( event.type )
            {
                case SDL_QUIT: return false;

                case SDL_WINDOWEVENT:
                    w = selectWindow( event.window.windowID );
                    if(w) w.window_eh( event.window );
                    break;
                case SDL_KEYDOWN:
                case SDL_KEYUP: 
                    w = selectWindow( event.key.windowID );
                    if(w) w.keyboard_eh( event.key );
                    break;
                case SDL_TEXTEDITING: break;
                case SDL_TEXTINPUT: 
                    w = selectWindow( event.text.windowID );
                    if(w) w.textinput_eh( event.text );
                    break;

                case SDL_MOUSEMOTION: 
                    w = selectWindow( event.motion.windowID );
                    if(w) w.mouse_motion_eh( event.motion );
                    break;
                case SDL_MOUSEBUTTONDOWN:
                case SDL_MOUSEBUTTONUP: 
                    w = selectWindow( event.button.windowID );
                    if(w) w.mouse_button_eh( event.button );
                    break;
                case SDL_MOUSEWHEEL: 
                    w = selectWindow( event.wheel.windowID );
                    if(w) w.mouse_wheel_eh( event.wheel );
                    break;

                case SDL_JOYAXISMOTION:
                    joystick_eh( event.jaxis.which, DiJoyEvent.Type.AXIS, event.jaxis.axis );
                    break;
                case SDL_JOYBALLMOTION: 
                    joystick_eh( event.jball.which, DiJoyEvent.Type.BALL, event.jball.ball );
                    break;
                case SDL_JOYHATMOTION:
                    joystick_eh( event.jhat.which, DiJoyEvent.Type.HAT, event.jhat.hat );
                    break;
                case SDL_JOYBUTTONDOWN:
                case SDL_JOYBUTTONUP: 
                    joystick_eh( event.jbutton.which, DiJoyEvent.Type.BUTTON, event.jbutton.button );
                    break;

                case SDL_JOYDEVICEADDED: break;
                case SDL_JOYDEVICEREMOVED: break;

                case SDL_CONTROLLERAXISMOTION: break;
                case SDL_CONTROLLERBUTTONDOWN: break;
                case SDL_CONTROLLERBUTTONUP: break;
                case SDL_CONTROLLERDEVICEADDED: break;
                case SDL_CONTROLLERDEVICEREMOVED: break;
                case SDL_CONTROLLERDEVICEREMAPPED: break;

                case SDL_FINGERDOWN: break;
                case SDL_FINGERUP: break;
                case SDL_FINGERMOTION: break;

                case SDL_DOLLARGESTURE: break;
                case SDL_DOLLARRECORD: break;
                case SDL_MULTIGESTURE: break;

                case SDL_CLIPBOARDUPDATE: break;

                case SDL_DROPFILE: break;
                default: break;
            }
        }

        foreach( id, win; windows ) win.process();

        return true;
    }

public:
    static void init()
    {
        destroy();
        singleton = new DiApplication;
    }

    static void run() 
    { 
        if( singleton is null ) init();
        while( singleton.work() ) SDL_Delay(1); 
    }

    static bool evProc()
    {
        if( singleton is null ) init();
        return singleton.work();
    }

    static void destroy()
    {
        if( singleton !is null ) clear( singleton );
    }
}
