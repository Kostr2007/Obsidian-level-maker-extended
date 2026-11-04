find_package(Qt6 6.4 REQUIRED COMPONENTS Quick QuickControls2 Test)
qt_standard_project_setup()
add_library(obsidian-qt-core STATIC
  configuration.cpp configuration.h
  wadpreview.cpp wadpreview.h
  backend.cpp backend.h)
target_link_libraries(obsidian-qt-core PUBLIC Qt6::Quick)
target_compile_features(obsidian-qt-core PUBLIC cxx_std_17)
qt_add_executable(obsidian-qt main.cpp)
set_target_properties(obsidian-qt PROPERTIES OUTPUT_NAME obsidian)
target_compile_definitions(obsidian-qt PRIVATE OBSIDIAN_EXTENDED_VERSION="${PROJECT_VERSION}")
target_link_libraries(obsidian-qt PRIVATE obsidian-qt-core Qt6::QuickControls2)
qt_add_resources(obsidian-qt "interface" PREFIX "/ui"
  BASE "${CMAKE_CURRENT_SOURCE_DIR}" FILES Main.qml OptionEditor.qml ActionButton.qml Surface.qml GameSetup.qml)
add_dependencies(obsidian-qt obsidian)
add_custom_command(TARGET obsidian-qt POST_BUILD
  COMMAND "${CMAKE_COMMAND}" -E copy "$<TARGET_FILE:obsidian-qt>" "${CMAKE_SOURCE_DIR}"
  VERBATIM)
include(CTest)
if(BUILD_TESTING)
  qt_add_executable(qt-core-tests tests/test_core.cpp)
  target_link_libraries(qt-core-tests PRIVATE obsidian-qt-core Qt6::Test)
  add_dependencies(qt-core-tests obsidian)
  add_test(NAME qt-core COMMAND qt-core-tests)
  set_tests_properties(qt-core PROPERTIES
    ENVIRONMENT "QT_QPA_PLATFORM=offscreen;OBSIDIAN_TEST_ENGINE=$<TARGET_FILE:obsidian>;OBSIDIAN_TEST_DATA=${CMAKE_SOURCE_DIR}")
endif()
