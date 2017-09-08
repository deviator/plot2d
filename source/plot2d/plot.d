///
module plot2d.plot;

import std.datetime : StopWatch;

import std.stdio;

import plot2d.drawable;
import plot2d.axis;
import plot2d.label;
import plot2d.style;
import plot2d.trtor;
import plot2d.chart;
import plot2d.util;

///
class Plot
{
public:
    ///
    struct Settings
    {
        ///
        Viewport viewport = {w: DimSeg(0, 1), h: DimSeg(0, 1)};

        /// use summury charts viewports
        bool autoFit = true;

        ///
        Point minGridStep = Point(20,20);

        /// from border to axis
        Border margin = Border(60, 10, 40, 40);

        /// from axis to charts
        Border padding = Border(0, 10);
    }

    ///
    Settings settings;

    ///
    Trtor tr;
    /// namespaced style
    NSStyle st;

    ///
    Axis axis;
    ///
    Grid grid;
    ///
    LBGridLabel label;

    ///
    Chart[] charts;

    ///
    this(Label.Formatter fmter)
    {
        fmter = fmter is null ? new DefaultLabelFormatter : fmter;

        tr = new Trtor;
        st = new NSStyle;

        axis = new LBAxis();
        grid = new Grid();
        grid.dash = [5, 8];
        label = new LBGridLabel(fmter);

        //this.gsc = gsc is null ? new DefaultGridStepCalculator : gsc;

        //st.number.set("label.fontsize", 15);
        //st.strval.set("label.fontface", "Monospace");
        //st.color.set("label.color", Color(0,0,0,0.8));

        //st.number.set("axis.linewidth", 1.5);
        //st.color.set("axis.color", Color(0,0,0,.7));

        //st.number.set("grid.linewidth", 1);
        //st.color.set("grid.color", Color(0,0,0,.2));

        //st.number.set("linechart.linewidth", 2);

        //st.number.set("trechart.linewidth", 2);
        //st.number.set("trechart.limlinewidth", 1);
    }

    ///
    static auto defaultFmtFunc(double value, double step)
    {
        import std.string;
        auto sf = format("%f", step).tr("0", " ").strip.split(".");
        return format("%.*f", sf[1].length, value);
    }

    static class DefaultLabelFormatter : Label.Formatter
    {
        string maxX = "0.0", maxY = "0.0";
    override:
        string x(double v, double s)
        {
            auto r = defaultFmtFunc(v, s);
            if (r.length > maxX.length) maxX = r;
            return r;
        }

        string y(double v, double s)
        {
            auto r = defaultFmtFunc(v, s);
            if (r.length > maxY.length) maxY = r;
            return r;
        }

        string maxXValue() @property { return maxX; }
        string maxYValue() @property { return maxY; }
    }

    void update() { foreach (c; charts) c.update(); }

    void draw(Ctx cr, Point size)
    {
        if (recalculateTrtor(cr, size)) return;
        drawElements(cr);
    }

protected:

    int recalculateTrtor(Ctx cr, Point sz)
    {
        auto vp = getViewport();

        tr.setSMPV(sz, settings.margin, settings.padding, vp);

        Point lmgs;
        {
            mixin(scopeSave!cr);
            lmgs = label.minGridStep(cr, st);
        }

        tr.optimizeGridStep(
            Point(max(settings.minGridStep.x, lmgs.x * 1.25),
                  max(settings.minGridStep.y, lmgs.y * 1.25)));

        // invert '<=' to '>' for nan-check
        if (tr.gridStep.x > 0 && tr.gridStep.y > 0) { }
        else
        {
            .warning("bad grid step: ", tr.gridStep);
            return 1;
        }

        correctGridOffset();
        return 0;
    }

    Viewport getViewport()
    {
        Viewport ret = settings.viewport;

        if (charts.length == 0 ||
            !settings.autoFit) return ret;

        bool s = false; // for setup first viewport
        foreach (c; charts.filter!"a.visible")
        {
            if (s) ret.expand(c.viewport);
            else { ret = c.viewport; s = true; }
        }

        double minViewDiff = double.epsilon * 1e3;

        if (abs(ret.w.diff) < minViewDiff)
            ret.w.stepExpand(minViewDiff);

        if (abs(ret.h.diff) < minViewDiff)
            ret.h.stepExpand(minViewDiff);

        return ret;
    }

    void correctGridOffset()
    {
        auto im = tr.inMargin;
        auto gs = tr.gridStep;
        auto s = tr.scale;

        auto orig = Point(im.w.min, im.h.max);
        auto p0 = tr.toCh(orig);
        auto chgs = gs / s;
        p0 = Point(p0.x.quantize!ceil(chgs.x),
                   p0.y.quantize!ceil(-chgs.y));
        auto r = tr.toDA(p0) - orig;
        tr.gridOffset = Point(r.x, -r.y);
    }

    void drawElements(Ctx cr)
    {
        foreach (p; chain(only(cast(Drawable)axis,
                               cast(Drawable)grid,
                               cast(Drawable)label),
                    charts.map!(a=>cast(Drawable)a)))
        {
            if (p is null) continue;
            mixin(scopeSave!cr);
            p.draw(cr, tr, st);
        }
    }
}