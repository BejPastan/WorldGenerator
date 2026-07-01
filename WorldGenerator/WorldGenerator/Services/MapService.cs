using NetTopologySuite.Features;
using WorldGenerator.Repos.Interfaces;
using WorldGenerator.Services.Interfaces;

namespace WorldGenerator.Services
{
    public class MapService(ILogger<MapService> logger, IMapRepo mapRepo) : IMapService
    {
        readonly ILogger _logger = logger;
        readonly IMapRepo _mapRepo = mapRepo;

        public async Task<FeatureCollection> GetMapPart(float minLat, float maxLat, float minLng, float maxLng, int zoom)
        {
            return await _mapRepo.GetMapPart(minLat, maxLat, minLng, maxLng, zoom);
        }
    }
}
