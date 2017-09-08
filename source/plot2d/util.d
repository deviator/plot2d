///
module plot2d.util;

public
{
    import std.math;
    import std.algorithm;
    import std.range;
    import std.string : format;
    import std.conv : to, text;
    import std.experimental.logger;

    import plot2d.backend;
}

///
void set(alias f, T)(ref T value, auto ref const T b)
{ value = f(value, b); }
