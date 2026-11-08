cmake_minimum_required(VERSION 3.21)
project(QtMacOS VERSION 0.1.0 LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
find_package(Qt6 6.4 REQUIRED COMPONENTS Quick QuickControls2)
qt_standard_project_setup()
if(PROJECT_IS_TOP_LEVEL)
    include(CTest)
endif()
option(QTMACOS_BUILD_GALLERY "Build the standalone component gallery" ${PROJECT_IS_TOP_LEVEL})
option(QTMACOS_BUILD_TESTS "Build Qt-MacOS tests" ${PROJECT_IS_TOP_LEVEL})

set(mac_qml
    qml/QtMacOS/Theme.qml
    qml/QtMacOS/MacLabel.qml
    qml/QtMacOS/MacBox.qml
    qml/QtMacOS/MacDisclosureGroup.qml
    qml/QtMacOS/MacLockup.qml
    qml/QtMacOS/MacCollectionView.qml
    qml/QtMacOS/MacListView.qml
    qml/QtMacOS/MacTableView.qml
    qml/QtMacOS/MacColumnBrowser.qml
    qml/QtMacOS/MacOutlineView.qml
    qml/QtMacOS/MacSplitView.qml
    qml/QtMacOS/MacTabView.qml
    qml/QtMacOS/Controls/MacButton.qml
    qml/QtMacOS/Controls/MacTextField.qml
    qml/QtMacOS/Controls/MacCheckBox.qml
    qml/QtMacOS/Controls/MacComboBox.qml
    qml/QtMacOS/Controls/MacScrollBar.qml
    qml/QtMacOS/Controls/MacSlider.qml
    qml/QtMacOS/Controls/MacSwitch.qml
    qml/QtMacOS/Controls/MacPopupButton.qml
    qml/QtMacOS/Controls/MacPushButton.qml
    qml/QtMacOS/Controls/MacHelpButton.qml
    qml/QtMacOS/SettingsGroup.qml
    qml/QtMacOS/SettingsRow.qml
    qml/QtMacOS/SettingsSidebar.qml
    qml/QtMacOS/SettingsIcon.qml
    qml/QtMacOS/MacWindow.qml
    qml/QtMacOS/MacDialog.qml
    qml/QtMacOS/WindowButtons.qml
    qml/QtMacOS/Sidebar.qml
    qml/QtMacOS/SearchField.qml)
set_source_files_properties(qml/QtMacOS/Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)
foreach(file IN LISTS mac_qml)
    get_filename_component(name "${file}" NAME)
    set_source_files_properties("${file}" PROPERTIES QT_RESOURCE_ALIAS "${name}")
endforeach()
qt_add_library(qtmacos STATIC)
set_source_files_properties(assets/fonts/InterVariable.ttf PROPERTIES QT_RESOURCE_ALIAS "fonts/InterVariable.ttf")
qt_add_qml_module(qtmacos
    URI QtMacOS VERSION 1.0
    RESOURCE_PREFIX /qt/qml
    OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/qml/QtMacOS"
    QML_FILES ${mac_qml}
    RESOURCES assets/fonts/InterVariable.ttf)
target_link_libraries(qtmacos PUBLIC Qt6::Quick Qt6::QuickControls2)

if(QTMACOS_BUILD_GALLERY OR (BUILD_TESTING AND QTMACOS_BUILD_TESTS))
    qt_add_qml_module(qtmacos_demo STATIC
        URI QtMacOS.Demo VERSION 1.0 CLASS_NAME QtMacOSDemoPlugin
        RESOURCE_PREFIX /qt/qml
        OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/qml/QtMacOS/Demo"
        SOURCES demo/WorkspaceModel.h demo/WorkspaceModel.cpp)
    target_include_directories(qtmacos_demo PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/demo")
    target_link_libraries(qtmacos_demo PUBLIC Qt6::Qml)
endif()

file(GLOB icon_files CONFIGURE_DEPENDS assets/icons/*.svg)
foreach(file IN LISTS icon_files)
    get_filename_component(name "${file}" NAME)
    set_source_files_properties("${file}" PROPERTIES QT_RESOURCE_ALIAS "assets/icons/${name}")
endforeach()
if(QTMACOS_BUILD_GALLERY)
    qt_add_executable(qtmacos-gallery demo/main.cpp)
    set_target_properties(qtmacos-gallery PROPERTIES QT_QML_MODULE_NO_IMPORT_SCAN TRUE)
    target_link_libraries(qtmacos-gallery PRIVATE qtmacosplugin qtmacos_demoplugin Qt6::Quick Qt6::QuickControls2)
    qt_add_resources(qtmacos-gallery gallery PREFIX /gallery FILES
        demo/Main.qml demo/FileBrowser.qml demo/FinderIcon.qml demo/FinderToolButton.qml
        demo/FinderSidebar.qml demo/FinderThumbnail.qml demo/SettingsMain.qml demo/LayoutMain.qml)
    qt_add_resources(qtmacos-gallery icons PREFIX / FILES ${icon_files})
endif()

if(BUILD_TESTING AND QTMACOS_BUILD_TESTS)
    find_package(Qt6 REQUIRED COMPONENTS QuickTest Test)
    qt_add_executable(qtmacos-tests tests/quicktest.cpp)
    set_target_properties(qtmacos-tests PROPERTIES QT_QML_MODULE_NO_IMPORT_SCAN TRUE)
    target_link_libraries(qtmacos-tests PRIVATE qtmacosplugin qtmacos_demoplugin Qt6::QuickTest Qt6::Qml)
    qt_add_executable(workspace-model-tests tests/test_workspace_model.cpp)
    set_target_properties(workspace-model-tests PROPERTIES QT_QML_MODULE_NO_IMPORT_SCAN TRUE)
    target_link_libraries(workspace-model-tests PRIVATE qtmacos_demo Qt6::Test)
    add_test(NAME workspace-model COMMAND workspace-model-tests)
    qt_add_resources(qtmacos-tests testicons PREFIX / FILES ${icon_files})
    target_compile_definitions(qtmacos-tests PRIVATE QUICK_TEST_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}/tests")
    add_test(NAME qtmacos-controls COMMAND qtmacos-tests)
    set_tests_properties(qtmacos-controls PROPERTIES
        TIMEOUT 60
        ENVIRONMENT "QT_QPA_PLATFORM=offscreen;QT_QUICK_BACKEND=software")
endif()
