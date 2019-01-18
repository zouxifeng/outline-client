set(TUN2SOCKS_SOURCES
    tun2socks.c
    SocksUdpGwClient.c)

if (CMAKE_SYSTEM_NAME STREQUAL "Darwin")
  # Remove the Objective-C compiler flag so that the shared library can be linked.
  string(REPLACE "-x objective-c" "" CMAKE_C_FLAGS ${CMAKE_C_FLAGS})
  add_library(tun2socks SHARED ${TUN2SOCKS_SOURCES})
  # Set the shared library RPATH to @rpath.
  set_target_properties(tun2socks
    PROPERTIES MACOSX_RPATH 1
    BUILD_WITH_INSTALL_NAME_DIR 1
    INSTALL_NAME_DIR "@rpath")

  target_link_libraries(tun2socks system flow tuntap lwip socksclient udpgw_client stringmap socks_udp_client)
else()
  add_executable(badvpn-tun2socks ${TUN2SOCKS_SOURCES})
  target_link_libraries(badvpn-tun2socks system flow tuntap lwip socksclient udpgw_client stringmap socks_udp_client)
  install(
      TARGETS badvpn-tun2socks
      RUNTIME DESTINATION bin
  )

  install(
      FILES badvpn-tun2socks.8
      DESTINATION share/man/man8
  )
endif()
