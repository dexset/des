module des.gui.shape;

import des.gui.base;

///
interface DiShape
{
    @property
    {
        /// bounding box of area
        DiRect rect() const;

        ///
        DiRect rect( in DiRect );
    }

    ///
    bool contains( in DiVec ) const;
    ///
    bool contains( in DiRect ) const;

    ///
    bool intersect( in DiRect ) const;

    final @property
    {
        DiVec pos() const { return rect.pos; }
        DiVec size() const { return rect.size; }
    }
}

///
class DiRectShape : DiShape
{
protected:

    DiRect bbox;
    DiVec min_size, max_size;

public:

    invariant()
    {
        enforce( min_size.w <= max_size.w );
        enforce( min_size.h <= max_size.h );
    }

    @property
    {
        ///
        DiRect rect() const { return bbox; }

        ///
        DiRect rect( in DiRect r )
        {
            reshape(r);
            return bbox;
        }

        ///
        DiVec minSize() const { return min_size; }
        ///
        DiVec minSize( in DiVec ms ) { min_size = ms; return ms; }

        ///
        DiVec maxSize() const { return max_size; }
        ///
        DiVec maxSize( in DiVec ms ) { max_size = ms; return ms; }
    }

    ///
    bool contains( in DiVec v ) const
    { return v in bbox; }

    ///
    bool contains( in DiRect r ) const
    { return contains( r.pos ) && contains( r.lim ); }

    ///
    bool intersect( in DiRect r ) const
    { return bbox.overlap(r).volume > 0; }

    ///
    bool reshape( in DiRect nr )
    {
        auto nb = calcAllowRect( nr );
        bool ret = bbox != nb;
        bbox = nb;
        return ret;
    }

protected:

    /// use min_size and max_size for calc new rect
    DiRect calcAllowRect( in DiRect r ) const
    {
        auto sz = DiVec( r.size );

        if( sz != r.size )
        {
            if( sz.w > max_size.w ) sz.w = max_size.w;
            if( sz.w < min_size.w ) sz.w = min_size.w;

            if( sz.h > max_size.h ) sz.h = max_size.h;
            if( sz.h < min_size.h ) sz.h = min_size.h;
        }

        return DiRect( r.pos, sz );
    }
}
