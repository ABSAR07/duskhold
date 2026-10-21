extends GutTest
## Pitfall 3, P3: NavGrid sizes its cell grid from every plot position, so a plot outside the
## current content box would change the flow field's layout. The shipped prototype map's grid is
## pinned here on purpose: origin (-82, -82), 82 by 67 cells of 2.0 m. The castle plot (plan 05-02)
## and every plot the later economy plans add must lie inside the box; a plan that moves the layout
## has to say so and re-pin it deliberately.

const PROTOTYPE := "res://data/maps/prototype_map.tres"
const ORIGIN := Vector2(-82.0, -82.0)
const WIDTH: int = 82
const HEIGHT: int = 67
const CELL_M: float = 2.0
const CASTLE: StringName = &"castle_plot"


func _grid() -> NavGrid:
	return NavGrid.new(load(PROTOTYPE))


func test_the_shipped_grid_keeps_its_origin() -> void:
	assert_eq(_grid().origin(), ORIGIN, "origin (-82, -82)")


func test_the_shipped_grid_keeps_its_width_and_height() -> void:
	var grid: NavGrid = _grid()
	assert_eq(grid.width(), WIDTH, "82 cells wide")
	assert_eq(grid.height(), HEIGHT, "67 cells high")


func test_the_cells_are_two_metres() -> void:
	assert_eq(_grid().cell_size(), CELL_M, "2.0 m cells")


func test_the_castle_plot_lies_inside_the_grid() -> void:
	var grid: NavGrid = _grid()
	var map: MapConfig = load(PROTOTYPE)
	for spot: BuildSpotDef in map.spots:
		if spot.id == CASTLE:
			var cell: int = grid.cell_of(Vector2(spot.position.x, spot.position.z))
			assert_gte(cell, 0, "the castle plot is inside the grid")
			return
	fail_test("the map has no castle plot")


func test_every_plot_lies_inside_the_grid() -> void:
	var grid: NavGrid = _grid()
	var map: MapConfig = load(PROTOTYPE)
	for spot: BuildSpotDef in map.spots:
		var cell: int = grid.cell_of(Vector2(spot.position.x, spot.position.z))
		assert_gte(cell, 0, "%s is inside the grid" % spot.id)


func test_the_grid_is_inside_the_cell_cap() -> void:
	var grid: NavGrid = _grid()
	assert_lte(grid.width() * grid.height(), NavGrid.MAX_NAV_CELLS, "inside the cell cap")
