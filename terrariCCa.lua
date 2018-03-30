local engine = require "engine"

local elements = {}
elements.tilemap = engine.elements.new.tilemap({
  offset = {0, 0},
  tileset = engine.elements.new.tileset({
    air = {texture = engine.elements.new.texture({{" ", "3", "3"}})},
    grass = {texture = engine.elements.new.texture({{" ", "7", "d"}}),solid = true, behind = "dirt"},
    plant = {texture = engine.elements.new.texture({{"p", "d", "3"}})},
    dirt = {texture = engine.elements.new.texture({{" ", "7", "c"}}), solid = true, behind = "wall"},
    stone = {texture = engine.elements.new.texture({{" ", "f", "8"}}), solid = true, behind = "wall"},
    leaves = {texture = engine.elements.new.texture({{"b", "5", "d"}}), behind = "air"},
    log = {texture = engine.elements.new.texture({{"B", "7", "c"}}), behind = "air"},
  }),
  createWall = function(self, tileName)
    local tile = self.tileset[tileName]
    self.tileset[tileName.."wall"] = {
      texture = engine.elements.new.texture({{"\127", tile.texture[1][3], "7"}})
    }
  end,
  changeMove = function(oldMove)
    local move = oldMove
    if math.random(1, 10) == 1 then
      if math.random(2) == 1 then
        move = 0.6
      else
        move = -0.6
      end
      if math.random(1, 10) == 1 then
        move = move * 2
      end
    elseif math.random(1, 10) == 1 then
      move = engine.math.reduce(oldMove)
    elseif math.random(1, 10) == 1 then
      move = move + 0.5
    elseif math.random(1, 10) == 1 then
      move = move - 0.5
    end
    if math.abs(move) >= 3 then
      engine.math.reduce(move)
    end
    return move
  end,
  generateLine = function(self, x, surfaceHeight, stoneHeight, height)
    self.set.rectangle(self, x, surfaceHeight, 1, height-surfaceHeight, "dirt")
    self.set.rectangle(self, x, stoneHeight, 1, height-stoneHeight, "stone")
    self.set.tile(self, x, surfaceHeight, "grass")
    if math.random(1, 5) == 1 then
      self.set.tile(self, x, surfaceHeight+1, "grass")
    end
    if math.random(1, 2) == 1 then
      self.set.tile(self, x, surfaceHeight-1, "plant")
    end
  end,
  addTree = function(self, x, trees, surfaceHeight, height)
    local height = math.random(4, 12)
    table.insert(trees, {
      x = x, y = surfaceHeight-height-1,
      height = height,
    })
    return trees
  end,
  generateStump = function(self, tree)
    for y = tree.y, tree.y+tree.height do
      self.set.tile(self, tree.x, y, "log")
    end
  end,
  generateLeaves = function(self, tree)
    self.set.sphere(self, tree.x, tree.y, tree.height/2, "leaves")
  end,
  generateWalls = function(self)
    for tileName, tile in pairs(self.tileset) do
      if tile.texture then
        self:createWall(tileName)
      end
    end
  end,
  generateTrees = function(self, trees)
    local generatedTrees = {}
    for treeNum = 1, #trees do
      local tree = trees[treeNum]
      if not generatedTrees[tree.x-1] and not generatedTrees[tree.x+1] then
        self:generateStump(tree)
        generatedTrees[tree.x] = true
      end
    end
    for treeNum = 1, #trees do
      local tree = trees[treeNum]
      if not generatedTrees[tree.x-1] and not generatedTrees[tree.x+1] then
        self:generateLeaves(tree)
        generatedTrees[tree.x] = true
      end
    end
  end,
  spawnPlayer = function(self)
    local y = 1
    while true do
      if self[elements.player.x][y] ~= "air" then
        elements.player.y = y-1
        return
      end
      y = y + 1
    end
  end,
  init = function(self)
    local trees = {}
    local width = engine.w*50
    local height = engine.h*20
    local surfaceY = math.floor(height/2)
    local surfaceHeight = surfaceY
    local stoneHeight = surfaceY+10
    local move = 0

    self:generateWalls()
    self.set.rectangle(self, 1, 1, width, height, "air")

    for x = 1, width do
      move = self.changeMove(move)
      stoneHeight = stoneHeight + move+math.random(3)-2
      surfaceHeight = surfaceHeight + move
      local tiledSurfaceHeight = math.floor(surfaceHeight)
      local tiledStoneHeight = math.floor(stoneHeight)
      if stoneHeight-surfaceHeight < 5 then stoneHeight = stoneHeight + 2 end

      self:generateLine(x, tiledSurfaceHeight, tiledStoneHeight, height)
      if math.floor(move) == 0 and math.random(1, 5) == 1 then
        trees = self:addTree(x, trees, tiledSurfaceHeight, height)
      end
    end

    self:spawnPlayer()
    self:generateTrees(trees)
  end
})
elements.player = engine.elements.new.kinematic({
  priority = true,
  tilemap = elements.tilemap,
  texture = engine.elements.new.texture({
    {" ", "4", "4"},
    {" ", "9", "9"}
  }),
  x = math.floor(engine.w*3/2), y = 3,
  maxJumpHeight = 6,
  breakBlock = function(self, tileX, tileY)
    local tileToSetOn = self.tilemap:getTile(tileX, tileY)
    if tileToSetOn then
      local tileToSet = tileToSetOn.behind
      local tileName = self.tilemap[tileX][tileY]
      if tileToSet == "wall" then
        tileToSet = tileName.."wall"
      end
      if tileToSet then
        if not self.tilemap.tileset[tileToSet] then
          self.tilemap:createWall(tileName)
        end
        self.tilemap.set.tile(self.tilemap, tileX, tileY, tileToSet)
      end
    end
  end,
  update = function(self)
    local offX, offY = engine.math.getOffset(engine.w, self.x), engine.math.getOffset(engine.h, self.y)
    self.offX, self.offY = offX, offY
    self.tilemap.offX, self.tilemap.offY = offX, offY
    if engine.mouse.left then
      self:breakBlock(engine.mouse.x-offX, engine.mouse.y-offY)
    end
  end
})
elements.inventory = engine.elements.new.inventory({
  x = 3, y = 3, slotNum = 5
})


engine.run(elements, 0.001)
