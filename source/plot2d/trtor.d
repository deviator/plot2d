///
module plot2d.trtor;

import plot2d.types;
import plot2d.util;

///
class Trtor
{
protected:
    Point _size, _scale, _offset, _gridStep, _gridOffset;
    Viewport _viewport;
    Border _margin, _padding;

public:
    ///
    this(){}

    @property
    {
        const
        {
            /// drawing area size
            ref const(Point) size() { return _size; }
            /// chart margin (axis offset)
            ref const(Border) margin() { return _margin; }
            ///
            Viewport inMargin()
            {
                return Viewport(
                    DimSeg(_margin.left, _size.x - _margin.right),
                    DimSeg(_margin.top, _size.y - _margin.bottom)
                );
            }
            ///
            Viewport inPadding()
            {
                return Viewport(
                    DimSeg(_margin.left + _padding.left,
                           _size.x - _margin.right - _padding.right),
                    DimSeg(_margin.top + _padding.top,
                           _size.y - _margin.bottom - _padding.bottom)
                );
            }

            /// chart padding inside axis
            ref const(Border) padding() { return _padding; }
            /// limits of displayed values of data
            ref const(Viewport) viewport() { return _viewport; }
            /// transform coeficient
            ref const(Point) scale() { return _scale; }
            /// ditto
            ref const(Point) offset() { return _offset; }
            ///
            ref const(Point) gridStep() { return _gridStep; }
            ///
            ref const(Point) gridOffset() { return _gridOffset; }
        }

        ///
        void size(Point s) { _size = s; recalc(); }

        ///
        void margin(Border m) { _margin = m; recalc(); }

        ///
        void padding(Border p) { _padding = p; recalc(); }

        ///
        void viewport(Viewport v) { _viewport = v; recalc(); }

        ///
        void gridStep(Point s) { _gridStep = s; }

        ///
        void gridOffset(Point s) { _gridOffset = s; }
    }

    ///
    void setSMPV(Point size, Border margin,
                 Border padding, Viewport viewport)
    {
        _size = size;
        _margin = margin;
        _padding = padding;
        _viewport = viewport;
        recalc();
    }

    ///
    void recalc()
    {
        _scale = calcScale(_viewport);
        recalcOffset(); // scale used
    }

    ///
    Point calcScale()(auto ref const Viewport v)
    {
        alias m = _margin;
        alias p = _padding;
        return Point(
            (_size.x - m.sx - p.sx) / v.w.diff,
            (-_size.y + m.sy + p.sy) / v.h.diff);
        //   ^-- drawing area has downside Y direction
    }

    ///
    void recalcOffset()
    {
        alias m = _margin;
        alias p = _padding;
        alias s = _size;
        alias v = _viewport;
        _offset = Point(m.left + p.left,
                        s.y - m.bottom - p.bottom)
                        - Point(v.w.min, v.h.min) * _scale;
    }

    ///
    void correctGridOffset()
    {
        auto im = inMargin;
        auto orig = Point(im.w.min, im.h.max);
        auto p0 = toCh(orig);
        auto chgs = _gridStep / _scale;
        p0 = Point(p0.x.quantize!ceil(chgs.x),
                   p0.y.quantize!ceil(-chgs.y));
        auto r = toDA(p0) - orig;
        _gridOffset = Point(r.x, -r.y);
    }

    ///
    void optimizeGridStep(Point minGridCellSize)
    {
        double cs(double m, double delegate(double) stepper)
        {
            auto mv = max(abs(m), double.epsilon * 1e2);
            double rs;
            if (stepper is null)
                rs = roundStepFunc!10(mv);
            else
                rs = stepper(mv);
            return mv.quantize!ceil(rs);
        }

        auto m = minGridCellSize / _scale;
        auto r = Point(cs(m.x, calcXGridStep),
                       cs(m.y, calcYGridStep)) * _scale;
        _gridStep = Point(abs(r.x), abs(r.y));
    }

    ///
    double delegate(double) calcXGridStep, calcYGridStep;

    import std.traits : isNumeric;

    ///
    static double roundStepFunc(alias bais)(double val) nothrow @nogc
        if (isNumeric!(typeof(bais)))
    {
        alias mlog = std.math.log;
        enum z = mlog(bais);
        return bais ^^ floor(mlog(val) / z);
    }

    const pure nothrow @nogc @safe
    {
        /// transfrom coord from chart to drawing area
        Point toDA(double x, double y) { return toDA(Point(x,y)); }
        /// ditto
        Point toDA(Point p) { return p * _scale + _offset; }
        /// ditto
        double toDAX(double x) { return x * _scale.x + _offset.x; }
        /// ditto
        double toDAY(double y) { return y * _scale.y + _offset.y; }

        /// transform coord from drawing area to chart
        Point toCh(double x, double y) { return toCh(Point(x,y)); }
        /// ditto
        Point toCh(Point p) { return (p - _offset) / _scale; }
        /// ditto
        double toChX(double x) { return (x - _offset.x) / _scale.x; }
        /// ditto
        double toChY(double y) { return (y - _offset.y) / _scale.y; }
    }
}