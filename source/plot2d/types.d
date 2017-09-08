///
module plot2d.types;

import plot2d.util;

///
struct DimSeg
{
    ///
    double min = 0, max = 0;

    /// set this.min as min(a,b), this.max as max(a,b)
    this(double a, double b)
    {
        min = .min(a,b);
        max = .max(a,b);
    }

@safe nothrow @nogc:

    /// quantize!round max and min by step and add and sub step
    void stepExpand(double step)
    {
        max = max.quantize!round(step) + step;
        min = min.quantize!round(step) - step;
    }

    /// max - min
    double diff() const @property { return max - min; }
}

///
struct Viewport
{
    ///
    DimSeg w, h;

    static Viewport initial()(auto ref const Point v)
    { return Viewport(DimSeg(v.x, v.x), DimSeg(v.y, v.y)); }

    ///
    void expand()(auto ref const Point p)
    {
        set!max(w.max, p.x);
        set!max(h.max, p.y);
        set!min(w.min, p.x);
        set!min(h.min, p.y);
    }

    ///
    void expand()(auto ref const Viewport o)
    {
        set!max(w.max, o.w.max);
        set!max(h.max, o.h.max);
        set!min(w.min, o.w.min);
        set!min(h.min, o.h.min);
    }

    ///
    void expandRel()(auto ref const Point p)
    {
        if (p.x > 0) w.max += p.x;
        else w.min += p.x; // p.x is negative

        if (p.y > 0) h.max += p.y;
        else h.min += p.y; // p.y is negative
    }

    ///
    bool onBinaryRight(string op)(auto ref const Point p)
        if (op == "in")
    {
        return p.x <= w.max &&
               p.x >= w.min &&
               p.y <= h.max &&
               p.y >= h.min;
    }

pure @safe nothrow @nogc const @property:

    /// left top
    Point lt() { return Point(w.min, h.min); }
    /// left bottom
    Point lb() { return Point(w.min, h.max); }
    /// right top
    Point rt() { return Point(w.max, h.min); }
    /// right bottom
    Point rb() { return Point(w.max, h.max); }
}

///
struct Border
{
    ///
    double left, top, right, bottom;

    ///
    this(double o) { this(o,o,o,o); }
    ///
    this(double x, double y) { this(x,y,x,y); }
    ///
    this(double l, double t, double r, double b)
    { left = l; top = t; right = r; bottom = b; }

    const pure nothrow @safe @property @nogc
    {
        ///
        double sx() { return left + right; }
        ///
        double sy() { return top + bottom; }
    }
}

///
struct Point
{
    ///
    double x, y;

    const pure nothrow
    {
        ///
        Point opBinary(string op)(auto ref const Point b)
        { mixin(q{return Point(x %1$s b.x, y %1$s b.y);}.format(op)); }

        ///
        Point opBinary(string op)(double b)
        { mixin(q{return Point(x %1$s b, y %1$s b);}.format(op)); }

        ///
        Point opUnary(string op)() if (op == "-")
        { return Point(-x, -y); }

        @property
        {
            ///
            double len2() { return x*x + y*y; }
            ///
            double len() { return hypot(x, y); }
        }
    }
}

///
struct Color
{
    ///
    double r=0, g=0, b=0, a=1;

    ///
    auto opBinary(string op)(auto ref const Color c) const pure nothrow
    {
        mixin(q{return Color(r %1$s c.r,
                             g %1$s c.g,
                             b %1$s c.b,
                             a %1$s c.a
                             );}.format(op));
    }

    ///
    auto opBinary(string op)(double c) const pure nothrow
    {
        mixin(q{return Color(r %1$s c,
                             g %1$s c,
                             b %1$s c,
                             a %1$s c
                             );}.format(op));
    }

    static pure nothrow
    {
        ///
        Color red(double v=1, double b=0) { return Color(v, b, b, 1); }
        ///
        Color green(double v=1, double b=0) { return Color(b, v, b, 1); }
        ///
        Color blue(double v=1, double b=0) { return Color(b, b, v, 1); }
        ///
        Color mono(double v=1, double a=1) { return Color(v, v, v, a); }
        ///
        Color none() @property { return Color.mono(0, 0); }
    }
}