// SPDX-License-Identifier: GPL-2.0-or-later
#pragma once
#include <QLineF>
#include <QQuickPaintedItem>
#include <QVector>

struct MapGeometry {
    QVector<QLineF> lines;
    QString name;
    QString error;
    static MapGeometry read(const QString &filename);
};

class WadPreview : public QQuickPaintedItem {
    Q_OBJECT
    Q_PROPERTY(QString file READ file WRITE setFile NOTIFY fileChanged)
public:
    explicit WadPreview(QQuickItem *parent = nullptr) : QQuickPaintedItem(parent) { setAntialiasing(true); }
    QString file() const { return m_file; }
    void setFile(const QString &file);
    void paint(QPainter *painter) override;
signals:
    void fileChanged();
private:
    QString m_file;
    MapGeometry m_map;
};
