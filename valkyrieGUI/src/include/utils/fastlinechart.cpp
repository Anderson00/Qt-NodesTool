#include "fastlinechart.h"
#include <QSGGeometryNode>
#include <QSGFlatColorMaterial>
#include <QSGGeometry>
#include <cmath>

// ── Default colour palette ────────────────────────────────────────────────────
const QColor FastLineChart::kDefaultColors[8] = {
    QColor("#e74c3c"), QColor("#f39c12"), QColor("#2ecc71"), QColor("#3498db"),
    QColor("#9b59b6"), QColor("#1abc9c"), QColor("#e67e22"), QColor("#ec407a")
};

// ── Custom root node carrying child pointers across updatePaintNode calls ─────
// This avoids storing render-thread-owned node pointers in the QQuickItem.
struct ChartRootNode : QSGNode {
    QSGGeometryNode        *gridNode = nullptr;
    QVector<QSGGeometryNode *> seriesNodes;
};

// ── Helpers ───────────────────────────────────────────────────────────────────

static QSGGeometryNode *makeNode()
{
    auto *node = new QSGGeometryNode();
    node->setFlag(QSGNode::OwnsMaterial, true);
    node->setFlag(QSGNode::OwnsGeometry, true);
    node->setMaterial(new QSGFlatColorMaterial());
    node->setGeometry(new QSGGeometry(QSGGeometry::defaultAttributes_Point2D(), 0));
    return node;
}

// ── Constructor ───────────────────────────────────────────────────────────────

FastLineChart::FastLineChart(QQuickItem *parent) : QQuickItem(parent)
{
    setFlag(ItemHasContents, true);
}

void FastLineChart::markDirty()
{
    m_dirty = true;
    update();
}

void FastLineChart::ensureSeries(int idx)
{
    while (m_series.size() <= idx) {
        SeriesData sd;
        sd.color = kDefaultColors[m_series.size() % 8];
        m_series.append(sd);
    }
}

// ── Data mutations (main thread) ──────────────────────────────────────────────

void FastLineChart::appendPoint(int seriesIdx, double x, double y)
{
    ensureSeries(seriesIdx);
    auto &s = m_series[seriesIdx];

    // Trim oldest point before inserting the new one
    if (s.points.size() >= m_maxPoints) {
        const QPointF removed = s.points.first();
        s.points.removeFirst();
        // If the removed point was an extreme, we need a full rescan next time
        if (removed.y() <= s.yMin || removed.y() >= s.yMax)
            s.needsRescan = true;
    }

    s.points.append(QPointF(x, y));

    // Update per-series extremes incrementally
    if (y < s.yMin) s.yMin = y;
    if (y > s.yMax) s.yMax = y;

    if (m_autoScale) recomputeAutoScale();
    markDirty();
}

void FastLineChart::appendPointAutoX(int seriesIdx, double y)
{
    ensureSeries(seriesIdx);
    const auto &thisPts = m_series[seriesIdx].points;

    double nextX;
    if (!thisPts.isEmpty()) {
        // Normal case: advance by 1 from this series' own last point.
        nextX = thisPts.last().x() + 1.0;
    } else {
        // Series is empty (first call or after a clear).
        // Align to the current X position of the most-advanced series so that
        // a late-starting channel appears on top of existing data instead of
        // at X=0 on the far left of the axis.
        nextX = 0.0;
        for (const auto &s : std::as_const(m_series))
            if (!s.points.isEmpty())
                nextX = qMax(nextX, s.points.last().x());
        // Use the same X (no +1) so the first point lands on the current tick,
        // not one tick ahead of every other series.
    }
    appendPoint(seriesIdx, nextX, y);
}

void FastLineChart::clearSeries(int seriesIdx)
{
    if (seriesIdx < 0 || seriesIdx >= m_series.size()) return;
    auto &s = m_series[seriesIdx];
    s.points.clear();
    s.yMin =  qInf();
    s.yMax = -qInf();
    s.needsRescan = false;
    if (m_autoScale) recomputeAutoScale();
    markDirty();
}

void FastLineChart::clearAll()
{
    for (auto &s : m_series) {
        s.points.clear();
        s.yMin =  qInf();
        s.yMax = -qInf();
        s.needsRescan = false;
    }
    m_xMin = 0.0; m_xMax = 10.0;
    m_yMin = -1.0; m_yMax = 1.0;
    recomputeTicks();
    emit xRangeChanged();
    emit yRangeChanged();
    markDirty();
}

