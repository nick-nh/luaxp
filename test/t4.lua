test = require('test/test')
testeval = test.testeval -- bring into global space

print("### Luaxp functional test -- binary operators")

testeval("45 + 64", "109")
testeval("45 - 64", "-19")
testeval("45 * 64", "2880")
testeval("64/16", "4")
testeval("7 % 5", "2")
testeval("7 & 3", "3")
testeval("7 & 8", "0")
testeval("7 & 7", "7")
testeval("1 | 2", "3")
testeval("3 | 2", "3")
testeval("8 | 2", "10")
testeval("8 ^ 15", "7")
testeval("1 ^ 1", "0")
testeval("0 ^ 1", "1")
testeval("8 ^ 8", "0")
testeval("0 ^ 8", "8")
testeval("8 ^ 4", "12")
testeval("64 > 45", "1")
testeval("45 > 64", "0")
testeval("64 >= 45", "1")
testeval("45 >= 64", "0")
testeval("64 <= 45", "0")
testeval("45 <= 64", "1")
testeval("45 > 45", "0")
testeval("45 < 45", "0")
testeval("45 >= 45", "1")
testeval("45 <= 45", "1")
testeval("45 == 45", "1")
testeval("45 == 64", "0")
testeval("45 = 45", "1")
testeval("45 != 45", "0")
testeval("45 != 64", "1")
testeval("45 <> 64", "1")
testeval("45 <> 45", "0")
testeval("45 ~= 64", "1")
testeval("45 ~= 45", "0")

testeval("10 / 1.25", "8")
testeval("8 * 1.25", "10")
testeval("1.25 + 1.33", "2.58")
testeval("1.25 - 0.5", "0.75")
testeval("1.25 - 2.5", "-1.25")