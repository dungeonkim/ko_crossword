-- Each cell on the crossword grid is null or one of these
function CrosswordCell(letter){
    this.char = letter -- the actual letter for the cell on the crossword
    -- If a word hits this cell going in the "across" direction, this will be a CrosswordCellNode
    this.across = null 
    -- If a word hits this cell going in the "down" direction, this will be a CrosswordCellNode
    this.down = null
end

-- You can tell if the Node is the start of a word (which is needed if you want to number the cells)
-- and what word and clue it corresponds to (using the index)
function CrosswordCellNode(is_start_of_word, index){
    this.is_start_of_word = is_start_of_word
    this.index = index -- use to map this node to its word or clue
end

function WordElement(word, index){
    this.word = word -- the actual word
    this.index = index -- use to map this node to its word or clue
end

Crossword = Core.class()

function Crossword:init(words_in, clues_in)
    local GRID_ROWS = 50
    local GRID_COLS = 50
    -- This is an index of the positions of the char in the crossword (so we know where we can potentially place words)
    -- example {"a" : [{'row' : 10, 'col' : 5}, {'row' : 62, 'col' :17}], {'row' : 54, 'col' : 12}], "b" : [{'row' : 3, 'col' : 13}]} 
    -- where the two item arrays are the row and column of where the letter occurs
    local char_index = {}	

    -- these words are the words that can't be placed on the crossword
    local bad_words

    -- constructor
    if(words_in.length < 2) throw "A crossword must have at least 2 words"
    if(words_in.length != clues_in.length) throw "The number of words must equal the number of clues"	

    -- build the grid
    local grid = new Array(GRID_ROWS)
    for(local i = 0 i < GRID_ROWS i++){
        grid[i] = new Array(GRID_COLS)	
    }

    -- build the element list (need to keep track of indexes in the originial input arrays)
    local word_elements = []	
    for(local i = 0 i < words_in.length i++){
        word_elements.push(new WordElement(words_in[i], i))
    }

    -- I got this sorting idea from http:--stackoverflow.com/questions/943113/algorithm-to-generate-a-crossword/1021800#1021800
    -- seems to work well
    word_elements.sort(function(a, b){ return b.word.length - a.word.length })
end


-- returns the crossword grid that has the ratio closest to 1 or null if it can't build one
function Crossword:getSquareGrid(max_tries)
	local best_grid = null
	local best_ratio = 0
	for(local i = 0 i < max_tries i++){
		local a_grid = this.getGrid(1)
		if(a_grid == null) continue
		local ratio = Math.min(a_grid.length, a_grid[0].length) * 1.0 / Math.max(a_grid.length, a_grid[0].length)
		if(ratio > best_ratio){
			best_grid = a_grid
			best_ratio = ratio
		}

		if(best_ratio == 1) break
	}
	return best_grid
end

-- returns an abitrary grid, or null if it can't build one
function Crossword:getGrid(max_tries)
	for(local tries = 0 tries < max_tries tries++){
		clear() -- always start with a fresh grid and char_index
		-- place the first word in the middle of the grid
		local start_dir = randomDirection()
		local r = Math.floor(grid.length / 2)
		local c = Math.floor(grid[0].length / 2)
		local word_element = word_elements[0]
		if(start_dir == "across"){
			c -= Math.floor(word_element.word.length/2)
		} else {
			r -= Math.floor(word_element.word.length/2)
		}

		if(canPlaceWordAt(word_element.word, r, c, start_dir) !== false){
			placeWordAt(word_element.word, word_element.index, r, c, start_dir)
		} else {
			bad_words = [word_element]
			return null
		}

		-- start with a group containing all the words (except the first)
		-- as we go, we try to place each word in the group onto the grid
		-- if the word can't go on the grid, we add that word to the next group 
		local groups = []
		groups.push(word_elements.slice(1))
		for(local g = 0 g < groups.length g++){
			word_has_been_added_to_grid = false
			-- try to add all the words in this group to the grid
			for(local i = 0 i < groups[g].length i++){
				local word_element = groups[g][i] 
				local best_position = findPositionForWord(word_element.word)
				if(!best_position){ 
					-- make the new group (if needed)
					if(groups.length - 1 == g) groups.push([])
					-- place the word in the next group
					groups[g+1].push(word_element)
				} else {
					local r = best_position["row"], c = best_position["col"], dir = best_position['direction']
					placeWordAt(word_element.word, word_element.index, r, c, dir)
					word_has_been_added_to_grid = true						
				}
			}
			-- if we haven't made any progress, there is no point in going on to the next group
			if(!word_has_been_added_to_grid) break
		}
		-- no need to try again
		if(word_has_been_added_to_grid) return minimizeGrid()  
	}

	bad_words = groups[groups.length - 1]
	return null
end

-- returns the list of WordElements that can't fit on the crossword
function Crossword:getBadWords()
	return bad_words
end

-- get two arrays ("across" and "down") that contain objects describing the
-- topological position of the word (e.g. 1 is the first word starting from
-- the top left, going to the bottom right), the index of the word (in the
-- original input list), the clue, and the word itself
function Crossword:getLegend(grid)
	local groups = {"across" : [], "down" : []}
	local position = 1
	for(local r = 0 r < grid.length r++){	
		for(local c = 0 c < grid[r].length c++){
			local cell = grid[r][c]
			local increment_position = false
			-- check across and down
			for(local k in groups){
				-- does a word start here? (make sure the cell isn't null, first)
				if(cell && cell[k] && cell[k]['is_start_of_word']){
					local index = cell[k]['index']
					groups[k].push({"position" : position, "index" : index, "clue" : clues_in[index], "word" : words_in[index]})
					increment_position = true
				}
			}

			if(increment_position) position++
		}
	}
	return groups
end	

-- move the grid onto the smallest grid that will fit it
local function minimizeGrid(self)
	-- find bounds
	local r_min = GRID_ROWS-1, r_max = 0, c_min = GRID_COLS-1, c_max = 0
	for(local r = 0 r < GRID_ROWS r++){
		for(local c = 0 c < GRID_COLS c++){
			local cell = grid[r][c]
			if(cell != null){
				if(r < r_min) r_min = r
				if(r > r_max) r_max = r
				if(c < c_min) c_min = c
				if(c > c_max) c_max = c
			}
		}
	}
	-- initialize new grid
	local rows = r_max - r_min + 1 
	local cols = c_max - c_min + 1 
	local new_grid = new Array(rows)
	for(local r = 0 r < rows r++){
		for(local c = 0 c < cols c++){
			new_grid[r] = new Array(cols)
		}
	}

	-- copy the grid onto the smaller grid
	for(local r = r_min, r2 = 0 r2 < rows r++, r2++){
		for(local c = c_min, c2 = 0 c2 < cols c++, c2++){
			new_grid[r2][c2] = grid[r][c]
		}
	}

	return new_grid
end

-- helper for placeWordAt()
local function addCellToGrid(self,word, index_of_word_in_input_list, index_of_char, r, c, direction)
	local char = word.charAt(index_of_char)
	if(grid[r][c] == null){
		grid[r][c] = new CrosswordCell(char)

		-- init the char_index for that character if needed
		if(!char_index[char]) char_index[char] = []

		-- add to index
		char_index[char].push({"row" : r, "col" : c})
	}

	local is_start_of_word = index_of_char == 0
	grid[r][c][direction] = new CrosswordCellNode(is_start_of_word, index_of_word_in_input_list)

end	

-- place the word at the row and col indicated (the first char goes there)
-- the next chars go to the right (across) or below (down), depending on the direction
local function placeWordAt(self,word, index_of_word_in_input_list, row, col, direction)
	if(direction == "across"){
		for(local c = col, i = 0 c < col + word.length c++, i++){
			addCellToGrid(word, index_of_word_in_input_list, i, row, c, direction)
		}
	} else if(direction == "down"){
		for(local r = row, i = 0 r < row + word.length r++, i++){
			addCellToGrid(word, index_of_word_in_input_list, i, r, col, direction)
		}			
	} else {
		throw "Invalid Direction"	
	}
end

-- you can only place a char where the space is blank, or when the same
-- character exists there already
-- returns false, if you can't place the char
-- 0 if you can place the char, but there is no intersection
-- 1 if you can place the char, and there is an intersection
local function canPlaceCharAt(self,char, row, col)
	-- no intersection
	if(grid[row][col] == null) return 0
	-- intersection!
	if(grid[row][col]['char'] == char) return 1

	return false
end

-- determines if you can place a word at the row, column in the direction
local function canPlaceWordAt(self,word, row, col, direction)
	-- out of bounds
	if(row < 0 || row >= grid.length || col < 0 || col >= grid[row].length) return false

	if(direction == "across"){
		-- out of bounds (word too long)
		if(col + word.length > grid[row].length) return false
		-- can't have a word directly to the left
		if(col - 1 >= 0 && grid[row][col - 1] != null) return false
		-- can't have word directly to the right
		if(col + word.length < grid[row].length && grid[row][col+word.length] != null) return false

		-- check the row above to make sure there isn't another word
		-- running parallel. It is ok if there is a character above, only if
		-- the character below it intersects with the current word
		for(local r = row - 1, c = col, i = 0 r >= 0 && c < col + word.length c++, i++){
			local is_empty = grid[r][c] == null
			local is_intersection = grid[row][c] != null && grid[row][c]['char'] == word.charAt(i)
			local can_place_here = is_empty || is_intersection
			if(!can_place_here) return false
		}

		-- same deal as above, we just search in the row below the word
		for(local r = row + 1, c = col, i = 0 r < grid.length && c < col + word.length c++, i++){
			local is_empty = grid[r][c] == null
			local is_intersection = grid[row][c] != null && grid[row][c]['char'] == word.charAt(i)
			local can_place_here = is_empty || is_intersection
			if(!can_place_here) return false
		}

		-- check to make sure we aren't overlapping a char (that doesn't match)
		-- and get the count of intersections
		local intersections = 0
		for(local c = col, i = 0 c < col + word.length c++, i++){
			local result = canPlaceCharAt(word.charAt(i), row, c)
			if(result === false) return false
			intersections += result
		}
	} else if(direction == "down"){
		-- out of bounds
		if(row + word.length > grid.length) return false
		-- can't have a word directly above
		if(row - 1 >= 0 && grid[row - 1][col] != null) return false
		-- can't have a word directly below
		if(row + word.length < grid.length && grid[row+word.length][col] != null) return false

		-- check the column to the left to make sure there isn't another
		-- word running parallel. It is ok if there is a character to the
		-- left, only if the character to the right intersects with the
		-- current word
		for(local c = col - 1, r = row, i = 0 c >= 0 && r < row + word.length r++, i++){
			local is_empty = grid[r][c] == null
			local is_intersection = grid[r][col] != null && grid[r][col]['char'] == word.charAt(i)
			local can_place_here = is_empty || is_intersection
			if(!can_place_here) return false
		}

		-- same deal, but look at the column to the right
		for(local c = col + 1, r = row, i = 0 r < row + word.length && c < grid[r].length r++, i++){
			local is_empty = grid[r][c] == null
			local is_intersection = grid[r][col] != null && grid[r][col]['char'] == word.charAt(i)
			local can_place_here = is_empty || is_intersection
			if(!can_place_here) return false
		}

		-- check to make sure we aren't overlapping a char (that doesn't match)
		-- and get the count of intersections
		local intersections = 0
		for(local r = row, i = 0 r < row + word.length r++, i++){
			local result = canPlaceCharAt(word.charAt(i, 1), r, col)
			if(result === false) return false
			intersections += result
		}
	} else {
		throw "Invalid Direction"	
	}
	return intersections
}

