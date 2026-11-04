// SPDX-License-Identifier: GPL-2.0-or-later
#include "wadpreview.h"
#include <QFile>
#include <QMap>
#include <QPainter>
#include <QRegularExpression>
#include <QtEndian>
#include <cmath>

namespace {
quint32 u32(const char *p) { return qFromLittleEndian<quint32>(reinterpret_cast<const uchar *>(p)); }
quint16 u16(const char *p) { return qFromLittleEndian<quint16>(reinterpret_cast<const uchar *>(p)); }
struct Lump { quint32 offset, size; QByteArray name; };
}
MapGeometry MapGeometry::read(const QString &filename) {
    MapGeometry result;
    auto fail = [&result](const QString &error) { result.lines.clear(); result.error = error; return result; };
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
        }
    }
    if (result.lines.isEmpty()) return fail("В карте нет линий для предпросмотра.");
    return result;
}
void WadPreview::setFile(const QString &file) {
    if (m_file == file) return;
    m_file = file; m_map = file.isEmpty() ? MapGeometry() : MapGeometry::read(file);
    emit fileChanged(); update();
}
void WadPreview::paint(QPainter *p) {
    p->fillRect(boundingRect(), QColor("#14191e"));
    p->setPen(QColor("#283239"));
    for (int x = 16; x < width(); x += 24)
        for (int y = 16; y < height(); y += 24) p->drawPoint(x, y);
    if (m_map.lines.isEmpty()) {
        p->setPen(QColor("#b9c8d0"));
        p->drawText(boundingRect().adjusted(24,24,-24,-24), Qt::AlignCenter | Qt::TextWordWrap,
                    m_map.error.isEmpty() ? "Здесь появится настоящая карта\nпосле завершения генерации" : m_map.error);
        return;
    }
    qreal minx = m_map.lines[0].x1(), maxx = minx, miny = m_map.lines[0].y1(), maxy = miny;
    for (const auto &line : m_map.lines) for (const auto &point : {line.p1(), line.p2()}) {
        minx = qMin(minx, point.x()); maxx = qMax(maxx, point.x());
        miny = qMin(miny, point.y()); maxy = qMax(maxy, point.y());
    }
    const qreal scale = qMin(qMax(1., width()-48) / qMax(1., maxx-minx), qMax(1., height()-48) / qMax(1., maxy-miny));
    p->save(); p->translate(width()/2, height()/2); p->scale(scale, -scale);
    p->translate(-(minx+maxx)/2, -(miny+maxy)/2);
    QPen pen(QColor("#a5dfd5")); pen.setCosmetic(true); pen.setWidthF(1.1); p->setPen(pen);
    p->drawLines(m_map.lines); p->restore();
    p->setPen(QColor("#d6e4eb")); p->drawText(QPointF(16,24), m_map.name);
}
