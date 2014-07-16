module descl.program;

import descl.base;
import descl.device;
import descl.context;

class CLProgram : CLReference
{
package cl_program id;

protected:

    this( cl_program id ) { this.id = id; }
    CLDevice[] last_build_devices;

public:

    static CLProgram createWithSource( CLContext context, string source )
    {
        int retcode;
        char[] str = source.dup;
        char* buf = str.ptr;
        auto id = clCreateProgramWithSource( context.id, 1, 
                     &buf, [source.length].ptr, &retcode );
        checkError( retcode, "clCreateProgramWithSource" );

        return new CLProgram(id);
    }

    void release() { checkCall!(clReleaseProgram)(id); }

    void build( CLDevice[] devices, CLBuildOption[] options=[] )
    {
        last_build_devices = devices.dup;
        checkCall!(clBuildProgram)( id,
                cast(uint)devices.length,
                amap!(a=>a.id)(devices).ptr,
                getOptionsStringz( options ),
                null, null /+ callback and userdata for callback +/ );
    }

    enum BuildStatus
    {
        NONE        = CL_BUILD_NONE,
        ERROR       = CL_BUILD_ERROR,
        SUCCESS     = CL_BUILD_SUCCESS,
        IN_PROGRESS = CL_BUILD_IN_PROGRESS
    }

    static struct BuildInfo
    {
        CLDevice device;
        BuildStatus status;
        string log;

        string toString() { return format( "%s for %s:\n%s", status, device.name, log ); }
    }

    BuildInfo[] buildInfo()
    {
        BuildInfo[] ret;
        foreach( dev; last_build_devices )
            ret ~= BuildInfo( dev,
                    buildStatusForDevice(dev), 
                    buildLogForDevice( dev ) );
        return ret;
    }

protected:

    auto getOptionsStringz( CLBuildOption[] options )
    {
        if( options.length == 0 ) return null;
        return amap!(a=>a.toString)(options).join(" ").toStringz;
    }

    BuildStatus buildStatusForDevice( CLDevice device )
    {
        cl_build_status val;
        size_t len;
        checkCall!(clGetProgramBuildInfo)( id, device.id, 
                CL_PROGRAM_BUILD_STATUS, cl_build_status.sizeof, &val, &len );
        return cast(BuildStatus)val;
    }

    string buildLogForDevice( CLDevice device )
    {
        size_t len;
        checkCall!(clGetProgramBuildInfo)( id, device.id, 
                CL_PROGRAM_BUILD_LOG, 0, null, &len );
        auto val = new char[](len);
        checkCall!(clGetProgramBuildInfo)( id, device.id, 
                CL_PROGRAM_BUILD_LOG, val.length, val.ptr, &len );
        return val.idup;
    }
}

interface CLBuildOption
{
    string toString();

    static
    {
        CLBuildOption define( string name, string val=null )
        {
            return new class CLBuildOption
            { 
                override string toString()
                { return format( "-D %s%s", name, (val?"="~val:"") ); }
            };
        }

        CLBuildOption directory( string dir )
        {
            return new class CLBuildOption
            { override string toString() { return format( "-l %s", dir ); } };
        }

        @property CLBuildOption inhibitAllWarningMessages()
        {
            return new class CLBuildOption
            { override string toString() { return "-w"; } };
        }

        @property CLBuildOption makeAllWarningsIntoErrors()
        {
            return new class CLBuildOption
            { override string toString() { return "-Werror"; } };
        }

        private
        {
            enum string[] simple_cl_options =
            [
                "single-precision-constant",
                "denorms-are-zero",
                "opt-disable",
                "strict-aliasing",
                "mad-enable",
                "no-signed-zeros",
                "unsafe-math-optimizations",
                "finite-math-only",
                "fast-relaxed-math"
            ];

            private string simpleCLOptionsListFunctionsString( in string[] list )
            { return amap!(a=>simpleCLOptionFunctionString(a))(list).join("\n"); }

            string simpleCLOptionFunctionString( string opt )
            {
                return format(`
            static @property CLBuildOption %s()
            {
                return new class CLBuildOption
                { override string toString() { return "-cl-%s"; } };
            }`, toCamelCase(opt,"-",false), opt );
            }
        }

        mixin( simpleCLOptionsListFunctionsString( simple_cl_options ) );
    }
}
