local t = ...
local pl = t.pl

-- Copy all additional files.
t:install{
  ['local/netX90_reset_NXJTAG-4000-USB.tcl']    = '${install_base}/',
  ['local/netX500_reset_NXHX_onboard_FTDI.tcl'] = '${install_base}/',
  ['local/reset.lua']                           = '${install_base}/',

  ['${report_path}']                            = '${install_base}/.jonchki/'
}

t:createPackageFile()
t:createHashFile()
t:createArchive('${install_base}/../../../${default_archive_name}', 'native')

return true

