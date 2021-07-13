local __APPLICATION__ = 'netx_reset'
local __VERSION__ = '${root_artifact_version}'

local argparse = require 'argparse'
local openocd = require 'luaopenocd'
local pl = require'pl.import_into'()

local atLogLevels = {
  'debug',
  'info',
  'warning',
  'error',
  'fatal'
}
local atTranslateLogLevels = {
  ['debug'] = 'debug',
  ['info'] = 'info',
  ['warning'] = 'warning',
  ['error'] = 'error',
  ['fatal'] = 'fatal'
}

local tParser = argparse(__APPLICATION__, 'Reset a netX board.')
tParser:flag('--version')
  :description('Show the version and exit.')
  :action(function()
    print(string.format('%s %s', __APPLICATION__, __VERSION__))
    print('Copyright (C) 2021 by Christoph Thelen (doc_bacardi@users.sourceforge.net)')
    os.exit(0)
  end)
tParser:argument('script')
  :argname('<TCL_SCRIPT_FILE>')
  :description('Read the TCL script from TCL_SCRIPT_FILE.')
  :target('strTclScriptFile')
tParser:option('-v --verbose')
  :description(string.format('Set the verbosity level to LEVEL. Possible values for LEVEL are %s.', table.concat(atLogLevels, ', ')))
  :argname('<LEVEL>')
  :convert(atTranslateLogLevels)
  :default('warning')
  :target('strLogLevel')
tParser:option('-l --logfile')
  :description('Write all output to FILE.')
  :argname('<FILE>')
  :default(nil)
  :target('strLogFileName')
tParser:mutex(
  tParser:flag('--color')
    :description('Use colors to beautify the console output. This is the default on Linux.')
    :action("store_true")
    :target('fUseColor'),
  tParser:flag('--no-color')
    :description('Do not use colors for the console output. This is the default on Windows.')
    :action("store_false")
    :target('fUseColor')
)
local tArgs = tParser:parse()

-----------------------------------------------------------------------------
--
-- Create a log writer.
--

local fUseColor = tArgs.fUseColor
if fUseColor==nil then
  if pl.path.is_windows==true then
    -- Running on windows. Do not use colors by default as cmd.exe
    -- does not support ANSI on all windows versions.
    fUseColor = false
  else
    -- Running on Linux. Use colors by default.
    fUseColor = true
  end
end

-- Collect all log writers.
local atLogWriters = {}

-- Create the console logger.
local tLogWriterConsole
if fUseColor==true then
  tLogWriterConsole = require 'log.writer.console.color'.new()
else
  tLogWriterConsole = require 'log.writer.console'.new()
end
table.insert(atLogWriters, tLogWriterConsole)

-- Create the file logger if requested.
local tLogWriterFile
if tArgs.strLogFileName~=nil then
  tLogWriterFile = require 'log.writer.file'.new{ log_name=tArgs.strLogFileName }
  table.insert(atLogWriters, tLogWriterFile)
end

-- Combine all writers.
local tLogWriter
if _G.LUA_VER_NUM==501 then
  tLogWriter = require 'log.writer.list'.new(unpack(atLogWriters))
else
  tLogWriter = require 'log.writer.list'.new(table.unpack(atLogWriters))
end

-- Set the logger level from the command line options.
local cLogWriter = require 'log.writer.filter'.new(tArgs.strLogLevel, tLogWriter)
local tLog = require "log".new(
  -- maximum log level
  "trace",
  cLogWriter,
  -- Formatter
  require "log.formatter.format".new()
)

-- Read the TCL script.
local strTclScript, strError = pl.utils.readfile(tArgs.strTclScriptFile, false)
if strTclScript==nil then
  tLog.error('Failed to read the TCL script "%s": %s.', tArgs.strTclScriptFile, tostring(strError))
  error('Failed to read the TCL script.')
end

local function msg_callback(strMsg)
  tLog.debug('[openOCD] %s', tostring(strMsg))
end
local tOpenOCD = openocd.luaopenocd(msg_callback)
tLog.debug('Initializing OpenOCD.')
tOpenOCD:initialize()

local strResult
local fOK
local iResult = tOpenOCD:run(strTclScript)
if iResult~=0 then
  tLog.error('Failed to execute the script.')
else
  strResult = tOpenOCD:get_result()
  tLog.debug('Script result: %s', strResult)
  if strResult=='0' then
    fOK = true
  else
    tLog.error('The script failed with the result %s.', tostring(strResult))
  end
end


tLog.debug('Uninitialize OpenOCD.')
tOpenOCD:uninit()

if fOK~=true then
  tLog.error('The script did not succeed.')
else
  tLog.info('')
  tLog.info(' #######  ##    ## ')
  tLog.info('##     ## ##   ##  ')
  tLog.info('##     ## ##  ##   ')
  tLog.info('##     ## #####    ')
  tLog.info('##     ## ##  ##   ')
  tLog.info('##     ## ##   ##  ')
  tLog.info(' #######  ##    ## ')
  tLog.info('')
end
