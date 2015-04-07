module des.gui.sdlgl.window;

import des.gui.sdlgl.base;

import des.gui.event;
import des.gui.sdlgl.context;
import des.gui.sdlgl.canvas;

import std.conv;

class NotInputEventException : Exception
{ this() @safe pure nothrow { super( "service exception" ); } }

/// SDL window with open gl
class DiSDLGLWindow : DesObject
{
    mixin DES;

package:

    SDL_Window* win = null;

    void prepare()
    {
        _canvas.prepare();
    }

protected:

    ivec2 _size;

    DiSDLGLContext ctx;

    DiWidget _widget;
    DiGLCanvas _canvas;

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

    this( DiSDLGLContext ctx, DiWidget w )
    {
        bool fullscreen = false;
        int display = 0;

        _widget = w;
        this.ctx = ctx;

        createWindow( to!string(w.name), w.size, fullscreen, display );

        _canvas = newEMM!DiGLCanvas;

        logger.Debug( "pass" );
    }

    ///
    DiWidget widget() @property { return _widget; }

    ///
    DiCanvas canvas() @property { return _canvas; }

    ///
    //Предполагается, что входящее событие предназначено именно этому окну
    void procEvent( in SDL_Event ev )
    {
        try widget.processInput( convToInputEvent(ev) );
        catch( NotInputEventException )
        {
            /+ TODO: process window, user, quit etc +/
        }

        if( ev.type == SDL_WINDOWEVENT &&
            ev.window.event == SDL_WINDOWEVENT_RESIZED )
        {
            _size = ivec2( ev.window.data1, ev.window.data2 );
            _canvas.resize( _size );
            widget.shape.rect = DiRect( 0, 0, _size );
        }
    }

    void step()
    {
        makeCurrent();
        widget.update();

        preDraw();
        widget.render();
        postDraw();
    }

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

    void startTextInput() { ctx.startTextInput(); }
    void stopTextInput() { ctx.stopTextInput(); }

protected:

    DiInputEvent convToInputEvent( in SDL_Event ev ) const
    {
        switch( ev.type )
        {
            case SDL_KEYDOWN:
            case SDL_KEYUP:
            case SDL_MOUSEMOTION:
            case SDL_MOUSEBUTTONDOWN:
            case SDL_MOUSEBUTTONUP:
            case SDL_MOUSEWHEEL:
            case SDL_TEXTINPUT:
            case SDL_TEXTEDITING:
            case SDL_JOYAXISMOTION:
            case SDL_JOYBALLMOTION:
            case SDL_JOYHATMOTION:
            case SDL_JOYBUTTONUP:
            case SDL_JOYBUTTONDOWN:
            case SDL_JOYDEVICEADDED:
            case SDL_JOYDEVICEREMOVED:
            case SDL_FINGERDOWN:
            case SDL_FINGERUP:
            case SDL_FINGERMOTION:
            case SDL_DROPFILE:
                return cast(DiInputEvent)ev;
            default:
                throw new NotInputEventException;
        }
    }

    void preDraw() { canvas.preDraw(); }
    void postDraw()
    {
        canvas.postDraw();
        SDL_GL_SwapWindow( win );
    }
    void makeCurrent() { SDL_GL_MakeCurrent( win, ctx.context ); }

    ///
    uint SDLFlags() const @property
    { return SDL_GetWindowFlags( cast(SDL_Window*)win ); }

    void createWindow( string title, ivec2 sz, bool fullscreen, int display )
    {
        _size = sz;
        if( display != -1 && display > SDL_GetNumVideoDisplays() - 1 )
            throw new DiException( format( "No such display: display%d", display ) );

        auto flags = Flag.OPENGL | Flag.SHOWN | ( fullscreen ? Flag.FULLSCREEN : Flag.RESIZABLE );

        auto pos = ivec2( SDL_WINDOWPOS_CENTERED );

        if( display != -1 )
            pos = ivec2( SDL_WINDOWPOS_CENTERED_DISPLAY( display ) );

        win = SDL_CreateWindow( title.toStringz, pos.x, pos.y, _size.x, _size.y, flags );
        if( win is null )
            throw new DiException( "Couldn't create SDL widnow: " ~ toDString( SDL_GetError() ) );
    }

    override void selfDestroy()
    {
        if( win !is null )
            SDL_DestroyWindow( win );
        win = null;
        debug logger.Debug("pass");
    }
}
