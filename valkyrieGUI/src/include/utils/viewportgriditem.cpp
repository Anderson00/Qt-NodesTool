#include "viewportgriditem.h"
#include <QSGGeometryNode>
#include <QSGFlatColorMaterial>
#include <QSGGeometry>
#include <QSGClipNode>
#include <cmath>
#include <vector>

// ── SGG node container ────────────────────────────────────────────────────────
struct GridRootNode : QSGNode {
    QSGGeometryNode *hazBlackNode  = nullptr; // hazard fill (behind grid)
    QSGGeometryNode *hazYellowNode = nullptr; // hazard yellow stripes (behind grid)
    QSGClipNode     *gridClipNode  = nullptr; // clips minor+major to boundary rect
    QSGGeometryNode *minorNode     = nullptr; // minor grid (low opacity)
    QSGGeometryNode *majorNode     = nullptr; // major grid (higher opacity)
    QSGGeometryNode *axisNode      = nullptr; // axis lines + tick marks
    QSGGeometryNode *boundaryNode  = nullptr; // workspace boundary (dashed approx)
};

// ── Vertex helpers ────────────────────────────────────────────────────────────

static QSGGeometryNode *makeNode()
{
    auto *n = new QSGGeometryNode();
    n->setFlag(QSGNode::OwnsMaterial, true);
    n->setFlag(QSGNode::OwnsGeometry, true);
    n->setMaterial(new QSGFlatColorMaterial());
    n->setGeometry(new QSGGeometry(QSGGeometry::defaultAttributes_Point2D(), 0));
    return n;
}

static inline void writeQuad(QSGGeometry::Point2D *v, int &vi,
                              float cx, float cy, float r)
{
    float l=cx-r, t=cy-r, ri=cx+r, b=cy+r;
    v[vi++].set(l,t); v[vi++].set(ri,t); v[vi++].set(l,b);
    v[vi++].set(ri,t); v[vi++].set(ri,b); v[vi++].set(l,b);
}

static inline void writeLine(QSGGeometry::Point2D *v, int &vi,
                              float x0, float y0, float x1, float y1)
{ v[vi++].set(x0,y0); v[vi++].set(x1,y1); }

static void writeDashedSeg(QSGGeometry::Point2D *v, int &vi,
                            float x0, float y0, float x1, float y1,
                            float dashLen=7.f, float gapLen=5.f)
{
    float dx=x1-x0, dy=y1-y0;
    float len=std::sqrt(dx*dx+dy*dy);
    if (len<0.5f) return;
    dx/=len; dy/=len;
    float period=dashLen+gapLen;
    for (float t=0; t<len; t+=period) {
        float t2=std::min(t+dashLen, len);
        writeLine(v,vi, x0+dx*t, y0+dy*t, x0+dx*t2, y0+dy*t2);
    }
}

static void writeCircle(QSGGeometry::Point2D *v, int &vi,
                         float cx, float cy, float r, int sides=8)
{
    float step=6.28318f/sides;
    for (int i=0;i<sides;++i) {
        float a0=i*step, a1=(i+1)*step;
        writeLine(v,vi, cx+r*std::cos(a0), cy+r*std::sin(a0),
                        cx+r*std::cos(a1), cy+r*std::sin(a1));
    }
}

static void writeHexagon(QSGGeometry::Point2D *v, int &vi,
                          float cx, float cy, float r)
{
    for (int i=0;i<6;++i) {
        float a0=(i*60.f-30.f)*0.01745329f;
        float a1=((i+1)*60.f-30.f)*0.01745329f;
        writeLine(v,vi, cx+r*std::cos(a0), cy+r*std::sin(a0),
                        cx+r*std::cos(a1), cy+r*std::sin(a1));
    }
}

// ── Hazard stripe helpers ─────────────────────────────────────────────────────

// Sutherland-Hodgman clip of convex polygon against half-plane ax+by <= c.
// Returns clipped vertex count (written into ox/oy, capacity >= n+1).
static int clipHalfPlane(const float *px, const float *py, int n,
                          float a, float b, float c,
                          float *ox, float *oy)
{
    int on = 0;
    for (int i = 0; i < n; ++i) {
        float x0=px[i], y0=py[i];
        float x1=px[(i+1)%n], y1=py[(i+1)%n];
        bool in0 = (a*x0 + b*y0 <= c + 1e-5f);
        bool in1 = (a*x1 + b*y1 <= c + 1e-5f);
        if (in0) { ox[on]=x0; oy[on]=y0; ++on; }
        if (in0 != in1) {
            float denom = a*(x1-x0) + b*(y1-y0);
            if (std::abs(denom) > 1e-9f) {
                float t = (c - a*x0 - b*y0) / denom;
                ox[on]=x0+t*(x1-x0); oy[on]=y0+t*(y1-y0); ++on;
            }
        }
    }
    return on;
}

