module plot2d.chart.base;

public import plot2d.chart.types;
public import plot2d.drawable;

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
}

///
class BaseChart(T) : Chart
{
protected:
    ///
    Viewport vp;

    Appender!(T[]) buffer;
    void delegate(ref Appender!(T[])) fillData;

    void expandViewport(size_t i, ref const T val);

public:

    this(void delegate(ref Appender!(T[])) fillData)
    { this.fillData = fillData; }

    override 
    {
        bool visible() const @property { return !buffer.data.empty; }
        ref const(Viewport) viewport() const @property { return vp; }
    }

    ///
    override void update()
    {
        buffer.clear();
        vp = Viewport(DimSeg(0, 1), DimSeg(0, 1));

        fillData(buffer);

        if (buffer.data.length == 0)
        {
            .warning("buffer is empty");
            return;
        }

        foreach (i, ref const t; buffer.data)
            expandViewport(i, t);
    }

    ///
    abstract void draw(Ctx cr, Trtor tr, Style st);
}