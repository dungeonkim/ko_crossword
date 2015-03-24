MAX_COL = 200
MAX_ROW = 200

MIN_WORD = 10
SIZE_X = 12
SIZE_Y = 12

CELL_WIDTH = application:getLogicalWidth()/SIZE_X
CELL_HEIGHT = CELL_WIDTH

ttf = TTFont.new("mtcg_ui.ttf",20)
ttf2 = TTFont.new("mtcg_ui.ttf",15)
ttf3 = TTFont.new("mtcg_ui.ttf",15)


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
	local maxx = math.max(self.maxx,x+dx*len-1)
	local maxy = math.max(self.maxy,y+dy*len-1)
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
	--print(word,clue,len)
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
	self.maxx = math.max(self.maxx,x+dx*len-1)
	self.maxy = math.max(self.maxy,y+dy*len-1)
	for i=1,len do
		local char = word:sub(i*3-2,i*3)
		grid[cy][cx] = char
		cx = cx + dx
		cy = cy + dy
	end
	self.count = self.count + 1
	self.quiz[dir][#self.quiz[dir]+1] = {si,x,y}
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
		self.quiz = {{},{}}
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
				--[[
				local t = TextField.new(ttf,char)
				t:setPosition((x-0.5)*CELL_WIDTH-t:getWidth()/2,(y-0.5)*CELL_HEIGHT+ttf:getAscender()-t:getHeight()/2)
				self:addChild(t)
				]]
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
	local y = SIZE_Y*CELL_HEIGHT+20
	local t = TextField.new(ttf2,"** 가로힌트 **")
	t:setPosition(0,y)
	self:addChild(t)
	y=y+16
	print("** 가로힌트 **")
	for i,v in ipairs(self.quiz[1]) do
		local clue = i.."."..dict[v[1]][2]
		local t = TextField.new(ttf2,clue)
		t:setPosition(0,y)
		self:addChild(t)
		y=y+16
		do
			local x,y = v[2]-self.minx+1,v[3]-self.miny+1
			local t = TextField.new(ttf3,i)
			t:setPosition((x-1)*CELL_WIDTH+2,(y-1)*CELL_HEIGHT+ttf3:getAscender()+2)
			self:addChild(t)
		end
		print(clue.."="..dict[v[1]][1])
	end
	y=y+5
	local t = TextField.new(ttf2,"** 세로힌트 **")
	t:setPosition(0,y)
	self:addChild(t)
	y=y+16
	local vclues = {}
	local num = #self.quiz[1]+1
	for i,v in ipairs(self.quiz[2]) do
		local duplicated = false
		local num2 = num
		for i2,v2 in ipairs(self.quiz[1]) do
			if v2[2]==v[2] and v2[3]==v[3] then
				num2=i2
				duplicated = true
				break
			end
		end
		local clue = num2.."."..dict[v[1]][2]
		vclues[#vclues+1] = {num2,clue,v[2],v[3],dict[v[1]][1]}
		if not duplicated then
			num = num + 1
		end
	end
	print("** 세로힌트 **")
	table.sort(vclues,function(a,b) return a[1]<b[1] end)
	for i,v in ipairs(vclues) do
		local t = TextField.new(ttf2,v[2])
		t:setPosition(0,y)
		self:addChild(t)
		y=y+16
		local x,y = v[3]-self.minx+1,v[4]-self.miny+1
		local t = TextField.new(ttf3,v[1])
		t:setPosition((x-1)*CELL_WIDTH+2,(y-1)*CELL_HEIGHT+ttf3:getAscender()+2)
		self:addChild(t)
		print(v[2].."="..v[5])
	end
end

