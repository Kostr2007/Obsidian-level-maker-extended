find_package(Qt6 6.4 REQUIRED COMPONENTS Quick QuickControls2 Test)
qt_standard_project_setup()
set(OBSIDIAN_QTMACOS_ROOT "" CACHE PATH "Optional pinned Qt-MacOS source directory for Studio")
if(OBSIDIAN_QTMACOS_ROOT)
  if(NOT EXISTS "${OBSIDIAN_QTMACOS_ROOT}/qml/QtMacOS/Theme.qml")
    message(FATAL_ERROR "OBSIDIAN_QTMACOS_ROOT must point to a Qt-MacOS source checkout")
  endif()
  set(QTMACOS_BUILD_GALLERY OFF CACHE BOOL "" FORCE)
  set(QTMACOS_BUILD_TESTS OFF CACHE BOOL "" FORCE)
  add_subdirectory("${OBSIDIAN_QTMACOS_ROOT}" "${CMAKE_CURRENT_BINARY_DIR}/qtmacos" EXCLUDE_FROM_ALL)
endif()
add_library(obsidian-qt-core STATIC
  configuration.cpp configuration.h
  wadpreview.cpp wadpreview.h
  backend.cpp backend.h presentation.cpp presentation.h)
qt_add_resources(obsidian-qt-core "studio" PREFIX "/studio"
  BASE "${CMAKE_CURRENT_SOURCE_DIR}" FILES studio-catalog.json)
qt_add_resources(obsidian-qt-core "gameplay" PREFIX "/gameplay"
  BASE "${CMAKE_SOURCE_DIR}/docs/artwork/gameplay" FILES
  "${CMAKE_SOURCE_DIR}/docs/artwork/gameplay/lighting-low.png"
  "${CMAKE_SOURCE_DIR}/docs/artwork/gameplay/lighting-high.png"
  "${CMAKE_SOURCE_DIR}/docs/artwork/gameplay/steepness-low.png"
  "${CMAKE_SOURCE_DIR}/docs/artwork/gameplay/steepness-high.png"
  "${CMAKE_SOURCE_DIR}/docs/artwork/gameplay/monsters-low.png"
  "${CMAKE_SOURCE_DIR}/docs/artwork/gameplay/monsters-high.png")
qt_add_resources(obsidian-qt-core "freedoom" PREFIX "/freedoom"
  BASE "${CMAKE_CURRENT_SOURCE_DIR}/assets/freedoom" FILES
  assets/freedoom/manifest.json
  assets/freedoom/clip.png
  assets/freedoom/ammo_box.png
  assets/freedoom/shells.png
  assets/freedoom/shell_box.png
  assets/freedoom/rocket.png
  assets/freedoom/rocket_box.png
  assets/freedoom/cell.png
  assets/freedoom/cell_pack.png
  assets/freedoom/stimpack.png
  assets/freedoom/medikit.png
  assets/freedoom/health_bonus.png
  assets/freedoom/green_armor.png
  assets/freedoom/blue_armor.png
  assets/freedoom/armor_bonus.png
  assets/freedoom/shotgun.png
  assets/freedoom/super_shotgun.png
  assets/freedoom/chaingun.png
  assets/freedoom/rocket_launcher.png
  assets/freedoom/plasma_rifle.png
  assets/freedoom/bfg.png
  assets/freedoom/chainsaw.png
  assets/freedoom/soul_bonus.png)
qt_add_resources(obsidian-qt-core "fonts" PREFIX "/fonts"
  BASE "${CMAKE_CURRENT_SOURCE_DIR}/assets/fonts" FILES
  assets/fonts/Inter-Regular.ttf assets/fonts/Inter-Medium.ttf
  assets/fonts/Inter-SemiBold.ttf assets/fonts/InterDisplay-SemiBold.ttf
  assets/fonts/OFL.txt)
target_link_libraries(obsidian-qt-core PUBLIC Qt6::Quick)
target_compile_features(obsidian-qt-core PUBLIC cxx_std_17)
qt_add_executable(obsidian-qt main.cpp)
set_target_properties(obsidian-qt PROPERTIES OUTPUT_NAME obsidian)
target_compile_definitions(obsidian-qt PRIVATE OBSIDIAN_EXTENDED_VERSION="${PROJECT_VERSION}")
target_link_libraries(obsidian-qt PRIVATE obsidian-qt-core Qt6::QuickControls2)
set(STUDIO_QML Main.qml OptionEditor.qml ActionButton.qml Surface.qml GameSetup.qml StudioInspector.qml GameplayComparison.qml AssetPreview.qml ResourceAssets.js
  prototype/Preview.qml prototype/DesignTokens.qml prototype/PreviewButton.qml prototype/PreviewIcon.qml prototype/PreviewOptionRow.qml prototype/ResourceGallery.qml prototype/PreviewComboBox.qml prototype/PreviewTextField.qml prototype/PreviewDialog.qml prototype/PreviewToolTip.qml prototype/PreviewMenu.qml prototype/PreviewMenuItem.qml)
if(OBSIDIAN_QTMACOS_ROOT)
  target_link_libraries(obsidian-qt PRIVATE qtmacosplugin)
  target_compile_definitions(obsidian-qt PRIVATE OBSIDIAN_QTMACOS=1)
  # Keep the existing window API and the independent design preview unchanged.
  set_source_files_properties(Main.qml PROPERTIES QT_RESOURCE_ALIAS "BaseMain.qml")
  list(REMOVE_ITEM STUDIO_QML ActionButton.qml Surface.qml StudioInspector.qml)
  list(APPEND STUDIO_QML mac/Main.qml mac/ActionButton.qml mac/Surface.qml mac/StudioInspector.qml)
  foreach(component Main ActionButton Surface StudioInspector)
    set_source_files_properties("mac/${component}.qml" PROPERTIES QT_RESOURCE_ALIAS "${component}.qml")
  endforeach()
endif()
qt_add_resources(obsidian-qt "interface" PREFIX "/ui"
  BASE "${CMAKE_CURRENT_SOURCE_DIR}" FILES ${STUDIO_QML})
add_dependencies(obsidian-qt obsidian)
add_custom_command(TARGET obsidian-qt POST_BUILD
  COMMAND "${CMAKE_COMMAND}" -E copy "$<TARGET_FILE:obsidian-qt>" "${CMAKE_SOURCE_DIR}"
  VERBATIM)
include(CTest)
if(BUILD_TESTING)
  qt_add_executable(qt-core-tests tests/test_core.cpp)
  target_link_libraries(qt-core-tests PRIVATE obsidian-qt-core Qt6::Test Qt6::QuickControls2)
  if(OBSIDIAN_QTMACOS_ROOT)
    target_link_libraries(qt-core-tests PRIVATE qtmacosplugin)
    target_compile_definitions(qt-core-tests PRIVATE OBSIDIAN_QTMACOS=1)
  endif()
  qt_add_resources(qt-core-tests "testinterface" PREFIX "/ui"
    BASE "${CMAKE_CURRENT_SOURCE_DIR}" FILES ${STUDIO_QML})
  add_dependencies(qt-core-tests obsidian)
  add_test(NAME qt-core COMMAND qt-core-tests)
  set_tests_properties(qt-core PROPERTIES
    ENVIRONMENT "QT_QPA_PLATFORM=offscreen;OBSIDIAN_TEST_ENGINE=$<TARGET_FILE:obsidian>;OBSIDIAN_TEST_DATA=${CMAKE_SOURCE_DIR}")
endif()
