using NetTopologySuite.Features;
using static WorldGenerator.Services.MapGenerator;

namespace WorldGenerator.Services.Interfaces
{
    public interface IMapGenerator
    {
        public event ProgressEvent progressMessage;
        public Task<List<Guid>> GenerateTectonicPlates(int platesNum, int segmentNum, float planetSize, string connectionId);
    }
}