local function randomDirection(self)
	return Math.floor(Math.random()*2) ? "across" : "down"
end

local function findPositionForWord(self,word)
	-- check the char_index for every letter, and see if we can put it there in a direction
	local bests = []
	for(local i = 0 i < word.length i++){
		local possible_locations_on_grid = char_index[word.charAt(i)]
		if(!possible_locations_on_grid) continue
		for(local j = 0 j < possible_locations_on_grid.length j++){
			local point = possible_locations_on_grid[j]
			local r = point['row']
			local c = point['col']
			-- the c - i, and r - i here compensate for the offset of character in the word
			local intersections_across = canPlaceWordAt(word, r, c - i, "across")
			local intersections_down = canPlaceWordAt(word, r - i, c, "down")

			if(intersections_across !== false)
				bests.push({"intersections" : intersections_across, "row" : r, "col" : c - i, "direction" : "across"})
			if(intersections_down !== false)
				bests.push({"intersections" : intersections_down, "row" : r - i, "col" : c, "direction" : "down"})
		}
	}

	if(bests.length == 0) return false

	-- find a good random position
	local best = bests[Math.floor(Math.random()*bests.length)]

	return best
end

local function clear(self)
	for(local r = 0 r < grid.length r++){
		for(local c = 0 c < grid[r].length c++){
			grid[r][c] = null
		}
	}
	char_index = {}
