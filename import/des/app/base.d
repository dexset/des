module des.app.base;

import std.stdio;
import std.string;

public import derelict.opengl3.gl3;
public import derelict.sdl2.sdl;

public import derelict.freetype.ft;

public import des.util.arch;
public import des.util.stdext.string;

import des.util.logsys;

import des.app.event;

import des.app.evproc;

///
class DesAppException : Exception
{
    ///
    this( string msg, string file = __FILE__, size_t line = __LINE__ ) @safe pure nothrow
    { super( msg, file, line ); }
}

/// SDL window with open gl
class DesWindow : DesObject
{
    mixin DES;

protected:

    ///
    abstract void prepare();

    SDL_Window* win = null;
    ivec2 _size;

    DesApp app;

    SDLEventProcessor[] processors;

public:

    enum Flag : uint
    {
        FULLSCREEN         = SDL_WINDOW_FULLSCREEN,         /// `SDL_WINDOW_FULLSCREEN`
        FULLSCREEN_DESKTOP = SDL_WINDOW_FULLSCREEN_DESKTOP, /// `SDL_WINDOW_FULLSCREEN_DESKTOP`
        OPENGL             = SDL_WINDOW_OPENGL,             /// `SDL_WINDOW_OPENGL`
        SHOWN              = SDL_WINDOW_SHOWN,              /// `SDL_WINDOW_SHOWN`
        HIDDEN             = SDL_WINDOW_HIDDEN,             /// `SDL_WINDOW_HIDDEN`
        BORDERLESS         = SDL_WINDOW_BORDERLESS,         /// `SDL_WINDOW_BORDERLESS`
        RESIZABLE          = SDL_WINDOW_RESIZABLE,          /// `SDL_WINDOW_RESIZABLE`
        MINIMIZED          = SDL_WINDOW_MINIMIZED,          /// `SDL_WINDOW_MINIMIZED`
        MAXIMIZED          = SDL_WINDOW_MAXIMIZED,          /// `SDL_WINDOW_MAXIMIZED`
        INPUT_GRABBED      = SDL_WINDOW_INPUT_GRABBED,      /// `SDL_WINDOW_INPUT_GRABBED`
        INPUT_FOCUS        = SDL_WINDOW_INPUT_FOCUS,        /// `SDL_WINDOW_INPUT_FOCUS`
        MOUSE_FOCUS        = SDL_WINDOW_MOUSE_FOCUS,        /// `SDL_WINDOW_MOUSE_FOCUS`
        FOREIGN            = SDL_WINDOW_FOREIGN,            /// `SDL_WINDOW_FOREIGN`
        ALLOW_HIGHDPI      = SDL_WINDOW_ALLOW_HIGHDPI,      /// `SDL_WINDOW_ALLOW_HIGHDPI`
    }

    ///
    SignalBox!() draw;
    ///
    Signal!() idle;

    ///
    MouseEventProcessor mouse;
    ///
    WindowEventProcessor event;
    ///
    KeyboardEventProcessor key;

    this( string title, ivec2 sz, bool fullscreen = false, int display = -1 )
    {
        prepareBaseEventProcessors();
        prepareSDLWindow( title, sz, fullscreen, display );
        prepareDrawSignal();
        logger.Debug( "pass" );
    }

    ///
    //Предполагается, что входящее событие предназначено именно этому окну
    void procEvent( in SDL_Event ev )
    {
        foreach( p; processors ) if( p.procSDLEvent(ev) ) break;

        if( ev.type == SDL_WINDOWEVENT &&
            ev.window.event == SDL_WINDOWEVENT_RESIZED )
            _size = ivec2( ev.window.data1, ev.window.data2 );
    }

    /++ register additional event processor
     + Retruns:
     + registered `T` object
     +/
    auto registerEvProc(T)( T ep )
        if( is( T : SDLEventProcessor ) )
    {
        foreach( ex; processors ) if( ex == ep ) return ep;
        processors ~= registerChildEMM( ep );
        return ep;
    }

