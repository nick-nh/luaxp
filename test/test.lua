require("json")

local mt = getmetatable(_G)
if mt == nil then
  mt = {}
  setmetatable(_G, mt)
end

__STRICT = true
mt.__declared = {}

mt.__newindex = function (t, n, v)
  if __STRICT and not mt.__declared[n] then
    local w = debug.getinfo(2, "S").what
    if w ~= "C" then
      print("ASSIGNMENT TO GLOBAL "..n)
      -- error("assign to undeclared global variable '"..n.."'", 2)
    end
    mt.__declared[n] = true
  end
  rawset(t, n, v)
end

mt.__index = function (t, n)
  if not mt.__declared[n] and debug.getinfo(2, "S").what ~= "C" then
    print("REFERENCE TO UNDECLARED GLOBAL " .. n)
    print(debug.traceback())
    error("variable '"..n.."' is not declared", 2)
  end
  return rawget(t, n)
end

local function debugPrint( msg )
    print(string.char(27) .. "[0;34;40m" .. msg .. string.char(27) .. "[0m") -- debug in blue
end

local L = require("luaxp")

-- Uncomment the line below to enable debugging
-- L._DEBUG = debugPrint

local ctx = {}
local nTest = 0
local nErr = 0
local nSkip = 0

local RED = string.char(27) .. "[0;31;40m"
local YELLOW = string.char(27) .. "[0;33;40m"
local RESET = string.char(27) .. "[0m"

local function fail(m, ...)
    local msg
    if m == nil then msg = "Incorrect result, check manually"
    else msg = string.format(m, ...) end
    print(RED .. "     >>>>> FAIL, " .. msg .. RESET)
    nErr = nErr + 1
end

local function skip(s, ...)
    nTest = nTest + 1
    print(string.format("%03d: %s", nTest, s))
    print(string.format(YELLOW .. "     ***** SKIPPED, ", nTest) .. string.format(...) .. RESET)
    nSkip = nSkip + 1
end

--[[ Evaluate the passed string s. Compare to the expected result.
     To pass, the result must have the same value and data type as
     expected. If the expression is meant to throw an error, then
     failExpect may contain a fragment of the expected error message,
     and it is a failure for the expression to not fail or fail with
     any other message.
--]]
local function eval(s, expected, failExpect, comment)
    nTest = nTest + 1
    if nTest == 999 then L._DEBUG = debugPrint end
    local r,err = L.evaluate(s, ctx)
    L._DEBUG = false
    local mm, errmsg
    if r == nil then
        -- There was an error
        if type(err) == "table" then
            mm = string.format("(%s error at %s) %s", err.type, err.location or "unknown", err.message)
            errmsg = err.message
        else
            mm = string.format("(RUNTIME ERROR) %s", tostring(err))
            errmsg = err
        end
    else    
        mm = string.format("(%s)%s", type(r), L.dump(r)) 
    end
    print(string.format("%03d: %s=%s", nTest, s, mm))
    if comment ~= nil then
        print("     NOTE: " .. comment)
    end
    if r == nil then
        if failExpect == nil or not string.find( errmsg, failExpect ) then
            fail("error thrown: %s", mm)
        end
    elseif failExpect ~= nil then
        fail("expected error not thrown (%s)", failExpect)
    elseif expected ~= nil then
        if type(expected) == "function" then
            expected( r )
        elseif type(r) == type(expected) then
            if type(r) == "number" then
                local delta = r - expected
                if math.abs(delta) > 0.00001 then
                    fail("expected (%s)%s, delta %f", type(expected), tostring(expected), delta)
                end
            else
                if r ~= expected then
                    fail("expected (%s)%s", type(expected), tostring(expected))
                end
            end
        else 
            fail("expected (%s)%s", type(expected), tostring(expected))
        end
    else
        print(YELLOW .. "     !!!!! WARNING, test has no defined expected result; check manually." .. RESET)
    end
    return r
end

