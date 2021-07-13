proc probe {} {
  global SC_CFG_RESULT
  set SC_CFG_RESULT 0
  set RESULT -1

  # Disable all servers.
  gdb_port disabled
  tcl_port disabled
  telnet_port disabled

  # Setup the interface.
  interface ftdi
  transport select jtag
#  ftdi_device_desc ""
  ftdi_vid_pid 0x0640 0x0028
  adapter_khz 1000
  ftdi_layout_init 0x0108 0x010b
  ftdi_layout_signal nTRST -data 0x0100
  ftdi_layout_signal nSRST -data 0x0200 -oe 0x0200

  # Expect a netX500 scan chain.
  jtag newtap netX_ARM926 cpu -irlen 4 -ircapture 1 -irmask 0xf -expected-id 0x07926021
  jtag configure netX_ARM926.cpu -event setup { global SC_CFG_RESULT ; echo {Yay - setup netX500} ; set SC_CFG_RESULT {OK} }

  # Expect working SRST and TRST lines.
  reset_config trst_and_srst separate
  adapter_nsrst_delay 500
  adapter_nsrst_assert_width 50

  # Try to initialize the JTAG layer.
  if {[ catch {jtag init} ]==0 } {
    if { $SC_CFG_RESULT=={OK} } {
      target create netX_ARM926.cpu arm926ejs -endian little -chain-position netX_ARM926.cpu
      netX_ARM926.cpu configure -event reset-init { halt }

      init

      # Reset the netX.
      echo {Trying SRST}
      jtag_reset 0 1
      sleep 100
      jtag_reset 0 0

      set RESULT 0
    }
  }

  return $RESULT
}

probe
