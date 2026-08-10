using NetTopologySuite.Features;

namespace WorldGenerator.Services.Interfaces
{
    public interface IMapGenerator
    {
        public Task<FeatureCollection> GenerateTectonicPlates(int platesNum, int segmentNum, float planetSize);
    }
}