-- ********************* TIME PARSING TESTS **********************
local function doTimeTests()
    local now = eval("time()", function( result ) if result ~= os.time() then fail() end end)
    local localeDateTime = eval("strftime(\"%x %X\", " .. now .. ")", nil, nil, "The result should be current date in locale format")
    eval("strftime(\"%b %B\", time())", nil, nil, "The result should be abbrev and full name for current month in locale language/format")
    eval("time('2014-04-28T16:00-05:00')", 1398715200)
    eval("time('2017-01-20T12:00:00-05:00')", 1484931600)
    eval("time('2013-07-08T09:10:00.553-05:00')", 1373289000)
    eval("time('20180128T151617-0500')", 1517170577)
    eval("time('2013-07-13')", 1373688000)
    eval("time('12/21/2021T0000')", 1640062800)
    eval("time('8/8/2008 8:8:8')", 1218197288)
    eval("time('7/7/7 7:7:7')", 1183806427)
    eval("time('13/11/2011')", 1321160400)
    eval("time('12:45')", function( result ) local dn = os.date("*t") local dr = os.date("*t", result) if not (dr.hour == 12 and dr.min == 45 and dr.year == dn.year and dr.month == dn.month and dr.day == dn.day and dr.sec == 0 ) then fail() end end)
    eval("time('0300')", function( result ) local dn = os.date("*t") local dr = os.date("*t", result) if not (dr.hour == 3 and dr.min == 0 and dr.year == dn.year and dr.month == dn.month and dr.day == dn.day and dr.sec == 0 ) then fail() end end)
    eval("time('8/1 1:45pm')", function( result ) local dn = os.date("*t") local dr = os.date("*t", result) if not (dr.hour == 13 and dr.min == 45 and dr.year == dn.year and dr.month == 8 and dr.day == 1 and dr.sec == 0 ) then fail() end end)
    eval("time('8/1/15 3:17am')", 1438413420)
    eval("time('Mon Jan 29 9:43:00 2018')", 1517236980)
    eval("time('Jan 31 2018')", 1517374800)
    eval("time('Jul 4 09:43p')", function( result ) local dn = os.date("*t") local dr = os.date("*t", result) if not (dr.hour == 21 and dr.min == 43 and dr.year == dn.year and dr.month == 7 and dr.day == 4 and dr.sec == 0 ) then fail() end end)
    eval("time('10-Nov-2018')", 1541826000)
    eval("time('" .. localeDateTime .. "')", now)
    eval("time('Mar 10 2014 +24:00:00')", 1394510400)
    eval("time('Oct 1 2009 +30:00:00:00')", 1256961600)
    eval("time('Sep 21 2012 15:30 -12:15')", 1348255065)
    eval("time('13/11/2011 garbage-at-end')", 1321142400, "Unparseable data")
    local thn = eval("dateadd('2018-06-15', 45, 30, 15, 6, 3, 2)", 1600716645)
    eval("datediff(dateadd(time(),0,0,0,1))", 86400)
    eval("dateadd('1980-09-01',0,0,0,0,360)", 1283313600)
    
    if ctx.response ~= nil then
        eval("strftime(\"%c\", response.loadtime)", nil, nil, "The result should comport with the loadtime value in sample.json")
    else
        skip("strftime(\"%c\", response.loadtime)", "file sample1.json could not be loaded")
    end
end

local function doStringOpsTests()
    eval('"Es gibt kein Bier auf Hawaii"', "Es gibt kein Bier auf Hawaii")
    eval("'Ich bin Berliner!'", "Ich bin Berliner!")
    eval("'Hello \"there\"'", 'Hello "there"')
    eval('"Well, \'hello\' to you too"', "Well, 'hello' to you too")
    eval("'collaborate' + 'learn'", "collaboratelearn")
    eval("'abc'-'def'", nil, "string to number failed")
    eval("'abc'*'def'", nil, "string to number failed")
    eval("'*'*20", nil, "string to number failed")
    eval("'abc'/'def'", nil, "string to number failed")
    eval("99 + ' bottles of beer on the wall'", "99 bottles of beer on the wall")
    eval("'There are ' + 0 + ' remaining.'", "There are 0 remaining.")
    eval('"What is the reason?', nil, "Unterminated string")
    eval("'New York' == 'NEW YORK'", false)
    eval("'New York' == 'New York'", true)
    eval("'New York' == 'Philadelphia'", false)
    eval("'New York' != 'NEW YORK'", true)
    eval("'New York' != 'New York'", false)
    eval("'New York' != 'Philadelphia'", true)
