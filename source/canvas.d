module canvas;

import raylib;

struct SpatialHash
{
	int[][int] grid;
	float cellSize;

	void clear()
	{
		grid.clear();
	}

	int cellKey(float x, float y)
	{
		int cx = cast(int)(x / cellSize);
		int cy = cast(int)(y / cellSize);
		return cx * 10000 + cy;
	}

	void insert(int idx, float x, float y)
	{
		grid[cellKey(x, y)] ~= idx;
	}

	int[] nearby(float x, float y)
	{
		int[] result;
		int cx = cast(int)(x / cellSize);
		int cy = cast(int)(y / cellSize);
		foreach (dx; -1 .. 2)
			foreach (dy; -1 .. 2)
			{
				auto key = (cx + dx) * 10000 + (cy + dy);
				if (auto cell = key in grid)
					result ~= *cell;
			}
		return result;
	}
}