module plot2d.chart;

import plot2d.drawable;

///
interface Chart : Drawable
{
    @property
    {
        ///
        ref const(Viewport) viewport() const;
        ///
        bool visible() const;
    }

    /// update buffered data and viewport
    void update();

    ///
    void drawLegend(Ctx cr);
}

///
class BaseChart : Chart
{
protected:
    ///
    Viewport vp;

public:

    override 
    {
        bool visible() const @property { return true; }
        ref const(Viewport) viewport() const @property { return vp; }
        void drawLegend(Ctx cr) {}
    }

    abstract
    {
        ///
        void update();
        ///
        void draw(Ctx cr, Trtor tr, Style st);
    }
}

///
class LineChart : BaseChart
{
protected:
    void delegate(ref Appender!(Point[])) fillData;
    Appender!(Point[]) buffer;

public:
    ///
    Color stroke;
    ///
    double[] dash = [];
    ///
    double dashOffset = 0;

    ///
    this(Color stroke,
         void delegate(ref Appender!(Point[])) fd)
    {
        this.stroke = stroke;
        this.fillData = fd;
    }

    override
    {
        bool visible() const @property
        { return buffer.data.length != 0; }

        void update()
        {
            buffer.clear();
            vp = Viewport(DimSeg(0, 1), DimSeg(0, 1));

            fillData(buffer);

            if (buffer.data.length == 0)
            {
                .warning("buffer is empty");
                return;
            }

            auto p0 = buffer.data.front;

            vp = Viewport(DimSeg(p0.x, p0.x), DimSeg(p0.y, p0.y));

            foreach (p; buffer.data) vp.expand(p);
        }

        void draw(Ctx cr, Trtor tr, Style style)
        {
            if (buffer.data.length == 0) return;

            cr.setLineWidth(style.number.get("linewidth", 2));    
            cr.setDash(dash, dashOffset);
            cr.setColor(stroke);
            
            cr.clipViewport(tr.inPadding);

            cr.moveToP(tr.toDA(buffer.data.front));

            foreach (val; buffer.data)
            {
                cr.lineToP(tr.toDA(val));
                // TODO: DIZASTIr
            }
            cr.stroke();
        }
    }
}

///
class TripleChart : BaseChart
{
    struct Tre
    {
        double tm, max, val, min;
        alias P = Point;

    const pure nothrow @nogc @safe @property:
        P[3] points() { return [maxPnt, valPnt, minPnt]; }
        P maxPnt() { return P(tm, max); }
        P minPnt() { return P(tm, min); }
        P valPnt() { return P(tm, val); }
    }

    Color fillUp, fillDown, stroke, strokeLimUp, strokeLimDown;

    double disaster;
    double disasterCoef = 3; // must be > 1

    void delegate(ref typeof(buffer)) fillData;
    Appender!(Tre[]) buffer;

    this(Color stroke,
         Color strokeLimUp, Color fillUp,
         Color strokeLimDown, Color fillDown,
         void delegate(ref typeof(buffer)) fd)
    {
        this.stroke = stroke;
        this.fillUp = fillUp;
        this.fillDown = fillDown;
        this.strokeLimUp = strokeLimUp;
        this.strokeLimDown = strokeLimDown;
        this.fillData = fd;
    }

    override
    {
        bool visible() const @property { return buffer.data.length != 0; }

        void update()
        {
            buffer.clear();
            vp = Viewport(DimSeg(0, 1), DimSeg(0, 1));

            fillData(buffer);

            if (buffer.data.length == 0)
            {
                .warning("buffer is empty");
                return;
            }

            auto p0 = buffer.data.front;

            vp = Viewport(DimSeg(p0.tm, p0.tm), DimSeg(p0.min, p0.max));
            import std.stdio;

            foreach (tre; buffer.data)
                foreach (p; tre.points)
                    vp.expand(p);

            auto avg_diff = 0.0;
            foreach (a, b; lockstep(buffer.data[0..$-1], buffer.data[1..$]))
                avg_diff += b.tm - a.tm;
            avg_diff /= buffer.data.length;
            disaster = avg_diff * disasterCoef;
        }

        void draw(Ctx cr, Trtor tr, Style style)
        {
            auto limlinewidth = style.number.get("limlinewidth", 1);
            auto linewidth = style.number.get("linewidth", 2);

            if (buffer.data.length == 0) return;

            cr.clipViewport(tr.inPadding);

            auto lst = buffer.data.front;

            foreach (val; buffer.data[1..$])
            {
                //if (val.tm - lst.tm > disaster)
                //{ lst = val; continue; }

                cr.setColor(fillUp);
                cr.lineP2P(tr.toDA(lst.maxPnt),
                           tr.toDA(lst.valPnt),
                           tr.toDA(val.maxPnt));
                cr.fill();
                cr.lineP2P(tr.toDA(lst.valPnt),
                           tr.toDA(val.maxPnt),
                           tr.toDA(val.valPnt));
                cr.fill();

                cr.setColor(fillDown);
                cr.lineP2P(tr.toDA(lst.valPnt),
                           tr.toDA(lst.minPnt),
                           tr.toDA(val.valPnt));
                cr.fill();
                cr.lineP2P(tr.toDA(lst.minPnt),
                           tr.toDA(val.valPnt),
                           tr.toDA(val.minPnt));
                cr.fill();

                cr.setLineWidth(limlinewidth);

                cr.setColor(strokeLimUp);
                cr.lineP2P(tr.toDA(lst.maxPnt), tr.toDA(val.maxPnt));
                cr.stroke();

                cr.setColor(strokeLimDown);
                cr.lineP2P(tr.toDA(lst.minPnt), tr.toDA(val.minPnt));
                cr.stroke();

                cr.setLineWidth(linewidth);    
                cr.setColor(stroke);
                cr.lineP2P(tr.toDA(lst.valPnt), tr.toDA(val.valPnt));
                cr.stroke();

                lst = val;
            }
        }
    }
}