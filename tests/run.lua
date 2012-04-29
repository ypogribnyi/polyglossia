require 'lfs'
require 'lpeg'

local P, C, match = lpeg.P, lpeg.C, lpeg.match

local slash = P'/'
local nonslash = 1 - slash

local ego = arg[0]
local abspath = ego

if not match(slash, ego) then -- Path is not absolute
  abspath = lfs.currentdir() .. '/' .. ego
end

-- TODO no idea why it doesn’t work the other way round: C((slash * nonslash^1)^1) * slash
local dirnamepatt = C(slash * (nonslash^1 * slash)^0)

local testdir = match(dirnamepatt, abspath)

-- TODO I don’t like that at all ...
local alnum = lpeg.S'-_' + lpeg.R'az' + lpeg.R'AZ'
local dottex = alnum^0 * P'.tex' * -1

-- lfs.chdir(testdir + 'out')

local outdir = testdir .. 'out'
lfs.mkdir(outdir) -- returns nil and string 'File exists' if it exists already.
lfs.chdir(outdir)

local basenames = { }
for tex in lfs.dir(testdir) do
  if match(dottex, tex) then
    local basename = match(C(alnum^0), tex)
    table.insert(basenames, basename)
  end
end

local errors = { }

-- Designed for Lua 5.1 (see _VERSION).  os.execute returns only the command’s return value.
for _, basename in ipairs(basenames) do
  local tex = basename .. '.tex'
  if match(dottex, tex) then
    os.execute("xelatex " .. testdir .. '/' .. tex .. ' >/dev/null')
    os.execute("pdftotext -enc UTF-8 " .. outdir .. '/' .. basename ..  '.pdf' .. ' >/dev/null')
    local retvalue = os.execute("diff " .. testdir .. '/ref/' .. basename .. '.txt ' ..  testdir .. '/out/' .. basename .. '.txt')
    if(retvalue == 0) then
      print('Test file ' .. tex .. ' OK.')
    else
      print('Something went wrong with ' .. tex)
    end
  end
end