    /++ create and register additional event processor
     + Params:
     + args = pass to `T` ctor
     + Returns:
     + created `T` object
     +/
    auto newEvProc(T,Args...)( Args args )
        if( is( T : SDLEventProcessor ) )
    { return registerEvProc( new T(args) ); }

    @property
    {
        ///
        uint id() { return SDL_GetWindowID( win ); }
        ///
        ivec2 size() const { return _size; }

        ///
        float brightness() const
        { return SDL_GetWindowBrightness( cast(SDL_Window*)win ); }

        ///
        float brightness( float v )
        {
            SDL_SetWindowBrightness( win, v );
            return v;
        }

        ///
        int displayIndex() const
        { return SDL_GetWindowDisplayIndex( cast(SDL_Window*)win ); }
    }

    ///
    void show() { SDL_ShowWindow( win ); }
    ///
    void hide() { SDL_HideWindow( win ); }

    ///
    bool checkFlag( Flag flag ) const { return cast(bool)( SDLFlags & flag ); }

    const @property
    {
        ///
        bool isFullscreen()        { return checkFlag( Flag.FULLSCREEN ); }
        ///
        bool isFullscreenDesktop() { return checkFlag( Flag.FULLSCREEN_DESKTOP ); }
        ///
        bool isOpenGL()            { return checkFlag( Flag.OPENGL ); }
        ///
        bool isShown()             { return checkFlag( Flag.SHOWN ); }
        ///
        bool isHidden()            { return checkFlag( Flag.HIDDEN ); }
        ///
        bool isBorderless()        { return checkFlag( Flag.BORDERLESS ); }
        ///
        bool isResizable()         { return checkFlag( Flag.RESIZABLE ); }
        ///
        bool isMinimized()         { return checkFlag( Flag.MINIMIZED ); }
        ///
        bool isMaximized()         { return checkFlag( Flag.MAXIMIZED ); }
        ///
        bool isInputGrabbed()      { return checkFlag( Flag.INPUT_GRABBED ); }
        ///
        bool isInputFocus()        { return checkFlag( Flag.INPUT_FOCUS ); }
        ///
        bool isMouseFocus()        { return checkFlag( Flag.MOUSE_FOCUS ); }
        ///
        bool isForeign()           { return checkFlag( Flag.FOREIGN ); }
        ///
        bool isAllowHighdpi()      { return checkFlag( Flag.ALLOW_HIGHDPI ); }
    }

    void startTextInput() { app.startTextInput(); }
    void stopTextInput() { app.stopTextInput(); }

package:
    void setApp( DesApp owner ) { app = owner; }
    void makeCurrent() { SDL_GL_MakeCurrent( win, app.context );}

protected:

    ///
    uint SDLFlags() const @property { return SDL_GetWindowFlags( cast(SDL_Window*)win ); }

    void prepareBaseEventProcessors()
    {
        mouse = registerEvProc( new MouseEventProcessor );
        event = registerEvProc( new WindowEventProcessor );
        key = registerEvProc( new KeyboardEventProcessor );

        logger.Debug( "mouse: %s, event: %s, key: %s", mouse !is null, event !is null, key !is null );
    }

    void prepareSDLWindow( string title, ivec2 sz, bool fullscreen, int display )
    {
        _size = sz;
        if( display != -1 && display > SDL_GetNumVideoDisplays() - 1 )
            throw new DesAppException( format( "No such display: display%d", display ) );

        auto flags = Flag.OPENGL | Flag.SHOWN | ( fullscreen ? Flag.FULLSCREEN : Flag.RESIZABLE );

        auto pos = ivec2( SDL_WINDOWPOS_CENTERED );

        if( display != -1 )
            pos = ivec2( SDL_WINDOWPOS_CENTERED_DISPLAY( display ) );

        win = SDL_CreateWindow( title.toStringz, pos.x, pos.y, _size.x, _size.y, flags );
        if( win is null )
            throw new DesAppException( "Couldn't create SDL widnow: " ~ toDString( SDL_GetError() ) );
    }

