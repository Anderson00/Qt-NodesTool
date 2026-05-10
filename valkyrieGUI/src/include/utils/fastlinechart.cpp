#include "fastlinechart.h"
#include <QSGGeometryNode>
#include <QSGFlatColorMaterial>
#include <QSGVertexColorMaterial>
#include <QSGGeometry>
#include <QQuickItemGrabResult>
#include <cmath>

const QColor FastLineChart::kDefaultColors[8] = {
    QColor("#e74c3c"), QColor("#f39c12"), QColor("#2ecc71"), QColor("#3498db"),
    QColor("#9b59b6"), QColor("#1abc9c"), QColor("#e67e22"), QColor("#ec407a")
};

// ── SGG node layout ───────────────────────────────────────────────────────────
//   grid → overlay(reflines+markers) → fills → glows → lines → mavgs
// This ordering ensures fills render behind all lines, and overlays on top.
struct ChartRootNode : QSGNode {
    QSGGeometryNode          *gridNode    = nullptr;
    QSGGeometryNode          *overlayNode = nullptr; // ref lines + markers (vertex-colored)
    QSGNode                  *fillLayer   = nullptr;
    QSGNode                  *glowLayer   = nullptr;
    QSGNode                  *lineLayer   = nullptr;
    QSGNode                  *mavgLayer   = nullptr;
    QVector<QSGGeometryNode*> fillNodes;
    QVector<QSGGeometryNode*> glowNodes;
    QVector<QSGGeometryNode*> lineNodes;
    QVector<QSGGeometryNode*> mavgNodes;
};

// ── Node factories ────────────────────────────────────────────────────────────

static QSGGeometryNode *makeFlatNode()
{
    auto *n = new QSGGeometryNode();
    n->setFlag(QSGNode::OwnsMaterial, true);
    n->setFlag(QSGNode::OwnsGeometry, true);
    n->setMaterial(new QSGFlatColorMaterial());
    n->setGeometry(new QSGGeometry(QSGGeometry::defaultAttributes_Point2D(), 0));
    return n;
}

static QSGGeometryNode *makeColoredNode()
{
    auto *n = new QSGGeometryNode();
    n->setFlag(QSGNode::OwnsMaterial, true);
    n->setFlag(QSGNode::OwnsGeometry, true);
    n->setMaterial(new QSGVertexColorMaterial());
    n->setGeometry(new QSGGeometry(QSGGeometry::defaultAttributes_ColoredPoint2D(), 0));
    return n;
}

static QSGNode *makeLayerNode() { return new QSGNode(); }

// ── Helpers ───────────────────────────────────────────────────────────────────

