module descl.context;

import descl.base;
import descl.device;
import descl.platform;

class CLContext : CLReference
{
package cl_context id;
package CLPlatform platform;

private bool inited = false;
package bool isInited() const { return inited; }

public:

    this( CLPlatform pl ) { this.platform = pl; }

    final void initializeFromType( CLDevice.Type type=CLDevice.Type.GPU )
    {
        auto prop = getProperties();

        int retcode;
        auto ctx_id = clCreateContextFromType( prop.ptr, type,
                                               null, // pointer to callback function
                                               null, // user data
                                               &retcode );

        checkError( retcode, "clCreateContextFromType" );
        id = ctx_id;
        inited = true;
    }

    final void initializeFromDevices( CLDevice[] devices... )
    {
        auto prop = getProperties();

        int retcode;
        auto ctx_id = clCreateContext( prop.ptr,
                                       cast(uint)devices.length,
                                       amap!(a=>a.id)(devices).ptr,
                                       null, // pointer to callback function
                                       null, // user data
                                       &retcode );

        checkError( retcode, "clCreateContext" );
        id = ctx_id;
        inited = true;
    }

    /+
        TODO: fill
        type:param_name,
        cl_type:dlang_type:param_name
    +/
    static private enum prop_list = 
    [
        "uint:reference_count"
    ];

    mixin( infoProperties( "context", prop_list ) );

    void release()
    {
        checkCall!(clReleaseContext)(id);
        inited = false;
    }

protected:

    cl_context_properties[] getProperties()
    {
        return [ CL_CONTEXT_PLATFORM, cast(cl_context_properties)(platform.id), 0 ];
    }
}
