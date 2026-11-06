// SPDX-License-Identifier: GPL-2.0-or-later
#pragma once
#include <QLineF>
#include <QColor>
#include <QFont>
#include <QRectF>
#include <QQuickPaintedItem>
#include <QVector>

struct MapGeometry {
    QVector<QLineF> lines;
    QVector<bool> twoSided;
    QVector<bool> primaryLines;
    QRectF bounds;
    QRectF mainBounds;
    void calculateBounds();
    QString name;
    QString error;
    static MapGeometry read(const QString &filename);
};

class WadPreview : public QQuickPaintedItem {
    Q_OBJECT
    Q_PROPERTY(QString file READ file WRITE setFile NOTIFY fileChanged)
    Q_PROPERTY(QColor canvasColor MEMBER m_canvas NOTIFY appearanceChanged)
    Q_PROPERTY(QColor wallColor MEMBER m_walls NOTIFY appearanceChanged)
    Q_PROPERTY(QColor detailColor MEMBER m_details NOTIFY appearanceChanged)
    Q_PROPERTY(QColor gridColor MEMBER m_grid NOTIFY appearanceChanged)
    Q_PROPERTY(QFont viewFont MEMBER m_font NOTIFY appearanceChanged)
    Q_PROPERTY(QString mapName READ mapName NOTIFY fileChanged)
    Q_PROPERTY(int lineCount READ lineCount NOTIFY fileChanged)
    Q_PROPERTY(int mainLineCount READ mainLineCount NOTIFY fileChanged)
    Q_PROPERTY(qreal zoom READ zoom WRITE setZoom NOTIFY zoomChanged)
    Q_PROPERTY(bool showAll READ showAll WRITE setShowAll NOTIFY showAllChanged)
public:
    explicit WadPreview(QQuickItem *parent = nullptr);
    QString mapName() const { return m_map.name; }
    int lineCount() const { return m_map.lines.size(); }
    int mainLineCount() const { return m_map.primaryLines.count(true); }
    qreal zoom() const { return m_zoom; }
    void setZoom(qreal zoom);
    bool showAll() const { return m_showAll; }
    void setShowAll(bool all);
    Q_INVOKABLE void resetView();
    QString file() const { return m_file; }
    void setFile(const QString &file);
    void paint(QPainter *painter) override;
signals:
    void fileChanged();
    void appearanceChanged();
    void zoomChanged();
    void showAllChanged();
protected:
    void wheelEvent(QWheelEvent *event) override;
    void mousePressEvent(QMouseEvent *event) override;
    void mouseMoveEvent(QMouseEvent *event) override;
    void mouseReleaseEvent(QMouseEvent *event) override;
    void keyPressEvent(QKeyEvent *event) override;
private:
    QRectF focusBounds() const;
    qreal mapScale() const;
    qreal m_zoom = 1;
    bool m_showAll = true;
    QPointF m_pan, m_lastMouse;
    QColor m_canvas{"#202023"}, m_walls{"#84baff"}, m_details{"#727b88"}, m_grid{"#303037"};
    QFont m_font;
    QString m_file;
    MapGeometry m_map;
};
