module des.app.app;

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

    abstract void prepare();
    SDL_Window* win = null;
    ivec2 _size;

    DesApp app;

    SDLEventProcessor[] processors;

public:

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
    }

    //Предполагается, что входящее событие предназначено именно этому окну
    void procEvents( in SDL_Event ev )
    {
        foreach( p; processors ) if( p.procSDLEvent(ev) ) break;

        if( ev.type == SDL_WINDOWEVENT &&
            ev.window.event == SDL_WINDOWEVENT_RESIZED )
            _size = ivec2( ev.window.data1, ev.window.data2 );
    }

    /// register additional event processor
    void registerEvProc( SDLEventProcessor ep )
    { processors ~= registerChildsEMM( ep ); }

    @property
    {
        ///
        uint id() { return SDL_GetWindowID( win ); }
        ///
        ivec2 size() const { return _size; }
    }

package:
    void setApp( DesApp owner ) { app = owner; }
    void makeCurrent() { SDL_GL_MakeCurrent( win, app.context );}

protected:

    void prepareBaseEventProcessors()
    {
        mouse = newEMM!MouseEventProcessor;
        event = newEMM!WindowEventProcessor;
        key = newEMM!KeyboardEventProcessor;

        processors ~= mouse;
        processors ~= event;
        processors ~= key;
    }

    void prepareSDLWindow( string title, ivec2 sz, bool fullscreen, int display )
    {
        _size = sz;
        if( display != -1 && display > SDL_GetNumVideoDisplays() - 1 )
            throw new DesAppException( format( "No such display: display%d", display ) );

        SDL_WindowFlags flags = SDL_WINDOW_OPENGL |
                                SDL_WINDOW_SHOWN |
                                ( fullscreen ? SDL_WINDOW_FULLSCREEN : SDL_WINDOW_RESIZABLE );

        int pos_x = SDL_WINDOWPOS_CENTERED;
        int pos_y = SDL_WINDOWPOS_CENTERED;

        if( display != -1 )
        {
            pos_x = SDL_WINDOWPOS_CENTERED_DISPLAY( display );
            pos_y = SDL_WINDOWPOS_CENTERED_DISPLAY( display );
        }

        win = SDL_CreateWindow( title.toStringz, pos_x, pos_y,
                                _size.x, _size.y, flags );
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

class DesApp : ExternalMemoryManager
{
    mixin EMM;

protected:

    SDL_GLContext context = null;
    DesWindow[uint] windows;
    DesWindow current;
    bool is_runing;

public:

    this()
    {
        DerelictSDL2.load();
        DerelictGL3.load();
        DerelictFT.load();

        if( SDL_Init( SDL_INIT_VIDEO ) < 0 )
            throw new DesAppException( "Error initializing SDL: " ~ toDString( SDL_GetError() ) );

        SDL_GL_SetAttribute( SDL_GL_BUFFER_SIZE, 32 );
        SDL_GL_SetAttribute( SDL_GL_DEPTH_SIZE, 24 );
        SDL_GL_SetAttribute( SDL_GL_DOUBLEBUFFER, 1 );

        is_runing = true;
    }

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

    @property bool isRuning(){ return is_runing; }

    DesWindow addWindow( DesWindow delegate() winFunc )
    {
        auto win = registerChildsEMM( winFunc() );
        if( context == null )
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

    void quit() { is_runing = false; }

protected:

    void delay()
    {
        import core.thread;
        Thread.sleep(dur!"usecs"(1));
    }

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
                current.procEvents( ev );
        }
        return true;
    }

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
