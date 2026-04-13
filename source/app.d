import raylib;

import std.random;
import std.stdio;
import std.conv;
import std.math;

// global variables
float width = 500;
float height = 500;

int border = 25;
int radius = 5;
int numBalls = 1000;
float cellSize = 250.0f;
float repelCellSizeFactor = 5.0f;
float attractFactor = 1.0f / 100.0f;
float repelFactor;
int attractThreshold = 15;
int repelThreshold = 25;
float friction = 0.97f;

float maxSpeed = 5.0f;

static this()
{
	repelFactor = attractFactor * 10000.0f;
}

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
	InitWindow(to!int(width), to!int(height), "Hello, Raylib-D!");
	SetTargetFPS(6000);
	auto rnd = Random(unpredictableSeed);

	Ball[] balls;
	int colorPos = 0;

	width = GetScreenWidth();
	height = GetScreenHeight();
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
		ball.radius = radius;
		ball.x = uniform(0.0f, width, rnd);
		ball.y = uniform(0.0f, height, rnd);
		ball.speedX = uniform(-maxSpeed, maxSpeed, rnd);
		ball.speedY = uniform(-maxSpeed, maxSpeed, rnd);

		ubyte randUbyte = cast(ubyte) uniform(50.0f, 255.0f, rnd);
		switch (colorPos)
		{
		case 0:
			ball.color = Color(0, randUbyte/2, randUbyte);
			break;
		case 1:
			ball.color = Color(randUbyte, 0, randUbyte/2);
			break;
		case 2:
			ball.color = Color(randUbyte/2, randUbyte, 0);
			break;
		default:
			ball.color = Color(255, 255, 255);
		}

		ball.color = Color(randUbyte, randUbyte, randUbyte);

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
				cast(int)(b1.color.r - b2.color.r) ^^ 2 +
				cast(int)(b1.color.g - b2.color.g) ^^ 2 +
				cast(int)(b1.color.b - b2.color.b) ^^ 2));

			if (cd < attractThreshold)
				attractedTo[i] ~= cast(int) j;
			else if (cd > repelThreshold)
				repelledFrom[i] ~= cast(int) j;
		}

	while (!WindowShouldClose())
	{
		BeginDrawing();
		ClearBackground(Colors.BLACK);
		width = GetScreenWidth();
		height = GetScreenHeight();

		SpatialHash sh;
		sh.cellSize = cellSize;

		sh.clear();
		foreach (i, ref ball; balls)
			sh.insert(cast(int)i, ball.x, ball.y);

		foreach (i, ref ball; balls)
		{
			float spd = sqrt(ball.speedX^^2 + ball.speedY^^2);
			if (spd > maxSpeed) {
				ball.speedX = ball.speedX / spd * maxSpeed;
				ball.speedY = ball.speedY / spd * maxSpeed;
			}
				
			foreach (j; attractedTo[i]) {
				ref ball2 = balls[j];
				float dx = ball2.x - ball.x;
				float dy = ball2.y - ball.y;
				float dist = sqrt(dx*dx + dy*dy);
				if (dist > 0) {
					float force = attractFactor * 0.01f / (dist * dist);
					ball.speedX += dx * force;
					ball.speedY += dy * force;
				}
			}
			foreach (j; repelledFrom[i]) {
				ref ball2 = balls[j];
				float dx = ball2.x - ball.x;
				float dy = ball2.y - ball.y;
				float dist = sqrt(dx*dx + dy*dy);
				if (dist > 0) {
					float force = repelFactor * 0.01f / (dist * dist);
					ball.speedX -= dx * force;
					ball.speedY -= dy * force;
				}
			}

			foreach (j; sh.nearby(ball.x, ball.y))
			{
				if (i == j) continue;
				ref ball2 = balls[j];


				// all balls slightly attracted to the center point
				ball.speedX += (width/2 - ball.x) * attractFactor * 0.001f;
				ball.speedY += (height/2 - ball.y) * attractFactor * 0.001f;

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
					ball.speedX = ball2.speedX * friction;
					ball.speedY = ball2.speedY * friction;
					ball2.speedX = tmpX * friction;
					ball2.speedY = tmpY * friction;
				}
			}
			ball.update(cast(float)width, cast(float)height);
		}
		EndDrawing();
	}
	CloseWindow();
}
