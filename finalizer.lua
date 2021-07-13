local t = ...
local pl = t.pl

-- Copy all additional files.
t:install{
  ['local/netX90_reset_NXJTAG-4000-USB.tcl']    = '${install_base}/',
  ['local/netX500_reset_NXHX_onboard_FTDI.tcl'] = '${install_base}/',

  ['${report_path}']                            = '${install_base}/.jonchki/'
}

-- Read the "reset.lua" script and replace all "${}" expressions.
-- This is used to insert the version number.
local strSrcFile = pl.path.abspath('local/reset.lua', t.strCwd)
local strTemplate, strMessage = pl.utils.readfile(strSrcFile)
if strTemplate==nil then
  error('Failed to read ' .. strSrcFile .. ' : '..tostring(strMessage))
end
local strText = t:replace_template(strTemplate)
local strDstFile = t:replace_template('${install_base}/reset.lua')
local fResult
fResult, strMessage = pl.utils.writefile(strDstFile, strText)
if fResult~=true then
  error('Failed to write to ' .. tostring(strDstFile) .. ' : ' .. tostring(strMessage))
end

t:createPackageFile()
t:createHashFile()
t:createArchive('${install_base}/../../../${default_archive_name}', 'native')

return true
