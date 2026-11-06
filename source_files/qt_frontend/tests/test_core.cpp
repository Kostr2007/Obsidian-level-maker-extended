// SPDX-License-Identifier: GPL-2.0-or-later
#include "../backend.h"
#include "../presentation.h"
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQmlExpression>
#include <QQuickStyle>
#include <QImage>
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
        QTest::keyClick(window,Qt::Key_G,Qt::ControlModifier);
        auto *gameDialog=window->findChild<QObject*>("gameDialog");QVERIFY(gameDialog);
        QTRY_VERIFY(gameDialog->property("visible").toBool());
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
