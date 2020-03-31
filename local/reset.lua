require 'muhkuh_cli_init'

local openocd = require 'luaopenocd'

-- Read the TCL script.
local tFile = io.open('netX90_reset_NXJTAG-4000-USB.tcl', 'r')
local strScript = tFile:read('*a')
tFile:close()

local function msg_callback(strMsg)
  print(string.format('[openOCD] %s', tostring(strMsg)))
end
local tOpenOCD = openocd.luaopenocd(msg_callback)
tOpenOCD:initialize()

local strResult
local iResult = tOpenOCD:run(strScript)
if iResult~=0 then
  error('Failed to execute the script.')
else
  strResult = tOpenOCD:get_result()
  print(string.format('Script result: %s', strResult))
  if strResult=='0' then
    fOK = true
  else
    tLog.debug('The script result is not "0".')
  end
end

print('Uninitialize OpenOCD.')
tOpenOCD:uninit()

if fOK~=true then
  error('The script did not succeed.')
else
  print('')
  print(' #######  ##    ## ')
  print('##     ## ##   ##  ')
  print('##     ## ##  ##   ')
  print('##     ## #####    ')
  print('##     ## ##  ##   ')
  print('##     ## ##   ##  ')
  print(' #######  ##    ## ')
  print('')
end
