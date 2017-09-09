///
module plot2d.backend.dlangui;

import std.exception : enforce;
import plot2d.backend.base;

version (dlangui):

import dlangui;

alias PPoint = plot2d.Point;
alias PColor = plot2d.Color;

alias UIPoint = dlangui.PointF;
alias UIColor = dlangui.Color;

UIPoint toUI()(auto ref const PPoint p)
{ return UIPoint(p.x, p.y); }

uint toUI()(auto ref const PColor c)
{
    return (cast(uint)c.r*255)<<16 &
           (cast(uint)c.g*255)<<8 &
           (cast(uint)c.b*255)<<0;
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
        PColor color;
        Rect clip;
    }

    State[] stateStack;

    ref State state() @property { return stateStack.back; }

    void setCurrentState()
    {
        buf.resetClipping();
        buf.clipRect = state.clip;
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
        buf.alpha = cast(uint)(state.color.a * 255);
        foreach (ln; state.lines.data)
            buf.drawLineF(ln[0].toUI, ln[1].toUI,
                          state.lineWidth,
                          state.color.toUI);
        state.lines.clear();
    }

    void fill()
    {
        if (state.lines.data.length == 0) return;
        buf.alpha = cast(uint)(state.color.a * 255);
        auto p0 = state.lines.data[0][0];
        foreach (ln; state.lines.data[1..$])
            buf.fillTriangleF(p0.toUI, ln[0].toUI,
                             ln[1].toUI, state.color.toUI);
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
        
    }

    void setDash(double[] dash, double offset)
    {
        
    }

    void setColor(double r, double g, double b, double a=1)
    { state.color = PColor(r,g,b,a); }

    void getTextSize(string str, out double w, out double h)
    {
        // TODO
    }

    void setFont(string name, double size)
    {
        // TODO
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