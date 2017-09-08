module plot2d.backend;

import plot2d.types;

version (cairo_be)
{
    public import cairo.Context;
    alias Ctx = Context;

    Ctx getTestCtx() { return new Context(null, true); }

    void setColor(Ctx cr, double r, double g, double b, double a)
    { cr.setSourceRgba(r,g,b,a); }

    void clipViewport(Ctx cr, Viewport vp)
    {
        cr.moveTo(vp.w.min, vp.h.min);
        cr.lineTo(vp.w.max, vp.h.min);
        cr.lineTo(vp.w.max, vp.h.max);
        cr.lineTo(vp.w.min, vp.h.max);
        cr.lineTo(vp.w.min, vp.h.min);
        cr.clip();
        cr.newPath();
    }

    void getTextSize(Ctx cr, string str, ref Point ret)
    {
        cairo_text_extents_t te;
        cr.textExtents(str, &te);
        ret.x = te.width;
        ret.y = te.height;
    }

    void setFont(Ctx cr, string name, double size)
    {
        cr.selectFontFace(name,
            cairo_font_slant_t.NORMAL,
            cairo_font_weight_t.NORMAL);
        cr.setFontSize(size);
    }
}
else
{
    static assert(0, "not supported backend");
}

mixin template checkCtxFunc(string f, Args...)
{
    import std.traits : ReturnType;
    static assert(is(ReturnType!getTestCtx == Ctx),
        "no 'getTestCtx' function for creation test context");
    import std.string : format;
    import std.meta : staticMap;

    static template str(T) { enum str = T.stringof; }
    static template ini(T) { enum ini = T.init; }

    bool impl(string tt)()
    {
        bool ff(Ctx c)
        {
            Args args;
            mixin(format("c.%s(args);", tt));
            return true;
        }
        return ff(getTestCtx());
    }

    static assert(is(typeof(impl!f)),
        format("Backend %s doesn't support %s(%-(%s,%)) function",
                 Ctx.stringof, f, cast(string[])[staticMap!(str, Args)]));

    mixin("enum ctxHave_"~f~" = true;");
}

mixin checkCtxFunc!("save");
mixin checkCtxFunc!("restore");
mixin checkCtxFunc!("stroke");
mixin checkCtxFunc!("fill");
mixin checkCtxFunc!("moveTo", double, double);
mixin checkCtxFunc!("lineTo", double, double);
mixin checkCtxFunc!("setLineWidth", double);
mixin checkCtxFunc!("showText", string);
mixin checkCtxFunc!("setDash", double[], double);
mixin checkCtxFunc!("setColor", double, double, double, double);
mixin checkCtxFunc!("getTextSize", string, Point);
mixin checkCtxFunc!("clipViewport", Viewport);

/++ mixin string for saving Context
    and restore on exit from scope
+/
string scopeSave(alias cr)()
    if (is(typeof(cr) == Ctx))
{
    import std.string : format;
    return format(q{
        %1$s.save();
        scope(exit)
            %1$s.restore();
    }, __traits(identifier, cr));
}

void moveToP(P)(Ctx cr, P p) { cr.moveTo(p.x, p.y); }
void lineToP(P)(Ctx cr, P p) { cr.lineTo(p.x, p.y); }

void lineP2P()(Ctx cr,
            auto ref const Point p0,
            Point[] ps...)
{
    cr.moveToP(p0);
    foreach (p; ps) cr.lineToP(p);
}

void lineP2P()(Ctx cr,
            double x1, double y1,
            double x2, double y2)
{ cr.lineP2P(Point(x1, y1), Point(x2, y2)); }

void setColor(C)(Ctx cr, C c)
{ cr.setColor(c.r, c.g, c.b, c.a); }

void setColor(C)(Ctx cr, C c, double a)
{ cr.setColor(c.r, c.g, c.b, a); }