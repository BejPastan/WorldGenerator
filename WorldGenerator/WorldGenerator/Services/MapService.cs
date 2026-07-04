using NetTopologySuite.Features;
using WorldGenerator.Models;
using WorldGenerator.Repos.Interfaces;
using WorldGenerator.Services.Interfaces;

namespace WorldGenerator.Services
{
    public class MapService(ILogger<MapService> logger, IMapRepo mapRepo) : IMapService
    {
        readonly ILogger _logger = logger;
        readonly IMapRepo _mapRepo = mapRepo;

        public Task<string> AddWay(List<Node> nodes, string wayName)
        {
            return _mapRepo.AddWay(nodes, wayName);
        }

        public async Task<FeatureCollection> GetMapPart(float minLat, float maxLat, float minLng, float maxLng, int zoom)
        {
            return await _mapRepo.GetMapPart(minLat, maxLat, minLng, maxLng, zoom);
        }
    }
}
