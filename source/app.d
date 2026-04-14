import raylib;

import std.random;
import std.stdio;
import std.conv;
import std.range : iota;
import std.math;
import std.algorithm;
import std.format;

import ball;
import canvas;
import simulation_state;

void main()
{
	auto state = new SimulationState;

	validateRaylibBinding();
	SetTraceLogLevel(7);
	SetConfigFlags(ConfigFlags.FLAG_WINDOW_RESIZABLE);
	InitWindow(to!int(state.width), to!int(state.height), "Hello, Raylib-D!");
	SetTargetFPS(6000);
	auto rnd = Random(unpredictableSeed);

	auto balls = generateBalls(state.numBalls, state.radius, state.cellSize, rnd);

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

			if (cd < state.attractThreshold)
				attractedTo[i] ~= cast(int) j;
			else if (cd > state.repelThreshold)
				repelledFrom[i] ~= cast(int) j;
		}

	while (!WindowShouldClose())
	{
		BeginDrawing();
		ClearBackground(Colors.BLACK);
		state.width = GetScreenWidth();
		state.height = GetScreenHeight();

		SpatialHash sh;
		sh.cellSize = state.cellSize;


		sh.clear();
		foreach (i, ref ball; balls)
			sh.insert(cast(int)i, ball.x, ball.y);

		foreach (i, ref ball; balls)
		{
			float spd = sqrt(ball.speedX^^2 + ball.speedY^^2);
			if (spd > state.maxSpeed) {
				ball.speedX = ball.speedX / spd * state.maxSpeed;
				ball.speedY = ball.speedY / spd * state.maxSpeed;
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
						force = state.attractFactor * 0.1f;
					else
						force = state.attractFactor * 0.1f;
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
					float force = state.repelFactor * 0.01f / (dist * dist);
					ball.speedX -= dx * force;
					ball.speedY -= dy * force;
				}
			}

			foreach (j; sh.nearby(ball.x, ball.y))
			{
				if (i == j) continue;
				ref ball2 = balls[j];

				// all balls slightly attracted to the center point
				float cx = ball.x - state.width/2;
				float cy = ball.y - state.height/2;
				float distFromCenter = sqrt(cx*cx + cy*cy);
				float radialForce = (distFromCenter - state.ringRadius) * 0.0005f;
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
						ball.speedX  = ball2.speedX * state.friction;
						ball.speedY  = ball2.speedY * state.friction;
						ball2.speedX = tmpX * state.friction;
						ball2.speedY = tmpY * state.friction;
					}
				}
			}
			ball.update(cast(float)state.width, cast(float)state.height, state.maxSpeed, state.border);
		}
		if (IsKeyPressed(KeyboardKey.KEY_Q))
			state.attractFactor *= 2;
		else if (IsKeyPressed(KeyboardKey.KEY_A))
			state.attractFactor /= 2;
		else if (IsKeyPressed(KeyboardKey.KEY_W))
			state.repelFactor *= 2;
		else if (IsKeyPressed(KeyboardKey.KEY_S))
			state.repelFactor /= 2;
		else if (IsKeyDown(KeyboardKey.KEY_E))
			state.friction = min(state.friction * 1.01, 0.999999f);
		else if (IsKeyDown(KeyboardKey.KEY_D))
			state.friction = max(state.friction * 0.99, 0.001f);
		else if (IsKeyPressed(KeyboardKey.KEY_Y))
		{	
			state.ringRadius += 10;
		}
		else if (IsKeyPressed(KeyboardKey.KEY_H))
		{	
			state.ringRadius -= 10;
		}
		

		// labels with current values
		DrawText(to!string(format("Attract: %.2f", state.attractFactor)).ptr, 10, 10, 30, Colors.WHITE);
		DrawText(to!string(format("Repel: %.2f", state.repelFactor)).ptr, 10, 60, 30, Colors.WHITE);
		DrawText(to!string(format("Friction: %.2f", state.friction)).ptr, 10, 110, 30, Colors.WHITE);

		EndDrawing();
	}
	CloseWindow();
}
