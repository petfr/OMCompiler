cmake_minimum_required(VERSION 2.8.9)

project(${RK12Name})

add_library(${RK12Name} RK12.cpp RK12Settings.cpp FactoryExport.cpp )

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${RK12Name} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
endif(NOT BUILD_SHARED_LIBS)

target_link_libraries(${RK12Name} ${SolverName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES})
add_precompiled_header(${RK12Name} Include/Core/Modelica.h)

install(TARGETS ${RK12Name} DESTINATION ${LIBINSTALLEXT})
install(FILES "config/RK12Settings.xml" DESTINATION share/omc/runtime/cpp/config)
