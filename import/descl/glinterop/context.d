module descl.glinterop.context;

import descl.base;
import descl.device;
import descl.platform;
import descl.context;

class CLGLContext : CLContext
{
public:

    this( CLPlatform pl ) { super(pl); }

protected:
    override cl_context_properties[] getProperties()
    {
        version(linux)
        {
            import derelict.opengl3.glx;
            return [ CL_GL_CONTEXT_KHR, cast(cl_context_properties)glXGetCurrentContext(),
                    CL_GLX_DISPLAY_KHR, cast(cl_context_properties)glXGetCurrentDisplay() ] ~
                super.getProperties();
        }
        version(Windows)
        {
            // TODO
            static assert(0, "not implemented");
        }
        version(OSX)
        {
            // TODO
            static assert(0, "not implemented");
        }
    }
}
