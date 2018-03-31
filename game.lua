local engine = require "engine"
local gameRunning = true
local elements = {}
elements = {
  button = engine.elements.new.button({
    x = 10, y = 10, w = 10, h = 4,
    color = colors.gray,
    clickedColor = colors.lightGray,
    clickedFunction = function(self)
      elements.apple:replaceColor("7", "8")
    end,
    releasedFunction = function(self)
      self:moveAndCollide(0, 1, elements.tilemap)
      self:moveAndCollide(1, 0, elements.tilemap)
      elements.apple:replaceColor("8", "7")
    end,
    draw = function(self)
      elements.apple:drawTexture(self.x+self.w/2, self.y+self.h/2-1)
    end,
    priority = true
  }),
  apple = engine.elements.new.texture({
    {"\155\159", "7d", "c7"},
    {"\129\130", "77", "ee"},
    {"\139\135", "ee", "77"}
  }),
  tilemap = engine.elements.new.tilemap({
    mouse_click = function(self, button, x, y)
      if not elements.button.clicked then
        self.set.tile(self, x, y, {"wall", "wall", "grass", "floor"})
      end
    end,
    tileset = engine.elements.new.tileset({
      grass = {
        texture = engine.elements.new.texture({{",", "5", "d"}})
      },
      floor = {
        texture = engine.elements.new.texture({{" ", "d", "d"}})
      },
      wall = {
        texture = engine.elements.new.texture({{" ", "7", "7"}}),
        solid = true
      }
    }),
    init = function(self)
      self.mouse_drag = self.mouse_click
      self.set.rectangle(self, 1, 1, 30, 20, {"floor", "floor", "floor", "grass"})
      self.set.rectangle(self, 4, 4, 4, 4, "wall")
    end
  })
}

engine.run(elements)
