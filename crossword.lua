MAX_COL = 100
MAX_ROW = 100
CELL_WIDTH = 16
CELL_HEIGHT = 16



ttf = TTFont.new("mtcg_ui.ttf",15)


local function checkValid(self,i,dir,x,y)
	local word = dict[i][1]
	local len = #word/3
	local dx,dy = 0,0
	local cx,cy = x,y
	local grid = self.grid
	if dir == 1 then
		dx = 1
	else
		dy = 1
	end
	if len-math.floor(len)>0 then return false end 
	if cy+dy*len>MAX_ROW or cx+dx*len>MAX_COL or cx-dx<1 or cy-dy<1 then
		return false
	end
	if grid[cy+dy*len][cx+dx*len]~=nil or grid[cy-dy][cx-dx]~=nil then
		return false
	end
	for i=1,len do
		local char = word:sub(i*3-2,i*3)
		if grid[cy][cx] ~= char then
			if grid[cy][cx] then
				return false
			end
			if (dir==1 and (grid[cy-1][cx] or grid[cy+1][cx])) or
			   (dir==2 and (grid[cy][cx-1] or grid[cy][cx+1])) then
				return false
			end
		end
		cx = cx + dx
		cy = cy + dy
	end
	return true
end

local function build(self,si,dir,x,y)
	local word = dict[si][1]
	local clue = dict[si][2]
	local len = #word/3
	print(word,clue,len)
	local dx,dy = 0,0
	local cx,cy = x,y
	local grid = self.grid
	if dir == 1 then
		dx = 1
	else
		dy = 1
	end
	for i=1,len do
		local char = word:sub(i*3-2,i*3)
		grid[cy][cx] = char
		cx = cx + dx
		cy = cy + dy
	end
	cx,cy = x,y
	self.used[si] = true
	local lastCharUsed = false
	for i=1,len do
		local char = word:sub(i*3-2,i*3)
		local t = TextField.new(ttf,char)
		t:setPosition(	(cx-50)*CELL_WIDTH+application:getLogicalWidth()/2,
						(cy-50)*CELL_HEIGHT+application:getLogicalHeight()/2)
		self:addChild(t)
		if map[char] and not lastCharUsed then
			lastCharUsed = false
			for j,v in ipairs(map[char]) do
				if not self.used[v] then
					local adj = (dict[v][1]:find(char)-1)/3 
					local ax,ay = 0,0
					if dir == 2 then
						ax = - adj
					else
						ay = - adj
					end
					if checkValid(self,v,3-dir,cx+ax,cy+ay) then
						build(self,v,3-dir,cx+ax,cy+ay)
						lastCharUsed = true
						break
					end
				end
			end
		else
			lastCharUsed = false
		end
		cx = cx + dx
		cy = cy + dy
	end
end




Crossword = Core.class(Sprite)

function Crossword:init()
	local startIndex = math.random(#dict)
	local dir = math.random(2)	-- 1:H 2:V
	self.grid = {}
	self.used = {}
	for i=1,MAX_ROW do
		self.grid[i]={}
	end
	build(self,startIndex,dir,50,50)
	print("완료")
end

