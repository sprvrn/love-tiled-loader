# lovely-tiles

Import [Tiled](https://www.mapeditor.org/) files and render it in [löve2d](https://love2d.org/).

Dependency : [classic.lua](https://github.com/rxi/classic)

## Example

In Tiled, export your map as lua file
```lua
local lvt = require "lovelytiles"

love.load = function()
	map = lvt.new("assets/maps/test.lua")
  -- or
  -- map = lvt.new(require("assets.maps.test"))
end

love.update = function(dt)
	map:update(dt)
end

love.draw = function()
	map:draw()
end
```
**lvt.new(map,startx,starty,width,height,layers,initObjects)**
* map : the file path as a string, or a table (the actual content of the lua file from Tiled)
* startx, starty : default 0
* width, height : the size of the map
* layers : a table of string elements containing the layers to draw (default {} or nil > draw all the layers)
* initObjects : a table of functions to call when creating objects (example : {{type=objectType,call=function(obj,x,y,map)  end}} )

## Advance
```lua
local lvt = require "lovelytiles"

player = {}
coins = {}

love.load = function()
	local initObjects = {
		{
			type="player",
			call = function(obj,x,y,map)
				player = {x=x,y=y,life=obj.properties.life}
			end
		},
		{
			type="coin",
			call = function(obj,x,y,map)
				table.insert(coins, {x=x,y=y})
			end
		}
	}
	map = lvt.new("assets/maps/test.lua",32,32,16,16,{"water","ground"},initObjects)
end

love.update = function(dt)
	map:update(dt)
end

love.draw = function()
	map:draw()

	love.graphics.rectangle("fill", player.x, player.y, 8, 8)

	for i=1,#coins do
		love.graphics.circle("fill", coins[i].x, coins[i].y, 4)
	end
end
```
You can iterate through the objects and tiles like this 
```lua
for _,objgrp in pairs(map:getObjectGroups()) do
	print(objgrp.name)
	for _,obj in pairs(objgrp.objects) do
		print(obj.name,obj.x,obj.y,obj.properties)
	end
end

for _,layer in pairs(map.layers) do
	if layer.type == "tilelayer" then
	    for x,t in pairs(layer.tiles) do
			for y,tile in pairs(t) do
				print(layer.name,x,y,tile.tileset,tile.properties)
			end
		end
	end
end
```
