using MathNet.Numerics.LinearAlgebra;

int size = 10000;
var matrixA = CreateMatrix.Dense(size, size, 2.0);
var matrixB = CreateMatrix.Dense(size, size, 3.0);

int Compare()
{
    float startTime = Environment.TickCount;
    var result = matrixA * matrixB;
    float endTime = Environment.TickCount;

    Console.WriteLine($"{(endTime - startTime)/1000.0f}");
    return 0;
}

for(int i = 0; i < 50; i++)
{
    Compare();   
}