    void prepareDrawSignal()
    {
        draw.begin.connect( newSlot(
        {
            glViewport( 0, 0, _size.x, _size.y );
            glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
        }));
        draw.end.connect( newSlot( { SDL_GL_SwapWindow( win ); } ) );
    }

    override void selfDestroy()
    {
        if( win !is null )
            SDL_DestroyWindow( win );
        win = null;
        debug logger.Debug("pass");
    }
}

/++ windows handler
 
 +/
class DesApp : ExternalMemoryManager
{
    mixin EMM;

protected:

    SDL_GLContext context = null;
    DesWindow[uint] windows;
    DesWindow current;
    bool is_runing;

public:

    /++ create app

      load `DerelictSDL2`, `DerelictGL3`,
      init SDL with video mode, set GL attributes,
     +/
    this()
    {
        DerelictSDL2.load();
        DerelictGL3.load();

        if( SDL_Init( SDL_INIT_VIDEO ) < 0 )
            throw new DesAppException( "Error initializing SDL: " ~ toDString( SDL_GetError() ) );

        SDL_GL_SetAttribute( SDL_GL_BUFFER_SIZE, 32 );
        SDL_GL_SetAttribute( SDL_GL_DEPTH_SIZE, 24 );
        SDL_GL_SetAttribute( SDL_GL_DOUBLEBUFFER, 1 );

        is_runing = true;
    }

    /// single processing step
    bool step()
    {
        if( context is null )
        {
            logger.warn( "no windows" );
            return false;
        }

        if( !procEvents() )
            return false;

        foreach( win; windows )
        {
            win.makeCurrent();
            win.idle();
            win.draw();
        }

        return true;
    }

    ///
    bool isRuning() @property { return is_runing; }

    /++ create and return window from create function `winFunc`

        created window registered as child EMM, create GL contex if it null,
        calls `prepare` for new window, add window to windows list
     +/
    DesWindow addWindow( DesWindow delegate() winFunc )
    {
        auto win = registerChildEMM( winFunc() );
        if( context is null )
        {
            context = SDL_GL_CreateContext( win.win );

            if( context is null )
                throw new DesAppException( "Couldn't create GL context: " ~ toDString( SDL_GetError() ) );
            DerelictGL3.reload();
        }

        win.setApp( this );
        win.prepare();

        windows[win.id] = win;

        return win;
    }

    ///
    void quit() { is_runing = false; }

    void startTextInput() { SDL_StartTextInput(); }
    void stopTextInput() { SDL_StopTextInput(); }

protected:

    void delay()
    {
        import core.thread;
        Thread.sleep(dur!"usecs"(1));
    }

    /++ process all events with SDL_PollEvent

        set current window by windowID in event structure,
        call process event by current window
     +/
    bool procEvents()
    {
        SDL_Event ev;
        while( SDL_PollEvent( &ev ) )
        {
            switch( ev.type )
            {
                case SDL_QUIT: return false;
                // set current window
                case SDL_WINDOWEVENT: setCurrent( ev.window.windowID ); break;
                case SDL_KEYDOWN:
                case SDL_KEYUP: setCurrent( ev.key.windowID ); break;
                case SDL_TEXTEDITING:
                case SDL_TEXTINPUT: setCurrent( ev.text.windowID ); break;
                case SDL_MOUSEMOTION: setCurrent( ev.text.windowID ); break;
                case SDL_MOUSEBUTTONDOWN:
                case SDL_MOUSEBUTTONUP: setCurrent( ev.button.windowID ); break;
                case SDL_MOUSEWHEEL: setCurrent( ev.wheel.windowID ); break;
                default: break;
            }

            if( current !is null )
                current.procEvent( ev );
        }
        return true;
    }

    ///
    void setCurrent( uint winID ) { current = windows.get( winID, null ); }

    void selfDestroy()
    {
        destroyContext();
        shutdown();
    }

    void destroyContext()
    {
        if( context !is null )
            SDL_GL_DeleteContext( context );
        context = null;
        debug logger.Debug("pass");
    }

    void shutdown() { if( SDL_Quit !is null ) SDL_Quit(); }
}
