# lovely-tiles

Import [Tiled](https://www.mapeditor.org/) files and render it in [löve2d](https://love2d.org/).

*Note: some Tiled features might be missing*

## Example

In Tiled, export your map as lua file
```lua
local lvt = require "lovelytiles"

love.load = function()
	map = lvt.new("assets/maps/test.lua")
end

love.update = function(dt)
	map:update(dt) -- update the animated tiles
end

love.draw = function()
	map:draw()
end
```
**lvt.new(map, startx, starty, width, height, layers, initObjects)**
* map : the file path as a string, or a table (the actual content of the lua file from Tiled)
* startx, starty : default 0
* width, height : the size of the map (default: max width and height of the Tiled map)
* layers : a table of string elements containing the layers to draw (default {} or nil > draw all the layers)
* initObjects : a table of functions to call when creating objects (example : {{type=objectType,call=function(obj,x,y,map)  end}} )

## Advance
```lua
local lvt = require "lovelytiles"

coins = {}

love.load = function()
	map = lvt.new("assets/maps/test.lua", 32, 32, 16, 16, {"ground", "items"})
	
	map:foreach("object", function(map, layer, object)
		if (layer.name == "items") then
			table.insert(coins, {x=object.x, y=object.y})
		end
	end)
end

love.update = function(dt)
	map:update(dt)
end

love.draw = function()
	map:draw()

	for i=1,#coins do
		love.graphics.circle("fill", coins[i].x, coins[i].y, 4)
	end
end
```
In this example we only load and render the a 16x16 map, starting from 32,32. We also only load the layers "ground" and "items".
We add an element in 'coins' table for every Tiled object of "coin" type.

```lua
-- map:draw can take the same arguments of love.graphics.draw
map:draw(x, y, r, sx, sy, ox, oy, kx, ky)

-- you can iterate through the objects, tiles and layers like this:
map:foreach("object", function(map, layer, object)
end)

map:foreach("tile", function(map, layer, tile, x, y)
	-- note: x and y are the position in pixel of the tile
end)

map:foreach("layer", function(map, layer)
end)

-- get a layer object by its name
layer = map:getLayer("layer_name")

-- draw a layer
layer:draw(x, y, r, sx, sy, ox, oy, kx, ky)

-- get a tileset object by its name
tileset = map:getTileset("tileset_name")

-- get a tile
tile = layer:getTile(x, y)

-- remove a tile from a layer
layer:removeTile(x, y)

-- object:getDrawArguments(mode) returns the arguments ready to be use for love.graphics, depending on object.shape
-- mode is "line" or "fill" (default is "fill")
love.graphics.points(object:getDrawArguments()) -- object.shape == "point"
love.graphics.polygon(object:getDrawArguments()) -- object.shape == "polygon"
love.graphics.ellipse(object:getDrawArguments()) -- object.shape == "ellipse"
love.graphics.rectangle(object:getDrawArguments()) -- object.shape == "rectangle"
love.graphics.print(object:getDrawArguments()) -- object.shape == "print"
```

*Note*: if you hide a layer tile or an image layer in Tiled, it won't be renderer. You can also set a **boolean** property named "hide" and set it to true, lovelytiles will ignore it (a tile or a layer).

## Map
|attribute|type|note|
|-|-|-|
|width|number|width of the map file|
|height|number|height of the map file|
|startx|number||
|starty|number||
|mapWidth|number|width of the loaded map|
|mapHeight|number|height of the loaded map|
|orientation|string|"orthogonal" or "isometric"|
|tilewidth|number||
|tileheight|number||
|backgroundcolor|table||
|properties|table||
## Layer
|attribute|type|note|
|-|-|-|
|name|string||
|offsetx|number||
|offsety|number||
|width|number||
|height|number||
|visible|bool||
|tintcolor|table||
|opacity|number||
|properties|table||
## Tile
|attribute|type|note|
|-|-|-|
|x|number||
|y|number||
|data|TilesetTile||
|properties|table||
## Tileset
|attribute|type|note|
|-|-|-|
|name|string||
|tilewidth|number||
|tileheight|number||
|tilecount|number||
|image|[Image](https://love2d.org/wiki/Image)||
|imagewidth|number||
|imageheight|number||
|columns|number||
|spacing|number||
|margin|number||
|properties|table||
## TilesetTile
|attribute|type|note|
|-|-|-|
|x|number|x position of the tile in the tileset|
|y|number|y position of the tile in the tileset|
|tileset|Tileset||
|properties|table||