// Append triangle-fan vertices for the diagonal (x+y) stripe bands of one
// colour that fall inside the given screen rectangle.
// evenBand=true → bands at [d, d+sw]; false → bands at [d+sw, d+2sw].
static void appendHazardStripes(std::vector<QSGGeometry::Point2D> &buf,
                                  float rx0, float ry0, float rx1, float ry1,
                                  float stripeW, bool evenBand)
{
    if (rx1 <= rx0 + 0.5f || ry1 <= ry0 + 0.5f) return;
    float dMin   = rx0 + ry0;
    float dMax   = rx1 + ry1;
    float period = stripeW * 2.f;
    float firstD = std::floor(dMin / period) * period;

    for (float d = firstD; d < dMax + period; d += period) {
        float d1 = evenBand ? d            : d + stripeW;
        float d2 = evenBand ? d + stripeW  : d + period;
        if (d2 < dMin || d1 > dMax) continue;

        float px[4]={rx0,rx1,rx1,rx0}, py[4]={ry0,ry0,ry1,ry1};
        float tx[8], ty[8], ux[8], uy[8];
        // clip against x+y >= d1  →  -(x+y) <= -d1
        int n = clipHalfPlane(px, py, 4, -1.f, -1.f, -d1, tx, ty);
        // clip against x+y <= d2
        n = clipHalfPlane(tx, ty, n,  1.f,  1.f,  d2, ux, uy);
        if (n < 3) continue;

        QSGGeometry::Point2D v;
        for (int i = 1; i < n-1; ++i) {
            v.set(ux[0], uy[0]); buf.push_back(v);
            v.set(ux[i], uy[i]); buf.push_back(v);
            v.set(ux[i+1], uy[i+1]); buf.push_back(v);
        }
    }
}

// ── Constructor ───────────────────────────────────────────────────────────────

ViewportGridItem::ViewportGridItem(QQuickItem *parent) : QQuickItem(parent)
{
    setFlag(ItemHasContents, true);
}

void ViewportGridItem::markDirty() { m_dirty=true; update(); }

// ── Property setters ──────────────────────────────────────────────────────────

void ViewportGridItem::setPanX(qreal v)         { if(qFuzzyCompare(m_panX,v))return; m_panX=v; recomputeOverlayInfo(); emit panXChanged(); markDirty(); }
void ViewportGridItem::setPanY(qreal v)         { if(qFuzzyCompare(m_panY,v))return; m_panY=v; recomputeOverlayInfo(); emit panYChanged(); markDirty(); }
void ViewportGridItem::setZoom(qreal v)         { if(qFuzzyCompare(m_zoom,v))return; m_zoom=v; recomputeOverlayInfo(); emit zoomChanged(); markDirty(); }
void ViewportGridItem::setMinWgrid(int v)       { if(m_minWgrid==v)return; m_minWgrid=v; emit gridChanged(); markDirty(); }
void ViewportGridItem::setPattern(const QString&v) { if(m_pattern==v)return; m_pattern=v; emit gridChanged(); markDirty(); }
void ViewportGridItem::setCanvasWidth(qreal v)  { if(qFuzzyCompare(m_canvasWidth,v))return; m_canvasWidth=v; recomputeOverlayInfo(); emit canvasSizeChanged(); markDirty(); }
void ViewportGridItem::setCanvasHeight(qreal v) { if(qFuzzyCompare(m_canvasHeight,v))return; m_canvasHeight=v; recomputeOverlayInfo(); emit canvasSizeChanged(); markDirty(); }
void ViewportGridItem::setPrimaryColor(const QColor&c) { if(m_primaryColor==c)return; m_primaryColor=c; emit primaryColorChanged(); markDirty(); }

void ViewportGridItem::geometryChange(const QRectF &n, const QRectF &o)
{
    QQuickItem::geometryChange(n,o);
    recomputeOverlayInfo();
    markDirty();
}

