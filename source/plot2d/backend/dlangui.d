///
module plot2d.backend.dlangui;

import std.exception : enforce;
import plot2d.backend.base;

version (dlangui):

import dlangui;

alias PPoint = plot2d.Point;
alias PColor = plot2d.Color;

alias UIPoint = dlangui.PointF;
alias UIPointI = dlangui.Point;
alias UIColor = dlangui.Color;

import std.math : floor, ceil;

int floori(double v) { return cast(int)floor(v); }

UIPoint toUI()(auto ref const PPoint p)
{ return UIPoint(p.x, p.y); }

UIPointI toUII()(auto ref const PPoint p)
{ return UIPointI(floori(p.x), floori(p.y)); }

uint toUI()(auto ref const PColor c)
{
    return (cast(uint)(c.r*255))<<16 |
           (cast(uint)(c.g*255))<<8 |
           (cast(uint)(c.b*255));
}

import std.array;
import std.typecons : Tuple;

///
class DlangUICtx : Ctx
{
protected:
    alias Line = Tuple!(PPoint, PPoint);

    static struct State
    {
        PPoint position;
        Appender!(Line[]) lines;
        float lineWidth = 1.0;
        PColor color = PColor.red;
        Rect clip;
        string fontface;
        double fontsize;
    }

    State[] stateStack;

    ref State state() @property { return stateStack.back; }

    void setCurrentState()
    {
        buf.resetClipping();
        buf.clipRect = state.clip;
        buf.alpha = cast(uint)(state.color.a * 255);
    }

    void reset()
    {
        stateStack.length = 1;
        setCurrentState();
    }

    struct StackReseter
    {
        DlangUICtx ctx;
        this(DlangUICtx c) { ctx = c; }
        ~this() { ctx.reset(); }
    }

    DrawBuf buf;

    void drawLineSoft(PPoint a, PPoint b, int c)
    { buf.drawLine(a.toUII, b.toUII, c); }

    void fillTriangleSoft(PPoint p0, PPoint p1, PPoint p2, int clr)
    {
        import std.algorithm : sort;
        auto p = [p0, p1, p2].sort!"a.x < b.x";
        
        auto d1 = floori(p[1].x) - floori(p[0].x);
        auto d2 = floori(p[2].x) - floori(p[1].x);
        auto d3 = p[2].x - p[0].x;

        foreach (i; 0 .. d1+1)
        {
            auto fa = i/cast(float)d1;
            auto a = (p[0] * (1-fa) + p[1] * fa);
            auto fb = (a.x - p[0].x) / d3;
            auto b = (p[0] * (1-fb) + p[2] * fb);
            auto x = p[0].x + i;
            drawLineSoft(PPoint(x, a.y), PPoint(x, b.y), clr);
        }

        foreach (i; 0 .. d2+1)
        {
            auto fa = i/cast(float)d2;
            auto a = (p[1] * (1-fa) + p[2] * fa);
            auto fb = (a.x - p[0].x) / d3;
            auto b = (p[0] * (1-fb) + p[2] * fb);
            auto x = p[1].x + i;
            drawLineSoft(PPoint(x, a.y), PPoint(x, b.y), clr);
        }
    }

public:

    StackReseter set(DrawBuf buf)
    {
        this.buf = buf;
        state.clip = buf.clipRect;
        return StackReseter(this);
    }

    this()
    {
        stateStack.length = 1;
    }

override:
    void save() { stateStack ~= stateStack[$-1]; }

    void restore()
    {
        enforce(stateStack.length > 1, "no saved state");
        stateStack.popBack();
        setCurrentState();
    }

    void stroke()
    {
        setCurrentState();
        auto clr = state.color.toUI;
        foreach (ln; state.lines.data)
            //drawLineSoft(ln[0], ln[1], clr);
            buf.drawLineF(ln[0].toUI, ln[1].toUI,
                          state.lineWidth,
                          state.color.toUI);
        state.lines.clear();
    }

    void fill()
    {
        if (state.lines.data.length == 0) return;
        setCurrentState();
        auto p0 = state.lines.data[0][0];
        auto clr = state.color.toUI;
        foreach (ln; state.lines.data[1..$])
            //fillTriangleSoft(p0, ln[0], ln[1], clr);
            buf.fillTriangleF(p0.toUI, ln[0].toUI,
                             ln[1].toUI, clr);
        state.lines.clear();
    }

    void moveTo(double x, double y)
    { state.position = PPoint(x,y); }

    void lineTo(double x, double y)
    {
        state.lines.put(Line(state.position, PPoint(x,y)));
        moveTo(x, y);
    }

    void setLineWidth(double lw) { state.lineWidth = lw; }

    void showText(string str)
    {
        // TODO
        auto p = state.position;
        Glyph g;
        g.blackBoxX = 10;
        g.blackBoxY = 15;
        g.originX = 0;
        g.originY = 0;
        g.width = 10;
        auto hh = 15;
        g.glyph.length = g.width * hh;
        foreach (i; 0..hh) foreach (j; 0..g.width)
        {
            if (i == j || g.width - i == j)
                g.glyph[i*g.width + j] = 1;
        }
        foreach (c; str)
            buf.drawGlyph(cast(int)p.x, cast(int)p.y, &g,
                            UIColor.red);
    }

    void setDash(double[] dash, double offset)
    {
        // TODO
    }

    void setColor(double r, double g, double b, double a=1)
    { state.color = PColor(r,g,b,a); }

    void getTextSize(string str, out double w, out double h)
    {
        // TODO
        w = str.length * 0.7 * 15;
        h = 15;
    }

    void setFont(string name, double size)
    {
        state.fontface = name;
        state.fontsize = size;
    }

    void clipViewport(Viewport vp)
    {
        state.clip = Rect(cast(int)vp.w.min,
                          cast(int)vp.h.min,
                          cast(int)vp.w.max,
                          cast(int)vp.h.max);
        buf.clipRect = state.clip;
        state.clip = buf.clipRect;
    }
}