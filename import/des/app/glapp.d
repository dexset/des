module des.app.glapp;

import des.app.base;

import std.stdio;

public import derelict.opengl3.gl3;
public import derelict.freetype.ft;
public import des.util.arch;
public import des.util.stdext.string;
public import des.app.event;
public import derelict.sdl2.sdl;

import des.util.logsys;

class GLAppException : AppException
{
    @safe pure nothrow this( string msg, string file = __FILE__, size_t line = __LINE__ )
    { super( msg, file, line ); }
}

class GLWindow : DesObject
{
    mixin DES;

private:
    MouseEvent main_event;

protected:

    abstract void prepare();
    SDL_Window* win = null;
    ivec2 _size;

    GLApp app;

    bool mouseProc( ref const(SDL_Event) ev )
    {
        switch( ev.type )
        {
            case SDL_MOUSEMOTION:
                auto e = ev.motion;
                main_event.type = MouseEvent.Type.MOTION;
                main_event.btn = MouseEvent.Button.NONE;
                main_event.pos = ivec2( e.x, e.y );
                main_event.rel = ivec2( e.xrel, e.yrel );

                foreach( i, btn; [EnumMembers!(MouseEvent.Button)][1..$] )
                {
                    if( binHas( main_event.mask, btn ) )
                        main_event.relPress[i] = main_event.pos - main_event.posPress[i];
                    else
                    {
                        main_event.posPress[i] = main_event.pos;
                        main_event.relPress[i] = ivec2(0,0);
                    }
                }
                mouse( main_event );
            return true;
            case SDL_MOUSEBUTTONDOWN:
            case SDL_MOUSEBUTTONUP:
                auto e = ev.button;
                main_event.btn = cast(MouseEvent.Button)SDL_BUTTON(e.button);
                if( e.state == SDL_PRESSED )
                {
                    main_event.type = MouseEvent.Type.PRESSED;
                    main_event.appendButton( SDL_BUTTON(e.button) );
                    main_event.posPress[main_event.buttonIndex(main_event.btn)] = main_event.pos;
                }
                else
                {
                    main_event.type = MouseEvent.Type.RELEASED;
                    main_event.removeButton( SDL_BUTTON(e.button) );
                }
                mouse( main_event );
            return true;
            case SDL_MOUSEWHEEL:
                auto e = ev.wheel;
                main_event.type = MouseEvent.Type.WHEEL;
                main_event.btn = MouseEvent.Button.NONE;
                main_event.whe = ivec2( e.x, e.y );
                mouse( main_event );
            return true;
            default: return false;
        }
    }

    bool keyProc( ref const(SDL_Event) ev )
    {
        switch( ev.type )
        {
            case SDL_KEYUP:
            case SDL_KEYDOWN:
                auto rep = cast(bool)ev.key.repeat;
                auto pre = cast(bool)ev.key.state;
                auto cod = cast(KeyboardEvent.Scan)ev.key.keysym.scancode;
                auto sym = ev.key.keysym.sym;
                auto mod = cast(KeyboardEvent.Mod)ev.key.keysym.mod;
                key( KeyboardEvent( pre, rep, cod, sym, mod ) );
                return true;
            default: return false;
        }
    }

    bool winProc( ref const(SDL_Event) ev )
    {
        if( ev.type != SDL_WINDOWEVENT ) return false;
        auto wID = ev.window.windowID;
        int[2] data = [ ev.window.data1, ev.window.data2 ];

        switch(ev.window.event){
            case SDL_WINDOWEVENT_SHOWN: shown(); break;
            case SDL_WINDOWEVENT_HIDDEN: hidden(); break;
            case SDL_WINDOWEVENT_EXPOSED: exposed(); break;
            case SDL_WINDOWEVENT_MOVED: moved(ivec2(data)); break;
            case SDL_WINDOWEVENT_RESIZED: resized(ivec2(data)); break;
            case SDL_WINDOWEVENT_MINIMIZED: minimized(); break;
            case SDL_WINDOWEVENT_MAXIMIZED: maximized(); break;
            case SDL_WINDOWEVENT_RESTORED: restored(); break;
            case SDL_WINDOWEVENT_ENTER: enter(); break;
            case SDL_WINDOWEVENT_LEAVE: leave(); break;
            case SDL_WINDOWEVENT_FOCUS_GAINED: focusGained(); break;
            case SDL_WINDOWEVENT_FOCUS_LOST: focusLost(); break;
            case SDL_WINDOWEVENT_CLOSE: close(); break;
            default: return false;
        }
        return true;
    }

    bool delegate( ref const(SDL_Event) )[] processors;

public:
    alias ref const(MouseEvent) in_MouseEvent;

    SignalBox!() draw;
    Signal!() idle;

    Signal!( in_MouseEvent ) mouse;

    Signal!( const(KeyboardEvent) ) key;

    Signal!() shown;
    Signal!() hidden;
    Signal!() exposed;
    Signal!(ivec2) moved;
    Signal!(ivec2) resized;
    Signal!() minimized;
    Signal!() maximized;
    Signal!() restored;
    Signal!() enter;
    Signal!() leave;
    Signal!() focusGained;
    Signal!() focusLost;
    Signal!() close;

    this( string title, ivec2 sz, bool fullscreen = false, int display = -1 )
    {
        super();
        processors ~= &mouseProc;
        processors ~= &keyProc;
        processors ~= &winProc;
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

        draw.begin.connect( newSlot(
        {
            glViewport( 0, 0, _size.x, _size.y );
            glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
        }));
        draw.end.connect( newSlot( { SDL_GL_SwapWindow( win ); } ) );
    }

    void procEvents( ref const(SDL_Event) ev )//Предполагается, что входящее событие предназначено именно этому окну
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

    override void selfDestroy()
    {
        if( win !is null )
            SDL_DestroyWindow( win );
        win = null;
        debug logger.Debug("pass");
    }
}

class GLApp : App, ExternalMemoryManager
{
    mixin EMM;
protected:
    SDL_GLContext context = null;
    GLWindow[uint] windows;
    GLWindow current;
    bool is_runing;

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
        auto win = registerChildsEMM( winFunc() );
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
        debug logger.Debug("pass");
    }

    void shutdown() { if( SDL_Quit !is null ) SDL_Quit(); }
}