end

CrosswordUtils = Core.class()

CrosswordUtils.PATH_TO_PNGS_OF_NUMBERS = "numbers/"

function CrosswordUtils:toHtml(grid, show_answers)
	if grid == nil then return end
	local html = ""
	html = htm .. "<table class='crossword'>\n"
	local label = 1
	for r = 1, grid.length do
		html = html.. "<tr>\n"
		for c = 1, #grid[r].length
			local cell = grid[r][c]
			local is_start_of_word = false
			if cell == null then
				local char = "&nbsp"
				local css_class = "no-border"
			else 
				local char = cell['char']
				local css_class = ""
				local is_start_of_word = (cell['across'] and cell['across']['is_start_of_word']) or (cell['down'] and cell['down']['is_start_of_word'])
			end

			if is_start_of_word then
				local img_url = CrosswordUtils.PATH_TO_PNGS_OF_NUMBERS + label + ".png"
				html = html .. "<td class='" .. css_class .. "' title='" .. r .. ", " .. c .. "' style=\"background-image:url('" .. img_url .. "')\">\n"
				label = label + 1
			else
				html = html .. "<td class='" .. css_class .. "' title='" .. r .. ", " .. c .. "'>\n"			
			end

			if show_answers then
				html = html .. char
			else
				html = html .. "&nbsp"
			end
		}
		html = html .. "</tr>\n"
	}
	html = html .. "</table>\n"
	return html
end