end

local function doNumericParsingTests()
    eval("0",0)
    eval("1",1)
    eval("-1",-1)
    eval("-1+1",0)
    eval("186282",186282)
    eval("-255",-255)
    eval("077",63)
    eval("0x1F",31)
    eval("0b0011",3)
    eval("1e3", 1000)
    eval("1E", nil, "Missing exponent")
    eval("10e-1",1)
    eval("-0.567112E+06", -567112)
    eval(".7177", 0.7177)
    eval("'123'+321",'123321')
    eval("tonumber(123)+321",444)
    eval("pi",3.14159265)
    eval("0xgg", nil, "Invalid")
    eval("0ff", nil, "Invalid")
    eval("0b2", nil, "Invalid")
end

local function doNumericOpsTests()
    eval("123 + 456", 579)
    eval("579-123", 456)
    eval("8--1", 9)
    eval("-8-1", -9)
    eval("-8--9", 1)
    eval("123*4", 492)
    eval("492/123", 4)
    eval("127 % 100", 27)
    eval("400 % 100", 0)
    eval("300 < 400", true)
    eval("300 < 300", false)
    eval("300 < 200", false)
    eval("500 > 100", true)
    eval("500 > 500", false)
    eval("500 > 600", false)
    eval("300 <= 400", true)
    eval("300 <= 300", true)
    eval("300 <= 200", false)
    eval("500 >= 100", true)
    eval("500 >= 500", true)
    eval("500 >= 600", false)
    eval("500 == 500", true)
    eval("500 != 500", false)
    eval("500 == 600", false)
    eval("500 != 600", true)
    eval("15&8",8)
    eval("7&8",0)
    eval("2|4",6)
    eval("6^4",2)
    eval("!8", 4294967287)
    eval("!0", 4294967295)
    
    -- Precedence tests
    eval("1+2*3", 7)
    eval("1*2-4", -2)
    eval("8-32/4", 0)
    eval("1+(2-4)", -1)
    eval("(((((((((( 24 ))))))))))", 24)
    eval("2+4>5", true)
    eval("2+6!=6", true)
    eval("1==1&4", true, nil, "Equiv (1==1)&4 so true&4 is true; not 1==(1&4), 1==0 is false")
    eval("1==(1&4)", false)
    eval("1+1&5", 0, nil, "Equiv (1+1)&5 so 2&5 is 0; not 1+(1&5), 1+1 is 2")
    eval("1+(1&5)", 2)
    eval("3|4+7", 11, nil, "Equiv 3|(4+7), 3|11 is 11; not (3|4)+7, 7+7 is 14")
    eval("(3|4)+7", 14)
end

local function doBooleanOpsTests()
    -- Note !0 and !1 are treated as number, not boolean, and produce a 32-bit bitwise result. See num ops tests
    eval("true", true)
    eval("false", false)
    eval("!'0'",true)
    eval("!'1'",false)
    eval("true&1",true)
    eval("true&0",false)
    eval("true&'true'", true)
    eval("'false'&'false'", false)
    eval("'false'&'true'", false)
    eval("'true'&'true'", true)
    eval("'false'|'false'", false)
    eval("'false'|'true'", true)
    eval("'true'|'true'", true)
    eval("'false'^'false'", false)
    eval("'false'^'true'", true)
    eval("'true'^'true'", false)
end