// ── Overlay info (tick labels + boundary corners) — main thread ───────────────

void ViewportGridItem::recomputeOverlayInfo()
{
    const float W=static_cast<float>(width()), H=static_cast<float>(height());
    if (W<=0||H<=0) return;

    const float ox5=static_cast<float>(m_panX+5000*m_zoom);
    const float oy5=static_cast<float>(m_panY+5000*m_zoom);
    const float step=static_cast<float>(500*m_zoom);

    m_axisXScreenY = (oy5>=0&&oy5<=H) ? oy5 : -1;
    m_axisYScreenX = (ox5>=0&&ox5<=W) ? ox5 : -1;

    // X-axis tick labels
    m_xAxisTicks.clear();
    if (m_axisXScreenY>=0 && step>1.f) {
        float sx=std::fmod(ox5, step); if(sx<0) sx+=step;
        for (float tx=sx; tx<=W+step; tx+=step) {
            int wx=static_cast<int>(std::round((tx-ox5)/m_zoom));
            if (wx%500!=0||wx==0||tx<=4||tx>=W-4) continue;
            QVariantMap m; m["screenX"]=static_cast<double>(tx); m["label"]=QString::number(wx);
            m_xAxisTicks.append(m);
        }
    }

    // Y-axis tick labels
    m_yAxisTicks.clear();
    if (m_axisYScreenX>=0 && step>1.f) {
        float sy=std::fmod(oy5, step); if(sy<0) sy+=step;
        for (float ty=sy; ty<=H+step; ty+=step) {
            int wy=static_cast<int>(std::round((ty-oy5)/m_zoom));
            if (wy%500!=0||wy==0||ty<=10||ty>=H-4) continue;
            QVariantMap m; m["screenY"]=static_cast<double>(ty); m["label"]=QString::number(wy);
            m_yAxisTicks.append(m);
        }
    }

    // Boundary corner glyphs
    m_boundaryCorners.clear();
    float bL=static_cast<float>(m_panX), bT=static_cast<float>(m_panY);
    float bR=static_cast<float>(m_panX+m_canvasWidth*m_zoom);
    float bB=static_cast<float>(m_panY+m_canvasHeight*m_zoom);

    auto addCorner=[&](float x, float y, const char *sym){
        if (x<-10||x>W+10||y<-10||y>H+10) return;
        QVariantMap m; m["x"]=static_cast<double>(x); m["y"]=static_cast<double>(y); m["symbol"]=QString(sym);
        m_boundaryCorners.append(m);
    };
    if (bL>=2&&bL<=W-20&&bT>=2&&bT<=H-14)  addCorner(bL+3,  bT+12, "⌜");
    if (bR>=20&&bR<=W-2&&bT>=2&&bT<=H-14)  addCorner(bR-13, bT+12, "⌝");
    if (bL>=2&&bL<=W-20&&bB>=14&&bB<=H-2)  addCorner(bL+3,  bB-3,  "⌞");
    if (bR>=20&&bR<=W-2&&bB>=14&&bB<=H-2)  addCorner(bR-13, bB-3,  "⌟");

    emit overlayChanged();
}

// ── Scene graph rendering ─────────────────────────────────────────────────────

