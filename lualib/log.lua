local skynet = require "skynet"
local t = require("table")
local m = require("math")
local d = require("debug")
local s = require("string")

local type = type
local print = print
local pairs = pairs
local ipairs = ipairs
local select = select
local tostring = tostring

local log = {}

local getinfo = d.getinfo

-------------------内部使用的函数----------------------
--[[
    dump_obj(obj [, key ][, sp ][, lv ][, st])
    obj: object to dump
    key: a string identifying the name of the obj, optional.
    sp: space string used for indention, optional(default:'  ').
    lv: for internal use, leave it alone! levels of nested dump.
    st: for internal use, leave it alone! map of saved-table.
 
    it returns a string, which is simply formed just by calling
    'tostring' with any value or sub values of object obj, exc-
    -ept table!.
--]]
local function dump_obj(obj, key, sp, lv, st)
    sp = sp or '  '

    if type(obj) ~= 'table' then
        return sp..(key or '')..' = '..tostring(obj)..'\n'
    end

    local ks, vs, s= { mxl = 0 }, {}
    lv, st =  lv or 1, st or {}

    st[obj] = key or '.' -- map it!
    key = key or ''
    for k, v in pairs(obj) do
        if type(v)=='table' then
            if st[v] then -- a dumped table?
                t.insert(vs,'['.. st[v]..']')
                s = sp:rep(lv)..tostring(k)
                t.insert(ks, s)
                ks.mxl = m.max(#s, ks.mxl)
            else
                st[v] =key..'.'..k -- map it!
                t.insert(vs,
                    dump_obj(v, st[v], sp, lv+1, st)
                )
                s = sp:rep(lv)..tostring(k)
                t.insert(ks, s)
                ks.mxl = m.max(#s, ks.mxl)
            end
        else
            if type(v)=='string' then
                t.insert(vs,
                    (('%q'):format(v)
                        :gsub('\\\10','\\n')
                        :gsub('\\r\\n', '\\n')
                    )
                )
            else
                t.insert(vs, tostring(v))
            end
            s = sp:rep(lv)..tostring(k)
            t.insert(ks, s)
            ks.mxl = m.max(#s, ks.mxl);
        end
    end

    s = ks.mxl
    for i, v in ipairs(ks) do
        vs[i] = v..(' '):rep(s-#v)..' = '..vs[i]..'\n'
    end

    return '{\n'..t.concat(vs)..sp:rep(lv-1)..'}'
end

local function log_base(...)
    local level = 3
    local info = getinfo(level, "Sl")
    local file = info and info.short_src or "unknown"
    local line = info and info.currentline or 0
    local msg = ""
    for i = 1, select('#', ...) do
        if msg == "" then
            msg = tostring(select(i, ...))
        else
            msg = msg .. "\t" .. tostring(select(i, ...))
        end
    end
    return string.format("[%s:%d] %s", file, line, msg)
end

--------------供外部调用的函数---------------
function log.fatal(...)
    local msg = log_base(...)
    skynet.error(msg .. "\n" .. d.traceback())
end

function log.error(...)
    local msg = log_base(...)
    skynet.error(msg .. "\n" .. d.traceback())
end

function log.warn(...)
    local msg = log_base(...)
    skynet.error(msg)
end

function log.info(...)
    local msg = log_base(...)
    skynet.error(msg)
end

function log.debug(...)
    local msg = log_base(...)
    skynet.error(msg)
end

--打印table，供调试用
function log.table(t, text)
    text = text or '----------table content----------'
    local msg = log_base(text .. "\n" .. dump_obj(t, "base"))
    skynet.error(msg)
end


return log