static void screenDedup(QVector<float> &ox, QVector<float> &oy,
                        const QVector<QPointF> &pts,
                        float W, float H,
                        double xMn, double xRng, double yMn, double yRng)
{
    ox.clear(); oy.clear();
    if (pts.isEmpty()) return;
    ox.reserve(pts.size() * 3); oy.reserve(pts.size() * 3);
    
    // Para resolver o problema de "degraus" (quantização), implementamos
    // uma interpolação Catmull-Rom que suaviza a transição entre pontos.
    auto getPt = [&](int i) -> QPointF {
        int idx = qBound(0, i, (int)pts.size() - 1);
        return pts[idx];
    };

    // 1. Pré-processamento: Filtro Passa-Baixa seletivo (apenas em áreas suaves)
    const double yRange = yRng;
    const double edgeThreshold = yRange * 0.12; 
    QVector<QPointF> processed = pts;
    if (pts.size() > 2) {
        for (int i = 1; i < (int)pts.size() - 1; ++i) {
            double dy1 = std::abs(pts[i].y() - pts[i - 1].y());
            double dy2 = std::abs(pts[i + 1].y() - pts[i].y());
            // Só suaviza se não houver um salto brusco adjacente
            if (dy1 < edgeThreshold && dy2 < edgeThreshold) {
                processed[i].setY((pts[i - 1].y() + 2.0 * pts[i].y() + pts[i + 1].y()) / 4.0);
            }
        }
    }

    // 2. Renderização Híbrida
    for (int i = 0; i < (int)processed.size() - 1; ++i) {
        QPointF p1 = processed[i];
        QPointF p2 = processed[i + 1];
        double dy = std::abs(p2.y() - p1.y());

        if (dy > edgeThreshold) {
            // SALTO BRUSCO: Renderiza linha reta (onda quadrada)
            for (int step = 0; step < 2; ++step) {
                float t = (float)step;
                float cx = static_cast<float>((p1.x() + t * (p2.x() - p1.x()) - xMn) / xRng * W);
                float cy = H - static_cast<float>((p1.y() + t * (p2.y() - p1.y()) - yMn) / yRng * H);
                ox.append(cx); oy.append(cy);
            }
        } else if (i > 0 && i < (int)processed.size() - 2) {
            // ÁREA SUAVE: Usa B-Spline para máxima fluidez
            QPointF p0 = processed[i - 1];
            QPointF p3 = processed[i + 2];
            
            // Garantimos que a janela de 4 pontos não cruze um salto brusco
            if (std::abs(p1.y()-p0.y()) < edgeThreshold && std::abs(p3.y()-p2.y()) < edgeThreshold) {
                for (int step = 0; step < 6; ++step) {
                    double t = step / 6.0;
                    double t2 = t * t; double t3 = t2 * t;
                    double b0 = (1.0 - 3.0*t + 3.0*t2 - t3) / 6.0;
                    double b1 = (4.0 - 6.0*t2 + 3.0*t3) / 6.0;
                    double b2 = (1.0 + 3.0*t + 3.0*t2 - 3.0*t3) / 6.0;
                    double b3 = t3 / 6.0;
                    double x = b0*p0.x() + b1*p1.x() + b2*p2.x() + b3*p3.x();
                    double y = b0*p0.y() + b1*p1.y() + b2*p2.y() + b3*p3.y();
                    ox.append(static_cast<float>((x - xMn) / xRng * W));
                    oy.append(H - static_cast<float>((y - yMn) / yRng * H));
                }
            } else {
                // Transição: Linear simples para evitar overshooting perto de bordas
                float cx = static_cast<float>((p1.x() - xMn) / xRng * W);
                float cy = H - static_cast<float>((p1.y() - yMn) / yRng * H);
                ox.append(cx); oy.append(cy);
            }
        } else {
            // Pontas do gráfico: Linear simples
            float cx = static_cast<float>((p1.x() - xMn) / xRng * W);
            float cy = H - static_cast<float>((p1.y() - yMn) / yRng * H);
            ox.append(cx); oy.append(cy);
        }
    }
    
    // Adiciona o último ponto real
    const auto &last = pts.last();
    ox.append(static_cast<float>((last.x() - xMn) / xRng * W));
    oy.append(H - static_cast<float>((last.y() - yMn) / yRng * H));
}

static void buildRibbon(QSGGeometry::Point2D *v,
                        const QVector<float> &sx, const QVector<float> &sy,
                        float halfW)
{
    const int n = sx.size();
    if (n < 2) return;

    for (int i = 0; i < n; ++i) {
        float dx, dy;
        
        if (i == 0) {
            dx = sx[1] - sx[0];
            dy = sy[1] - sy[0];
        } else if (i == n - 1) {
            dx = sx[n - 1] - sx[n - 2];
            dy = sy[n - 1] - sy[n - 2];
        } else {
            // Miter join: Usa a média das direções dos dois segmentos adjacentes
            float dx1 = sx[i] - sx[i - 1];
            float dy1 = sy[i] - sy[i - 1];
            float dx2 = sx[i + 1] - sx[i];
            float dy2 = sy[i + 1] - sy[i];
            
            float len1 = std::sqrt(dx1 * dx1 + dy1 * dy1);
            float len2 = std::sqrt(dx2 * dx2 + dy2 * dy2);
            
            if (len1 > 0) { dx1 /= len1; dy1 /= len1; }
            if (len2 > 0) { dx2 /= len2; dy2 /= len2; }
            
            dx = dx1 + dx2;
            dy = dy1 + dy2;
        }

        float len = std::sqrt(dx * dx + dy * dy);
        if (len < 1e-4f) {
            // Fallback para o segmento anterior se a média falhar
            dx = 1.0f; dy = 0.0f; len = 1.0f;
        }
        
        // Normal unitária (perpendicular)
        float nx = -dy / len;
        float ny = dx / len;

        v[2 * i].set(sx[i] + nx * halfW, sy[i] + ny * halfW);
        v[2 * i + 1].set(sx[i] - nx * halfW, sy[i] - ny * halfW);
    }
}