void FastLineChart::setSeriesColor(int seriesIdx, const QColor &color)
{
    ensureSeries(seriesIdx);
    m_series[seriesIdx].color = color;
    markDirty();
}

int FastLineChart::pointCount(int seriesIdx) const
{
    if (seriesIdx < 0 || seriesIdx >= m_series.size()) return 0;
    return m_series[seriesIdx].points.size();
}

// ── Property setters ──────────────────────────────────────────────────────────

void FastLineChart::setXMin(double v)
{
    if (qFuzzyCompare(m_xMin, v)) return;
    m_xMin = v; recomputeTicks(); emit xRangeChanged(); markDirty();
}
void FastLineChart::setXMax(double v)
{
    if (qFuzzyCompare(m_xMax, v)) return;
    m_xMax = v; recomputeTicks(); emit xRangeChanged(); markDirty();
}
void FastLineChart::setYMin(double v)
{
    if (qFuzzyCompare(m_yMin, v)) return;
    m_yMin = v; recomputeTicks(); emit yRangeChanged(); markDirty();
}
void FastLineChart::setYMax(double v)
{
    if (qFuzzyCompare(m_yMax, v)) return;
    m_yMax = v; recomputeTicks(); emit yRangeChanged(); markDirty();
}
void FastLineChart::setXRange(double min, double max)
{
    m_xMin = min; m_xMax = max; recomputeTicks(); emit xRangeChanged(); markDirty();
}
void FastLineChart::setYRange(double min, double max)
{
    m_yMin = min; m_yMax = max; recomputeTicks(); emit yRangeChanged(); markDirty();
}
void FastLineChart::setAutoScale(bool enabled)
{
    if (m_autoScale == enabled) return;
    m_autoScale = enabled;
    if (enabled) recomputeAutoScale();
    emit autoScaleChanged();
}
void FastLineChart::setMaxPoints(int max)
{
    max = qMax(2, max);
    if (m_maxPoints == max) return;
    m_maxPoints = max;
    emit maxPointsChanged();
}
void FastLineChart::setGridColor(const QColor &c)
{
    if (m_gridColor == c) return;
    m_gridColor = c; emit appearanceChanged(); markDirty();
}
void FastLineChart::setGridCountX(int n)
{
    n = qBound(0, n, 20);
    if (m_gridCountX == n) return;
    m_gridCountX = n; emit appearanceChanged(); markDirty();
}
void FastLineChart::setGridCountY(int n)
{
    n = qBound(0, n, 20);
    if (m_gridCountY == n) return;
    m_gridCountY = n; emit appearanceChanged(); markDirty();
}
void FastLineChart::setLineWidth(qreal w)
{
    w = qBound(0.5, w, 20.0);
    if (qFuzzyCompare(m_lineWidth, w)) return;
    m_lineWidth = w; emit appearanceChanged(); markDirty();
}

void FastLineChart::geometryChange(const QRectF &n, const QRectF &o)
{
    QQuickItem::geometryChange(n, o);
    recomputeTicks();
    markDirty();
}

// ── Auto-scale ────────────────────────────────────────────────────────────────

void FastLineChart::recomputeAutoScale()
{
    double xMin =  qInf();
    double xMax = -qInf();
    double yMin =  qInf();
    double yMax = -qInf();
    bool   hasData = false;

    for (auto &s : m_series) {
        if (s.points.isEmpty()) continue;
        hasData = true;

        // X extremes: always use first and last point (O(1) for sorted auto-X data)
        xMin = std::min(xMin, s.points.first().x());
        xMax = std::max(xMax, s.points.last().x());

        // Y extremes: use cached per-series values; only do a full scan when an
        // evicted point was the previous extreme (happens at most once every maxPoints
        // insertions per series rather than on every append)
        if (s.needsRescan) {
            s.yMin =  qInf();
            s.yMax = -qInf();
            for (const auto &p : std::as_const(s.points)) {
                if (p.y() < s.yMin) s.yMin = p.y();
                if (p.y() > s.yMax) s.yMax = p.y();
            }
            s.needsRescan = false;
        }
        yMin = std::min(yMin, s.yMin);
        yMax = std::max(yMax, s.yMax);
    }
    if (!hasData) return;

    const double yPad = std::max(std::abs(yMax - yMin) * 0.12, 0.5);
    const double xPad = std::max(std::abs(xMax - xMin) * 0.05, 1.0);
    m_xMin = xMin;        m_xMax = xMax + xPad;
    m_yMin = yMin - yPad; m_yMax = yMax + yPad;
    recomputeTicks();
    emit xRangeChanged();
    emit yRangeChanged();
}

