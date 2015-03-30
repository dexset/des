module des.fonts.base;

import des.math.linear;
import des.il;

///
class FontException : Exception
{
    ///
    this( string msg, string file=__FILE__, size_t line=__LINE__ ) @safe pure nothrow
    { super( msg, file, line ); }
}

///
struct Glyph
{
    ///
    wstring chars;
    ///
    ivec2 pos;
    ///
    ivec2 next;
    ///
    ivec2 size;
}

///
struct GlyphImage
{
    ///
    Glyph glyph;
    ///
    Image image;
}

///
struct BitmapGlyph
{
    ///
    Glyph glyph;

    /// offset in font image coords
    ivec2 offset;
}

///
struct BitmapFont
{
    ///
    uint height;
    ///
    BitmapGlyph[wchar] info;
    ///
    Image image;
}

///
struct FontRenderParam
{
    ///
    enum Flag : ubyte
    {
        NONE        = 0b0000, ///
        BOLD        = 0b0001, ///
        ITALIC      = 0b0010, ///
        UNDERLINE   = 0b0100, ///
        STRIKED     = 0b1000  ///
    }

    ///
    ubyte flag = Flag.NONE;

    ///
    uint height=14;
}

///
interface FontRender
{
    ///
    void setParams( in FontRenderParam );
    ///
    GlyphImage renderChar( wchar );
    ///
    BitmapFont generateBitmapFont( wstring );
}