// ── Constructor ───────────────────────────────────────────────────────────────

FastLineChart::FastLineChart(QQuickItem *parent) : QQuickItem(parent)
{
    setFlag(ItemHasContents, true);
}

void FastLineChart::markDirty() { m_dirty = true; update(); }

void FastLineChart::ensureSeries(int idx)
{
    while (m_series.size() <= idx) {
        SeriesData sd;
        sd.color = kDefaultColors[m_series.size() % 8];
        sd.name  = QString("Channel %1").arg(m_series.size() + 1);
        m_series.append(sd);
        emit seriesCountChanged();
    }
}

// ── Series management ─────────────────────────────────────────────────────────

int FastLineChart::addSeries(const QString &name, const QColor &color)
{
    int idx = m_series.size();
    ensureSeries(idx);
    m_series[idx].name  = name;
    m_series[idx].color = color;
    markDirty();
    return idx;
}

void FastLineChart::appendPoint(int idx, double x, double y)
{
    ensureSeries(idx);
    auto &s = m_series[idx];

    if (s.points.size() >= m_maxPoints) {
        const QPointF removed = s.points.first();
        s.points.removeFirst();
        if (removed.y() <= s.yMin || removed.y() >= s.yMax) s.needsRescan = true;
    }
    s.points.append(QPointF(x, y));
    if (y < s.yMin) s.yMin = y;
    if (y > s.yMax) s.yMax = y;

    if (m_autoScale) recomputeAutoScale();
    markDirty();
}

void FastLineChart::appendPointAutoX(int idx, double y)
{
    ensureSeries(idx);
    const auto &thisPts = m_series[idx].points;

    double nextX;
    if (!thisPts.isEmpty()) {
        nextX = thisPts.last().x() + 1.0;
    } else {
        nextX = 0.0;
        for (const auto &s : std::as_const(m_series))
            if (!s.points.isEmpty()) nextX = qMax(nextX, s.points.last().x());
    }
    appendPoint(idx, nextX, y);
}

void FastLineChart::clearSeries(int idx)
{
    if (idx < 0 || idx >= m_series.size()) return;
    auto &s = m_series[idx];
    s.points.clear();
    s.yMin = qInf(); s.yMax = -qInf(); s.needsRescan = false;
    if (m_autoScale) recomputeAutoScale();
    markDirty();
}

void FastLineChart::clearAll()
{
    for (auto &s : m_series) {
        s.points.clear();
        s.yMin = qInf(); s.yMax = -qInf(); s.needsRescan = false;
    }
    m_xMin = 0; m_xMax = 10; m_yMin = -1; m_yMax = 1;
    m_yRightMin = -1; m_yRightMax = 1;
    recomputeTicks();
    emit xRangeChanged(); emit yRangeChanged(); emit yRightRangeChanged();
    markDirty();
}

void FastLineChart::setSeriesColor(int idx, const QColor &c)
    { ensureSeries(idx); m_series[idx].color = c; markDirty(); }

QColor FastLineChart::seriesColor(int idx) const
    { return (idx >= 0 && idx < m_series.size()) ? m_series[idx].color : QColor(); }

void FastLineChart::setSeriesName(int idx, const QString &name)
    { ensureSeries(idx); m_series[idx].name = name; }

QString FastLineChart::seriesName(int idx) const
    { return (idx >= 0 && idx < m_series.size()) ? m_series[idx].name : QString(); }

void FastLineChart::setSeriesVisible(int idx, bool v)
    { ensureSeries(idx); m_series[idx].visible = v; markDirty(); }

bool FastLineChart::seriesVisible(int idx) const
    { return (idx >= 0 && idx < m_series.size()) ? m_series[idx].visible : true; }

void FastLineChart::setSeriesFillOpacity(int idx, float o)
    { ensureSeries(idx); m_series[idx].fillOpa = qBound(0.0f, o, 1.0f); markDirty(); }

