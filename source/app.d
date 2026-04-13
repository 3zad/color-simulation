import raylib;

import std.random;
import std.stdio;
import std.conv;
import std.math;

struct Ball
{
	float x;
	float y;
	float radius;
	float speedX;
	float speedY;
	Color color;

	void update(float width, float height)
	{
		int border = 25;

		x += speedX;
		y += speedY;

		if (x - radius < border && speedX < 0)
		{
			speedX *= -1;
		}
		else if (x + radius > width - border && speedX > 0)
		{
			speedX *= -1;
		}
		if (y - radius < border && speedY < 0)
		{
			speedY *= -1;
		}
		else if (y + radius > height - border && speedY > 0)	
		{
			speedY *= -1;
		}

		draw();
	}

	void draw()
	{
		DrawCircle(cast(int) x, cast(int) y, radius, color);
	}
}

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

void main()
{
	validateRaylibBinding();
	SetTraceLogLevel(7);
	SetConfigFlags(ConfigFlags.FLAG_WINDOW_RESIZABLE);
	InitWindow(1000, 1000, "Hello, Raylib-D!");
	SetTargetFPS(6000);

	auto rnd = Random(unpredictableSeed);

	Ball[] balls;
	int numBalls = 1000;
	int colorPos = 0;

	float width = GetScreenWidth();
	float height = GetScreenHeight();
	foreach (i; 0 .. numBalls)
	{
		if (numBalls / 3 > i)
		{
			colorPos = 0;
		}
		else if (numBalls / 3 * 2 > i)
		{
			colorPos = 1;
		}
		else
		{
			colorPos = 2;
		}

		Ball ball;
		ball.radius = 5;
		ball.x = uniform(0.0f, width, rnd);
		ball.y = uniform(0.0f, height, rnd);
		ball.speedX = uniform(-10.0f, 10.0f, rnd);
		ball.speedY = uniform(-10.0f, 10.0f, rnd);

		ubyte randUbyte = cast(ubyte) uniform(50.0f, 255.0f, rnd);
		switch (colorPos)
		{
		case 0:
			ball.color = Color(randUbyte, randUbyte, randUbyte);
			break;
		case 1:
			ball.color = Color(randUbyte, randUbyte, randUbyte);
			break;
		case 2:
			ball.color = Color(randUbyte, randUbyte, randUbyte);
			break;
		default:
			ball.color = Color(255, 255, 255);
		}

		balls ~= ball;
	}

	int[][] attractedTo;
	int[][] repelledFrom;
	attractedTo.length = balls.length;
	repelledFrom.length = balls.length;
	foreach (i, ref b1; balls)
		foreach (j, ref b2; balls)
		{
			if (i == j)
				continue;
			float cd = sqrt(cast(float)(
					(b1.color.r - b2.color.r) ^^ 2 +
					(
					b1.color.g - b2.color.g) ^^ 2 +
					(b1.color.b - b2.color.b) ^^ 2));
			if (cd < 25)
				attractedTo[i] ~= cast(int) j;
			else if (cd > 30)
				repelledFrom[i] ~= cast(int) j;
		}

	while (!WindowShouldClose())
	{
		BeginDrawing();
		ClearBackground(Colors.BLACK);
		width = GetScreenWidth();
		height = GetScreenHeight();

		SpatialHash sh;
		sh.cellSize = 50.0f;

		sh.clear();
		foreach (i, ref ball; balls)
			sh.insert(cast(int)i, ball.x, ball.y);

		foreach (i, ref ball; balls)
		{
			foreach (j; sh.nearby(ball.x, ball.y))
			{
				if (i == j) continue;
				ref ball2 = balls[j];

				foreach (k; attractedTo[i])
				{
					if (k == j)
					{
						float strength = 1.0f / 100.0f;
						ball.speedX += (ball2.x - ball.x) * strength * 0.01f;
						ball.speedY += (ball2.y - ball.y) * strength * 0.01f;
						break;
					}
				}

				foreach (k; repelledFrom[i])
				{
					if (k == j)
					{
						float strength = 1.0f / 500.0f;
						ball.speedX -= (ball2.x - ball.x) * strength * 0.01f;
						ball.speedY -= (ball2.y - ball.y) * strength * 0.01f;
						break;
					}
				}

				// --- Collision resolution ---
				float dx = ball.x - ball2.x;
				float dy = ball.y - ball2.y;
				float dist = sqrt(dx*dx + dy*dy);
				if (dist < ball.radius + ball2.radius && dist > 0)
				{
					float overlap = ball.radius + ball2.radius - dist;
					float angle = atan2(dy, dx);
					float cx = cos(angle) * overlap * 0.5f;
					float cy = sin(angle) * overlap * 0.5f;

					ball.x  += cx;  ball.y  += cy;
					ball2.x -= cx;  ball2.y -= cy;

					float tmpX = ball.speedX;
					float tmpY = ball.speedY;
					ball.speedX = ball2.speedX * 0.9f;
					ball.speedY = ball2.speedY * 0.9f;
					ball2.speedX = tmpX * 0.9f;
					ball2.speedY = tmpY * 0.9f;
				}
			}
			ball.update(cast(float)width, cast(float)height);
		}
		EndDrawing();
	}
	CloseWindow();
}