local function doMathFuncTests()
    eval("abs(123)", 123)
    eval("abs(-123)", 123)
    eval("abs(0)", 0)
    eval("abs(-0)", 0)
    eval("sgn(123)", 1)
    eval("sgn(-123)", -1)
    eval("sgn(0)", 0)
    eval("sgn(-0)", 0)
    eval("round(1.1111,2)", 1.11)
    eval("round(1.78,0)", 2)
    eval("round(0, 4)", 0)
    eval("sqrt(64)",8)
    eval("sin(pi/2)",1)
    eval("cos(pi/2)",0)
    eval("sin(0)",0)
    eval("cos(0)",1)
    eval("sqrt(2)/2")
    eval("sin(45 * pi / 180)", nil, nil, "The result should be about sqrt(2)/2 = 0.707...")
    eval("floor(123)",123)
    eval("floor(0.123*1000)", 123.0, nil, "There is a known rounding error that needs to be resolved here")
    eval("floor(1.8)", 1)
    eval("floor(1.2)", 1)
    eval("floor(-1.2)", -2)
    eval("ceil(1.8)", 2)
    eval("ceil(1.2)", 2)
    eval("ceil(-1.2)", -1)
    eval("pow(10,2)", 100)
    eval("pow(10,-1)", 0.1)
    eval("min(1,9)", 1)
    eval("min(9,1)", 1)
    eval("max(1,9)", 9)
    eval("max(9,1)", 9)
end

local function doStringFuncTests()
    eval("len('The rain in Spain stays mainly in the plain.')", 44)
    eval("sub('The rain in Spain stays mainly in the plain.', 5, 8)", "rain")
    eval("sub('The rain in Spain stays mainly in the plain.', 40, 49)", "lain.")
    eval("sub('The rain in Spain stays mainly in the plain.', 35, -5)", "the pl")
    eval("sub('The rain in Spain stays mainly in the plain.', 39)", "plain.")
    eval("sub('[in brackets]', 2, -2)", "in brackets")
    eval("find('The rain in Spain stays mainly in the plain.', 'not there')", 0)
    eval("find('The rain in Spain stays mainly in the plain.', 'plain.')", 39)
    eval("upper('The rain in Spain stays mainly in the plain.')", "THE RAIN IN SPAIN STAYS MAINLY IN THE PLAIN.")
    eval("lower('The rain in Spain stays mainly in the plain.')", "the rain in spain stays mainly in the plain.")
    eval("format('I like %s, I buy %dkg at a time.', 'cheese', 5)", "I like cheese, I buy 5kg at a time.")
    eval("rtrim('   only on the right   ')", "   only on the right")
    eval("ltrim('   only on the left   ')", "only on the left   ")
    eval("trim('      both sides     ')", "both sides")
    eval("tostring(true)", "true")
    eval("tostring(123)", "123")
    eval("tostring(1.23)", "1.23")
    eval("tostring('cardiovascular')", "cardiovascular")
    eval("tonumber(true)", 1)
    eval("tonumber(false)", 0)
    eval("tonumber(123)", 123)
    eval("tonumber(12.3)", 12.3)
    eval("tonumber('456')", 456)
    eval("tonumber('1e5')", 100000)
    eval("tonumber('dog and cat')", nil, "could not be converted")
    eval("tonumber('1E',16)", 30)
    eval("tonumber('-7f',16)", nil, nil, "Known limitation in Lua tonumber(), ignore this case.")
    eval("tonumber('377',8)", 255)
    eval("tonumber('-377',8)", nil, nil, "Known limitation in Lua tonumber(), ignore this case.")
    eval("tonumber('1001',2)", 9)
end

local function doMiscFuncTests()
    eval("choose(3,\"default\",\"A\",\"B\",\"C\",\"D\")", "C")
    eval("choose(9,\"default\",\"A\",\"B\",\"C\",\"D\")", "default")
    
    if ctx.response ~= nil then
        eval("#keys(response.rooms)", 23)
        eval("i=''", "",nil,"Setup for next test") 
        eval("#iterate(response.rooms,'void(i = i + \",\" + _.name)')", 0, nil, "Iterator using anonymous upvalue and empty result array")
        eval("#i", 254, nil, "Expected length of string may change if data altered")
        eval('#iterate(response.devices,"if(device.room==10,device.id)","device")', 7, nil, "Expected number of matching rooms may change if data altered")
    else
        nSkip = nSkip + 5
    end
end

