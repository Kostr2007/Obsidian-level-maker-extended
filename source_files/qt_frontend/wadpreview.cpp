// SPDX-License-Identifier: GPL-2.0-or-later
#include "wadpreview.h"
#include <QFile>
#include <QMap>
#include <QPainter>
#include <QRegularExpression>
#include <QtEndian>
#include <cmath>
#include <QWheelEvent>
#include <QMouseEvent>
#include <QKeyEvent>
#include <QCursor>
#include <algorithm>

namespace {
quint32 u32(const char *p) { return qFromLittleEndian<quint32>(reinterpret_cast<const uchar *>(p)); }
quint16 u16(const char *p) { return qFromLittleEndian<quint16>(reinterpret_cast<const uchar *>(p)); }
struct Lump { quint32 offset, size; QByteArray name; };
}
MapGeometry MapGeometry::read(const QString &filename) {
    MapGeometry result;
    auto fail = [&result](const QString &error) { result.lines.clear(); result.twoSided.clear(); result.error = error; return result; };
    QFile file(filename);
    if (!file.open(QIODevice::ReadOnly)) return fail(file.errorString());
    const auto header = file.read(12);
    if (header.size() != 12 || (header.left(4) != "PWAD" && header.left(4) != "IWAD"))
        return fail("Предпросмотр доступен для WAD; для других форматов откройте папку результата.");
    const quint32 count = u32(header.constData() + 4), directory = u32(header.constData() + 8);
    if (directory < 12 || !count || count > 1000000 || quint64(directory) + quint64(count) * 16 > quint64(file.size()))
        return fail("Повреждённый каталог WAD.");
    file.seek(directory);
    const auto entries = file.read(qint64(count) * 16);
    if (entries.size() != qint64(count) * 16) return fail("Не удалось прочитать каталог WAD.");
    QVector<Lump> lumps;
    for (quint32 i = 0; i < count; ++i) {
        const char *p = entries.constData() + i * 16;
        Lump l{u32(p), u32(p + 4), QByteArray(p + 8, 8).split('\0').first()};
        if (quint64(l.offset) + l.size > quint64(file.size())) return fail("Блок WAD выходит за границы файла.");
        lumps.push_back(l);
    }
    int first = -1;
    const QRegularExpression marker("^(MAP[0-9][0-9]|E[0-9]M[0-9])$");
    for (int i = 0; i < lumps.size(); ++i)
        if (marker.match(QString::fromLatin1(lumps[i].name)).hasMatch()) { first = i; break; }
    if (first < 0) return fail("В WAD не найден стандартный маркер карты.");
    result.name = QString::fromLatin1(lumps[first].name);
    QMap<QByteArray, Lump> map;
    for (int i = first + 1; i < lumps.size(); ++i) {
        if (marker.match(QString::fromLatin1(lumps[i].name)).hasMatch()) break;
        map[lumps[i].name] = lumps[i];
    }
    auto read = [&file, &map](const QByteArray &name, quint32 limit) {
        if (!map.contains(name) || map[name].size > limit) return QByteArray();
        file.seek(map[name].offset); return file.read(map[name].size);
    };
    QVector<QPointF> vertices;
    if (map.contains("TEXTMAP")) {
        auto text = QString::fromUtf8(read("TEXTMAP", 32 * 1024 * 1024));
        // Strip comments before matching the generated UDMF geometry blocks.
        text.remove(QRegularExpression("/\\*.*?\\*/|//[^\\n]*", QRegularExpression::DotMatchesEverythingOption));
        auto blocks = QRegularExpression("vertex\\s*\\{([^}]*)\\}").globalMatch(text);
        auto field = [](const QString &body, const QString &key, bool *ok) {
            auto m = QRegularExpression("\\b" + key + "\\s*=\\s*([-+0-9.eE]+)\\s*;").match(body);
            double v = m.captured(1).toDouble(ok);
            *ok = *ok && m.hasMatch() && std::isfinite(v);
            return v;
        };
        while (blocks.hasNext()) {
            const auto body = blocks.next().captured(1); bool xok = false, yok = false;
            const double x = field(body, "x", &xok), y = field(body, "y", &yok);
            if (!xok || !yok) return fail("Некорректная вершина UDMF.");
            vertices.push_back(QPointF(x, y));
        }
        blocks = QRegularExpression("linedef\\s*\\{([^}]*)\\}").globalMatch(text);
        while (blocks.hasNext()) {
            const auto body = blocks.next().captured(1); bool aok = false, bok = false;
            const double a = field(body, "v1", &aok), b = field(body, "v2", &bok);
            if (!aok || !bok || a != std::floor(a) || b != std::floor(b) ||
                a < 0 || b < 0 || a >= vertices.size() || b >= vertices.size())
                return fail("Некорректная линия UDMF.");
            result.lines.push_back(QLineF(vertices[int(a)], vertices[int(b)]));
            result.twoSided.push_back(QRegularExpression("\\btwosided\\s*=\\s*true\\s*;").match(body).hasMatch());
        }
    } else {
        const auto v = read("VERTEXES", 4 * 1000000), l = read("LINEDEFS", 32 * 1000000);
        const int stride = map.contains("BEHAVIOR") ? 16 : 14;
        if (v.isEmpty() || v.size() % 4 || l.isEmpty() || l.size() % stride)
            return fail("Отсутствует или повреждена геометрия карты.");
        for (int i = 0; i < v.size(); i += 4)
            vertices.push_back(QPointF(qint16(u16(v.constData() + i)), qint16(u16(v.constData() + i + 2))));
        for (int i = 0; i < l.size(); i += stride) {
            const int a = u16(l.constData() + i), b = u16(l.constData() + i + 2);
            if (a >= vertices.size() || b >= vertices.size()) return fail("Линия ссылается на отсутствующую вершину.");
            result.lines.push_back(QLineF(vertices[a], vertices[b]));
            result.twoSided.push_back((u16(l.constData() + i + 4) & 4) != 0);
        }
    }
    if (result.lines.isEmpty()) return fail("В карте нет линий для предпросмотра.");
    result.calculateBounds();
    if (!std::isfinite(result.bounds.width()) || !std::isfinite(result.bounds.height()) ||
        !std::isfinite(result.bounds.center().x()) || !std::isfinite(result.bounds.center().y()))
        return fail("Координаты карты выходят за диапазон предпросмотра.");
    return result;
}
void MapGeometry::calculateBounds() {
    bounds={};mainBounds={};primaryLines.clear();
    if (lines.isEmpty()) return;
    // Fit the densest connected component by default. All geometry remains available.
    QMap<QPair<qreal,qreal>, int> ids;
    QVector<int> parents;
    auto id = [&](QPointF p) {
        const auto key = qMakePair(p.x(),p.y());
        if (!ids.contains(key)) { ids[key]=parents.size(); parents.push_back(parents.size()); }
        return ids[key];
    };
    auto root = [&](int n) { while (parents[n]!=n) { parents[n]=parents[parents[n]];n=parents[n]; } return n; };
    QVector<QPair<int,int>> endpoints;
    for (const auto &l:lines) { int a=id(l.p1()),b=id(l.p2()); endpoints.push_back({a,b}); a=root(a);b=root(b);if(a!=b)parents[b]=a; }
    QMap<int,int> counts;
    QMap<int,QRectF> boxes;
    for(int i=0;i<lines.size();++i) {
        const auto &l=lines[i];const int group=root(endpoints[i].first);
        const QRectF box(l.p1(),l.p2());
        const QRectF normalized=box.normalized().adjusted(-.01,-.01,.01,.01);
        boxes[group]=counts[group] ? boxes[group].united(normalized) : normalized;
        bounds=i ? bounds.united(normalized) : normalized;
        ++counts[group];
    }
    int largest=counts.firstKey();
    for(auto i=counts.begin();i!=counts.end();++i)if(i.value()>counts[largest])largest=i.key();
    mainBounds=boxes[largest];
    for(const auto &pair:endpoints)primaryLines.push_back(root(pair.first)==largest);
}
WadPreview::WadPreview(QQuickItem *parent):QQuickPaintedItem(parent) {
    setAntialiasing(true);
    setActiveFocusOnTab(true);
    setAcceptedMouseButtons(Qt::LeftButton);
    setCursor(QCursor(Qt::OpenHandCursor));
    connect(this,&WadPreview::appearanceChanged,this,[this]{update();});
}
void WadPreview::setFile(const QString &file) {
    if (m_file == file) return;
    m_file = file; m_map = file.isEmpty() ? MapGeometry() : MapGeometry::read(file);
    resetView();emit fileChanged(); update();
}
QRectF WadPreview::focusBounds() const { return m_showAll ? m_map.bounds : m_map.mainBounds; }
qreal WadPreview::mapScale() const {
    auto box=focusBounds();
    return qMin(qMax(1.,width()-72)/qMax(1.,box.width()),qMax(1.,height()-72)/qMax(1.,box.height()))*m_zoom;
}
void WadPreview::setZoom(qreal value) {
    value=qBound(.25,value,12.);
    if(qFuzzyCompare(value,m_zoom))return;
    m_zoom=value;emit zoomChanged();update();
}
void WadPreview::setShowAll(bool all) { if(all==m_showAll)return;m_showAll=all;resetView();emit showAllChanged(); }
void WadPreview::resetView() { m_pan={};m_zoom=1;emit zoomChanged();update(); }
void WadPreview::wheelEvent(QWheelEvent *event) {
    const QPointF delta=event->position()-QPointF(width()/2,height()/2);
    const qreal before=mapScale();
    const QPointF world=m_pan+QPointF(delta.x()/before,-delta.y()/before);
    setZoom(m_zoom*std::pow(1.0015,event->angleDelta().y()));
    const qreal after=mapScale();
    m_pan=world-QPointF(delta.x()/after,-delta.y()/after);
    update();event->accept();
}
void WadPreview::mousePressEvent(QMouseEvent *event) { forceActiveFocus();m_lastMouse=event->position();setCursor(QCursor(Qt::ClosedHandCursor));event->accept(); }
void WadPreview::mouseMoveEvent(QMouseEvent *event) { auto delta=event->position()-m_lastMouse;m_lastMouse=event->position();m_pan+=QPointF(-delta.x()/mapScale(),delta.y()/mapScale());update();event->accept(); }
void WadPreview::mouseReleaseEvent(QMouseEvent *event) {setCursor(QCursor(Qt::OpenHandCursor));event->accept();}
void WadPreview::keyPressEvent(QKeyEvent *event) {
    switch(event->key()) {
    case Qt::Key_Plus:case Qt::Key_Equal:setZoom(m_zoom*1.2);break;
    case Qt::Key_Minus:setZoom(m_zoom/1.2);break;
    case Qt::Key_0:case Qt::Key_Home:resetView();break;
    case Qt::Key_Left:m_pan.rx()-=32/mapScale();update();break;
    case Qt::Key_Right:m_pan.rx()+=32/mapScale();update();break;
    case Qt::Key_Up:m_pan.ry()+=32/mapScale();update();break;
    case Qt::Key_Down:m_pan.ry()-=32/mapScale();update();break;
    default:QQuickPaintedItem::keyPressEvent(event);return;
    }
    event->accept();
}
void WadPreview::paint(QPainter *p) {
    p->fillRect(boundingRect(),m_canvas);
    p->setFont(m_font);
    if (m_map.lines.isEmpty()) {
        p->setPen(m_walls);
        p->drawText(boundingRect().adjusted(24,24,-24,-24), Qt::AlignCenter | Qt::TextWordWrap,
                    m_map.error.isEmpty() ? "Здесь появится карта после генерации" : m_map.error);
        return;
    }
    const auto center=focusBounds().center()+m_pan;
    const qreal scale=mapScale();
    qreal step=128*scale;
    while(step<32)step*=2;
    while(step>96)step/=2;
    p->setPen(QPen(m_grid,1));
    const auto origin=QPointF(width()/2-center.x()*scale,height()/2+center.y()*scale);
    for(qreal x=std::fmod(origin.x(),step);x<width();x+=step)p->drawLine(QPointF(x,0),QPointF(x,height()));
    for(qreal y=std::fmod(origin.y(),step);y<height();y+=step)p->drawLine(QPointF(0,y),QPointF(width(),y));
    p->save();p->setClipRect(boundingRect());p->translate(width()/2,height()/2);p->scale(scale,-scale);p->translate(-center);
    QVector<QLineF> walls,details;
    for(int i=0;i<m_map.lines.size();++i) {
        if(!m_showAll && !m_map.primaryLines.value(i,true))continue;
        (i<m_map.twoSided.size() && m_map.twoSided[i] ? details : walls).push_back(m_map.lines[i]);
    }
    QPen inner(m_details);inner.setCosmetic(true);inner.setWidthF(.8);p->setPen(inner);p->drawLines(details);
    QPen boundary(m_walls);boundary.setCosmetic(true);boundary.setWidthF(1.4);boundary.setCapStyle(Qt::RoundCap);p->setPen(boundary);p->drawLines(walls);
    p->restore();
}
