local engine = require "engine"

local elements = {}
elements.tilemap = engine.elements.new.tilemap({
  offset = {0, 0},
  tileset = engine.elements.new.tileset({
    air = {texture = engine.elements.new.texture({{" ", "3", "3"}})},
    grass = {texture = engine.elements.new.texture({{" ", "7", "d"}}),solid = true, behind = "dirt"},
    plant = {texture = engine.elements.new.texture({{"p", "d", "3"}})},
    dirt = {texture = engine.elements.new.texture({{" ", "7", "c"}}), solid = true, behind = "wall"},
    stone = {texture = engine.elements.new.texture({{" ", "f", "8"}}), solid = true, behind = "wall"}
  }),
  init = function(self)
    local width = engine.w*50
    local height = engine.h*10
    local surfaceY = math.floor(height/2)

    local surfaceHeight = surfaceY
    local stoneHeight = surfaceY+10
    local move = 0
    self.set.rectangle(self, 1, 1, width, height, "air")
    for x = 1, width do
      if math.random(1, 10) == 1 then
        local oldMove
        if math.random(2) == 1 then
          move = 1
        else
          move = -1
        end
      elseif math.random(1, 5) == 1 then
        move = engine.math.reduce(move)
      end
      stoneHeight = stoneHeight + move+math.random(3)-2
      surfaceHeight = surfaceHeight + move
      if stoneHeight-surfaceHeight < 5 then stoneHeight = stoneHeight + 2 end
      self.set.rectangle(self, x, surfaceHeight, 1, height-surfaceHeight, "dirt")
      self.set.rectangle(self, x, stoneHeight, 1, height-stoneHeight, "stone")
      self.set.tile(self, x, surfaceHeight, "grass")
      if math.random(1, 10+move) == 1 then
        self.set.tile(self, x, surfaceHeight-1, "plant")
      end
    end
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
        if not self.tilemap.tileset[tileName.."wall"] then
          local tile = self.tilemap.tileset[tileName]
          self.tilemap.tileset[tileName.."wall"] = {
            texture = engine.elements.new.texture({{"\127", "7", tile.texture[1][3]}})
          }
        end
        tileToSet = tileName.."wall"
      end
      if tileToSet then
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


engine.run(elements, 0.001)