void FastLineChart::setSeriesUseRightAxis(int idx, bool r)
{
    ensureSeries(idx);
    m_series[idx].rightAxis = r;
    m_hasRightAxis = false;
    for (const auto &s : m_series) if (s.rightAxis) { m_hasRightAxis = true; break; }
    if (m_autoScale) recomputeAutoScale();
    emit yRightRangeChanged();
    markDirty();
}

void FastLineChart::setSeriesMovingAvg(int idx, int window, const QColor &color)
{
    ensureSeries(idx);
    m_series[idx].mavgWin   = qMax(0, window);
    m_series[idx].mavgColor = color;
    markDirty();
}

int FastLineChart::pointCount(int idx) const
    { return (idx >= 0 && idx < m_series.size()) ? m_series[idx].points.size() : 0; }

// ── Overlays ──────────────────────────────────────────────────────────────────

void FastLineChart::addHLine(double y, const QColor &c, const QString &label)
    { m_refLines.append({y, true, c, label}); rebuildOverlayInfo(); markDirty(); }

void FastLineChart::addVLine(double x, const QColor &c, const QString &label)
    { m_refLines.append({x, false, c, label}); rebuildOverlayInfo(); markDirty(); }

void FastLineChart::clearRefLines()
    { m_refLines.clear(); rebuildOverlayInfo(); markDirty(); }

void FastLineChart::addMarker(double x, const QColor &c, const QString &label)
    { m_markers.append({x, c, label}); rebuildOverlayInfo(); markDirty(); }

void FastLineChart::clearMarkers()
    { m_markers.clear(); rebuildOverlayInfo(); markDirty(); }

void FastLineChart::rebuildOverlayInfo()
{
    // Each entry: {isH, value, colorStr, label} — QML positions labels from this
    m_refLinesInfo.clear();
    for (const auto &rl : m_refLines) {
        QVariantMap m;
        m["isH"]   = rl.isH;
        m["value"] = rl.value;
        m["color"] = rl.color.name(QColor::HexArgb);
        m["label"] = rl.label;
        m_refLinesInfo.append(m);
    }
    m_markersInfo.clear();
    for (const auto &mk : m_markers) {
        QVariantMap m;
        m["x"]     = mk.x;
        m["color"] = mk.color.name(QColor::HexArgb);
        m["label"] = mk.label;
        m_markersInfo.append(m);
    }
    emit overlayChanged();
}

// ── Range setters ─────────────────────────────────────────────────────────────

void FastLineChart::setXMin(double v)
    { if (qFuzzyCompare(m_xMin, v)) return; m_xMin=v; recomputeTicks(); emit xRangeChanged(); markDirty(); }
void FastLineChart::setXMax(double v)
    { if (qFuzzyCompare(m_xMax, v)) return; m_xMax=v; recomputeTicks(); emit xRangeChanged(); markDirty(); }
void FastLineChart::setYMin(double v)
    { if (qFuzzyCompare(m_yMin, v)) return; m_yMin=v; recomputeTicks(); emit yRangeChanged(); markDirty(); }
void FastLineChart::setYMax(double v)
    { if (qFuzzyCompare(m_yMax, v)) return; m_yMax=v; recomputeTicks(); emit yRangeChanged(); markDirty(); }
void FastLineChart::setYRightMin(double v)
    { if (qFuzzyCompare(m_yRightMin,v)) return; m_yRightMin=v; recomputeTicks(); emit yRightRangeChanged(); markDirty(); }
void FastLineChart::setYRightMax(double v)
    { if (qFuzzyCompare(m_yRightMax,v)) return; m_yRightMax=v; recomputeTicks(); emit yRightRangeChanged(); markDirty(); }

void FastLineChart::setXRange(double mn, double mx)
    { m_xMin=mn; m_xMax=mx; recomputeTicks(); emit xRangeChanged(); markDirty(); }
void FastLineChart::setYRange(double mn, double mx)
    { m_yMin=mn; m_yMax=mx; recomputeTicks(); emit yRangeChanged(); markDirty(); }
