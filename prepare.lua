local t = ...

-- Filter the testcase XML with the VCS ID.
t:filterVcsId('../..', '../../netx_reset.xml', 'netx_reset.xml')

return true