QSGNode *ViewportGridItem::updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *)
{
    const float W=static_cast<float>(width()), H=static_cast<float>(height());

    GridRootNode *root=static_cast<GridRootNode*>(oldNode);
    if (!root) {
        root=new GridRootNode();
        root->hazBlackNode  = makeNode(); root->appendChildNode(root->hazBlackNode);
        root->hazYellowNode = makeNode(); root->appendChildNode(root->hazYellowNode);
        // Grid clipped to boundary: minor+major are children of the clip node
        root->gridClipNode  = new QSGClipNode();
        root->gridClipNode->setIsRectangular(true);
        auto *clipGeo = new QSGGeometry(QSGGeometry::defaultAttributes_Point2D(), 4);
        clipGeo->setDrawingMode(QSGGeometry::DrawTriangleStrip);
        root->gridClipNode->setGeometry(clipGeo);
        root->gridClipNode->setFlag(QSGNode::OwnsGeometry, true);
        root->appendChildNode(root->gridClipNode);
        root->minorNode = makeNode(); root->gridClipNode->appendChildNode(root->minorNode);
        root->majorNode = makeNode(); root->gridClipNode->appendChildNode(root->majorNode);
        // Axis and boundary draw across the full viewport (unclipped)
        root->axisNode      = makeNode(); root->appendChildNode(root->axisNode);
        root->boundaryNode  = makeNode(); root->appendChildNode(root->boundaryNode);
    }
    if (W<=0||H<=0) return root;

    const float cell  = static_cast<float>(m_minWgrid * m_zoom);
    const float major = cell * 5.f;
    const bool  doMinor = (cell >= 32.f);
    const bool  noGrid  = (m_pattern == "none");

    // Boundary in screen coords (shared by clip, boundary, and hazard sections)
    const float bL = static_cast<float>(m_panX);
    const float bT = static_cast<float>(m_panY);
    const float bR = static_cast<float>(m_panX + m_canvasWidth  * m_zoom);
    const float bB = static_cast<float>(m_panY + m_canvasHeight * m_zoom);

    // Update grid clip to the visible portion of the workspace boundary
    {
        const float cL = std::max(0.f, bL), cT = std::max(0.f, bT);
        const float cR = std::min(W, bR),   cB = std::min(H, bB);
        root->gridClipNode->setClipRect(QRectF(cL, cT, cR - cL, cB - cT));
        auto *cv = root->gridClipNode->geometry()->vertexDataAsPoint2D();
        cv[0].set(cL, cT); cv[1].set(cR, cT);
        cv[2].set(cL, cB); cv[3].set(cR, cB);
        root->gridClipNode->markDirty(QSGNode::DirtyGeometry);
    }

    // Pan offsets: first minor grid line >= 0
    float ox  = std::fmod(std::fmod(static_cast<float>(m_panX), cell) +cell, cell);
    float oy  = std::fmod(std::fmod(static_cast<float>(m_panY), cell) +cell, cell);
    float mox = std::fmod(std::fmod(static_cast<float>(m_panX), major)+major, major);
    float moy = std::fmod(std::fmod(static_cast<float>(m_panY), major)+major, major);

    const float pr = m_primaryColor.redF();
    const float pg = m_primaryColor.greenF();
    const float pb = m_primaryColor.blueF();

    auto setColor=[&](QSGGeometryNode *n, float a){
        static_cast<QSGFlatColorMaterial*>(n->material())
            ->setColor(QColor::fromRgbF(pr,pg,pb,static_cast<double>(a)));
    };

    // Exact iteration count for: for(float x=offset; x<=size+step; x+=step)
    // The 1e-4f epsilon handles exact-multiple FP rounding (e.g. 6.0000→6.0001).
    auto gridCount=[](float offset, float size, float step)->int{
        if (step<=0) return 0;
        return static_cast<int>((size - offset + step) / step + 1e-4f) + 1;
    };

    // Exact vertex count for a dashed segment (mirrors writeDashedSeg loop)
    auto dashedVertCount=[](float x0,float y0,float x1,float y1)->int{
        float len=std::sqrt((x1-x0)*(x1-x0)+(y1-y0)*(y1-y0));
        if(len<0.5f) return 0;
        int cnt=0; for(float t=0;t<len;t+=12.f) cnt+=2;  // period=7+5=12
        return cnt;
    };

    // ── Minor grid ────────────────────────────────────────────────────────────
    {
        auto *node=root->minorNode;
        auto *geo=node->geometry();

        if (noGrid || !doMinor || cell<=0) {
            geo->allocate(0);
        } else if (m_pattern=="lines") {
            int cols=gridCount(ox,W,cell), rows=gridCount(oy,H,cell);
            geo->setDrawingMode(QSGGeometry::DrawLines);
            geo->allocate((cols+rows)*2);
            auto *v=geo->vertexDataAsPoint2D(); int vi=0;
            for (float lx=ox; lx<=W+cell; lx+=cell) writeLine(v,vi, lx,0,lx,H);
            for (float ly=oy; ly<=H+cell; ly+=cell) writeLine(v,vi, 0,ly,W,ly);
            // exact count — no adjustment needed
            setColor(node, 0.12f);
        } else if (m_pattern=="cross"||m_pattern=="x") {
            int cols=gridCount(ox,W,cell), rows=gridCount(oy,H,cell);
            float half=cell*0.14f;
            geo->setDrawingMode(QSGGeometry::DrawLines);
            geo->allocate(cols*rows*4);
            auto *v=geo->vertexDataAsPoint2D(); int vi=0;
            for (float lx=ox; lx<=W+cell; lx+=cell) {
                for (float ly=oy; ly<=H+cell; ly+=cell) {
                    if (m_pattern=="cross") {
                        writeLine(v,vi, lx-half,ly,lx+half,ly);
                        writeLine(v,vi, lx,ly-half,lx,ly+half);
                    } else {
                        writeLine(v,vi, lx-half,ly-half,lx+half,ly+half);
                        writeLine(v,vi, lx+half,ly-half,lx-half,ly+half);
                    }
                }
            }
            // exact count — no adjustment needed
            setColor(node, 0.15f);
        } else {
            // dots / circles / hexagon minor: small filled squares
            float r=std::max(0.9f, static_cast<float>(m_zoom)*0.48f);
            int cols=gridCount(ox,W,cell), rows=gridCount(oy,H,cell);
            geo->setDrawingMode(QSGGeometry::DrawTriangles);
            geo->allocate(cols*rows*6);
            auto *v=geo->vertexDataAsPoint2D(); int vi=0;
            for (float lx=ox; lx<=W+cell; lx+=cell)
                for (float ly=oy; ly<=H+cell; ly+=cell)
                    writeQuad(v,vi, lx,ly, r);
            // exact count — no adjustment needed
            setColor(node, 0.20f);
        }
        node->markDirty(QSGNode::DirtyGeometry|QSGNode::DirtyMaterial);
    }

    // ── Major grid ────────────────────────────────────────────────────────────
    {
        auto *node=root->majorNode;
        auto *geo=node->geometry();

        if (noGrid || major<=0) {
            geo->allocate(0);
        } else if (m_pattern=="lines") {
            int cols=gridCount(mox,W,major), rows=gridCount(moy,H,major);
            geo->setDrawingMode(QSGGeometry::DrawLines);
            geo->allocate((cols+rows)*2);
            auto *v=geo->vertexDataAsPoint2D(); int vi=0;
            for (float lx=mox; lx<=W+major; lx+=major) writeLine(v,vi, lx,0,lx,H);
            for (float ly=moy; ly<=H+major; ly+=major) writeLine(v,vi, 0,ly,W,ly);
            // exact count — no adjustment needed
            setColor(node, 0.22f);
        } else if (m_pattern=="cross"||m_pattern=="x") {
            int cols=gridCount(mox,W,major), rows=gridCount(moy,H,major);
            float half=cell*0.14f;
            geo->setDrawingMode(QSGGeometry::DrawLines);
            geo->allocate(cols*rows*4);
            auto *v=geo->vertexDataAsPoint2D(); int vi=0;
            for (float lx=mox; lx<=W+major; lx+=major) {
                for (float ly=moy; ly<=H+major; ly+=major) {
                    if (m_pattern=="cross") {
                        writeLine(v,vi, lx-half,ly,lx+half,ly);
                        writeLine(v,vi, lx,ly-half,lx,ly+half);
                    } else {
                        writeLine(v,vi, lx-half,ly-half,lx+half,ly+half);
                        writeLine(v,vi, lx+half,ly-half,lx-half,ly+half);
                    }
                }
            }
            // exact count — no adjustment needed
            setColor(node, 0.35f);
        } else if (m_pattern=="circles") {
            // Hollow octagon approximation
            int cols=gridCount(mox,W,major), rows=gridCount(moy,H,major);
            geo->setDrawingMode(QSGGeometry::DrawLines);
            geo->allocate(cols*rows*16);  // 8 sides × 2 vertices
            auto *v=geo->vertexDataAsPoint2D(); int vi=0;
            float r=cell*0.35f;
            for (float lx=mox; lx<=W+major; lx+=major)
                for (float ly=moy; ly<=H+major; ly+=major)
                    writeCircle(v,vi, lx,ly, r, 8);
            // exact count — no adjustment needed
            setColor(node, 0.18f);
        } else if (m_pattern=="hexagon") {
            int cols=gridCount(mox,W,major), rows=gridCount(moy,H,major);
            geo->setDrawingMode(QSGGeometry::DrawLines);
            geo->allocate(cols*rows*12);  // 6 sides × 2 vertices
            auto *v=geo->vertexDataAsPoint2D(); int vi=0;
            float r=major*0.42f;
            for (float lx=mox; lx<=W+major; lx+=major)
                for (float ly=moy; ly<=H+major; ly+=major)
                    writeHexagon(v,vi, lx,ly, r);
            // exact count — no adjustment needed
            setColor(node, 0.22f);
        } else {
            // dots (and circles minor = dots): larger filled squares
            float r=std::max(1.4f, static_cast<float>(m_zoom)*0.88f);
            int cols=gridCount(mox,W,major), rows=gridCount(moy,H,major);
            geo->setDrawingMode(QSGGeometry::DrawTriangles);
            geo->allocate(cols*rows*6);
            auto *v=geo->vertexDataAsPoint2D(); int vi=0;
            for (float lx=mox; lx<=W+major; lx+=major)
                for (float ly=moy; ly<=H+major; ly+=major)
                    writeQuad(v,vi, lx,ly, r);
            // exact count — no adjustment needed
            setColor(node, 0.48f);
        }
        node->markDirty(QSGNode::DirtyGeometry|QSGNode::DirtyMaterial);
    }

    // ── Axis lines + 500-unit tick marks ──────────────────────────────────────
    {
        auto *node=root->axisNode;
        auto *geo=node->geometry();
        geo->setDrawingMode(QSGGeometry::DrawLines);

        const float ox5=static_cast<float>(m_panX+5000*m_zoom);
        const float oy5=static_cast<float>(m_panY+5000*m_zoom);
        const float step=static_cast<float>(500*m_zoom);
        const float tickH=10.f;

        // Count vertices: 2 axis lines + ticks along each
        int xTickCount=0, yTickCount=0;
        bool showXAxis=(oy5>=0&&oy5<=H), showYAxis=(ox5>=0&&ox5<=W);
        if (showXAxis && step>1.f) {
            float sx=std::fmod(ox5,step); if(sx<0)sx+=step;
            for (float tx=sx; tx<=W+step; tx+=step)
                if (static_cast<int>(std::round((tx-ox5)/m_zoom))%500==0) xTickCount++;
        }
        if (showYAxis && step>1.f) {
            float sy=std::fmod(oy5,step); if(sy<0)sy+=step;
            for (float ty=sy; ty<=H+step; ty+=step)
                if (static_cast<int>(std::round((ty-oy5)/m_zoom))%500==0) yTickCount++;
        }

        int total = (showXAxis?2:0) + (showYAxis?2:0)
                  + xTickCount*2 + yTickCount*2;
        geo->allocate(total);
        auto *v=geo->vertexDataAsPoint2D(); int vi=0;

        if (showXAxis) writeLine(v,vi, 0,oy5,W,oy5);
        if (showYAxis) writeLine(v,vi, ox5,0,ox5,H);

        // X-axis ticks
        if (showXAxis && step>1.f) {
            float sx=std::fmod(ox5,step); if(sx<0)sx+=step;
            for (float tx=sx; tx<=W+step; tx+=step) {
                int wx=static_cast<int>(std::round((tx-ox5)/m_zoom));
                if (wx%500!=0) continue;
                writeLine(v,vi, tx,oy5-tickH,tx,oy5+tickH);
            }
        }
        // Y-axis ticks
        if (showYAxis && step>1.f) {
            float sy=std::fmod(oy5,step); if(sy<0)sy+=step;
            for (float ty=sy; ty<=H+step; ty+=step) {
                int wy=static_cast<int>(std::round((ty-oy5)/m_zoom));
                if (wy%500!=0) continue;
                writeLine(v,vi, ox5-tickH,ty,ox5+tickH,ty);
            }
        }
        setColor(node, 0.22f);
        node->markDirty(QSGNode::DirtyGeometry|QSGNode::DirtyMaterial);
    }

    // ── Workspace boundary (dashed approximation) ─────────────────────────────
    {
        auto *node=root->boundaryNode;
        auto *geo=node->geometry();
        geo->setDrawingMode(QSGGeometry::DrawLines);

        const float cT=std::max(0.f,bT), cB=std::min(H,bB);
        const float cL=std::max(0.f,bL), cR=std::min(W,bR);

        bool anyEdge=(bL>0&&bL<W)||(bR>0&&bR<W)||(bT>0&&bT<H)||(bB>0&&bB<H);

        if (!anyEdge) {
            geo->allocate(0);
        } else {
            // Compute exact vertex count by mirroring the write loop
            int exact = 0;
            if (bL>=0&&bL<=W) exact += dashedVertCount(bL,cT,bL,cB);
            if (bR>=0&&bR<=W) exact += dashedVertCount(bR,cT,bR,cB);
            if (bT>=0&&bT<=H) exact += dashedVertCount(cL,bT,cR,bT);
            if (bB>=0&&bB<=H) exact += dashedVertCount(cL,bB,cR,bB);
            geo->allocate(qMax(exact, 2));
            auto *v=geo->vertexDataAsPoint2D(); int vi=0;
            if (bL>=0&&bL<=W) writeDashedSeg(v,vi, bL,cT,bL,cB);
            if (bR>=0&&bR<=W) writeDashedSeg(v,vi, bR,cT,bR,cB);
            if (bT>=0&&bT<=H) writeDashedSeg(v,vi, cL,bT,cR,bT);
            if (bB>=0&&bB<=H) writeDashedSeg(v,vi, cL,bB,cR,bB);
            setColor(node, 0.55f);
        }
        node->markDirty(QSGNode::DirtyGeometry|QSGNode::DirtyMaterial);
    }

    // ── Hazard stripes outside workspace boundary ─────────────────────────────
    {
        // Clamp boundary edges to screen rect
        const float ibL = std::max(0.f, std::min(W, bL));
        const float ibT = std::max(0.f, std::min(H, bT));
        const float ibR = std::max(0.f, std::min(W, bR));
        const float ibB = std::max(0.f, std::min(H, bB));

        // Four screen strips that lie outside the boundary
        struct Rect { float x0,y0,x1,y1; };
        const Rect outside[4] = {
            {0.f, 0.f, W,    ibT },   // top
            {0.f, ibB, W,    H   },   // bottom
            {0.f, ibT, ibL,  ibB },   // left
            {ibR, ibT, W,    ibB }    // right
        };

        const float stripeW = 18.f;

        std::vector<QSGGeometry::Point2D> blackVerts, yellowVerts;
        for (const auto &r : outside) {
            if (r.x1 <= r.x0 || r.y1 <= r.y0) continue;
            // Solid black fill quad (2 triangles)
            QSGGeometry::Point2D v;
            v.set(r.x0,r.y0); blackVerts.push_back(v);
            v.set(r.x1,r.y0); blackVerts.push_back(v);
            v.set(r.x0,r.y1); blackVerts.push_back(v);
            v.set(r.x1,r.y0); blackVerts.push_back(v);
            v.set(r.x1,r.y1); blackVerts.push_back(v);
            v.set(r.x0,r.y1); blackVerts.push_back(v);
            // Yellow diagonal stripes over this rect
            appendHazardStripes(yellowVerts, r.x0,r.y0,r.x1,r.y1, stripeW, true);
        }

        {
            auto *node = root->hazBlackNode;
            auto *geo  = node->geometry();
            geo->setDrawingMode(QSGGeometry::DrawTriangles);
            const int cnt = static_cast<int>(blackVerts.size());
            geo->allocate(cnt > 0 ? cnt : 1);
            if (cnt > 0)
                std::memcpy(geo->vertexData(), blackVerts.data(),
                            cnt * sizeof(QSGGeometry::Point2D));
            static_cast<QSGFlatColorMaterial*>(node->material())
                ->setColor(QColor::fromRgbF(0.05, 0.05, 0.05, 0.60));
            node->markDirty(QSGNode::DirtyGeometry | QSGNode::DirtyMaterial);
        }
        {
            auto *node = root->hazYellowNode;
            auto *geo  = node->geometry();
            geo->setDrawingMode(QSGGeometry::DrawTriangles);
            const int cnt = static_cast<int>(yellowVerts.size());
            geo->allocate(cnt > 0 ? cnt : 1);
            if (cnt > 0)
                std::memcpy(geo->vertexData(), yellowVerts.data(),
                            cnt * sizeof(QSGGeometry::Point2D));
            static_cast<QSGFlatColorMaterial*>(node->material())
                ->setColor(QColor::fromRgbF(1.0, 0.82, 0.0, 0.55));
            node->markDirty(QSGNode::DirtyGeometry | QSGNode::DirtyMaterial);
        }
    }

    m_dirty=false;
    return root;
}