void FastLineChart::setYRightRange(double mn, double mx)
    { m_yRightMin=mn; m_yRightMax=mx; recomputeTicks(); emit yRightRangeChanged(); markDirty(); }

void FastLineChart::setAutoScale(bool v)
    { if (m_autoScale==v) return; m_autoScale=v; if (v) recomputeAutoScale(); emit autoScaleChanged(); }
void FastLineChart::setMaxPoints(int v)
    { v=qMax(2,v); if (m_maxPoints==v) return; m_maxPoints=v; emit maxPointsChanged(); }
void FastLineChart::setOscilloscopeWindow(double w)
    { if (qFuzzyCompare(m_oscWindow,w)) return; m_oscWindow=w; emit oscilloscopeChanged(); markDirty(); }
void FastLineChart::setAntialias(bool v)
    { if (m_antialias==v) return; m_antialias=v; emit appearanceChanged(); markDirty(); }
void FastLineChart::setGridColor(const QColor &c)
    { if (m_gridColor==c) return; m_gridColor=c; emit appearanceChanged(); markDirty(); }
void FastLineChart::setGridCountX(int n)
    { n=qBound(0,n,20); if (m_gridCountX==n) return; m_gridCountX=n; emit appearanceChanged(); markDirty(); }
void FastLineChart::setGridCountY(int n)
    { n=qBound(0,n,20); if (m_gridCountY==n) return; m_gridCountY=n; emit appearanceChanged(); markDirty(); }
void FastLineChart::setLineWidth(qreal w)
    { w=qBound(0.5,w,20.0); if (qFuzzyCompare(m_lineWidth,w)) return; m_lineWidth=w; emit appearanceChanged(); markDirty(); }

void FastLineChart::geometryChange(const QRectF &n, const QRectF &o)
    { QQuickItem::geometryChange(n, o); recomputeTicks(); markDirty(); }

// ── Auto-scale ────────────────────────────────────────────────────────────────

void FastLineChart::recomputeAutoScale()
{
    double xMin=qInf(), xMax=-qInf();
    double yMin=qInf(), yMax=-qInf(), yRMin=qInf(), yRMax=-qInf();
    bool hasL=false, hasR=false;

    for (auto &s : m_series) {
        if (s.points.isEmpty()) continue;

        // Oscilloscope: consider only the visible window for X
        xMin = std::min(xMin, s.points.first().x());
        xMax = std::max(xMax, s.points.last().x());

        if (s.needsRescan) {
            s.yMin=qInf(); s.yMax=-qInf();
            for (const auto &p : std::as_const(s.points)) {
                if (p.y()<s.yMin) s.yMin=p.y();
                if (p.y()>s.yMax) s.yMax=p.y();
            }
            s.needsRescan=false;
        }

        if (s.rightAxis) {
            yRMin=std::min(yRMin, s.yMin); yRMax=std::max(yRMax, s.yMax); hasR=true;
        } else {
            yMin=std::min(yMin, s.yMin);   yMax=std::max(yMax, s.yMax);   hasL=true;
        }
    }

    if (!hasL && !hasR) return;

    // Oscilloscope window: clamp X to the last `m_oscWindow` units
    if (m_oscWindow > 0 && xMax > -qInf()) {
        xMin = xMax - m_oscWindow;
    }

    const double xPad = std::max(std::abs(xMax-xMin)*0.05, 1.0);
    m_xMin=xMin; m_xMax=xMax+xPad;

    if (hasL) {
        const double yPad=std::max(std::abs(yMax-yMin)*0.12, 0.5);
        m_yMin=yMin-yPad; m_yMax=yMax+yPad;
    }
    if (hasR) {
        const double yPad=std::max(std::abs(yRMax-yRMin)*0.12, 0.5);
        m_yRightMin=yRMin-yPad; m_yRightMax=yRMax+yPad;
    }

    recomputeTicks();
    emit xRangeChanged(); emit yRangeChanged();
    if (hasR) emit yRightRangeChanged();
}

// ── Tick computation ──────────────────────────────────────────────────────────

