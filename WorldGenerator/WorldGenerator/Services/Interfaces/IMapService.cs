using NetTopologySuite.Features;

namespace WorldGenerator.Services.Interfaces
{
    public interface IMapService
    {
        Task<FeatureCollection> GetMapPart(float minLat, float maxLat, float minLng, float maxLng, int zoom);
    }
}
