using NetTopologySuite.Features;

namespace WorldGenerator.Services.Interfaces
{
    public interface IMapGenerator
    {
        public Task<List<Guid>> GenerateTectonicPlates(int platesNum, int segmentNum, float planetSize, string connectionId);
    }
}