module des.app.glapp;

import des.app.base;

import std.stdio;

public import derelict.opengl3.gl3;
public import derelict.freetype.ft;
public import des.util.emm;
public import des.util.string;
public import des.app.sdlevproc;

import des.util.logger;

class GLAppException : AppException
{
    @safe pure nothrow this( string msg, string file = __FILE__, size_t line = __LINE__ )
    { super( msg, file, line ); }
}

class GLWindow : ExternalMemoryManager
{
    mixin DirectEMM;
protected:

    abstract void prepare();
    SDL_Window* win = null;
    ivec2 _size;

    GLApp app;

public:
    EventProcessor[] processors;
    SignalBox!() draw;
    SignalBox!() idle;

    this( string title, ivec2 sz, bool fullscreen = false, int display = -1 )
    {
        _size = sz;
        import std.string;
        if( display != -1 && display > SDL_GetNumVideoDisplays() - 1 )
            throw new GLAppException( format( "No such display: display%d", display ) );
        SDL_WindowFlags flags = SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN;
        if( fullscreen )
            flags = flags | SDL_WINDOW_FULLSCREEN;
        else
            flags = flags | SDL_WINDOW_RESIZABLE;
        int pos_x = SDL_WINDOWPOS_CENTERED;
        int pos_y = SDL_WINDOWPOS_CENTERED;
        if( display != -1 )
        {
            pos_x = SDL_WINDOWPOS_CENTERED_DISPLAY(display);
            pos_y = SDL_WINDOWPOS_CENTERED_DISPLAY(display);
        }
        win = SDL_CreateWindow( title.toStringz, pos_x, pos_y,
                                _size.x, _size.y, flags );
        if( win is null )
            throw new GLAppException( "Couldn't create SDL widnow: " ~ toDString( SDL_GetError() ) );

        draw.addBegin(
        {
            glViewport( 0, 0, _size.x, _size.y );
            glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
        });
        draw.addEnd({ SDL_GL_SwapWindow( win ); });
    }

    auto addEventProcessor(T)( T evproc ) if( is( T : EventProcessor ) )
    {
        processors ~= cast(EventProcessor)evproc;
        return evproc;
    }

    auto addNewEventProcessor(T, Args...)( Args args )
        if( is( T : EventProcessor ) )
    {
        auto evproc = newEMM!T(args);
        return addEventProcessor( evproc );
    }

    void procEvents( const ref SDL_Event ev )//Предполагается, что входящее событие предназначено именно этому окну
    {
        foreach( p; processors ) if( p(ev) ) break;

        if( ev.type == SDL_WINDOWEVENT &&
            ev.window.event == SDL_WINDOWEVENT_RESIZED )
            _size = ivec2( ev.window.data1, ev.window.data2 );
    }

    uint id() @property { return SDL_GetWindowID( win ); }
    ivec2 size() const @property { return _size; }

private:
    void setApp( GLApp owner ) { app = owner; }
    void makeCurrent() { SDL_GL_MakeCurrent( win, app.context );}

protected:

    void selfDestroy()
    {
        if( win !is null )
            SDL_DestroyWindow( win );
        win = null;
        debug log_debug("pass");
    }
}

class GLApp : App, ExternalMemoryManager
{
    mixin DirectEMM;
protected:
    SDL_GLContext context = null;
    GLWindow[uint] windows;
    GLWindow current;
    bool is_runing;

    void delay() { SDL_Delay(1); }

    bool procEvents()
    {
        SDL_Event ev;
        while( SDL_PollEvent( &ev ) )
        {
            if( ev.type == SDL_QUIT )
                return false;

            if( ev.type == SDL_WINDOWEVENT )
                setCurrent( ev.window.windowID );

            if( current !is null )
                current.procEvents( ev );
        }
        return true;
    }

    void setCurrent( uint winID )
    {
        current = windows.get(winID,null);
    }

    void selfDestroy()
    {
        destroyContext();
        shutdown();
    }

public:
    this()
    {
        DerelictSDL2.load();
        DerelictGL3.load();
        DerelictFT.load();

        if( SDL_Init( SDL_INIT_VIDEO ) < 0 )
            throw new GLAppException( "Error initializing SDL: " ~ toDString( SDL_GetError() ) );

        SDL_GL_SetAttribute( SDL_GL_BUFFER_SIZE, 32 );
        SDL_GL_SetAttribute( SDL_GL_DEPTH_SIZE, 24 );
        SDL_GL_SetAttribute( SDL_GL_DOUBLEBUFFER, 1 );

        is_runing = true;
    }

    bool step()
    {
        if( context is null )
        {
            std.stdio.stderr.writeln( "warning: no windows." );
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

    GLWindow addWindow( GLWindow delegate() winFunc )
    {
        auto win = registerChildEMM( winFunc() );
        if( context == null )
        {
            context = SDL_GL_CreateContext( win.win );

            if( context is null )
                throw new GLAppException( "Couldn't create GL context: " ~ toDString( SDL_GetError() ) );
            DerelictGL3.reload();

            glClearColor( 0.0, 0.0, 0.0, 0.0 );
            glEnable( GL_BLEND );
            glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
        }

        win.setApp( this );
        win.prepare();

        windows[win.id] = win;

        return win;
    }

    void quit(){ is_runing = false; }

protected:

    void destroyContext()
    {
        if( context !is null )
            SDL_GL_DeleteContext( context );
        context = null;
        debug log_debug("pass");
    }

    void shutdown() { if( SDL_Quit !is null ) SDL_Quit(); }
}