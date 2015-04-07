module des.gui.sdlgl.context;

import des.gui.sdlgl.base;

import des.gui.sdlgl.window;
import des.gui.sdlgl.canvas;

class DiSDLGLContext : DesObject, DiContext
{
    mixin DES;

package:

    SDL_GLContext context = null;

    DiSDLGLWindow current;

    DiSDLGLWindow[DiWidget] windows;

    bool is_running;

public:

    this()
    {
        if( !DerelictSDL2.isLoaded )
            DerelictSDL2.load();

        if( !DerelictGL3.isLoaded )
            DerelictGL3.load();

        if( SDL_Init( SDL_INIT_VIDEO | SDL_INIT_JOYSTICK ) < 0 )
            throw new DiContextException( "Error initializing SDL: " ~ toDString( SDL_GetError() ) );

        SDL_GL_SetAttribute( SDL_GL_BUFFER_SIZE, 32 );
        SDL_GL_SetAttribute( SDL_GL_DEPTH_SIZE, 24 );
        SDL_GL_SetAttribute( SDL_GL_DOUBLEBUFFER, 1 );

        is_running = true;
    }

    ///
    bool step()
    {
        if( context is null )
        {
            logger.warn( "no windows" );
            return false;
        }

        if( !procEvents() ) return false;

        foreach( win; windows ) win.step();

        return true;
    }

    ///
    bool isRunning() @property { return is_running; }

    DiCanvas createTop( DiWidget w )
    {
        windows[w] = registerChildEMM( createWindow(w) );
        return windows[w].canvas;
    }

    void removeTop( DiWidget w )
    {
        if( w in windows )
        {
            windows[w].destroy();
            windows.remove(w);
        }
    }

    void startTextInput() { SDL_StartTextInput(); }
    void stopTextInput() { SDL_StopTextInput(); }

    ///
    void quit() { is_running = false; }

protected:

    DiSDLGLWindow createWindow( DiWidget w )
    {
        auto ret = new DiSDLGLWindow( this, w );

        if( context is null )
        {
            context = SDL_GL_CreateContext( ret.win );

            if( context is null )
                throw new DiContextException( "Couldn't create GL context: " ~ toDString( SDL_GetError() ) );

            DerelictGL3.reload();
        }

        ret.prepare();
        return ret;
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
                case SDL_WINDOWEVENT:     setCurrent( ev.window.windowID ); break;
                case SDL_KEYDOWN:         setCurrent( ev.key.windowID );    break;
                case SDL_KEYUP:           setCurrent( ev.key.windowID );    break;
                case SDL_TEXTEDITING:     setCurrent( ev.edit.windowID );   break;
                case SDL_TEXTINPUT:       setCurrent( ev.text.windowID );   break;
                case SDL_MOUSEMOTION:     setCurrent( ev.motion.windowID ); break;
                case SDL_MOUSEBUTTONDOWN: setCurrent( ev.button.windowID ); break;
                case SDL_MOUSEBUTTONUP:   setCurrent( ev.button.windowID ); break;
                case SDL_MOUSEWHEEL:      setCurrent( ev.wheel.windowID );  break;
                default: break;
            }

            if( current !is null )
                current.procEvent( ev );
        }

        return true;
    }

    ///
    void setCurrent( uint winID )
    {
        current = null;
        foreach( win; windows )
            if( win.id == winID )
            {
                current = win;
                break;
            }
    }

    override void selfDestroy()
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

    void shutdown()
    { if( SDL_Quit !is null ) SDL_Quit(); }
}
