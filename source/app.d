import raylib;

import std.random;
import std.stdio;
import std.conv;
import std.range : iota;
import std.math;
import std.algorithm;

// global variables
float width = 500;
float height = 500;

int border = 25;
int radius = 5;
int numBalls = 56;
float cellSize = 250.0f;
float repelCellSizeFactor = 5.0f;
float attractFactor = 20f;
float repelFactor = 40f;
int attractThreshold = 56 + 3;
int repelThreshold = 56 + 5;
float friction = 0.4535396f;

float maxSpeed = 0.25f;

void printAllGlobals()
{
	writeln("width: ", width);
	writeln("height: ", height);
	writeln("border: ", border);
	writeln("radius: ", radius);
	writeln("numBalls: ", numBalls);
	writeln("cellSize: ", cellSize);
	writeln("repelCellSizeFactor: ", repelCellSizeFactor);
	writeln("attractFactor: ", attractFactor);
	writeln("repelFactor: ", repelFactor);
	writeln("attractThreshold: ", attractThreshold);
	writeln("repelThreshold: ", repelThreshold);
	writeln("friction: ", friction);
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

		speedX = clamp(speedX, -maxSpeed, maxSpeed) * 0.98f;
		speedY = clamp(speedY, -maxSpeed, maxSpeed) * 0.98f;

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

	width = GetScreenWidth();
	height = GetScreenHeight();
	foreach (i; iota!ubyte(10, 255, numBalls))
	{
		ubyte r = cast(ubyte) i;
		foreach (j; iota!ubyte(10, 255, numBalls))
		{
			ubyte g = cast(ubyte) j;
			foreach (k; iota!ubyte(10, 255, numBalls))
			{
				ubyte b = cast(ubyte) k;
				Ball ball;
				ball.radius = radius;
				ball.x = uniform(0.0f, width, rnd);
				ball.y = uniform(0.0f, height, rnd);
				ball.speedX = uniform(-1.0f, 1.0f, rnd);
				ball.speedY = uniform(-1.0f, 1.0f, rnd);

				ball.color = Color(r, g, b);

				balls ~= ball;
			}
		}
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
				
			ball.speedX *= 0.98f;
			ball.speedY *= 0.98f;

			foreach (j; attractedTo[i]) {
				ref ball2 = balls[j];
				float dx = ball2.x - ball.x;
				float dy = ball2.y - ball.y;
				float dist = sqrt(dx*dx + dy*dy);
				float touchDist = ball.radius + ball2.radius + 2;
				if (dist > touchDist) {  // only attract when NOT already touching
					float force;
					if (dist < 40.0f)
						force = attractFactor * 0.1f;
					else
						force = attractFactor * 0.1f;
					ball.speedX += (dx / dist) * force;
					ball.speedY += (dy / dist) * force;
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
				float cx = ball.x - width/2;
				float cy = ball.y - height/2;
				float distFromCenter = sqrt(cx*cx + cy*cy);
				float targetRadius = 90.0f;
				float radialForce = (distFromCenter - targetRadius) * 0.0005f;
				ball.speedX -= (cx / distFromCenter) * radialForce;
				ball.speedY -= (cy / distFromCenter) * radialForce;

				// --- Collision resolution ---
				float dx = ball.x - ball2.x;
				float dy = ball.y - ball2.y;
				float dist = sqrt(dx*dx + dy*dy);
				if (dist < ball.radius + ball2.radius && dist > 0)
				{
					float overlap = ball.radius + ball2.radius - dist;
					float angle = atan2(dy, dx);
					cx = cos(angle) * overlap * 0.5f;
					cy = sin(angle) * overlap * 0.5f;

					ball.x  += cx;  ball.y  += cy;
					ball2.x -= cx;  ball2.y -= cy;

					bool isAttracted = false;
					bool isRepelled = false;
					foreach (k; attractedTo[i])
						if (j == k) { isAttracted = true; break; }
					foreach (k; repelledFrom[i])
						if (j == k) { isRepelled = true; break; }

					if (isAttracted)
					{
						float avgX = (ball.speedX + ball2.speedX) * 0.5f;
						float avgY = (ball.speedY + ball2.speedY) * 0.5f;
						float stickDamp = 0.05f;
						ball.speedX  = avgX * stickDamp;
						ball.speedY  = avgY * stickDamp;
						ball2.speedX = avgX * stickDamp;
						ball2.speedY = avgY * stickDamp;
					}
					else if (isRepelled)
					{
						float tmpX = ball.speedX;
						float tmpY = ball.speedY;
						ball.speedX  = ball2.speedX * friction;
						ball.speedY  = ball2.speedY * friction;
						ball2.speedX = tmpX * friction;
						ball2.speedY = tmpY * friction;
					}
				}
			}
			ball.update(cast(float)width, cast(float)height);
		}
		if (IsKeyPressed(KeyboardKey.KEY_Q))
			attractFactor *= 2;
		else if (IsKeyPressed(KeyboardKey.KEY_A))
			attractFactor /= 2;
		else if (IsKeyPressed(KeyboardKey.KEY_W))
			repelFactor *= 2;
		else if (IsKeyPressed(KeyboardKey.KEY_S))
			repelFactor /= 2;
		else if (IsKeyDown(KeyboardKey.KEY_E))
			friction = min(friction * 1.01, 0.999999f);
		else if (IsKeyDown(KeyboardKey.KEY_D))
			friction = max(friction * 0.99, 0.001f);
		else if (IsKeyDown(KeyboardKey.KEY_R))
			attractThreshold += 1;
		else if (IsKeyDown(KeyboardKey.KEY_F))
			attractThreshold -= 1;
		else if (IsKeyDown(KeyboardKey.KEY_T))
			repelThreshold += 1;
		else if (IsKeyDown(KeyboardKey.KEY_G))
			repelThreshold -= 1;
		else if (IsKeyPressed(KeyboardKey.KEY_Z))
			printAllGlobals();
		

		// labels with current values
		DrawText(to!string("Attract: " ~ to!string(attractFactor)).ptr, 10, 10, 30, Colors.WHITE);
		DrawText(to!string("Repel: " ~ to!string(repelFactor)).ptr, 10, 60, 30, Colors.WHITE);
		DrawText(to!string("Friction: " ~ to!string(friction)).ptr, 10, 110, 30, Colors.WHITE);
		DrawText(to!string("Attract Threshold: " ~ to!string(attractThreshold)).ptr, 10, 160, 30, Colors.WHITE);
		DrawText(to!string("Repel Threshold: " ~ to!string(repelThreshold)).ptr, 10, 210, 30, Colors.WHITE);

		EndDrawing();
	}
	CloseWindow();
}
