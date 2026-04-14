module ball;

import raylib;

import std.algorithm;
import std.random;
import std.range : iota;

struct Ball
{
	float x;
	float y;

	float radius;
	float speedX;
	float speedY;
	
	Color color;

	void update(float width, float height, float maxSpeed, float border)
	{
		x += speedX;
		y += speedY;

		speedX = clamp(speedX, -maxSpeed, maxSpeed) * 0.98f;
		speedY = clamp(speedY, -maxSpeed, maxSpeed) * 0.98f;

		if (x - radius < border && speedX < 0)
		{
			speedX *= -1;
			x = border + radius;
		}
		else if (x + radius > width - border && speedX > 0)
		{
			speedX *= -1;
			x = width - border - radius;
		}
		if (y - radius < border && speedY < 0)
		{
			speedY *= -1;
			y = border + radius;
		}
		else if (y + radius > height - border && speedY > 0)	
		{
			speedY *= -1;
			y = height - border - radius;
		}

		draw();
	}

	void draw()
	{
		DrawCircle(cast(int) x, cast(int) y, radius, color);
	}
}

public Ball[] generateBalls(int numBalls, float radius, float cellSize, Random rnd, float width = 500, float height = 500) {
	Ball[] balls;

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
	return balls;
}