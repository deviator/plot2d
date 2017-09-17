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
class BaseChart(T) : Chart, Stylized
{
    mixin StylizedHelper;
protected:
    ///
    Viewport vp;

    Appender!(Elem[]) buffer;
    BufferFiller fillData;

    abstract void expandViewport(ref const Elem val, ref bool inited);

public:

    alias Elem = T;
    alias BufferFiller = void delegate(ref Appender!(Elem[]));

    this(BufferFiller fillData) { this.fillData = fillData; }

    override const @property
    {
        bool visible() { return !buffer.data.empty; }
        ref const(Viewport) viewport() { return vp; }
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

        bool inited;
        foreach (ref const t; buffer.data)
            expandViewport(t, inited);
    }

    ///
    abstract void draw(Ctx cr, Trtor tr);
}