local function doMiscSyntaxTests()    
    -- Variable assignment
    eval("i=25",25) eval("i", 25)
    eval("k", nil, "Undefined var")

    -- Nesting
    eval("min(70,max(20,min(60,max(30,min(50,40)))))", 40)
    
    -- Quoted identifiers, subreferences, select()
    if ctx.response ~= nil then
        ctx.response['bad name!'] = ctx.response.loadtime
        eval("['response'].['bad name!']", ctx.response.loadtime, nil, "Quoted identifiers allow chars otherwise not permitted")
        eval("response.notthere", nil, "Subreference not found")
        eval("select( response.rooms, 'id', '14' ).name", "Front Porch")
    else
        skip("['response'].['loadtime']", "JSON data not loaded")
        skip("response.notthere", "JSON data not loaded")
        skip("select( response.rooms, 'id', '14' ).name", "JSON data not loaded")
    end

    -- Syntax abuse
    eval("true=123", nil, "reserved word")
    eval("1,2", nil, "Invalid operator") 
    eval("a[", nil, "Unexpected end of array subscript")
    eval("123+array]", nil, "Invalid operator")
    eval("+", nil, "Expected operand")

    -- Array subscripts
    ctx.array={11,22,33,44,55} eval("array[4]", 44) eval("array[19]", nil, "out of range")
    eval("true.val", nil, "Cannot subreference")
    eval("true[1]", nil, "not an array")
    eval("ff(1, )", nil, "Invalid subexpr") eval("ff( ,1)", nil, "Invalid subexpr")

    -- Custom functions
    ctx.__functions = { doublestring = function( argv ) return argv[1]..argv[1] end }
    eval("doublestring('galaxy')", "galaxygalaxy", nil, "Test custom function in __functions table (preferred)")
    ctx.dubstr = ctx.__functions.doublestring
    eval("dubstr('planet')", "planetplanet", nil, "Test custom function in context root (deprecated)")
end

local function doNullTests()
    eval("null", L.NULL)
    eval("nil", L.NULL)
    eval("null*4", nil, "Can't coerce null")
    eval("null/null", nil, "Can't coerce null")
    eval("tostring(null)", "")
    eval("null + 'abc'", "abc")
    eval("null & 123", false, nil, "null coerces to boolean false, and bool & number = bool")
    eval("null==0", false)
    eval("null==null", true)
    eval("null~=null", false)
    eval("null==1", false)
    eval("null==true", false)
    eval("null==false", true)
    eval("null==''", true)
end

local function doRegressionTests()
    -- For this test, save current context and use special.
    local s = '{"coord":{"lon":-84.56,"lat":33.39},"weather":[{"id":800,"main":"Clear","description":"clear sky","icon":"01d"}],"base":"stations","main":{"temp":281.29,"pressure":1026,"humidity":23,"temp_min":278.15,"temp_max":285.15},"visibility":16093,"wind":{"speed":5.1,"deg":150},"clouds":{"all":1},"dt":1517682900,"sys":{"type":1,"id":789,"message":0.0041,"country":"US","sunrise":1517661125,"sunset":1517699557},"id":0,"name":"Peachtree City","cod":200}'
    local t = ctx
    ctx = { response = json.decode(s) }
    eval("response.weather[1].description", "clear sky")
    ctx = t -- restore prior context
end

-- Load JSON data into context, if we can.
local json = require("json")
if json == nil then json = require('dkjson') end
if json then
    local file = io.open("test/testdata.json", "r")
    if file then
        local s = file:read("*all")
        file:close()
        ctx.response = json.decode(s)
    else
	print(RED.."JSON data could not be loaded!"..RESET)
    end
end

--[[
--]]
doNumericParsingTests()
doNullTests()
doNumericOpsTests()
doStringOpsTests()
doBooleanOpsTests()
doMathFuncTests()
doStringFuncTests()
doTimeTests()
doMiscSyntaxTests()
doMiscFuncTests()
doRegressionTests()

print("")
print(string.format("Ran %d tests, %d skipped, %d errors.", nTest, nSkip, nErr))
if ctx.response == nil then
    print(RED.."JSON data not loaded, some tests skipped"..RESET)
end
