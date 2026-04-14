module simulation_state;

struct SimulationState
{
    float width = 500;
    float height = 500;

    int border = 25;
    int radius = 2;
    int numBalls = 20;
    float cellSize = 250.0f;
    float repelCellSizeFactor = 5.0f;
    float attractFactor = 20f;
    float repelFactor = 40f;
    int attractThreshold = 20 + 3;
    int repelThreshold = 20*2 + 3;
    float friction = 0.4535396f;

    float maxSpeed = 0.25f;

    float ringRadius = 360.0f;
}