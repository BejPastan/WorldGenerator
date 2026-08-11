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

        public async Task<List<Guid>> AddNodesBatch(List<NewNode> nodes)
        {
            return await _mapRepo.AddNodesBatch(nodes);
        }

        public async Task<List<Guid>> AddRelationsBatch(List<NewRelation> relations)
        {
            return await _mapRepo.AddRelationsBatch(relations);
        }

        public async Task<Guid> AddWay(List<Node> nodes, string wayName)
        {
            return await _mapRepo.AddWay(nodes, wayName);
        }

        public async Task<List<Guid>> AddWaysBatch(List<NewWay> ways)
        {
            return await _mapRepo.AddWaysBatch(ways);
        }

        public async Task<FeatureCollection> GetMapPart(float minLat, float maxLat, float minLng, float maxLng, int zoom)
        {
            return await _mapRepo.GetMapPart(minLat, maxLat, minLng, maxLng, zoom);
        }
    }
}
