MAX_COL = 200
MAX_ROW = 200

MIN_WORD = 20
SIZE_X = 20
SIZE_Y = 20

CELL_WIDTH = application:getLogicalWidth()/SIZE_X
CELL_HEIGHT = CELL_WIDTH

ttf = TTFont.new("mtcg_ui.ttf",20)


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
	local minx = math.min(self.minx,x)
	local miny = math.min(self.miny,y)
	local maxx = math.max(self.maxx,x+len-1)
	local maxy = math.max(self.maxy,y+len-1)
	if maxx-minx+1>SIZE_X or maxy-miny+1>SIZE_Y then
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
	self.minx = math.min(self.minx,x)
	self.miny = math.min(self.miny,y)
	self.maxx = math.max(self.maxx,x+len-1)
	self.maxy = math.max(self.maxy,y+len-1)
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
		if map[char] and not lastCharUsed then
			lastCharUsed = false
			local pot = {}
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
						--길이만큼 추가
						for k=1,math.floor(#dict[v][1]/3) do
							pot[#pot+1] = {v,ax,ay}
						end
					end
				end
			end
			if #pot>0 then
				local pick = pot[math.random(#pot)]
				local ax,ay = pick[2],pick[3]
				build(self,pick[1],3-dir,cx+ax,cy+ay)
				lastCharUsed = true
				self.count = self.count + 1
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
	repeat
		self.minx = MAX_COL
		self.miny = MAX_ROW
		self.maxx = 0
		self.maxy = 0
		self.count = 0
		local startIndex = math.random(#dict)
		local dir = math.random(2)	-- 1:H 2:V
		self.grid = {}
		self.used = {}
		for i=1,MAX_ROW do
			self.grid[i]={}
		end
		build(self,startIndex,dir,100,100)
	until self.count>MIN_WORD
	self:draw()
end

function Crossword:draw()
	for i=self.minx,self.maxx do
		for j=self.miny,self.maxy do
			local s = Shape.new()
			s:beginPath()
			local x,y = i-self.minx+1,j-self.miny+1
			local char = self.grid[j][i]
			s:setLineStyle(2,0x000000,1.0)
			if char then
				local t = TextField.new(ttf,char)
				t:setPosition((x-1+0.25)*CELL_WIDTH,(y-1+0.23)*CELL_HEIGHT+ttf:getAscender())
				self:addChild(t)
				s:setFillStyle(Shape.NONE)
			else
				s:setFillStyle(Shape.SOLID,0x303030,1.0)
			end
			s:moveTo((x-1)*CELL_WIDTH,(y-1)*CELL_HEIGHT)
			s:lineTo((x-0)*CELL_WIDTH,(y-1)*CELL_HEIGHT)
			s:lineTo((x-0)*CELL_WIDTH,(y-0)*CELL_HEIGHT)
			s:lineTo((x-1)*CELL_WIDTH,(y-0)*CELL_HEIGHT)
			s:lineTo((x-1)*CELL_WIDTH,(y-1)*CELL_HEIGHT)
			s:closePath()
			s:endPath()
			self:addChild(s)
		end
	end
end

