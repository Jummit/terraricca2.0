local engine = {}
engine.w, engine.h = term.getSize()

engine.ui = {}
engine.ui = {
  isBoxClicked = function(box, x, y)
    return x>=box.x and y>=box.y and x<box.x+box.w and y<box.y+box.h
  end,
  codes = {
    red = "e",
    orange = 1,
    yellow = 4,
    black = "f",
    gray = 7,
    lightGray = 8,
    white = 1,
    blue = "b",
    cyan = 9,
    lightBlue = 3,
    green = "d",
    lime = 5,
    brown = "c",
    magenta = 2,
    pink = 6,
    purple = "a",
  },
  getColorOfPaintCode = function(code)
    for color, paintCode in pairs(engine.ui.paintColorCodes) do
      if paintCode == code then return color end
    end
  end
}

engine.mouseKeys = {"left", "right", "wheel"}
engine.mouse = {x = 0, y = 0}
engine.keyboard = {}
engine.eventHandler = {
  mouse_click = function(button, x, y)
    engine.mouse.x, engine.mouse.y = x, y
    engine.mouse[engine.mouseKeys[button]] = true
  end,
  mouse_up = function(button, x, y)
    engine.mouse.x, engine.mouse.y = x, y
    engine.mouse[engine.mouseKeys[button]] = false
    engine.mouse.dragged = false
  end,
  mouse_drag = function(button, x, y)
    engine.eventHandler.mouse_click(button, x, y)
    engine.mouse.dragged = true
  end,

  key = function(key)
    engine.keyboard[keys.getName(key)] = true
  end,
  key_up = function(key)
    engine.keyboard[keys.getName(key)] = false
  end,
  char = function(char)
    engine.keyboard[char] = true
  end
}

engine.math = {
  reduce = function(value)
    local returnValue = value
    if math.abs(value) ~= 0 then
      if value > 0 then
        returnValue = returnValue - 1
      else
        returnValue = returnValue + 1
      end
    end
  end,
  getOffset = function(w, pos)
    return math.floor(-pos+w/2)
  end
}

engine.elements = {}
engine.elements.methods = {
  element = true,
  moveAndCollide = function(self, xmove, ymove, tilemap)
    local canMove = true
    for x = self.x, self.x+self.w-1 do
      for y = self.y, self.y+self.h-1 do
        local tile = tilemap:getTile(x+xmove, y+ymove)
        if (not tile) or tile.solid then canMove = false end
      end
    end
    if canMove then
      self:move(xmove, ymove)
    end
  end,
  move = function(self, xmove, ymove)
    self.x = self.x + xmove
    self.y = self.y + ymove
  end
}
engine.elements.newElement = function(elementTable)
  return function(argTable)
    return setmetatable(argTable, {__index = setmetatable(elementTable, {__index = engine.elements.methods})})
  end
