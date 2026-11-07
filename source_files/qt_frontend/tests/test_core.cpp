// SPDX-License-Identifier: GPL-2.0-or-later
#include "../backend.h"
#include "../presentation.h"
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQmlComponent>
#include <QQmlExpression>
#include <QQuickStyle>
#include <QImage>
#include <QPainter>
#include <cmath>
#include <QCryptographicHash>
#include <QFontInfo>
#include <QRawFont>
#include <QQuickItem>
#include <QQuickWindow>
#include <QSet>
#include "../configuration.h"
#include "../wadpreview.h"
#include <QFile>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QtEndian>
#include <QtTest>

class CoreTests : public QObject {
    Q_OBJECT
    QString engine = qEnvironmentVariable("OBSIDIAN_TEST_ENGINE");
    QString data = qEnvironmentVariable("OBSIDIAN_TEST_DATA");
    static QQuickItem *visualItem(QQuickItem *parent, const QString &name) {
        if (!parent) return nullptr;
        if (parent->objectName()==name) return parent;
        for (auto *child:parent->childItems())
            if(auto *result=visualItem(child,name))return result;
        return nullptr;
    }
    static void write(const QString &path, const QByteArray &value) {
        QFile file(path); QVERIFY(file.open(QIODevice::WriteOnly)); QCOMPARE(file.write(value),value.size());
    }
    static void integer(QByteArray &bytes, quint32 value, int width = 4) {
        for (int i=0; i<width; ++i) bytes.append(char(value >> (i*8)));
    }
    static QByteArray wad(const QList<QPair<QByteArray,QByteArray>> &lumps) {
        QByteArray payload, directory;
        for (const auto &l : lumps) {
            integer(directory,12+payload.size()); integer(directory,l.second.size());
            directory += l.first.leftJustified(8,'\0',true); payload += l.second;
        }
        QByteArray out("PWAD"); integer(out,lumps.size()); integer(out,12+payload.size());
        return out+payload+directory;
    }
private slots:
    void studioUnknownAddonPreservesSettings() {
        QVariantMap option{{"id","future"},{"text","Future option"},{"kind","choice"},{"value","abc"},{"default","abc"}};
        QVariantMap module{{"id","new_addon"},{"text","New addon"},{"available",true},{"options",QVariantList{option}}};
        const auto result = studioPresentation({{"modules",QVariantList{module}}});
        const auto decorated = result.value("modules").toList()[0].toMap();
        QCOMPARE(decorated.value("category").toString(),QString("extensions"));
        const auto control = decorated.value("options").toList()[0].toMap();
        QCOMPARE(control.value("category").toString(),QString("extensions"));
        QCOMPARE(control.value("value").toString(),QString("abc"));
        QCOMPARE(control.value("title").toString(),QString("Future option"));
        QVERIFY(control.value("comparison").toString().isEmpty());
    }
    void studioNavigationAndSearch() {
        QTemporaryDir state; Backend backend(engine,data,state.path());
        QTRY_VERIFY_WITH_TIMEOUT(!backend.loading() && !backend.schema().isEmpty(),30000);
        QQuickStyle::setStyle("Fusion");
        qmlRegisterType<WadPreview>("Obsidian",1,0,"WadView");
        QQmlApplicationEngine qml; qml.rootContext()->setContextProperty("backend",&backend);
        qml.load(QUrl("qrc:/ui/Main.qml"));
        QVERIFY(!qml.rootObjects().isEmpty());
        auto *window = qml.rootObjects().first();
        auto evaluate = [&](const QString &expression) {
            QQmlExpression script(qml.rootContext(),window,expression);
            auto result=script.evaluate();
            if(script.hasError())qWarning()<<script.error();
            return result;
        };
        auto *nativeWindow=qobject_cast<QQuickWindow*>(window);
        QVERIFY(nativeWindow);
        // Qt 6.4 must finish creating/exposing the native surface before
        // keyboard injection processes pending geometry and layout events.
        nativeWindow->show();
        QVERIFY(QTest::qWaitForWindowExposed(nativeWindow));
        nativeWindow->requestActivate();
        QTRY_VERIFY(nativeWindow->isActive());
        window->setProperty("width",1440);
        QTest::qWait(100); // Complete the initial resize/layout before editing delegates.
        auto *search=visualItem(nativeWindow->contentItem(),"parameterSearch");
        QVERIFY(search);
        search->forceActiveFocus();
        QTRY_VERIFY(search->hasActiveFocus());
        for(const auto c:QByteArray("zzzz-no-option"))QTest::keyClick(nativeWindow,c);
        QCOMPARE(window->property("query").toString(),QString("zzzz-no-option"));
        QTest::keyClick(nativeWindow,Qt::Key_A,Qt::ControlModifier);
        QTest::keyClick(nativeWindow,Qt::Key_Backspace);
        for(const auto c:QByteArray("float_mons")) {
            QTest::keyClick(nativeWindow,c);
            QCoreApplication::processEvents();
            QVERIFY(search->hasActiveFocus());
        }
        QCOMPARE(window->property("query").toString(),QString("float_mons"));
        QCOMPARE(evaluate("inspected.comparison").toString(),QString("monsters"));
        window->setProperty("query",QString());
        QSet<QString> expected;
        for(const auto &entry:backend.schema().value("modules").toList()) {
            const auto m=entry.toMap();if(!m.value("available").toBool())continue;
            for(const auto &entry:m.value("options").toList()) {
                const auto o=entry.toMap();if(o.value("kind")=="header")continue;
                expected.insert(m.value("id").toString()+"/"+o.value("id").toString());
            }
        }
        window->setProperty("advanced",true);
        QSet<QString> found;
        for(const auto &category:{"project","geometry","combat","resources","appearance","extensions"}) {
            window->setProperty("section",category);
            const auto ids=evaluate("selectedModules(false).map(function(m){return m.options.map(function(o){return m.id+'/'+o.id}).join('\\n')}).join('\\n')").toString().split('\n',Qt::SkipEmptyParts);
            for(const auto &id:ids) { QVERIFY2(!found.contains(id),qPrintable(id));found.insert(id); }
        }
        QCOMPARE(found,expected); // Every available parameter appears exactly once across categories.
        window->setProperty("advanced",false);window->setProperty("section","resources");
        window->setProperty("query","float_size");
        QCOMPARE(evaluate("selectedModules(false)[0].options[0].id").toString(),QString("float_size"));
        window->setProperty("query","room_heights");
        QCOMPARE(evaluate("selectedModules(false)[0].id").toString(),QString("misc"));
        QCOMPARE(evaluate("selectedModules(false)[0].options.length").toInt(),1);
        QVERIFY(evaluate("selectedModules(false)[0].options[0].comparison").toString().isEmpty());
        window->setProperty("query","zzzz-no-option");
        QCOMPARE(evaluate("selectedModules(false).length").toInt(),0);
        window->setProperty("query","");window->setProperty("section","geometry");
        const int basic=evaluate("optionCount(false)").toInt();
        QVERIFY(basic>0);QVERIFY(evaluate("optionCount(true)").toInt()>basic);
        evaluate("refreshInspection()");
        QVERIFY(!evaluate("inspected.id").toString().isEmpty());
        for (const auto &example : {"lighting", "steepness", "monsters"}) {
            const auto key = QString(example)=="lighting" ? "float_overall_lighting_mult" : QString(example)=="steepness" ? "steepness" : "float_mons";
            window->setProperty("query",key);
            QCOMPARE(evaluate("inspected.comparison").toString(),QString(example));
            auto *gallery=visualItem(qobject_cast<QQuickWindow*>(window)->contentItem(),"gameplayComparison");
            QVERIFY(gallery);
            QTRY_COMPARE(gallery->property("example").toString(),QString(example));
            QTRY_VERIFY(gallery->isVisible());
            for (int i=0;i<2;++i) {
                auto *thumbnail=visualItem(gallery,"comparisonThumbnail"+QString::number(i));
                QVERIFY(thumbnail);
                QTRY_COMPARE(thumbnail->property("status").toInt(),1); // Image.Ready.
                QImage image(":/gameplay/"+QString(example)+(i?"-high.png":"-low.png"));
                QCOMPARE(image.size(),QSize(1280,720));
            }
            QVERIFY(QMetaObject::invokeMethod(gallery,"enlarge"));
            auto *dialog=gallery->findChild<QObject*>("comparisonDialog");QVERIFY(dialog);
            QTRY_VERIFY(dialog->property("visible").toBool());
            QVERIFY(QMetaObject::invokeMethod(dialog,"close"));
        }
        window->setProperty("query","");
        window->setProperty("width",1050);QTRY_VERIFY_WITH_TIMEOUT(!window->property("wide").toBool(),3000);
        window->setProperty("height",600);backend.setDark(false);
        QTest::qWait(100);
        backend.setGeneral("port","limit_enforcing");
        QTRY_VERIFY_WITH_TIMEOUT(!backend.loading(),30000);
        QVERIFY(!evaluate("selectedModules(true).some(function(m){return m.id==='ui_arch'})").toBool());
    }
    void previewArt04Capture() {
        QTemporaryDir state; QVERIFY(state.isValid());
        write(state.path()+"/CONFIG.txt", "engine = idtech_1\ngame = doom2\nport = boom\nlength = single\nseed = 12345\n@compress_output = 0\n");
        Backend backend(engine,data,state.path());
        backend.setDark(qEnvironmentVariable("OBSIDIAN_CAPTURE_MODE")=="dark");
        QTRY_VERIFY_WITH_TIMEOUT(!backend.loading() && !backend.schema().isEmpty(),30000);
        if(QQuickStyle::name().isEmpty())QQuickStyle::setStyle("Fusion");
        if(qmlTypeId("Obsidian",1,0,"WadView")<0)qmlRegisterType<WadPreview>("Obsidian",1,0,"WadView");
        QQmlApplicationEngine qml; qml.rootContext()->setContextProperty("backend",&backend);
        qml.load(QUrl("qrc:/ui/prototype/Preview.qml")); QVERIFY(!qml.rootObjects().isEmpty());
        auto *window=qobject_cast<QQuickWindow*>(qml.rootObjects().first()); QVERIFY(window);
        window->setWidth(1440); window->setHeight(900); window->show();
        QVERIFY(QTest::qWaitForWindowExposed(window)); window->requestActivate(); QTRY_VERIFY(window->isActive());
        auto evaluate=[&](const QString &expression) {
            QQmlExpression script(qml.rootContext(),window,expression); const auto value=script.evaluate();
            if(script.hasError())qFatal("%s",qPrintable(script.error().toString())); return value;
        };
        auto *tokens=window->findChild<QObject*>("designTokens"); QVERIFY(tokens);
        QTRY_VERIFY(tokens->property("fontsReady").toBool()); tokens->setProperty("reduceMotion",true);
        auto *menu=window->findChild<QObject*>("commandsMenu"); QVERIFY(menu);
        auto *a=window->findChild<QQuickItem*>("sidebarIconsOriginal"); QVERIFY(a);
        auto *b=window->findChild<QQuickItem*>("sidebarIconsBadges"); QVERIFY(b);
        auto *commands=visualItem(window->contentItem(),"commandsButton"); QVERIFY(commands);
        QCOMPARE(window->property("sidebarIconStyle").toString(),QString("original"));
        backend.exportConfig(QUrl::fromLocalFile(state.path()+"/before.txt"));
        QFile before(state.path()+"/before.txt"); QVERIFY(before.open(QIODevice::ReadOnly)); const auto config=before.readAll();
        const auto revision=backend.revision();
        auto click=[&](QQuickItem *item) {
            QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,item->mapToScene(QPointF(item->width()/2,item->height()/2)).toPoint());
        };
        // Real menu clicks, including repeated clicks on the checked entry.
        for(auto *choice:{a,a,b,b,a}) {
            click(commands); QTRY_VERIFY(menu->property("opened").toBool()); QTest::qWait(80);
            click(choice); QTRY_VERIFY(!menu->property("visible").toBool());
            QCOMPARE(a->property("checked").toBool(),choice==a); QCOMPARE(b->property("checked").toBool(),choice==b);
            QCOMPARE(window->property("sidebarIconStyle").toString(),QString(choice==a ? "original" : "badges"));
        }
        const QStringList sections{"project","geometry","combat","resources","appearance","results"};
        for(const QString style:{"original","badges"}) {
            window->setProperty("sidebarIconStyle",style);
            for(const auto &section:sections) {
                auto *row=visualItem(window->contentItem(),"sidebarRow_"+section); QVERIFY(row); click(row);
                QTRY_COMPARE(window->property("section").toString(),section);
                for(const auto &key:sections) {
                    auto *badge=visualItem(window->contentItem(),"sidebarIconBadge_"+key); QVERIFY(badge);
                    QCOMPARE(badge->isVisible(),style=="badges");
                }
                // Return activates the same delegate using its existing keyboard behavior.
                row->forceActiveFocus(Qt::TabFocusReason); QTest::keyClick(window,Qt::Key_Return);
                QCOMPARE(window->property("section").toString(),section);
            }
        }
        // Gallery keyboard navigation still works in both view modes with B selected.
        evaluate("go('resources')"); QTest::qWait(100);
        for(const QString mode:{"grid","list"}) {
            window->setProperty("resourceViewMode",mode);
            evaluate("selectResource('ammo',false)");
            auto *ammo=visualItem(window->contentItem(),"resourceCard_ammo"); QVERIFY(ammo);
            ammo->forceActiveFocus(Qt::TabFocusReason); QTest::keyClick(window,Qt::Key_Right);
            QTRY_COMPARE(window->property("currentResourceId").toString(),QString("health"));
            QTest::keyClick(window,Qt::Key_Left);
            QTRY_COMPARE(window->property("currentResourceId").toString(),QString("ammo"));
        }
        window->setProperty("resourceViewMode","grid");
        QTest::keyClick(window,Qt::Key_Tab); QVERIFY(window->activeFocusItem());
        click(commands); QTRY_VERIFY(menu->property("opened").toBool());
        QTest::keyClick(window,Qt::Key_Escape); QTRY_VERIFY(!menu->property("visible").toBool());
        const auto destination=qEnvironmentVariable("OBSIDIAN_CAPTURE_DIR"); QJsonArray shots;
        const bool core=qEnvironmentVariable("OBSIDIAN_ART04_CORE_ONLY")=="1";
        auto rect=[](QQuickItem *item) {const auto p=item->mapToScene(QPointF());return QJsonArray{p.x(),p.y(),item->width(),item->height()};};
        auto luminance=[](QColor color) {
            auto linear=[](double c){return c<=0.04045 ? c/12.92 : std::pow((c+0.055)/1.055,2.4);};
            return 0.2126*linear(color.redF())+0.7152*linear(color.greenF())+0.0722*linear(color.blueF());
        };
        for(const QString scenario:core ? QStringList{"normal"} : QStringList{"normal","minimum","large-text","focus"}) {
            for(const QString section:scenario=="normal" ? QStringList{"geometry","resources"} : QStringList{"geometry"}) {
                window->setWidth(scenario=="minimum" ? 900 : 1440); window->setHeight(scenario=="minimum" ? 540 : 900);
                tokens->setProperty("textScale",scenario=="large-text" ? 1.25 : 1.0);
                evaluate("go('"+section+"')"); QTest::qWait(1200); // Allow existing transient scrollbars to settle before pairing.
                QJsonArray originalGeometry; QImage originalImage;
                for(const QString style:{"original","badges"}) {
                    window->setProperty("sidebarIconStyle",style);
                    auto *focus= scenario=="focus" ? visualItem(window->contentItem(),"sidebarRow_geometry") : commands;
                    QVERIFY(focus); focus->forceActiveFocus(scenario=="focus" ? Qt::TabFocusReason : Qt::OtherFocusReason);
                    if(scenario=="focus")QVERIFY(focus->property("visualFocus").toBool());
                    QTest::mouseMove(window,QPoint(2,2)); QTest::qWait(180);
                    QJsonArray navigation, geometry, editor, scroll;
                    for(const auto &key:sections) {
                        auto *row=visualItem(window->contentItem(),"sidebarRow_"+key);
                        auto *label=visualItem(window->contentItem(),"sidebarLabel_"+key);
                        auto *slot=visualItem(window->contentItem(),"sidebarIconSlot_"+key);
                        auto *glyph=visualItem(window->contentItem(),"sidebarIconGlyph_"+key);
                        auto *badge=visualItem(window->contentItem(),"sidebarIconBadge_"+key);
                        QVERIFY(row && label && slot && glyph && badge);
                        const auto ink=glyph->property("ink").value<QColor>(), fill=badge->property("color").value<QColor>();
                        const auto ratio=(qMax(luminance(ink),luminance(fill))+0.05)/(qMin(luminance(ink),luminance(fill))+0.05);
                        if(style=="badges") {QVERIFY2(ratio>=3,qPrintable(key+" glyph contrast")); QVERIFY(badge->mapToScene(QPointF(badge->width(),0)).x()<label->mapToScene(QPointF()).x());}
                        geometry.append(QJsonObject{{"id",key},{"row",rect(row)},{"label",rect(label)},{"slot",rect(slot)},{"glyph",rect(glyph)}});
                        navigation.append(QJsonObject{{"id",key},{"selected",key==section},{"rowRect",rect(row)},{"labelRect",rect(label)},{"iconRect",rect(slot)},{"glyphRect",rect(glyph)},{"badgeRect",rect(badge)},
                            {"glyphColor",ink.name()},{"badgeColor",fill.name()},{"glyphContrast",ratio},{"badgeVisible",badge->isVisible()},{"visualFocus",row->property("visualFocus").toBool()}});
                    }
                    std::function<void(QQuickItem*)> record=[&](QQuickItem *item) {
                        if(item->objectName().startsWith("resourceCard_") || item->objectName().startsWith("optionRow_") || item->objectName()=="pageTitle")editor.append(QJsonObject{{"id",item->objectName()},{"rect",rect(item)}});
                        if(item->inherits("QQuickFlickable"))scroll.append(QJsonObject{{"rect",rect(item)},{"contentX",item->property("contentX").toDouble()},{"contentY",item->property("contentY").toDouble()}});
                        for(auto *child:item->childItems())record(child);
                    }; record(window->contentItem());
                    geometry.append(editor); geometry.append(scroll);
                    if(style=="original")originalGeometry=geometry; else QCOMPARE(geometry,originalGeometry);
                    QCOMPARE(backend.revision(),revision); QCOMPARE(backend.value("ui_pickups","ammo"),QString("normal"));
                    QCOMPARE(window->property("resourceSelectionStyle").toString(),QString("classic"));
                    QCOMPARE(window->property("geometryTextureStyle").toString(),QString("zebra"));
                    QCOMPARE(window->property("ammoInspectorStyle").toString(),QString("original"));
                    const auto image=window->grabWindow(); QVERIFY(!image.isNull());
                    const auto acceptedPath=qEnvironmentVariable("OBSIDIAN_ART04_BASELINE_IMAGE");
                    if(!acceptedPath.isEmpty() && scenario=="normal" && section=="resources" && style=="original" && window->devicePixelRatio()==1) {
                        const QImage accepted(acceptedPath); QVERIFY(!accepted.isNull());
                        // Accepted ART03 A sidebar, including all glyphs, labels and selected row.
                        QCOMPARE(image.copy(QRect(0,62,210,390)).convertToFormat(QImage::Format_ARGB32),accepted.copy(QRect(0,62,210,390)).convertToFormat(QImage::Format_ARGB32));
                    }
                    // Pixel evidence restricts the actual rendered change to the six badge bounds.
                    if(style=="original")originalImage=image; else {
                        auto masked=image, baseline=originalImage;
                        QPainter painter(&masked), basePainter(&baseline);
                        for(const auto &key:sections) {
                            auto *badge=visualItem(window->contentItem(),"sidebarIconBadge_"+key);
                            const auto p=badge->mapToScene(QPointF(-1,-1)); const double dpr=window->devicePixelRatio();
                            const QRect box(qFloor(p.x()*dpr),qFloor(p.y()*dpr),qCeil((badge->width()+2)*dpr),qCeil((badge->height()+2)*dpr));
                            painter.fillRect(box,Qt::black); basePainter.fillRect(box,Qt::black);
                        }
                        painter.end();basePainter.end();
                        if(masked!=baseline && !destination.isEmpty()) {masked.save(destination+"/difference-current.png");baseline.save(destination+"/difference-original.png");}
                        QCOMPARE(masked,baseline);
                    }
                    if(!destination.isEmpty()) {
                        const QString filename=scenario+"-"+section+"-"+style+".png"; QVERIFY(image.save(destination+"/"+filename));
                        QFile png(destination+"/"+filename); QVERIFY(png.open(QIODevice::ReadOnly));
                        auto *sidebar=visualItem(window->contentItem(),"sidebarPanel"); QVERIFY(sidebar);
                        shots.append(QJsonObject{{"file",filename},{"sha256",QString(QCryptographicHash::hash(png.readAll(),QCryptographicHash::Sha256).toHex())},
                            {"theme",backend.dark()?"dark":"light"},{"style",style},{"scenario",scenario},{"section",section},{"selectedResource",window->property("currentResourceId").toString()},
                            {"inspectedId",evaluate("inspected ? inspected.id : ''").toString()},{"inspectedModule",window->property("inspectedModule").toString()},{"value",evaluate("inspected ? backend.value(inspectedModule, inspected.id) : ''").toString()},{"ammoValue",backend.value("ui_pickups","ammo")},{"revision",double(revision)},
                            {"resourceSelectionStyle","classic"},{"geometryTextureStyle","zebra"},{"ammoInspectorStyle","original"},{"inspectorShown",window->property("inspectorShown").toBool()},{"inlineInspector",window->property("inlineInspector").toBool()},
                            {"textScale",tokens->property("textScale").toDouble()},{"logicalWidth",window->width()},{"logicalHeight",window->height()},{"pixelWidth",image.width()},{"pixelHeight",image.height()},{"dpr",window->devicePixelRatio()},
                            {"qtVersion",qVersion()},{"focus",window->activeFocusItem()?window->activeFocusItem()->objectName():QString()},{"sidebarRect",rect(sidebar)},{"navigation",navigation},{"editor",editor},{"scroll",scroll}});
                    }
                }
            }
        }
        backend.exportConfig(QUrl::fromLocalFile(state.path()+"/after.txt")); QFile after(state.path()+"/after.txt"); QVERIFY(after.open(QIODevice::ReadOnly)); QCOMPARE(after.readAll(),config);
        window->setProperty("sidebarIconStyle","badges");
        QQmlApplicationEngine fresh; fresh.rootContext()->setContextProperty("backend",&backend); fresh.load(QUrl("qrc:/ui/prototype/Preview.qml")); QVERIFY(!fresh.rootObjects().isEmpty());
        QCOMPARE(fresh.rootObjects().first()->property("sidebarIconStyle").toString(),QString("original"));
        if(!destination.isEmpty())write(destination+"/states.json",QJsonDocument(shots).toJson());
    }
    void previewArt03Capture() {
        QTemporaryDir state; QVERIFY(state.isValid());
        write(state.path()+"/CONFIG.txt", "engine = idtech_1\ngame = doom2\nport = boom\nlength = single\nseed = 12345\n@compress_output = 0\n");
        Backend backend(engine,data,state.path());
        backend.setDark(qEnvironmentVariable("OBSIDIAN_CAPTURE_MODE")=="dark");
        QTRY_VERIFY_WITH_TIMEOUT(!backend.loading() && !backend.schema().isEmpty(),30000);
        if(QQuickStyle::name().isEmpty())QQuickStyle::setStyle("Fusion");
        if(qmlTypeId("Obsidian",1,0,"WadView")<0)qmlRegisterType<WadPreview>("Obsidian",1,0,"WadView");
        QQmlApplicationEngine qml; qml.rootContext()->setContextProperty("backend",&backend);
        qml.load(QUrl("qrc:/ui/prototype/Preview.qml")); QVERIFY(!qml.rootObjects().isEmpty());
        auto *window=qobject_cast<QQuickWindow*>(qml.rootObjects().first()); QVERIFY(window);
        window->show(); QVERIFY(QTest::qWaitForWindowExposed(window));
        window->requestActivate(); QTRY_VERIFY(window->isActive());
        window->setWidth(1440); window->setHeight(900);
        auto evaluate=[&](const QString &expression) {
            QQmlExpression script(qml.rootContext(),window,expression); const auto value=script.evaluate();
            if(script.hasError())qFatal("%s",qPrintable(script.error().toString())); return value;
        };
        auto *tokens=window->findChild<QObject*>("designTokens"); QVERIFY(tokens);
        QTRY_VERIFY(tokens->property("fontsReady").toBool()); tokens->setProperty("reduceMotion",true);
        QCOMPARE(window->property("ammoInspectorStyle").toString(),QString("original"));
        auto *menu=window->findChild<QObject*>("commandsMenu"); QVERIFY(menu);
        auto *a=window->findChild<QQuickItem*>("ammoInspectorOriginal"); QVERIFY(a);
        auto *b=window->findChild<QQuickItem*>("ammoInspectorPriority"); QVERIFY(b);
        auto *commands=visualItem(window->contentItem(),"commandsButton"); QVERIFY(commands);
        backend.exportConfig(QUrl::fromLocalFile(state.path()+"/before.txt"));
        QFile before(state.path()+"/before.txt"); QVERIFY(before.open(QIODevice::ReadOnly)); const auto config=before.readAll();
        for(auto *choice:{a,a,b,b,a}) {
            QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,commands->mapToScene(QPointF(commands->width()/2,commands->height()/2)).toPoint());
            QTRY_VERIFY(menu->property("opened").toBool()); QTest::qWait(80);
            QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,choice->mapToScene(QPointF(choice->width()/2,choice->height()/2)).toPoint());
            QTRY_VERIFY(!menu->property("visible").toBool());
            QCOMPARE(a->property("checked").toBool(),choice==a); QCOMPARE(b->property("checked").toBool(),choice==b);
            QCOMPARE(window->property("ammoInspectorStyle").toString(),QString(choice==a ? "original" : "priority"));
            QVERIFY(window->findChild<QObject*>("resourceStyleClassic")->property("checked").toBool());
            QVERIFY(window->findChild<QObject*>("geometryTextureZebra")->property("checked").toBool());
        }
        window->setProperty("ammoInspectorStyle","priority");
        for(const QString id:{"health","items","weapons"}) {
            evaluate("selectResource('"+id+"',false)"); QTest::qWait(80);
            QVERIFY(!window->property("priorityAmmoInspector").toBool());
            QVERIFY(!visualItem(window->contentItem(),"inspectorAssets")->property("unifiedSurface").toBool());
        }
        window->setProperty("section","geometry"); QTest::qWait(80); QVERIFY(!window->property("priorityAmmoInspector").toBool());
        window->setProperty("section","resources"); evaluate("selectResource('ammo',false)"); QTest::qWait(100);
        // The value is read live from the backend, in both experiment states.
        const auto normal=backend.value("ui_pickups","ammo"); QCOMPARE(normal,QString("normal"));
        for(const QString style:{"original","priority"}) {
            window->setProperty("ammoInspectorStyle",style);
            backend.setOption("ui_pickups","ammo","more");
            QTRY_COMPARE(visualItem(window->contentItem(),"inspectorValue")->property("text").toString(),QString("more"));
            backend.setOption("ui_pickups","ammo",normal);
            QTRY_COMPARE(visualItem(window->contentItem(),"inspectorValue")->property("text").toString(),normal);
        }
        const QStringList ids{"clip","ammo_box","shells","shell_box","rocket","rocket_box","cell","cell_pack"};
        const QStringList captions{QString::fromUtf8("Патроны"),QString::fromUtf8("Ящик патронов"),QString::fromUtf8("Патроны для дробовика"),QString::fromUtf8("Коробка патронов"),QString::fromUtf8("Ракета"),QString::fromUtf8("Ящик ракет"),QString::fromUtf8("Энергетическая ячейка"),QString::fromUtf8("Блок ячеек")};
        const auto destination=qEnvironmentVariable("OBSIDIAN_CAPTURE_DIR"); QJsonArray shots;
        const bool core=qEnvironmentVariable("OBSIDIAN_ART03_CORE_ONLY")=="1";
        auto rect=[](QQuickItem *item) { const auto p=item->mapToScene(QPointF()); return QJsonArray{p.x(),p.y(),item->width(),item->height()}; };
        for(const QString scenario:core ? QStringList{"normal"} : QStringList{"normal","large-text","bottom","modal","modal-bottom"}) {
            const bool modal=scenario.startsWith("modal"), bottom=scenario.endsWith("bottom");
            window->setWidth(modal ? 1050 : 1440); window->setHeight(modal ? 640 : 900);
            tokens->setProperty("textScale",scenario=="large-text" ? 1.25 : 1.0);
            auto *dialog=window->findChild<QObject*>("inspectorDialog"); QVERIFY(dialog);
            if(modal) { QTRY_VERIFY(!window->property("inlineInspector").toBool()); evaluate("selectResource('ammo',true)"); QTRY_VERIFY(dialog->property("opened").toBool()); }
            QTest::qWait(150);
            QJsonArray baselineSprites, baselineEditor;
            for(const QString style:{"original","priority"}) {
                window->setProperty("ammoInspectorStyle",style); QTest::qWait(150);
                auto *root=modal ? dialog->property("contentItem").value<QQuickItem*>() : window->contentItem(); QVERIFY(root);
                auto *scroll=visualItem(root,"inspectorScroll"); QVERIFY(scroll);
                auto *flick=scroll->property("contentItem").value<QQuickItem*>(); QVERIFY(flick);
                const double maxY=qMax(0.0,flick->property("contentHeight").toDouble()-flick->height());
                flick->setProperty("contentY",bottom ? maxY : 0.0);
                if(modal)scroll->forceActiveFocus(Qt::OtherFocusReason); else commands->forceActiveFocus(Qt::OtherFocusReason);
                QTest::mouseMove(window,QPoint(2,2)); QTest::qWait(100);
                auto *assets=visualItem(root,"inspectorAssets"); QVERIFY(assets);
                auto *grid=visualItem(root,"assetSpriteGrid"); QVERIFY(grid);
                auto *value=visualItem(root,"inspectorValue"); QVERIFY(value);
                auto *desc=visualItem(root,"inspectorDescription"); QVERIFY(desc);
                auto *notice=visualItem(root,"assetRightsNotice"); QVERIFY(notice);
                auto *def=visualItem(root,"inspectorDefault"); QVERIFY(def);
                QCOMPARE(assets->property("unifiedSurface").toBool(),style=="priority");
                QCOMPARE(grid->property("columns").toInt(),2);
                QCOMPARE(value->property("text").toString(),normal);
                QVERIFY(desc->mapToScene(QPointF(0,desc->height())).y() < qMin(assets->mapToScene(QPointF()).y(),value->mapToScene(QPointF()).y()));
                if(style=="priority") QVERIFY(value->mapToScene(QPointF(0,value->height())).y() < assets->mapToScene(QPointF()).y());
                else QVERIFY(assets->mapToScene(QPointF(0,assets->height())).y() < value->mapToScene(QPointF()).y());
                if(scenario=="normal" && style=="priority") {
                    QVERIFY(value->mapToScene(QPointF(0,value->height())).y() < scroll->mapToScene(QPointF(0,scroll->height())).y());
                    QVERIFY(grid->mapToScene(QPointF()).y() < scroll->mapToScene(QPointF(0,scroll->height())).y());
                }
                // Original ColumnLayout excluded hidden blocks and placed every visible
                // block at implicit height with exactly 16 px spacing. Guard against
                // explicit GridLayout row holes changing A's retained geometry.
                if(style=="original") {
                    QQuickItem *previous=nullptr;
                    for(auto *block:desc->parentItem()->childItems())if(block->isVisible()) {
                        if(previous) QVERIFY(qAbs(block->y()-previous->y()-previous->height()-16)<0.01);
                        previous=block;
                    }
                }
                QCOMPARE(QQmlExpression(qml.rootContext(),assets,"examples.length").evaluate().toInt(),8);
                QJsonArray sprites;
                for(int i=0;i<ids.size();++i) {
                    auto *sprite=visualItem(assets,"freedoomSprite_"+ids[i]); QVERIFY(sprite);
                    auto *caption=visualItem(assets,"assetCaption_"+ids[i]); QVERIFY(caption);
                    QTRY_COMPARE(sprite->property("status").toInt(),1);
                    QCOMPARE(sprite->property("smooth").toBool(),false); QCOMPARE(sprite->property("mipmap").toBool(),false);
                    QCOMPARE(caption->property("text").toString(),captions[i]);
                    const auto source=sprite->property("source").toUrl(); QVERIFY(source.path().endsWith("/"+ids[i]+".png"));
                    const auto p=sprite->mapToItem(grid,QPointF()), cp=caption->mapToItem(grid,QPointF());
                    sprites.append(QJsonObject{{"id",ids[i]},{"source",source.toString()},{"x",p.x()},{"y",p.y()},{"width",sprite->width()},{"height",sprite->height()},
                        {"paintedWidth",sprite->property("paintedWidth").toDouble()},{"paintedHeight",sprite->property("paintedHeight").toDouble()},
                        {"smooth",false},{"mipmap",false},{"caption",captions[i]},{"captionRect",QJsonArray{cp.x(),cp.y(),caption->width(),caption->height()}}});
                }
                QJsonArray editor;
                std::function<void(QQuickItem*)> record=[&](QQuickItem *item) {
                    if(item->objectName().startsWith("resourceCard_") || item->objectName().startsWith("optionRow_"))editor.append(QJsonObject{{"id",item->objectName()},{"rect",rect(item)}});
                    for(auto *child:item->childItems())record(child);
                }; record(window->contentItem());
                if(style=="original") { baselineSprites=sprites; baselineEditor=editor; } else { QCOMPARE(sprites,baselineSprites); QCOMPARE(editor,baselineEditor); }
                if(bottom) {
                    const auto viewportBottom=scroll->mapToScene(QPointF(0,scroll->height())).y();
                    QVERIFY(notice->mapToScene(QPointF(0,notice->height())).y() <= viewportBottom+1);
                    QVERIFY(def->mapToScene(QPointF(0,def->height())).y() <= viewportBottom+1);
                    auto *last=visualItem(assets,"assetCaption_cell_pack"); QVERIFY(last->mapToScene(QPointF()).y() >= scroll->mapToScene(QPointF()).y());
                }
                QCOMPARE(window->property("resourceSelectionStyle").toString(),QString("classic"));
                QCOMPARE(window->property("geometryTextureStyle").toString(),QString("zebra"));
                QCOMPARE(evaluate("inspected.id").toString(),QString("ammo")); QCOMPARE(backend.value("ui_pickups","ammo"),normal);
                if(!destination.isEmpty()) {
                    window->update(); QCoreApplication::processEvents(); const auto image=window->grabWindow(); QVERIFY(!image.isNull());
                    QCOMPARE(image.size(),QSize(qRound(window->width()*window->devicePixelRatio()),qRound(window->height()*window->devicePixelRatio())));
                    const auto filename=scenario+"-"+style+".png"; QVERIFY(image.save(destination+"/"+filename));
                    QFile png(destination+"/"+filename); QVERIFY(png.open(QIODevice::ReadOnly));
                    shots.append(QJsonObject{{"file",filename},{"sha256",QString(QCryptographicHash::hash(png.readAll(),QCryptographicHash::Sha256).toHex())},
                        {"theme",backend.dark()?"dark":"light"},{"style",style},{"scenario",scenario},{"inspectedModule","ui_pickups"},{"inspectedId","ammo"},{"value",normal},
                        {"resourceSelectionStyle","classic"},{"geometryTextureStyle","zebra"},{"textScale",tokens->property("textScale").toDouble()},
                        {"logicalWidth",window->width()},{"logicalHeight",window->height()},{"pixelWidth",image.width()},{"pixelHeight",image.height()},{"dpr",window->devicePixelRatio()},
                        {"qtVersion",qVersion()},{"focus",window->activeFocusItem() ? window->activeFocusItem()->objectName() : QString()},
                        {"scrollPosition",bottom?"bottom":"top"},{"contentY",flick->property("contentY").toDouble()},{"contentHeight",flick->property("contentHeight").toDouble()},
                        {"inspectorRect",modal ? rect(dialog->property("background").value<QQuickItem*>()) : rect(scroll->parentItem()->parentItem())},{"viewport",rect(scroll)},{"description",rect(desc)},{"valueRect",rect(value)},{"galleryRect",rect(assets)},{"gridRect",rect(grid)},
                        {"notice",notice->property("text").toString()},{"noticeRect",rect(notice)},{"defaultText",def->property("text").toString()},{"defaultRect",rect(def)},
                        {"sprites",sprites},{"editor",editor}});
                }
            }
            if(modal) { QVERIFY(QMetaObject::invokeMethod(dialog,"close")); QTRY_VERIFY(!dialog->property("visible").toBool()); }
        }
        backend.exportConfig(QUrl::fromLocalFile(state.path()+"/after.txt")); QFile after(state.path()+"/after.txt"); QVERIFY(after.open(QIODevice::ReadOnly)); QCOMPARE(after.readAll(),config);
        // Shared Studio component remains opt-in; incompatible games never get
        // substitute Freedoom art even when the experiment is selected.
        QQmlComponent shared(&qml,QUrl("qrc:/ui/AssetPreview.qml"));
        QScopedPointer<QObject> sharedAssets(shared.create()); QVERIFY2(sharedAssets,qPrintable(shared.errorString()));
        QCOMPARE(sharedAssets->property("unifiedSurface").toBool(),false);
        sharedAssets->setProperty("optionId","ammo"); QVERIFY(sharedAssets->property("available").toBool());
        backend.setGeneral("game","heretic"); QTRY_VERIFY_WITH_TIMEOUT(!backend.loading(),30000);
        QTRY_VERIFY(!window->property("priorityAmmoInspector").toBool());
        QTRY_VERIFY(!sharedAssets->property("available").toBool());
        QCOMPARE(QQmlExpression(qml.rootContext(),sharedAssets.data(),"examples.length").evaluate().toInt(),0);
        backend.setGeneral("game","doom2"); QTRY_VERIFY_WITH_TIMEOUT(!backend.loading(),30000);
        QQmlApplicationEngine fresh; fresh.rootContext()->setContextProperty("backend",&backend); fresh.load(QUrl("qrc:/ui/prototype/Preview.qml")); QVERIFY(!fresh.rootObjects().isEmpty());
        QCOMPARE(fresh.rootObjects().first()->property("ammoInspectorStyle").toString(),QString("original"));
        if(!destination.isEmpty())write(destination+"/states.json",QJsonDocument(shots).toJson());
    }
    void previewArt02Capture() {
        QTemporaryDir state; QVERIFY(state.isValid());
        write(state.path()+"/CONFIG.txt", "engine = idtech_1\ngame = doom2\nport = boom\nlength = single\nseed = 12345\n@compress_output = 0\n");
        Backend backend(engine,data,state.path());
        backend.setDark(qEnvironmentVariable("OBSIDIAN_CAPTURE_MODE")=="dark");
        QTRY_VERIFY_WITH_TIMEOUT(!backend.loading() && !backend.schema().isEmpty(),30000);
        if(QQuickStyle::name().isEmpty())QQuickStyle::setStyle("Fusion");
        if(qmlTypeId("Obsidian",1,0,"WadView")<0)qmlRegisterType<WadPreview>("Obsidian",1,0,"WadView");
        QQmlApplicationEngine qml; qml.rootContext()->setContextProperty("backend",&backend);
        qml.load(QUrl("qrc:/ui/prototype/Preview.qml"));
        QVERIFY(!qml.rootObjects().isEmpty());
        auto *window=qobject_cast<QQuickWindow*>(qml.rootObjects().first()); QVERIFY(window);
        window->show(); QVERIFY(QTest::qWaitForWindowExposed(window));
        window->requestActivate(); QTRY_VERIFY(window->isActive());
        window->setWidth(1440); window->setHeight(900);
        auto evaluate=[&](const QString &expression) {
            QQmlExpression script(qml.rootContext(),window,expression);
            const auto value=script.evaluate();
            if(script.hasError())qFatal("%s",qPrintable(script.error().toString()));
            return value;
        };
        auto *tokens=window->findChild<QObject*>("designTokens"); QVERIFY(tokens);
        QTRY_VERIFY(tokens->property("fontsReady").toBool());
        tokens->setProperty("reduceMotion",true);
        QCOMPARE(window->property("geometryTextureStyle").toString(),QString("zebra"));
        QCOMPARE(window->property("resourceSelectionStyle").toString(),QString("classic"));
        auto *menu=window->findChild<QObject*>("commandsMenu"); QVERIFY(menu);
        auto *a=window->findChild<QQuickItem*>("geometryTextureZebra"); QVERIFY(a);
        auto *b=window->findChild<QQuickItem*>("geometryTextureUniform"); QVERIFY(b);
        auto *resourceA=window->findChild<QQuickItem*>("resourceStyleClassic"); QVERIFY(resourceA);
        auto *commands=visualItem(window->contentItem(),"commandsButton"); QVERIFY(commands);
        backend.exportConfig(QUrl::fromLocalFile(state.path()+"/before.txt"));
        QFile before(state.path()+"/before.txt"); QVERIFY(before.open(QIODevice::ReadOnly));
        const auto config=before.readAll();
        const auto revision=backend.revision();
        for(auto *choice:{a,a,b,b,a}) {
            QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,commands->mapToScene(QPointF(commands->width()/2,commands->height()/2)).toPoint());
            QTRY_VERIFY(menu->property("opened").toBool());
            QTest::qWait(80);
            QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,choice->mapToScene(QPointF(choice->width()/2,choice->height()/2)).toPoint());
            QTRY_VERIFY(!menu->property("visible").toBool());
            QCOMPARE(a->property("checked").toBool(),choice==a);
            QCOMPARE(b->property("checked").toBool(),choice==b);
            QCOMPARE(resourceA->property("checked").toBool(),true);
            QCOMPARE(window->property("geometryTextureStyle").toString(),QString(choice==a ? "zebra" : "uniform"));
        }
        auto rows=[&]() {
            QList<QQuickItem*> result;
            std::function<void(QQuickItem*)> visit=[&](QQuickItem *item) {
                if(item->objectName().startsWith("optionRow_"))result.append(item);
                for(auto *child:item->childItems())visit(child);
            };
            visit(window->contentItem()); return result;
        };
        // Both off-scope categories and search results retain their original surfaces.
        for(const auto &section:{"combat","resources","geometry"}) {
            window->setProperty("section",section);
            if(QString(section)=="geometry")window->setProperty("query","liquids");
            window->setProperty("geometryTextureStyle","uniform"); QTest::qWait(100);
            for(auto *row:rows()) {
                const bool target=QString(section)=="geometry" && row->property("moduleId").toString()=="ui_arch";
                QCOMPARE(row->property("uniformSurface").toBool(),target);
                if(!target) {
                    auto *surface=visualItem(row,"rowSurface"); QVERIFY(surface);
                    auto *separator=visualItem(row,"rowSeparator"); QVERIFY(separator);
                    QVERIFY(!separator->isVisible());
                    QCOMPARE(surface->property("color").value<QColor>(),tokens->property(row->property("stripeIndex").toInt()%2 ? "alternateRow" : "rowBase").value<QColor>());
                }
            }
        }
        window->setProperty("query",""); window->setProperty("section","geometry");
        evaluate("selectInitial()"); QTest::qWait(200);
        auto *groupTitle=visualItem(window->contentItem(),"groupTitle_ui_arch"); QVERIFY(groupTitle);
        QCOMPARE(groupTitle->property("text").toString(),QString::fromUtf8("Структура уровня"));
        const auto options=evaluate("JSON.stringify(modules())").toString();
        const auto destination=qEnvironmentVariable("OBSIDIAN_CAPTURE_DIR");
        QJsonArray shots;
        const bool core=qEnvironmentVariable("OBSIDIAN_ART02_CORE_ONLY")=="1";
        for(const QString scenario: core ? QStringList{"normal"} : QStringList{"normal","large-text","narrow","focus","popup"}) {
            window->setWidth(scenario=="narrow" ? 1050 : 1440);
            window->setHeight(scenario=="narrow" ? 640 : 900);
            tokens->setProperty("textScale",scenario=="large-text" ? 1.25 : 1.0);
            QTest::qWait(180);
            QJsonArray baseline;
            for(const QString style:{"zebra","uniform"}) {
                window->setProperty("geometryTextureStyle",style);
                commands->forceActiveFocus(Qt::OtherFocusReason); QTest::mouseMove(window,QPoint(2,2));
                QTest::qWait(150);
                auto currentRows=rows(); QVERIFY(!currentRows.isEmpty());
                QList<QQuickItem*> targetRows;
                for(auto *row:currentRows)if(row->property("moduleId").toString()=="ui_arch")targetRows.append(row);
                QVERIFY(targetRows.size()>2);
                QQuickItem *control=nullptr;
                std::function<void(QQuickItem*)> findCombo=[&](QQuickItem *item) {
                    if(!control && item->isVisible() && item->property("popup").isValid())control=item;
                    for(auto *child:item->childItems())findCombo(child);
                };
                findCombo(targetRows.first()); QVERIFY(control);
                auto *popup=control->property("popup").value<QObject*>(); QVERIFY(popup);
                if(scenario=="focus" || scenario=="popup") {
                    control->forceActiveFocus(Qt::TabFocusReason);
                    QTRY_VERIFY(control->hasActiveFocus());
                    QTRY_VERIFY(control->property("visualFocus").toBool());
                    if(scenario=="popup") { QTest::keyClick(window,Qt::Key_Space); QTRY_VERIFY(popup->property("opened").toBool()); }
                }
                QTest::qWait(120);
                QJsonArray geometry;
                for(auto *row:currentRows) {
                    const bool target=row->property("moduleId").toString()=="ui_arch";
                    QCOMPARE(row->property("uniformSurface").toBool(),target && style=="uniform");
                    auto *surface=visualItem(row,"rowSurface"); QVERIFY(surface);
                    auto *separator=visualItem(row,"rowSeparator"); QVERIFY(separator);
                    const bool separated=target && style=="uniform" && row!=targetRows.last();
                    QCOMPARE(separator->isVisible(),separated);
                    QCOMPARE(surface->property("color").value<QColor>(),tokens->property(target && style=="uniform" ? "surface" : row->property("stripeIndex").toInt()%2 ? "alternateRow" : "rowBase").value<QColor>());
                    QJsonArray children;
                    std::function<void(QQuickItem*)> record=[&](QQuickItem *item) {
                        if(item!=surface && item!=separator && item->isVisible()) {
                            const auto pos=item->mapToScene(QPointF());
                            QJsonObject detail{{"type",QString(item->metaObject()->className())},{"x",pos.x()},{"y",pos.y()},{"w",item->width()},{"h",item->height()}};
                            for(const auto key:{"text","currentIndex","value","checked"})if(item->property(key).isValid())detail[key]=QJsonValue::fromVariant(item->property(key));
                            children.append(detail);
                        }
                        for(auto *child:item->childItems())record(child);
                    };
                    record(row);
                    geometry.append(QJsonObject{{"id",row->objectName()},{"value",row->property("value").toString()},{"items",children}});
                }
                if(style=="zebra")baseline=geometry; else QCOMPARE(geometry,baseline);
                QCOMPARE(window->property("section").toString(),QString("geometry"));
                QCOMPARE(window->property("query").toString(),QString());
                QCOMPARE(window->property("resourceSelectionStyle").toString(),QString("classic"));
                QCOMPARE(backend.revision(),revision);
                QCOMPARE(evaluate("JSON.stringify(modules())").toString(),options);
                QCOMPARE(backend.value("","seed"),QString("12345"));
                if(!destination.isEmpty()) {
                    window->update(); QCoreApplication::processEvents();
                    const auto image=window->grabWindow(); QVERIFY(!image.isNull());
                    QCOMPARE(image.size(),QSize(qRound(window->width()*window->devicePixelRatio()),qRound(window->height()*window->devicePixelRatio())));
                    const auto filename=scenario+"-"+style+".png"; QVERIFY(image.save(destination+"/"+filename));
                    QFile png(destination+"/"+filename); QVERIFY(png.open(QIODevice::ReadOnly));
                    shots.append(QJsonObject{{"file",filename},{"sha256",QString(QCryptographicHash::hash(png.readAll(),QCryptographicHash::Sha256).toHex())},
                        {"theme",backend.dark()?"dark":"light"},{"style",style},{"section","geometry"},{"group","ui_arch"},{"resourceSelectionStyle","classic"},
                        {"scenario",scenario},{"textScale",tokens->property("textScale").toDouble()},{"logicalWidth",window->width()},{"logicalHeight",window->height()},
                        {"pixelWidth",image.width()},{"pixelHeight",image.height()},{"dpr",window->devicePixelRatio()},
                        {"controlFocus",control->hasActiveFocus()},{"visualFocus",control->property("visualFocus").toBool()},{"popupOpen",popup->property("opened").toBool()},
                        {"qtVersion",qVersion()},{"seed",backend.value("","seed")},{"focusReason",control->property("focusReason").toInt()},
                        {"selectedText",control->property("currentText").toString()},{"selectedIndex",control->property("currentIndex").toInt()},{"inspectedId",evaluate("inspected.id").toString()},{"rows",geometry}});
                }
                if(scenario=="popup") { QTest::keyClick(window,Qt::Key_Escape); QTRY_VERIFY(!popup->property("visible").toBool()); }
            }
        }
        backend.exportConfig(QUrl::fromLocalFile(state.path()+"/after.txt"));
        QFile after(state.path()+"/after.txt"); QVERIFY(after.open(QIODevice::ReadOnly)); QCOMPARE(after.readAll(),config);
        // A new actual QML window always starts at A even after this session chose B.
        QQmlApplicationEngine fresh; fresh.rootContext()->setContextProperty("backend",&backend);
        fresh.load(QUrl("qrc:/ui/prototype/Preview.qml")); QVERIFY(!fresh.rootObjects().isEmpty());
        QCOMPARE(fresh.rootObjects().first()->property("geometryTextureStyle").toString(),QString("zebra"));
        QCOMPARE(fresh.rootObjects().first()->property("resourceSelectionStyle").toString(),QString("classic"));
        if(!destination.isEmpty())write(destination+"/states.json",QJsonDocument(shots).toJson());
    }
    void previewArt01Capture() {
        QTemporaryDir state; QVERIFY(state.isValid());
        write(state.path()+"/CONFIG.txt", "engine = idtech_1\ngame = doom2\nport = boom\nlength = single\nseed = 12345\n@compress_output = 0\n");
        Backend backend(engine,data,state.path());
        backend.setDark(qEnvironmentVariable("OBSIDIAN_CAPTURE_MODE")=="dark");
        QTRY_VERIFY_WITH_TIMEOUT(!backend.loading() && !backend.schema().isEmpty(),30000);
        if(QQuickStyle::name().isEmpty())QQuickStyle::setStyle("Fusion");
        if(qmlTypeId("Obsidian",1,0,"WadView")<0)qmlRegisterType<WadPreview>("Obsidian",1,0,"WadView");
        QQmlApplicationEngine qml; qml.rootContext()->setContextProperty("backend",&backend);
        qml.load(QUrl("qrc:/ui/prototype/Preview.qml"));
        QVERIFY(!qml.rootObjects().isEmpty());
        auto *window=qobject_cast<QQuickWindow*>(qml.rootObjects().first()); QVERIFY(window);
        window->show(); QVERIFY(QTest::qWaitForWindowExposed(window));
        window->requestActivate(); QTRY_VERIFY(window->isActive());
        auto evaluate=[&](const QString &expression) {
            QQmlExpression script(qml.rootContext(),window,expression);
            const auto value=script.evaluate();
            if(script.hasError())qFatal("%s",qPrintable(script.error().toString()));
            return value;
        };
        auto *tokens=window->findChild<QObject*>("designTokens"); QVERIFY(tokens);
        QTRY_VERIFY(tokens->property("fontsReady").toBool());
        tokens->setProperty("reduceMotion",true);
        QCOMPARE(window->property("resourceSelectionStyle").toString(),QString("classic"));
        auto *menu=window->findChild<QObject*>("commandsMenu"); QVERIFY(menu);
        auto *classic=window->findChild<QQuickItem*>("resourceStyleClassic"); QVERIFY(classic);
        auto *art01=window->findChild<QQuickItem*>("resourceStyleArt01"); QVERIFY(art01);
        auto *commandsButton=visualItem(window->contentItem(),"commandsButton"); QVERIFY(commandsButton);
        for(auto *choice:{classic,classic,art01,art01,classic}) {
            QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,
                              commandsButton->mapToScene(QPointF(commandsButton->width()/2,commandsButton->height()/2)).toPoint());
            QTRY_VERIFY(menu->property("opened").toBool());
            QTRY_VERIFY(choice->width()>0 && choice->height()>0);
            QTest::qWait(100);
            QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,
                              choice->mapToScene(QPointF(choice->width()/2,choice->height()/2)).toPoint());
            QTRY_VERIFY(!menu->property("visible").toBool());
            QCOMPARE(classic->property("checked").toBool(),choice==classic);
            QCOMPARE(art01->property("checked").toBool(),choice==art01);
            QCOMPARE(window->property("resourceSelectionStyle").toString(),choice==classic ? QString("classic") : QString("art01"));
        }
        const auto variant=qEnvironmentVariable("OBSIDIAN_ART01_VARIANT","classic");
        QVERIFY(variant=="classic" || variant=="art01");
        window->setProperty("resourceSelectionStyle",variant);
        window->setWidth(1440); window->setHeight(900);
        auto *gallery=visualItem(window->contentItem(),"resourceGallery"); QVERIFY(gallery);
        const auto ammoValue=backend.value("ui_pickups","ammo");
        const auto healthValue=backend.value("ui_pickups","health");
        auto *ammo=visualItem(gallery,"resourceCard_ammo"); QVERIFY(ammo);
        auto *health=visualItem(gallery,"resourceCard_health"); QVERIFY(health);
        auto *title=visualItem(gallery,"resourceTitle_ammo"); QVERIFY(title);
        QTRY_COMPARE(gallery->property("selectionStyle").toString(),variant);
        const auto font=title->property("font").value<QFont>();
        QCOMPARE(font.pixelSize(),tokens->property("bodyFont").value<QFont>().pixelSize());
        QCOMPARE(font.weight(),variant=="art01" ? QFont::DemiBold : QFont::Normal);
        QCOMPARE(title->property("color").value<QColor>(),tokens->property(variant=="art01" ? "text" : "accentText").value<QColor>());
        auto *pill=title->property("background").value<QQuickItem*>(); QVERIFY(pill);
        QCOMPARE(pill->property("color").value<QColor>(),variant=="art01" ? QColor(Qt::transparent) : tokens->property("accent").value<QColor>());
        auto *background=ammo->property("background").value<QQuickItem*>(); QVERIFY(background);
        QCOMPARE(background->property("color").value<QColor>(),tokens->property("thumbnailSelected").value<QColor>());
        const auto destination=qEnvironmentVariable("OBSIDIAN_CAPTURE_DIR");
        QJsonArray shots;
        auto capture=[&](const QString &name,const QString &selected,bool focus,const QString &hovered) {
            qInfo() << "Capture state:" << name;
            QTest::qWait(180); // settle layout and the existing hover scale animation
            QCOMPARE(window->property("section").toString(),QString("resources"));
            QCOMPARE(window->property("currentResourceId").toString(),selected);
            auto *card=visualItem(gallery,"resourceCard_"+selected); QVERIFY(card);
            QCOMPARE(card->property("chosen").toBool(),true);
            QCOMPARE(card->hasActiveFocus(),focus);
            QCOMPARE(card->property("visualFocus").toBool(),focus);
            auto *bg=card->property("background").value<QQuickItem*>(); QVERIFY(bg);
            QQmlExpression border(qml.rootContext(),bg,"border.width");
            QCOMPARE(border.evaluate().toInt(),focus ? 2 : 0);
            QJsonArray hoveredIds;
            for(const QString id:{"ammo","health","items","weapons","secrets","secrets_bonus"}) {
                auto *item=visualItem(gallery,"resourceCard_"+id);
                if(item && item->property("hovered").toBool())hoveredIds.append(id);
            }
            QCOMPARE(hoveredIds,hovered.isEmpty() ? QJsonArray() : QJsonArray{hovered});
            window->update(); QCoreApplication::processEvents();
            const auto image=window->grabWindow(); QVERIFY(!image.isNull());
            QCOMPARE(image.size(),QSize(qRound(window->width()*window->devicePixelRatio()),
                                       qRound(window->height()*window->devicePixelRatio())));
            if(destination.isEmpty())return;
            const auto filename=name+".png"; QVERIFY(image.save(destination+"/"+filename));
            QFile png(destination+"/"+filename); QVERIFY(png.open(QIODevice::ReadOnly));
            shots.append(QJsonObject{{"file",filename},{"sha256",QString(QCryptographicHash::hash(png.readAll(),QCryptographicHash::Sha256).toHex())},
                {"variant",variant},{"theme",backend.dark() ? "dark" : "light"},{"viewMode",window->property("resourceViewMode").toString()},
                {"selectedId",selected},{"activeFocus",card->hasActiveFocus()},{"visualFocus",card->property("visualFocus").toBool()},
                {"focusReason",card->property("focusReason").toInt()},{"focusBorderWidth",border.evaluate().toInt()},{"hoveredIds",hoveredIds},
                {"logicalWidth",window->width()},{"logicalHeight",window->height()},{"pixelWidth",image.width()},{"pixelHeight",image.height()},
                {"dpr",window->devicePixelRatio()},{"textScale",tokens->property("textScale").toReal()}});
        };
        QTest::qWait(250); // initial queued resource focus request must finish first
        auto unfocus=[&]() { commandsButton->forceActiveFocus(Qt::OtherFocusReason); QTest::mouseMove(window,QPoint(2,2)); };
        unfocus(); capture("ammo-grid","ammo",false,{});
        window->setProperty("resourceViewMode","list"); unfocus(); capture("ammo-list","ammo",false,{});
        if(qEnvironmentVariable("OBSIDIAN_ART01_CORE_ONLY")=="1") {
            if(!destination.isEmpty())write(destination+"/states.json",QJsonDocument(shots).toJson());
            return;
        }
        window->setProperty("resourceViewMode","grid");
        ammo->forceActiveFocus(Qt::TabFocusReason); QTest::keyClick(window,Qt::Key_Right);
        QTRY_VERIFY(health->hasActiveFocus()); QTest::keyClick(window,Qt::Key_Left);
        QTRY_VERIFY(ammo->hasActiveFocus()); capture("ammo-keyboard","ammo",true,{});
        if(variant=="classic") {
            if(!destination.isEmpty())write(destination+"/states.json",QJsonDocument(shots).toJson());
            return;
        }
        unfocus(); QTest::mouseMove(window,health->mapToScene(QPointF(health->width()/2,health->height()/2)).toPoint());
        capture("ammo-hover-health","ammo",false,"health");
        unfocus(); evaluate("selectResource('health',false)"); capture("health-grid","health",false,{});
        evaluate("selectResource('items',false)"); capture("items-grid","items",false,{});
        tokens->setProperty("textScale",1.25); capture("items-large-text","items",false,{});
        window->setWidth(1050); window->setHeight(640); window->setProperty("resourceViewMode","list");
        capture("items-narrow-list","items",false,{});
        QCOMPARE(backend.value("ui_pickups","ammo"),ammoValue);
        QCOMPARE(backend.value("ui_pickups","health"),healthValue);
        if(!destination.isEmpty())write(destination+"/states.json",QJsonDocument(shots).toJson());
    }
    void previewGameDialogCapture() {
        // A test-only capture entry point: no application debug API is needed.
        QTemporaryDir state; QVERIFY(state.isValid());
        write(state.path()+"/CONFIG.txt", "engine = idtech_1\ngame = doom2\nport = boom\nlength = single\nseed = 12345\n@compress_output = 0\n");
        Backend backend(engine,data,state.path());
        backend.setDark(qEnvironmentVariable("OBSIDIAN_CAPTURE_MODE")=="dark");
        QTRY_VERIFY_WITH_TIMEOUT(!backend.loading() && !backend.schema().isEmpty(),30000);
        if(QQuickStyle::name().isEmpty())QQuickStyle::setStyle("Fusion");
        if(qmlTypeId("Obsidian",1,0,"WadView")<0)qmlRegisterType<WadPreview>("Obsidian",1,0,"WadView");
        QQmlApplicationEngine qml; qml.rootContext()->setContextProperty("backend",&backend);
        qml.load(QUrl("qrc:/ui/prototype/Preview.qml"));
        QVERIFY(!qml.rootObjects().isEmpty());
        auto *window=qobject_cast<QQuickWindow*>(qml.rootObjects().first()); QVERIFY(window);
        window->show(); QVERIFY(QTest::qWaitForWindowExposed(window));
        window->requestActivate(); QTRY_VERIFY(window->isActive());
        QQmlExpression go(qml.rootContext(),window,"go('project')"); go.evaluate(); QVERIFY(!go.hasError());
        QTRY_COMPARE(window->property("section").toString(),QString("project"));
        QTRY_VERIFY(!window->property("motionActive").toBool());
        auto *tokens=window->findChild<QObject*>("designTokens"); QVERIFY(tokens);
        QTRY_VERIFY(tokens->property("fontsReady").toBool());
        QCOMPARE(tokens->property("textScale").toReal(),1.0);
        auto *combo=visualItem(window->contentItem(),"gameChoice_engine"); QVERIFY(combo);
        auto *popup=combo->property("popup").value<QObject*>(); QVERIFY(popup);
        auto *dialog=window->findChild<QObject*>("gameDialog"); QVERIFY(dialog);
        combo->forceActiveFocus(); QTest::keyClick(window,Qt::Key_Space);
        QTRY_VERIFY(popup->property("opened").toBool());
        QTest::keyClick(window,Qt::Key_Escape);
        // Escape starts an exit transition. A shortcut sent while the popup
        // is still visible is consumed; wait for actual closure, not a delay.
        QTRY_VERIFY(!popup->property("visible").toBool());
        QTest::keyClick(window,Qt::Key_G,Qt::ControlModifier);
        QTRY_VERIFY(dialog->property("opened").toBool());
        QCOMPARE(dialog->property("opacity").toReal(),1.0);
        const auto destination=qEnvironmentVariable("OBSIDIAN_CAPTURE_DIR");
        if(!destination.isEmpty()) {
            // Wait for a rendered frame after opened, then recheck actual state.
            QSignalSpy frame(window,&QQuickWindow::frameSwapped); window->update();
            QVERIFY(frame.wait(5000));
            QVERIFY(dialog->property("visible").toBool());
            QVERIFY(dialog->property("opened").toBool());
            const auto image=window->grabWindow(); QVERIFY(!image.isNull());
            QCOMPARE(image.size(),QSize(qRound(window->width()*window->devicePixelRatio()),
                                       qRound(window->height()*window->devicePixelRatio())));
            QVERIFY(image.save(destination+"/game-dialog.png"));
            QJsonObject evidence{
                {"captureSource","QtTest QQuickWindow::grabWindow (separate test process)"},
                {"qml","qrc:/ui/prototype/Preview.qml"},
                {"logicalWidth",window->width()},{"logicalHeight",window->height()},
                {"pixelWidth",image.width()},{"pixelHeight",image.height()},
                {"devicePixelRatio",window->devicePixelRatio()},
                {"dark",backend.dark()},{"textScale",tokens->property("textScale").toReal()},
                {"section",window->property("section").toString()},
                {"popupVisible",popup->property("visible").toBool()},
                {"dialogVisible",dialog->property("visible").toBool()},
                {"dialogOpened",dialog->property("opened").toBool()},
                {"dialogOpacity",dialog->property("opacity").toReal()},
                {"engine",backend.value("","engine")},{"game",backend.value("","game")},
                {"port",backend.value("","port")},{"length",backend.value("","length")},
                {"seed",backend.value("","seed")}};
            write(destination+"/game-dialog-state.json",QJsonDocument(evidence).toJson());
        }
        QTest::keyClick(window,Qt::Key_Escape);
        QTRY_VERIFY(!dialog->property("visible").toBool());
    }
    void previewResourcesAndMotion() {
        QTemporaryDir state; Backend backend(engine,data,state.path());
        QTRY_VERIFY_WITH_TIMEOUT(!backend.loading() && !backend.schema().isEmpty(),30000);
        if(QQuickStyle::name().isEmpty())QQuickStyle::setStyle("Fusion");
        if(qmlTypeId("Obsidian",1,0,"WadView")<0)qmlRegisterType<WadPreview>("Obsidian",1,0,"WadView");
        QQmlApplicationEngine qml; qml.rootContext()->setContextProperty("backend",&backend);
        qml.load(QUrl("qrc:/ui/prototype/Preview.qml"));
        QVERIFY(!qml.rootObjects().isEmpty());
        auto *window=qobject_cast<QQuickWindow*>(qml.rootObjects().first());QVERIFY(window);
        window->show();QVERIFY(QTest::qWaitForWindowExposed(window));
        window->requestActivate();QTRY_VERIFY(window->isActive());
        window->setWidth(1440);window->setHeight(900);QTest::qWait(150);
        QTRY_VERIFY(!window->property("motionActive").toBool());
        // Bundled optical faces must be used instead of a platform fallback, including Cyrillic.
        auto *tokens=window->findChild<QObject*>("designTokens");QVERIFY(tokens);
        QTRY_VERIFY_WITH_TIMEOUT(tokens->property("fontsReady").toBool(),10000);
        const auto bodyFont=tokens->property("bodyFont").value<QFont>();
        const auto titleFont=tokens->property("titleFont").value<QFont>();
        const auto brandFont=tokens->property("brandFont").value<QFont>();
        const auto sectionFont=tokens->property("sectionFont").value<QFont>();
        const auto captionFont=tokens->property("captionFont").value<QFont>();
        QCOMPARE(QFontInfo(bodyFont).family(),QString("Inter"));
        QCOMPARE(QFontInfo(titleFont).family(),QString("Inter Display"));
        QVERIFY(titleFont.pixelSize()>brandFont.pixelSize());
        QVERIFY(brandFont.pixelSize()>bodyFont.pixelSize());
        QCOMPARE(sectionFont.pixelSize(),bodyFont.pixelSize());
        QVERIFY(sectionFont.weight()>bodyFont.weight());
        QVERIFY(captionFont.pixelSize()<bodyFont.pixelSize());
        const auto rawBody=QRawFont::fromFont(bodyFont);
        for(const auto letter:QString::fromUtf8("Размер уровня Ёё 0123456789"))
            QVERIFY2(rawBody.supportsCharacter(letter),qPrintable(QString(letter)));
        tokens->setProperty("textScale",1.25);
        QTRY_VERIFY(tokens->property("bodyFont").value<QFont>().pixelSize()>bodyFont.pixelSize());
        QTRY_VERIFY(tokens->property("captionFont").value<QFont>().pixelSize()>captionFont.pixelSize());
        tokens->setProperty("textScale",1.0);

        auto evaluate=[&](const QString &expression) {
            QQmlExpression script(qml.rootContext(),window,expression);
            const auto result=script.evaluate();
            if(script.hasError())qWarning()<<script.error();
            return result;
        };
        evaluate("go('project')");
        QTRY_COMPARE(window->property("section").toString(),QString("project"));
        QTRY_VERIFY(!window->property("motionActive").toBool());
        auto *length=visualItem(window->contentItem(),"gameChoice_length");QVERIFY(length);
        const auto beforeLength=backend.value("","length");
        const auto choices=backend.schema().value("choices").toMap().value("length").toList();
        const int beforeIndex=length->property("currentIndex").toInt();
        QVERIFY(choices.size()>1);QVERIFY(beforeIndex>=0);
        const bool increase=beforeIndex+1<choices.size();
        const int afterIndex=beforeIndex+(increase?1:-1);
        auto *popup=length->property("popup").value<QObject*>();QVERIFY(popup);
        length->forceActiveFocus();QTRY_VERIFY(length->hasActiveFocus());
        QTest::keyClick(window,Qt::Key_Space);
        QTRY_VERIFY(popup->property("visible").toBool());
        QTest::keyClick(window,increase?Qt::Key_Down:Qt::Key_Up);
        QTest::keyClick(window,Qt::Key_Escape);
        QTRY_VERIFY(!popup->property("visible").toBool());
        QCOMPARE(backend.value("","length"),beforeLength); // Dismissal never applies the highlighted choice.
        length->forceActiveFocus();
        QTest::keyClick(window,Qt::Key_Space);
        QTRY_VERIFY(popup->property("visible").toBool());
        QTest::keyClick(window,increase?Qt::Key_Down:Qt::Key_Up);
        QTest::keyClick(window,Qt::Key_Return);
        QTRY_VERIFY(!popup->property("visible").toBool());
        QTRY_COMPARE(backend.value("","length"),choices[afterIndex].toMap().value("id").toString());
        backend.setGeneral("length",beforeLength);
        QTRY_COMPARE(backend.value("","length"),beforeLength);
        auto dialogButton=[&](QObject *dialog,const QString &name) {
            auto *footer=dialog->property("footer").value<QObject*>();
            if(!footer)return static_cast<QQuickItem*>(nullptr);
            QQmlExpression script(QQmlEngine::contextForObject(footer),footer,"standardButton(Dialog."+name+")");
            const auto result=script.evaluate();
            if(script.hasError())qWarning()<<script.error();
            return qobject_cast<QQuickItem*>(result.value<QObject*>());
        };
        auto *gameDialog=window->findChild<QObject*>("gameDialog");QVERIFY(gameDialog);
        auto *menu=window->findChild<QObject*>("commandsMenu");QVERIFY(menu);
        auto *menuButton=visualItem(window->contentItem(),"commandsButton");QVERIFY(menuButton);
        QSignalSpy menuFade(menu,SIGNAL(opacityChanged()));QVERIFY(menuFade.isValid());
        QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,menuButton->mapToScene(menuButton->boundingRect().center()).toPoint());
        QTRY_VERIFY(menu->property("opened").toBool());
        QVERIFY(menu->property("width").toReal()>=300);
        QVERIFY(menuFade.count()>=2); // Actual intermediate opacity changes, not just configured durations.
        QQmlExpression menuScript(QQmlEngine::contextForObject(menu),menu,"itemAt(1)");
        auto *menuCommand=qobject_cast<QQuickItem*>(menuScript.evaluate().value<QObject*>());QVERIFY(menuCommand);
        QSignalSpy dialogFade(gameDialog,SIGNAL(opacityChanged()));QVERIFY(dialogFade.isValid());
        QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,menuCommand->mapToScene(menuCommand->boundingRect().center()).toPoint());
        QTRY_VERIFY(gameDialog->property("opened").toBool());
        QVERIFY(dialogFade.count()>=2);
        QTRY_VERIFY(!menu->property("visible").toBool());
        auto *ok=dialogButton(gameDialog,"Ok");QVERIFY(ok);
        QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,ok->mapToScene(ok->boundingRect().center()).toPoint());
        QTRY_VERIFY(!gameDialog->property("visible").toBool());
        evaluate("inspect(backend.schema.modules.filter(function(m){return m.id==='ui_mons'})[0].options.filter(function(o){return o.id==='float_mons'})[0], 'ui_mons', false)");
        auto *comparison=visualItem(window->contentItem(),"gameplayComparison");QVERIFY(comparison);
        QTRY_COMPARE(comparison->property("example").toString(),QString("monsters"));
        QVERIFY(QMetaObject::invokeMethod(comparison,"enlarge"));
        auto *comparisonDialog=comparison->findChild<QObject*>("comparisonDialog");QVERIFY(comparisonDialog);
        QTRY_VERIFY(comparisonDialog->property("visible").toBool());
        auto *close=dialogButton(comparisonDialog,"Close");QVERIFY(close);
        QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,close->mapToScene(close->boundingRect().center()).toPoint());
        QTRY_VERIFY(!comparisonDialog->property("visible").toBool());
        // A closed comparison still resizes: 900px crosses its two-column
        // breakpoint. Qt 6.4 previously crashed here after the dialog closed.
        evaluate("go('resources')");
        QTRY_COMPARE(window->property("section").toString(),QString("resources"));
        QTRY_VERIFY(!window->property("motionActive").toBool());
        for(int pass=0;pass<2;++pass) {
            window->setWidth(900);window->setHeight(540);
            QTest::qWait(100);
            QTRY_VERIFY(!window->property("motionActive").toBool());
            QVERIFY(window->isVisible());
            auto *card=visualItem(window->contentItem(),"resourceCard_ammo");QVERIFY(card);
            card->forceActiveFocus();QTRY_VERIFY(card->hasActiveFocus());
            QTest::keyClick(window,Qt::Key_Right);
            QTRY_COMPARE(window->property("currentResourceId").toString(),QString("health"));
            QTest::keyClick(window,Qt::Key_Left);
            QTRY_COMPARE(window->property("currentResourceId").toString(),QString("ammo"));
            window->setWidth(1440);window->setHeight(900);
            QTest::qWait(100);
            QTRY_VERIFY(!window->property("motionActive").toBool());
        }
        evaluate("go('geometry')");
        QTRY_COMPARE(window->property("section").toString(),QString("geometry"));
        QTRY_VERIFY(!window->property("motionActive").toBool());
        auto *pageTitle=visualItem(window->contentItem(),"pageTitle");QVERIFY(pageTitle);
        QCOMPARE(pageTitle->property("font").value<QFont>().family(),titleFont.family());
        auto *ordinaryRow=visualItem(window->contentItem(),"optionRow_ui_arch_outdoors");QVERIFY(ordinaryRow);
        auto *sliderRow=visualItem(window->contentItem(),"optionRow_ui_arch_float_size");QVERIFY(sliderRow);
        QTRY_VERIFY(ordinaryRow->height()>=44 && ordinaryRow->height()<=50);
        QVERIFY(sliderRow->height()>ordinaryRow->height());
        // Results used to resize the inspector while search rebuilt its delegates.
        for(int cycle=0;cycle<3;++cycle) {
            evaluate("go('results')");
            QTRY_COMPARE(window->property("section").toString(),QString("results"));
            QTRY_VERIFY(!window->property("motionActive").toBool());
            QTest::keyClick(window,Qt::Key_2,Qt::AltModifier);
            QTest::keyClick(window,Qt::Key_F,Qt::ControlModifier);
            QTest::qWait(1); // Deliver the queued search focus request.
            for(const auto c:QByteArray("float_mons"))QTest::keyClick(window,c,Qt::NoModifier,5);
            QTRY_COMPARE(window->property("query").toString(),QString("float_mons"));
            QTRY_VERIFY(!window->property("motionActive").toBool());
            evaluate("go('resources')");
            QTRY_COMPARE(window->property("section").toString(),QString("resources"));
            QTRY_VERIFY(!window->property("motionActive").toBool());
        }
        const auto ammoBefore=backend.value("ui_pickups","ammo");
        const auto healthBefore=backend.value("ui_pickups","health");
        QTest::keyClick(window,Qt::Key_3,Qt::AltModifier);
        QTRY_COMPARE(window->property("section").toString(),QString("resources"));
        QTRY_COMPARE(window->property("currentResourceId").toString(),QString("ammo"));
        QTRY_VERIFY(!window->property("motionActive").toBool());
        auto *gallery=visualItem(window->contentItem(),"resourceGallery");QVERIFY(gallery);
        auto *ammo=visualItem(gallery,"resourceCard_ammo");QVERIFY(ammo);
        QTRY_VERIFY(ammo->hasActiveFocus());
        QTest::keyClick(window,Qt::Key_Right);
        QTRY_COMPARE(window->property("currentResourceId").toString(),QString("health"));
        auto *health=visualItem(gallery,"resourceCard_health");QVERIFY(health);QTRY_VERIFY(health->hasActiveFocus());
        QVERIFY2(health->property("visualFocus").toBool(),"Arrow navigation must show visualFocus, not only activeFocus");
        QTest::keyClick(window,Qt::Key_Left);
        QTRY_COMPARE(window->property("currentResourceId").toString(),QString("ammo"));
        QCOMPARE(backend.value("ui_pickups","ammo"),ammoBefore);
        QCOMPARE(backend.value("ui_pickups","health"),healthBefore);
        QTest::keyClick(window,Qt::Key_2,Qt::ControlModifier);
        QTRY_COMPARE(window->property("resourceViewMode").toString(),QString("list"));
        QTRY_VERIFY(!window->property("motionActive").toBool());
        QTest::keyClick(window,Qt::Key_1,Qt::ControlModifier);
        QTRY_COMPARE(window->property("resourceViewMode").toString(),QString("grid"));
        QTRY_VERIFY(!window->property("motionActive").toBool());
        // Rapid navigation must settle at the final destination, including after interruption.
        QTest::keyClick(window,Qt::Key_1,Qt::AltModifier);
        QTest::keyClick(window,Qt::Key_2,Qt::AltModifier);
        QTest::keyClick(window,Qt::Key_3,Qt::AltModifier);
        QTRY_COMPARE(window->property("section").toString(),QString("resources"));
        QTRY_VERIFY(!window->property("motionActive").toBool());
        QTRY_VERIFY(visualItem(window->contentItem(),"resourceCard_ammo")->hasActiveFocus());
        // Observe actual animation lifecycle, not a duration-dependent intermediate frame.
        QSignalSpy motion(window,SIGNAL(motionActiveChanged()));QVERIFY(motion.isValid());
        QTest::keyClick(window,Qt::Key_1,Qt::AltModifier);
        QTRY_COMPARE(window->property("section").toString(),QString("geometry"));
        QTRY_VERIFY(!window->property("motionActive").toBool());
        QVERIFY(motion.count()>=2);
        QTest::keyClick(window,Qt::Key_M,Qt::ControlModifier|Qt::ShiftModifier);
        QTRY_VERIFY(window->property("reduceMotion").toBool());
        motion.clear();
        QTest::keyClick(window,Qt::Key_3,Qt::AltModifier);
        QTRY_COMPARE(window->property("section").toString(),QString("resources"));
        QVERIFY(!window->property("motionActive").toBool());QCOMPARE(motion.count(),0);
        QTest::keyClick(window,Qt::Key_M,Qt::ControlModifier|Qt::ShiftModifier);
        QTRY_VERIFY(!window->property("reduceMotion").toBool());
        window->setWidth(1050);window->setHeight(640);QTest::qWait(200);
        QTest::keyClick(window,Qt::Key_3,Qt::AltModifier);
        QTRY_VERIFY(!window->property("motionActive").toBool());
        auto *selected=visualItem(window->contentItem(),"resourceCard_ammo");QVERIFY(selected);selected->forceActiveFocus();
        QTest::keyClick(window,Qt::Key_2,Qt::ControlModifier);
        window->setHeight(540);QTest::qWait(150);
        selected=visualItem(window->contentItem(),"resourceCard_ammo");QVERIFY(selected);selected->forceActiveFocus();
        for(int i=0;i<5;++i)QTest::keyClick(window,Qt::Key_Down);
        QTRY_COMPARE(window->property("currentResourceId").toString(),QString("secrets_bonus"));
        auto *last=visualItem(window->contentItem(),"resourceCard_secrets_bonus");QVERIFY(last);
        QTRY_VERIFY(last->hasActiveFocus());
        QTRY_VERIFY(last->mapToScene(last->boundingRect().center()).y()>66);
        QTRY_VERIFY(last->mapToScene(last->boundingRect().center()).y()<window->height()-34);
        QTest::keyClick(window,Qt::Key_Return);
        auto *dialog=window->findChild<QObject*>("inspectorDialog");QVERIFY(dialog);
        QTRY_VERIFY(dialog->property("visible").toBool());
        QTest::keyClick(window,Qt::Key_Escape);QTRY_VERIFY(!dialog->property("visible").toBool());
        // Native WAD sprites keep their dimensions/transparency; no network or IWAD at runtime.
        QFile manifest(":/freedoom/manifest.json");QVERIFY(manifest.open(QIODevice::ReadOnly));
        const auto assets=QJsonDocument::fromJson(manifest.readAll()).object().value("assets").toArray();
        QVERIFY(assets.size()>=20);
        for(const auto &entry:assets) {
            const auto asset=entry.toObject();const auto dimensions=asset.value("dimensions").toArray();
            QImage image(":/freedoom/"+asset.value("file").toString());
            QVERIFY2(!image.isNull(),qPrintable(asset.value("file").toString()));
            QCOMPARE(image.size(),QSize(dimensions[0].toInt(),dimensions[1].toInt()));
            QVERIFY(image.hasAlphaChannel());
        }
    }
    void configurationRoundTrip() {
        const QByteArray input = "-- legacy\nengine = idtech_1\ngame = doom2\nseed = 18446744073709551615\nfloat_size = 42\nfuture_key = custom value\n@custom = 1\n  detail = rare\n  future_option = retained\n";
        Configuration config, result; QString error;
        QVERIFY2(config.parse(input,&error),qPrintable(error));
        QVERIFY(result.parse(config.serialize(),&error));
        QCOMPARE(result.general,config.general); QCOMPARE(result.modules,config.modules); QCOMPARE(result.enabled,config.enabled);
        QCOMPARE(result.value("ui_arch","float_size"),QString("42"));
        QCOMPARE(result.value("custom","future_option"),QString("retained"));
    }
    void invalidConfigIsTransactional() {
        Configuration c; c.general["game"] = "doom2"; QString error;
        QVERIFY(!c.parse("not an assignment",&error));
        QCOMPARE(c.general.value("game"),QString("doom2")); QVERIFY(!error.isEmpty());
        QVERIFY(!Configuration::safeValue("42\n@bad = 1"));
        QVERIFY(!c.parse("  orphan = 4",&error));
    }
    void binaryWad() {
        QTemporaryDir dir; QByteArray vertices,line;
        integer(vertices,0,2);integer(vertices,0,2);integer(vertices,100,2);integer(vertices,0,2);
        integer(line,0,2);integer(line,1,2);line.append(QByteArray(10,'\0'));
        auto bytes=wad({{"MAP01",{}},{"VERTEXES",vertices},{"LINEDEFS",line}});
        const auto path=dir.path()+"/map.wad";write(path,bytes);
        auto map=MapGeometry::read(path); QCOMPARE(map.lines.size(),1);QCOMPARE(map.lines[0].length(),100.0);
        write(path,wad({{"MAP01",{}},{"VERTEXES",vertices},{"LINEDEFS",line+QByteArray(2,'\0')},{"BEHAVIOR",{}}}));
        QCOMPARE(MapGeometry::read(path).lines.size(),1); // Hexen binary stride.
        // A line referring outside VERTEXES must not be drawn or crash.
        line[2]=char(5);write(path,wad({{"MAP01",{}},{"VERTEXES",vertices},{"LINEDEFS",line}}));
        QVERIFY(MapGeometry::read(path).lines.isEmpty());
        bytes[8]=char(255);bytes[9]=char(255);bytes[10]=char(255);bytes[11]=char(255);write(path,bytes);
        QVERIFY(MapGeometry::read(path).lines.isEmpty());
    }
    void mapViewport() {
        QTemporaryDir dir;
        const auto first=dir.path()+"/first.wad",second=dir.path()+"/second.wad";
        const QByteArray geometry="vertex{x=0;y=0;} vertex{x=100;y=0;} vertex{x=100;y=100;} vertex{x=10000;y=10000;} vertex{x=10100;y=10000;} linedef{v1=0;v2=1;} linedef{v1=1;v2=2;twosided=true;} linedef{v1=3;v2=4;}";
        write(first,wad({{"MAP01",{}},{"TEXTMAP",geometry},{"ENDMAP",{}}}));
        auto map=MapGeometry::read(first);
        QCOMPARE(map.lines.size(),3);QCOMPARE(map.twoSided.size(),3);QVERIFY(map.twoSided[1]);
        QVERIFY(map.mainBounds.width()<101);QVERIFY(map.bounds.width()>10000);
        WadPreview view;view.setWidth(500);view.setHeight(350);view.setFile(first);
        QCOMPARE(view.mapName(),QString("MAP01"));QCOMPARE(view.lineCount(),3);
        view.setShowAll(false);view.setZoom(4);QCOMPARE(view.zoom(),4.0);
        view.resetView();QCOMPARE(view.zoom(),1.0);
        view.setZoom(100);QCOMPARE(view.zoom(),12.0);
        write(second,wad({{"MAP02",{}},{"TEXTMAP",geometry},{"ENDMAP",{}}}));
        view.setFile(second);QCOMPARE(view.mapName(),QString("MAP02"));QCOMPARE(view.zoom(),1.0);
    }
    void udmfWad() {
        QTemporaryDir dir; const auto path=dir.path()+"/udmf.wad";
        write(path,wad({{"MAP01",{}},{"TEXTMAP","namespace=\"ZDoom\";\nvertex { x=-10.5; y=2; } vertex { x=12; y=40; } linedef { v1=0; v2=1; }"},{"ENDMAP",{}}}));
        auto map=MapGeometry::read(path);QCOMPARE(map.lines.size(),1);QCOMPARE(map.lines[0].x1(),-10.5);
    }
    void schemaAndGeneration() {
        QVERIFY2(QFile::exists(engine),qPrintable(engine));QTemporaryDir state,output;
        Backend backend(engine,data,state.path());
        QTRY_VERIFY_WITH_TIMEOUT(!backend.loading() && !backend.schema().isEmpty(),30000);
        QCOMPARE(backend.value("","game"),QString("doom2"));
        const auto modules = backend.schema().value("modules").toList();QVERIFY(modules.size()>10);
        bool architecture=false;
        for (const auto &entry : modules) {
            const auto m=entry.toMap();
            if (m.value("id")=="ui_arch") { architecture=true;QVERIFY(m.value("available").toBool()); }
        }
        QVERIFY(architecture);
        backend.setOption("ui_arch","float_size","30");QCOMPARE(backend.value("ui_arch","float_size"),QString("30"));
        backend.setOption("ui_arch","float_size","99999");QCOMPARE(backend.value("ui_arch","float_size"),QString("30"));
        backend.chooseOutput(QUrl::fromLocalFile(output.path()));backend.setGeneral("seed","12345");
        QSignalSpy finished(&backend,&Backend::generationFinished);backend.generate();
        QTRY_COMPARE_WITH_TIMEOUT(finished.count(),1,90000);
        QVERIFY2(finished[0][0].toBool(),qPrintable(backend.log()));
        QVERIFY(QDir(backend.resultFolder()).exists());QVERIFY(!MapGeometry::read(backend.previewFile()).lines.isEmpty());
        QVERIFY(QFile::exists(backend.resultFolder()+"/CONFIG.txt"));
        QCOMPARE(backend.value("","seed"),QString("12345"));
        QFile log(backend.resultFolder()+"/LOGS.txt"); QVERIFY(log.open(QIODevice::ReadOnly));
        QVERIFY(log.readAll().contains("seed = 12345"));
        const auto firstResult = backend.resultFolder();
        QFile firstConfig(firstResult+"/CONFIG.txt"); QVERIFY(firstConfig.open(QIODevice::ReadOnly));
        const auto firstInput = firstConfig.readAll();
        backend.generate();
        QTRY_COMPARE_WITH_TIMEOUT(finished.count(),2,90000);
        QVERIFY2(finished[1][0].toBool(),qPrintable(backend.log()));
        QVERIFY(firstResult != backend.resultFolder());
        QVERIFY(QDir(firstResult).exists());
        QFile secondConfig(backend.resultFolder()+"/CONFIG.txt"); QVERIFY(secondConfig.open(QIODevice::ReadOnly));
        QCOMPARE(secondConfig.readAll(), firstInput);
        QFile secondLog(backend.resultFolder()+"/LOGS.txt"); QVERIFY(secondLog.open(QIODevice::ReadOnly));
        QVERIFY(secondLog.readAll().contains("seed = 12345"));
        QVERIFY(!MapGeometry::read(backend.previewFile()).lines.isEmpty());
        // Geometry equality is not a frontend contract: the pre-Qt engine
        // already varies with a full config. See docs/qt6/ENGINE_NOTES.md.

    }
    void dependencyRefreshAndPresetImport() {
        QTemporaryDir state;Backend backend(engine,data,state.path());
        QTRY_VERIFY_WITH_TIMEOUT(!backend.loading() && !backend.schema().isEmpty(),30000);
        const auto preset=state.path()+"/import.txt";
        write(preset,"engine = idtech_1\ngame = doom2\nport = limit_enforcing\nlength = single\nseed = 12345\nfuture_unknown = retained\n");
        backend.importConfig(QUrl::fromLocalFile(preset));
        QTRY_VERIFY_WITH_TIMEOUT(!backend.loading(),30000);
        QCOMPARE(backend.value("","port"),QString("limit_enforcing"));
        QCOMPARE(backend.value("","seed"),QString("12345"));
        for (const auto &entry : backend.schema().value("modules").toList()) {
            const auto m=entry.toMap();if(m.value("id")=="ui_arch")QVERIFY(!m.value("available").toBool());
        }
        const auto exported=state.path()+"/export.txt";backend.exportConfig(QUrl::fromLocalFile(exported));
        QFile file(exported);QVERIFY(file.open(QIODevice::ReadOnly));QVERIFY(file.readAll().contains("future_unknown = retained"));
    }
    void cancellationPreservesExistingResults() {
        QTemporaryDir state,output;const auto existing=output.path()+"/existing.wad";write(existing,"KEEP");
        Backend backend(engine,data,state.path());
        QTRY_VERIFY_WITH_TIMEOUT(!backend.loading() && !backend.schema().isEmpty(),30000);
        backend.chooseOutput(QUrl::fromLocalFile(output.path()));backend.setGeneral("length","game");
        QSignalSpy finished(&backend,&Backend::generationFinished);backend.generate();
        QVERIFY(backend.busy());backend.cancel();
        QTRY_COMPARE_WITH_TIMEOUT(finished.count(),1,10000);QVERIFY(!finished[0][0].toBool());
        QFile file(existing);QVERIFY(file.open(QIODevice::ReadOnly));QCOMPARE(file.readAll(),QByteArray("KEEP"));
        QCOMPARE(QDir(output.path()).entryList(QDir::AllEntries|QDir::Hidden|QDir::NoDotAndDotDot),QStringList{"existing.wad"});
    }
    void missingWorkerReportsFailure() {
        QTemporaryDir state;Backend backend(state.path()+"/missing-worker",data,state.path());
        QTRY_VERIFY_WITH_TIMEOUT(!backend.loading() && backend.status().contains("Не удалось"),5000);
        QVERIFY(backend.schema().isEmpty());QVERIFY(!backend.busy());
    }
};
QTEST_MAIN(CoreTests)
#include "test_core.moc"
