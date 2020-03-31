local t = ...
local strDistId, strDistVersion, strCpuArch = t:get_platform()
local cLog = t.cLog
local tLog = t.tLog
local tResult
local archives = require 'installer.archives'
local hash = require 'Hash'
local pl = require'pl.import_into'()


-- Copy all additional files.
local atScripts = {
  ['local/netX90_reset_NXJTAG-4000-USB.tcl'] = '${install_base}/',
  ['local/reset.lua']                        = '${install_base}/',

  ['${report_path}']                        = '${install_base}/.jonchki/'
}
for strSrc, strDst in pairs(atScripts) do
  t:install(strSrc, strDst)
end


-- Install the CLI init script.
if strDistId=='windows' then
  t:install('local/windows/muhkuh_cli_init.lua', '${install_base}/')
  t:install('local/windows/reset.bat', '${install_base}/')
elseif strDistId=='ubuntu' then
  t:install('local/linux/muhkuh_cli_init.lua', '${install_base}/')
  t:install('local/linux/reset', '${install_base}/')
end


-- Create the package file.
local strPackageText = t:replace_template([[PACKAGE_NAME=${root_artifact_artifact}
PACKAGE_VERSION=${root_artifact_version}
PACKAGE_VCS_ID=${root_artifact_vcs_id}
HOST_DISTRIBUTION_ID=${platform_distribution_id}
HOST_DISTRIBUTION_VERSION=${platform_distribution_version}
HOST_CPU_ARCHITECTURE=${platform_cpu_architecture}
]])
local strPackagePath = t:replace_template('${install_base}/.jonchki/package.txt')
local tFileError, strError = pl.utils.writefile(strPackagePath, strPackageText, false)
if tFileError==nil then
  tLog.error('Failed to write the package file "%s": %s', strPackagePath, strError)
  error('Failed to write the package file.')
end


-- Create a hash file.
local strInstallBase = t:replace_template('${install_base}')
local astrPackageFiles = pl.dir.getallfiles(strInstallBase)
local astrHashes = {}
local tHash = hash(cLog)
for _, strPackageAbsFile in ipairs(astrPackageFiles) do
  -- Get the hash for the file.
  local strHash = tHash:_get_hash_for_file(strPackageAbsFile, 'SHA384')
  if strHash==nil then
    tLog.error('Failed to build the hash for %s.', strPackageAbsFile)
    error('Failed to build the hash.')
  end
  local strPackageFile = pl.path.relpath(strPackageAbsFile, strInstallBase)
  table.insert(astrHashes, string.format('%s *%s', strHash, strPackageFile))
end
local strHashFilePath = t:replace_template('${install_base}/.jonchki/package.sha384')
local strHashFile = table.concat(astrHashes, '\n')
tFileError, strError = pl.utils.writefile(strHashFilePath, strHashFile, false)
if tFileError==nil then
  tLog.error('Failed to write the hash file "%s": %s', strHashFilePath, strError)
  error('Failed to write the hash file.')
end


local Archive = archives(cLog)

-- Create a ZIP archive for Windows platforms. Build a "tar.gz" for Linux.
local strArchiveExtension
local tFormat
local atFilter
if strDistId=='windows' then
  strArchiveExtension = 'zip'
  tFormat = Archive.archive.ARCHIVE_FORMAT_ZIP
  atFilter = {}
else
  strArchiveExtension = 'tar.gz'
  tFormat = Archive.archive.ARCHIVE_FORMAT_TAR_GNUTAR
  atFilter = { Archive.archive.ARCHIVE_FILTER_GZIP }
end

local strArtifactVersion = t:replace_template('${root_artifact_artifact}-${root_artifact_version}')
local strDV = '-' .. strDistVersion
if strDistVersion=='' then
  strDV = ''
end
local strArchive = t:replace_template(string.format('${install_base}/../../../%s-%s%s_%s.%s', strArtifactVersion, strDistId, strDV, strCpuArch, strArchiveExtension))
local strDiskPath = t:replace_template('${install_base}')
local strArchiveMemberPrefix = strArtifactVersion

tResult = Archive:pack_archive(strArchive, tFormat, atFilter, strDiskPath, strArchiveMemberPrefix)

return tResult