end
engine.elements.new = {
  template = engine.elements.newElement({
    INIT = function(self)
    end,
    UPDATE = function(self, event, var1, var2, var3)
    end,
    DRAW = function(self)
    end
  }),
  texture = engine.elements.newElement({
    offX = 0,
    offY = 0,
    getDimensions = function(self)
      local w = 1
      for rowNum = 1, #self do
        local row = self[rowNum][1]
        if #row > w then
          w = #row
        end
      end
      return w, #self
    end,
    INIT = function(self)
      self.w, self.h = self:getDimensions()
    end,
    DRAW = function(self)
      if self.x and self.y then
        self:drawTexture(self.x, self.y)
      end
    end,
    drawTexture = function(self, x, y, offX, offY)
      local drawX, drawY = x+(offX or 0)+self.offX, y+(offY or 0)+self.offY
      if not (drawX < 0 or drawX > engine.w or drawY < 0 or drawY > engine.h) then
        for row = 1, #self do
          local texture = self[row]
          term.setCursorPos(drawX, drawY+row-1)
          term.blit(texture[1], texture[2], texture[3])
        end
      end
    end,
    replaceColor = function(self, toReplaceColor, color)
      for row = 1, #self do
        local texture = self[row]
        for i = 2, #texture do
          texture[i] = string.gsub(texture[i], toReplaceColor, color)
        end
      end
    end
  }),
  button = engine.elements.newElement({
    clicked = false,
    INIT = function(self)
      self.mouse_drag = self.mouse_click
    end,
    mouse_click = function(self, button, x, y)
      if engine.ui.isBoxClicked(self, x, y) then
        self.clicked = true
        if self.clickedFunction then
          self:clickedFunction()
        end
      else
        self.clicked = false
      end
    end,
    mouse_up = function(self)
      if self.clicked then
        if self.releasedFunction then
          self:releasedFunction()
        end
        self.clicked = false
      end
    end,
    DRAW = function(self)
      local color = self.color
      if self.clicked then
        color = self.clickedColor
      end
      paintutils.drawFilledBox(self.x, self.y, self.x+self.w, self.y+self.h, color)
    end
  }),
  tileset = engine.elements.newElement({
  }),
  tilemap = engine.elements.newElement({
    INIT = function(self)
      self.w, self.h = 0, 0
    end,
    offset = {0, 0},
    DRAW = function(self)
      local offX, offY = self.offX or 0, self.offY or 0
      for x = 1, #self do
        for y = 1, #self[x] do
          local tile = self.tileset[self[x][y]]
          tile.texture:drawTexture(x, y, offX, offY)
        end
      end
    end,
    updateDimensions = function(self)
      local h = 0
      for rowNum = 1, #self do
        local row = self[rowNum]
        if #row > h then
          h = #row
        end
      end
      self.w, self.h = #self, h
    end,
    getTile = function(self, x, y)
      if self[x] then
        return self.tileset[self[x][y]]
      end
    end,
    set = {
      tile = function(self, x, y, tile)
        local tileToSet = tile
        if type(tile) == "table" then
          tileToSet = tile[math.random(#tile)]
        end
        if not self[x] then self[x] = {} end
        self[x][y] = tileToSet
        self:updateDimensions()
      end,
      rectangle = function(self, x, y, w, h, tile)
        for x = x, x+w-1 do
          for y = y, y+h-1 do
            self.set.tile(self, x, y, tile)
          end
        end
      end
    }
  }),
  kinematic = engine.elements.newElement({
    jumping = false,
    jumpedHeight = 0,
    w = 1, h = 1,
    moves = {
      left = {-1, 0},
      right = {1, 0}
    },
    INIT = function(self)
      self.w, self.h = self.texture:getDimensions()
    end,
    UPDATE = function(self)
      self.jumping = engine.keyboard.up
      if self.tilemap:getTile(self.x, self.y-1).solid then
        self.jumping = false
      end
    end,
    DRAW = function(self)
      self.texture:drawTexture(self.x, self.y, self.offX, self.offY)
    end,
    PHYSICSUPDATE = function(self)
      for key, move in pairs(self.moves) do
        if engine.keyboard[key] then
          self:moveAndCollide(move[1], move[2], self.tilemap)
        end
      end

      if self.jumping and self.jumpedHeight<self.maxJumpHeight then
        self:moveAndCollide(0, -1, self.tilemap)
        self.jumpedHeight = self.jumpedHeight + 1
      else
        self:moveAndCollide(0, 1, self.tilemap)
      end
      if self.tilemap:getTile(self.x, self.y+self.h).solid then
        self.jumpedHeight = 0
      end
    end
  }),
}

engine.elements.runFunction = function(elements, func, ...)
  local prioritys = {}
  for elementName, element in pairs(elements) do
    local priority = element.priority
    if priority then
      if priority == true then
        table.insert(prioritys, element)
      else
        prioritys[priority] = element
      end
    end
    if element.element then
      if element[func] then
        element[func](element, ...)
      end
    else
      engine.elements.runFunction(element, func, ...)
    end
  end
  for priorityNum = 1, #prioritys do
    local element = prioritys[priorityNum]
    if element[func] then
      element[func](element, ...)
    end
  end
end
engine.elements.init = function(elements)
  engine.elements.runFunction(elements, "INIT")
  engine.elements.runFunction(elements, "init")
end
engine.elements.update = function(elements, event, ...)
  engine.elements.runFunction(elements, "UPDATE", event, ...)
  engine.elements.runFunction(elements, "update", event, ...)
  engine.elements.runFunction(elements, event, ...)
end
engine.elements.physicsUpdate = function(elements)
  engine.elements.runFunction(elements, "PHYSICSUPDATE")
  engine.elements.runFunction(elements, "physicsUpdate")
end
engine.elements.draw = function(elements)
  engine.elements.runFunction(elements, "DRAW")
  engine.elements.runFunction(elements, "draw")
end

engine.run = function(elements, dt)
  engine.elements.init(elements)

  local dt = dt or 0.01
  local buffer = window.create(term.current(), 1, 1, engine.w, engine.h)
  local oldTerm = term.redirect(buffer)

  local succ, mess = pcall(function()
  local gameRunning = true
  local physicsUpdateTimer = os.startTimer(0.1)
  while gameRunning do
    buffer.setVisible(false)
    term.setBackgroundColor(colors.black)
    term.clear()
    engine.elements.draw(elements)
    buffer.setVisible(true)

    local event, var1, var2, var3 = os.pullEventRaw()
    if event == "timer" then
      engine.elements.physicsUpdate(elements)
      os.cancelTimer(physicsUpdateTimer)
      physicsUpdateTimer = os.startTimer(0.1)
    end
    if engine.eventHandler[event] then
      engine.eventHandler[event](var1, var2, var3)
    end
    if event == "char" and var1 == "q" then gameRunning = false end
    engine.elements.update(elements, event, var1, var2, var3)
  end
  end)

  buffer.setVisible(true)
  term.setBackgroundColor(colors.black)
  term.clear()
  term.setCursorPos(1, 1)
  term.setTextColor(colors.red)
  if not succ and mess then
    print("The game crashed!")
    print("Error: "..tostring(mess))
  end
end

return engine