double FastLineChart::niceNum(double x, bool doRound)
{
    if (x==0) return 0;
    const double e=std::floor(std::log10(std::abs(x))), f=x/std::pow(10.0,e);
    double nf;
    if (doRound) nf=(f<1.5)?1:(f<3)?2:(f<7)?5:10;
    else         nf=(f<=1)?1:(f<=2)?2:(f<=5)?5:10;
    return nf*std::pow(10.0,e);
}

QVector<double> FastLineChart::niceTickValues(double mn, double mx, int cnt)
{
    if (mx<=mn||cnt<2) return {mn,mx};
    const double sp=niceNum(niceNum(mx-mn,false)/(cnt-1),true);
    if (sp<=0) return {mn,mx};
    const double nm=std::floor(mn/sp)*sp;
    QVector<double> t;
    for (double v=nm; v<=mx+1e-9*sp; v+=sp)
        if (v>=mn-1e-9*sp) t.append(v);
    return t;
}

void FastLineChart::recomputeTicks()
{
    const double xRng=m_xMax-m_xMin, yRng=m_yMax-m_yMin;
    const double yrRng=m_yRightMax-m_yRightMin;
    if (xRng<=0||yRng<=0) return;

    auto build=[](const QVector<double>&vals, double mn, double rng) {
        QVariantList out;
        for (double v : vals) {
            QVariantMap m; m["pos"]=(v-mn)/rng; m["label"]=QString::number(v,'g',4);
            out.append(m);
        }
        return out;
    };
    m_xTicks      = build(niceTickValues(m_xMin,m_xMax,m_gridCountX+1), m_xMin, xRng);
    m_yTicks      = build(niceTickValues(m_yMin,m_yMax,m_gridCountY+1), m_yMin, yRng);
    if (yrRng>0)
        m_yRightTicks = build(niceTickValues(m_yRightMin,m_yRightMax,m_gridCountY+1), m_yRightMin, yrRng);
    emit ticksChanged();
}

// ── Nearest-point query ───────────────────────────────────────────────────────

QPointF FastLineChart::nearestPoint(int idx, float sx) const
{
    if (idx<0||idx>=m_series.size()) return {};
    const auto &pts=m_series[idx].points;
    if (pts.isEmpty()||m_xMax<=m_xMin) return {};

    // Convert screen X to data X, then binary search (points are sorted by X)
    double dataX = m_xMin + (static_cast<double>(sx)/width())*(m_xMax-m_xMin);
    int lo=0, hi=pts.size()-1;
    while (lo<hi) {
        int mid=(lo+hi)/2;
        if (pts[mid].x()<dataX) lo=mid+1; else hi=mid;
    }
    if (lo>0 && std::abs(pts[lo-1].x()-dataX)<std::abs(pts[lo].x()-dataX)) --lo;
    return pts[lo];
}

// ── Grab to file ──────────────────────────────────────────────────────────────

void FastLineChart::grabToFile(const QString &path)
{
    auto res=grabToImage();
    if (!res) return;
    QObject::connect(res.data(), &QQuickItemGrabResult::ready, res.data(),
                     [res, path]() { res->saveToFile(path); });
}

// ── Scene graph rendering (render thread, main thread blocked) ────────────────

