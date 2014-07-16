module descl.platform;

import descl.base;

class CLPlatform
{
package cl_platform_id id;

protected:

    this( cl_platform_id id )
    {
        this.id = id;
        updateProperties();
    }

public:

    static CLPlatform[] getAll()
    {
        cl_uint nums;
        checkCall!(clGetPlatformIDs)( 0, null, &nums );
        auto ids = new cl_platform_id[](nums);
        checkCall!(clGetPlatformIDs)( nums, ids.ptr, &nums );
        CLPlatform[] buf;
        foreach( id; ids )
            buf ~= new CLPlatform(id);
        return buf;
    }

    /+
        type:param_name,
        cl_type:dlang_type:param_name
    +/
    static private enum prop_list =
    [
        "string:name",
        "string:vendor",
        "string:profile",
        "string:version",
        "string:extensions"
    ];

    mixin( infoProperties( "platform", prop_list ) );
}