// ── Tick computation ──────────────────────────────────────────────────────────

double FastLineChart::niceNum(double x, bool doRound)
{
    if (x == 0.0) return 0.0;
    const double exp = std::floor(std::log10(std::abs(x)));
    const double f   = x / std::pow(10.0, exp);
    double nf;
    if (doRound) {
        nf = (f < 1.5) ? 1 : (f < 3.0) ? 2 : (f < 7.0) ? 5 : 10;
    } else {
        nf = (f <= 1.0) ? 1 : (f <= 2.0) ? 2 : (f <= 5.0) ? 5 : 10;
    }
    return nf * std::pow(10.0, exp);
}

QVector<double> FastLineChart::niceTickValues(double min, double max, int targetCount)
{
    if (max <= min || targetCount < 2) return { min, max };
    const double spacing = niceNum(niceNum(max - min, false) / (targetCount - 1), true);
    if (spacing <= 0.0) return { min, max };
    const double niceMin = std::floor(min / spacing) * spacing;
    QVector<double> ticks;
    for (double v = niceMin; v <= max + 1e-9 * spacing; v += spacing)
        if (v >= min - 1e-9 * spacing)
            ticks.append(v);
    return ticks;
}

void FastLineChart::recomputeTicks()
{
    const double xRange = m_xMax - m_xMin;
    const double yRange = m_yMax - m_yMin;
    if (xRange <= 0.0 || yRange <= 0.0) return;

    auto toMap = [](const QVector<double> &vals, double mn, double range) {
        QVariantList list;
        for (double v : vals) {
            QVariantMap m;
            m["pos"]   = (v - mn) / range;   // 0..1 within the axis
            m["label"] = QString::number(v, 'g', 4);
            list.append(m);
        }
        return list;
    };

    m_xTicks = toMap(niceTickValues(m_xMin, m_xMax, m_gridCountX + 1), m_xMin, xRange);
    m_yTicks = toMap(niceTickValues(m_yMin, m_yMax, m_gridCountY + 1), m_yMin, yRange);
    emit ticksChanged();
}

// ── Scene graph rendering (render thread, main thread blocked) ────────────────