QSGNode *FastLineChart::updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *)
{
    const float W=static_cast<float>(width()), H=static_cast<float>(height());

    ChartRootNode *root=static_cast<ChartRootNode*>(oldNode);
    if (!root) {
        root=new ChartRootNode();
        root->gridNode    = makeFlatNode();    root->appendChildNode(root->gridNode);
        root->overlayNode = makeColoredNode(); root->appendChildNode(root->overlayNode);
        root->fillLayer   = makeLayerNode();   root->appendChildNode(root->fillLayer);
        root->glowLayer   = makeLayerNode();   root->appendChildNode(root->glowLayer);
        root->lineLayer   = makeLayerNode();   root->appendChildNode(root->lineLayer);
        root->mavgLayer   = makeLayerNode();   root->appendChildNode(root->mavgLayer);
    }
    if (W<=0||H<=0) return root;

    // Sync series node count in each layer
    auto syncLayer=[&](QSGNode *layer, QVector<QSGGeometryNode*> &nodes) {
        while (nodes.size()<m_series.size()) {
            auto *n=makeFlatNode(); layer->appendChildNode(n); nodes.append(n);
        }
        while (nodes.size()>m_series.size()) {
            auto *n=nodes.takeLast(); layer->removeChildNode(n); delete n;
        }
    };
    syncLayer(root->fillLayer, root->fillNodes);
    syncLayer(root->glowLayer, root->glowNodes);
    syncLayer(root->lineLayer, root->lineNodes);
    syncLayer(root->mavgLayer, root->mavgNodes);

    const float xRng=static_cast<float>(m_xMax-m_xMin);
    const float yRng=static_cast<float>(m_yMax-m_yMin);
    const float yrRng=static_cast<float>(m_yRightMax-m_yRightMin);
    const bool  vL=(xRng>0&&yRng>0), vR=(xRng>0&&yrRng>0);

    auto mapX  = [&](double x)->float{ return static_cast<float>((x-m_xMin)/xRng)*W; };
    auto mapYL = [&](double y)->float{ return H-static_cast<float>((y-m_yMin)/yRng)*H; };
    auto mapYR = [&](double y)->float{ return H-static_cast<float>((y-m_yRightMin)/yrRng)*H; };
    auto mapY  = [&](const FastLineChart::SeriesData &s, double y)->float{
        return s.rightAxis ? mapYR(y) : mapYL(y);
    };

    // ── Grid ──────────────────────────────────────────────────────────────
    {
        const int lc=m_gridCountX+m_gridCountY;
        auto *geo=root->gridNode->geometry();
        geo->setDrawingMode(QSGGeometry::DrawLines);
        geo->allocate(lc*2);
        auto *v=geo->vertexDataAsPoint2D(); int vi=0;
        for (int i=1;i<=m_gridCountX;++i){float x=W*i/(m_gridCountX+1); v[vi++].set(x,0); v[vi++].set(x,H);}
        for (int i=1;i<=m_gridCountY;++i){float y=H*i/(m_gridCountY+1); v[vi++].set(0,y); v[vi++].set(W,y);}
        static_cast<QSGFlatColorMaterial*>(root->gridNode->material())->setColor(m_gridColor);
        root->gridNode->markDirty(QSGNode::DirtyGeometry|QSGNode::DirtyMaterial);
    }

    // ── Ref lines + markers (vertex-colored DrawLines) ────────────────────
    {
        const int total = (m_refLines.size()+m_markers.size())*2;
        auto *geo=root->overlayNode->geometry();
        geo->setDrawingMode(QSGGeometry::DrawLines);
        geo->allocate(total);
        if (total>0 && vL) {
            auto *v=geo->vertexDataAsColoredPoint2D(); int vi=0;
            auto put=[&](float x,float y,const QColor &c){
                v[vi++].set(x,y,static_cast<uchar>(c.red()),static_cast<uchar>(c.green()),
                            static_cast<uchar>(c.blue()),static_cast<uchar>(c.alpha()));
            };
            for (const auto &rl : m_refLines) {
                if (rl.isH) { float sy=mapYL(rl.value); put(0,sy,rl.color); put(W,sy,rl.color); }
                else        { float sx=mapX(rl.value);  put(sx,0,rl.color); put(sx,H,rl.color); }
            }
            for (const auto &mk : m_markers) {
                float sx=mapX(mk.x); put(sx,0,mk.color); put(sx,H,mk.color);
            }
        }
        root->overlayNode->markDirty(QSGNode::DirtyGeometry|QSGNode::DirtyMaterial);
    }

    // ── Per-series rendering ──────────────────────────────────────────────
    const float halfW=static_cast<float>(m_lineWidth)*0.5f;

    for (int si=0; si<m_series.size(); ++si) {
        const auto &s=m_series[si];
        const bool valid=(s.rightAxis ? vR : vL) && s.visible;

        auto setEmpty=[](QSGGeometryNode *n){ n->geometry()->allocate(0); n->markDirty(QSGNode::DirtyGeometry); };

        if (!valid || s.points.size()<2) {
            setEmpty(root->fillNodes[si]); setEmpty(root->glowNodes[si]);
            setEmpty(root->lineNodes[si]); setEmpty(root->mavgNodes[si]);
            continue;
        }

        // Deduplicate screen-space coordinates
        QVector<float> scx, scy;
        const double useYMn = s.rightAxis ? m_yRightMin : m_yMin;
        const double useYRng= s.rightAxis ? yrRng : yRng;
        screenDedup(scx, scy, s.points, W, H, m_xMin, xRng, useYMn, useYRng);
        const int n=scx.size();

        if (n<2) {
            setEmpty(root->fillNodes[si]); setEmpty(root->glowNodes[si]);
            setEmpty(root->lineNodes[si]); setEmpty(root->mavgNodes[si]);
            continue;
        }

        // ── Fill area ─────────────────────────────────────────────────────
        auto *fillNode=root->fillNodes[si];
        if (s.fillOpa>0.0f) {
            float zeroY=qBound(0.0f, mapY(s, 0.0), H);
            auto *geo=fillNode->geometry();
            geo->setDrawingMode(QSGGeometry::DrawTriangleStrip);
            geo->allocate(2*n);
            auto *v=geo->vertexDataAsPoint2D();
            for (int i=0;i<n;++i){ v[2*i].set(scx[i],scy[i]); v[2*i+1].set(scx[i],zeroY); }
            QColor fc=s.color; fc.setAlphaF(static_cast<float>(s.fillOpa)*0.6f);
            static_cast<QSGFlatColorMaterial*>(fillNode->material())->setColor(fc);
            fillNode->markDirty(QSGNode::DirtyGeometry|QSGNode::DirtyMaterial);
        } else { setEmpty(fillNode); }

        // ── Anti-alias glow (wider, semi-transparent ribbon behind main) ──
        auto *glowNode=root->glowNodes[si];
        if (m_antialias) {
            auto *geo=glowNode->geometry();
            geo->setDrawingMode(QSGGeometry::DrawTriangleStrip);
            geo->allocate(2*n);
            buildRibbon(geo->vertexDataAsPoint2D(), scx, scy, halfW+1.5f);
            QColor gc=s.color; gc.setAlpha(70);
            static_cast<QSGFlatColorMaterial*>(glowNode->material())->setColor(gc);
            glowNode->markDirty(QSGNode::DirtyGeometry|QSGNode::DirtyMaterial);
        } else { setEmpty(glowNode); }

        // ── Main line ribbon ──────────────────────────────────────────────
        auto *lineNode=root->lineNodes[si];
        {
            auto *geo=lineNode->geometry();
            geo->setDrawingMode(QSGGeometry::DrawTriangleStrip);
            geo->allocate(2*n);
            buildRibbon(geo->vertexDataAsPoint2D(), scx, scy, halfW);
            static_cast<QSGFlatColorMaterial*>(lineNode->material())->setColor(s.color);
            lineNode->markDirty(QSGNode::DirtyGeometry|QSGNode::DirtyMaterial);
        }

        // ── Moving average ────────────────────────────────────────────────
        auto *mavgNode=root->mavgNodes[si];
        if (s.mavgWin>1 && n>=2) {
            // Compute trailing moving average in data space
            QVector<QPointF> mavgPts;
            mavgPts.reserve(s.points.size());
            double sum=0;
            for (int i=0;i<s.points.size();++i) {
                sum+=s.points[i].y();
                if (i>=s.mavgWin) sum-=s.points[i-s.mavgWin].y();
                mavgPts.append(QPointF(s.points[i].x(), sum/qMin(i+1,s.mavgWin)));
            }
            QVector<float> mx, my;
            screenDedup(mx, my, mavgPts, W, H, m_xMin, xRng, useYMn, useYRng);
            if (mx.size()>=2) {
                auto *geo=mavgNode->geometry();
                geo->setDrawingMode(QSGGeometry::DrawTriangleStrip);
                geo->allocate(2*mx.size());
                buildRibbon(geo->vertexDataAsPoint2D(), mx, my, halfW*0.6f);
                static_cast<QSGFlatColorMaterial*>(mavgNode->material())->setColor(s.mavgColor);
                mavgNode->markDirty(QSGNode::DirtyGeometry|QSGNode::DirtyMaterial);
            } else { setEmpty(mavgNode); }
        } else { setEmpty(mavgNode); }
    }

    m_dirty=false;
    return root;
}
