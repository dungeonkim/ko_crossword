


f = io.open("d:/downloads/kowiktionary-20150305-abstract.xml")
f2 = io.open("d:/projects/ko_crossword/dict.lua","w")
c = 0
local word = ""
local clue = ""
f2:write("dict = {\n")
local map = {}
repeat
	s = f:read("*l")
	if s and (s:find("<abstract>") or s:find("<title>")) then 
		local s2 = s:match(">(.*)<")
		if s2:find("^위키낱말사전: ") then
			word = s2:match("^위키낱말사전: (.*)")
		elseif s2:find("^%*1%. ") then
			local l = word:len()/3
			local h = word:sub(1,3)
			local buf 
			clue = s2:match("^%*1%. (.*)"):gsub('"','\"')
			if l>1 and h:find("[\234-\237][\128-\191][\128-\191]") then
				if clue:find(word)==nil and not clue:find("표기") then
					word = word:gsub(" ","")
					buf = ('{"'..word..'","'..clue..'"},')
					c=c+1
					f2:write("\t"..buf.."\n")
					for i=1,l do
						local char = word:sub(i*3-2,i*3)
						map[char] = map[char] or {}
						map[char][#map[char]+1] = c
					end
				end
				word = ""
			end
		end
	end
until s==nil --or c==100
f2:write("}")

f:close()
f2:close()
print("finish",c)


f3 = io.open("d:/projects/ko_crossword/map.lua","w")
f3:write("map = {\n")
for k,v in pairs(map) do
	f3:write('\t["'..k..'"]={')
	for i,v2 in ipairs(v) do
		f3:write(v2..",")
	end
	f3:write('},\n')
end
f3:write("}")
f3:close()