QSGNode *FastLineChart::updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *)
{
    const float W = static_cast<float>(width());
    const float H = static_cast<float>(height());

    ChartRootNode *root = static_cast<ChartRootNode *>(oldNode);
    if (!root) {
        root = new ChartRootNode();
        root->gridNode = makeNode();
        root->appendChildNode(root->gridNode);
    }

    if (W <= 0.0f || H <= 0.0f) return root;

    // Sync series node count to current series count
    while (root->seriesNodes.size() < m_series.size()) {
        auto *n = makeNode();
        root->appendChildNode(n);
        root->seriesNodes.append(n);
    }
    while (root->seriesNodes.size() > m_series.size()) {
        auto *n = root->seriesNodes.takeLast();
        root->removeChildNode(n);
        delete n;
    }

    const float xRange = static_cast<float>(m_xMax - m_xMin);
    const float yRange = static_cast<float>(m_yMax - m_yMin);
    const bool validRange = xRange > 0.0f && yRange > 0.0f;

    // Screen-space mapping helpers
    auto mapX = [&](double x) -> float {
        return static_cast<float>((x - m_xMin) / xRange) * W;
    };
    auto mapY = [&](double y) -> float {
        // Y is inverted: data-min → screen-bottom, data-max → screen-top
        return H - static_cast<float>((y - m_yMin) / yRange) * H;
    };

    // ── Grid ──────────────────────────────────────────────────────────────────
    {
        const int lineCount = m_gridCountX + m_gridCountY;
        auto *geo = root->gridNode->geometry();
        geo->setDrawingMode(QSGGeometry::DrawLines);
        geo->allocate(lineCount * 2);
        auto *v = geo->vertexDataAsPoint2D();
        int vi = 0;
        for (int i = 1; i <= m_gridCountX; ++i) {
            const float x = W * i / (m_gridCountX + 1);
            v[vi++].set(x, 0.0f); v[vi++].set(x, H);
        }
        for (int i = 1; i <= m_gridCountY; ++i) {
            const float y = H * i / (m_gridCountY + 1);
            v[vi++].set(0.0f, y); v[vi++].set(W, y);
        }
        static_cast<QSGFlatColorMaterial *>(root->gridNode->material())->setColor(m_gridColor);
        root->gridNode->markDirty(QSGNode::DirtyGeometry | QSGNode::DirtyMaterial);
    }

    // ── Series ────────────────────────────────────────────────────────────────
    // Rendered as a DrawTriangleStrip ribbon: 2 vertices (top/bottom) per point.
    // Portable across all Qt RHI backends (D3D, Metal, Vulkan, OpenGL) — line
    // width is controlled in software, not via the deprecated GL_LINE_WIDTH.
    for (int si = 0; si < m_series.size(); ++si) {
        auto *node     = root->seriesNodes[si];
        const auto &s  = m_series[si];

        static_cast<QSGFlatColorMaterial *>(node->material())->setColor(s.color);
        auto *geo = node->geometry();

        if (!validRange || s.points.size() < 2) {
            geo->allocate(0);
            node->markDirty(QSGNode::DirtyGeometry | QSGNode::DirtyMaterial);
            continue;
        }

        // ── Pass 1: map to screen space + sub-pixel deduplication ─────────────
        // When many data points compress into the same pixel (zoom-out or very
        // dense data), consecutive direction vectors become near-zero, collapsing
        // both ribbon vertices to the same point → zero-area triangles → holes.
        // Filtering out points closer than 0.5 px eliminates the degenerate case
        // and also reduces vertex count for dense views.
        QVector<float> scx, scy;
        scx.reserve(s.points.size());
        scy.reserve(s.points.size());
        {
            const float cx0 = mapX(s.points[0].x());
            const float cy0 = mapY(s.points[0].y());
            scx.append(cx0); scy.append(cy0);
            for (int i = 1; i < s.points.size(); ++i) {
                const float cx = mapX(s.points[i].x());
                const float cy = mapY(s.points[i].y());
                const float ddx = cx - scx.last(), ddy = cy - scy.last();
                if (ddx * ddx + ddy * ddy >= 0.25f) {   // ≥ 0.5 px distance
                    scx.append(cx); scy.append(cy);
                }
            }
        }

        const int n = scx.size();
        if (n < 2) {
            geo->allocate(0);
            node->markDirty(QSGNode::DirtyGeometry | QSGNode::DirtyMaterial);
            continue;
        }

        // ── Pass 2: build triangle-strip vertices ─────────────────────────────
        geo->setDrawingMode(QSGGeometry::DrawTriangleStrip);
        geo->allocate(2 * n);
        auto *v = geo->vertexDataAsPoint2D();

        const float halfW = static_cast<float>(m_lineWidth) * 0.5f;

        // lastDx/lastDy: stable fallback direction when consecutive deduplicated
        // points are still sub-pixel (direction length ≤ threshold). Without this
        // fallback, px/py stay near-zero and the ribbon collapses to a dot.
        float lastDx = 1.0f, lastDy = 0.0f;

        for (int i = 0; i < n; ++i) {
            // Tangent: average of the two adjacent segments (smooth miter join).
            // Endpoints fall back to their single adjacent segment.
            float dx, dy;
            if (i == 0) {
                dx = scx[1] - scx[0]; dy = scy[1] - scy[0];
            } else if (i == n - 1) {
                dx = scx[n-1] - scx[n-2]; dy = scy[n-1] - scy[n-2];
            } else {
                dx = scx[i+1] - scx[i-1]; dy = scy[i+1] - scy[i-1];
            }

            const float len = std::sqrt(dx * dx + dy * dy);
            if (len > 1e-4f) {
                lastDx = dx / len;
                lastDy = dy / len;
            }
            // else: reuse lastDx/lastDy — keeps ribbon stable when direction
            // is ambiguous (remaining sub-pixel cluster after deduplication)

            const float px = -lastDy * halfW;
            const float py =  lastDx * halfW;

            v[2*i  ].set(scx[i] + px, scy[i] + py);
            v[2*i+1].set(scx[i] - px, scy[i] - py);
        }

        node->markDirty(QSGNode::DirtyGeometry | QSGNode::DirtyMaterial);
    }

    m_dirty = false;
    return root;
}
