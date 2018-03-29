local engine = require "engine"

local elements = {}
elements.tilemap = engine.elements.new.tilemap({
  offset = {0, 0},
  tileset = engine.elements.new.tileset({
    air = {texture = engine.elements.new.texture({{" ", "3", "3"}})},
    grass = {texture = engine.elements.new.texture({{" ", "7", "d"}}),solid = true, behind = "dirt"},
    dirt = {texture = engine.elements.new.texture({{" ", "7", "c"}}), solid = true, behind = "wall"}
  }),
  init = function(self)
    local width = engine.w*3
    local height = engine.h*3
    local surfaceY = math.floor(height/2)
    self.set.rectangle(self, 1, 1, width, height, "air")
    self.set.rectangle(self, 1, surfaceY, width, surfaceY, "dirt")
    self.set.rectangle(self, 1, surfaceY, width, 1, "grass")
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
  init = function(self)
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


engine.run(elements, 0.01)
