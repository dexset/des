module descl.helpers;

import descl;

string getCLDeviceFullInfoString( CLDevice dev, string fmt="", string sep="\n" )
{
    string[] ret;

    if( fmt == "" ) fmt = "    %30 s : %s";

    ret ~= format( fmt, "name",                      dev.name );
    ret ~= format( fmt, "type",                      dev.type );
    ret ~= format( fmt, "available",                 dev.available );
    ret ~= format( fmt, "compiler_available",        dev.compiler_available );
    ret ~= format( fmt, "endian_little",             dev.endian_little );
    ret ~= format( fmt, "profile",                   dev.profile );
    ret ~= format( fmt, "vendor",                    dev.vendor );
    ret ~= format( fmt, "vendor_id",                 dev.vendor_id );
    ret ~= format( fmt, "version",                   dev._version );
    ret ~= format( fmt, "address_bits",              dev.address_bits );

    ret ~= format( fmt, "double_fp_config",          getMaskString!(CLDevice.FPConfig)(dev.double_fp_config) );
    ret ~= format( fmt, "single_fp_config",          getMaskString!(CLDevice.FPConfig)(dev.single_fp_config) );

    ret ~= format( fmt, "error_correction_support",  dev.error_correction_support );
    ret ~= format( fmt, "execution_capabilities",    getMaskString!(CLDevice.ExecCapabilities)(dev.execution_capabilities) );
    ret ~= format( fmt, "extensions",                dev.extensions );
    ret ~= format( fmt, "global_mem_cache_size",     dev.global_mem_cache_size );
    ret ~= format( fmt, "global_mem_cache_type",     getMaskString!(CLDevice.MemCacheType)(dev.global_mem_cache_type) );
    ret ~= format( fmt, "global_mem_cacheline_size", dev.global_mem_cacheline_size );
    ret ~= format( fmt, "global_mem_size",           dev.global_mem_size );
    ret ~= format( fmt, "local_mem_size",            dev.local_mem_size );
    ret ~= format( fmt, "local_mem_type",            getMaskString!(CLDevice.MemCacheType)(dev.local_mem_type) );
    ret ~= format( fmt, "image_support",             dev.image_support );
    ret ~= format( fmt, "image2d_max_height",        dev.image2d_max_height );
    ret ~= format( fmt, "image2d_max_width",         dev.image2d_max_width );
    ret ~= format( fmt, "image3d_max_depth",         dev.image3d_max_depth );
    ret ~= format( fmt, "image3d_max_height",        dev.image3d_max_height );
    ret ~= format( fmt, "image3d_max_width",         dev.image3d_max_width );
    ret ~= format( fmt, "max_clock_frequency",       dev.max_clock_frequency );
    ret ~= format( fmt, "max_compute_units",         dev.max_compute_units );
    ret ~= format( fmt, "max_constant_args",         dev.max_constant_args );
    ret ~= format( fmt, "max_constant_buffer_size",  dev.max_constant_buffer_size );
    ret ~= format( fmt, "max_mem_alloc_size",        dev.max_mem_alloc_size );
    ret ~= format( fmt, "max_parameter_size",        dev.max_parameter_size );
    ret ~= format( fmt, "max_read_image_args",       dev.max_read_image_args );
    ret ~= format( fmt, "max_samplers",              dev.max_samplers );
    ret ~= format( fmt, "max_work_group_size",       dev.max_work_group_size );
    ret ~= format( fmt, "max_work_item_dimensions",  dev.max_work_item_dimensions );
    ret ~= format( fmt, "max_work_item_sizes",       dev.max_work_item_sizes );
    ret ~= format( fmt, "max_write_image_args",      dev.max_write_image_args );
    ret ~= format( fmt, "mem_base_addr_align",       dev.mem_base_addr_align );
    ret ~= format( fmt, "min_data_type_align_size",  dev.min_data_type_align_size );
    ret ~= format( fmt, "preferred_vector_width_char", dev.preferred_vector_width_char );
    ret ~= format( fmt, "preferred_vector_width_short", dev.preferred_vector_width_short );
    ret ~= format( fmt, "preferred_vector_width_int", dev.preferred_vector_width_int );
    ret ~= format( fmt, "preferred_vector_width_long", dev.preferred_vector_width_long );
    ret ~= format( fmt, "preferred_vector_width_float", dev.preferred_vector_width_float );
    ret ~= format( fmt, "preferred_vector_width_double", dev.preferred_vector_width_double );
    ret ~= format( fmt, "profiling_timer_resolution", dev.profiling_timer_resolution );
    ret ~= format( fmt, "queue_properties",          getMaskString!(CLDevice.CommandQueueProperies)(dev.queue_properties) );

    return ret.join(sep);
}

import std.traits;

string getMaskString(T)( ulong mask )
{
    string[] ret;
    foreach( v; [EnumMembers!T] )
        if( mask & cast(ulong)v )
            ret ~= format( "%s", v );
    return ret.join(" | ");
}
