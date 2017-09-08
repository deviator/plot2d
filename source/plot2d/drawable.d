module plot2d.drawable;

import std.exception : enforce;

public
{
    import plot2d.backend;
    import plot2d.util;
    import plot2d.types;
    import plot2d.style;
    import plot2d.trtor;
}

///
interface Drawable
{
    ///
    void draw(Ctx, Trtor, Style);
}