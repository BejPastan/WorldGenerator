using NetTopologySuite.Features;

namespace WorldGenerator.Repos.Interfaces
{
    public interface IMapRepo
    {
        /// <summary>
        /// Get Features from database as GEOJSON and return collection of features
        /// </summary>
        /// <param name="minLat"></param>
        /// <param name="maxLat"></param>
        /// <param name="minLng"></param>
        /// <param name="maxLng"></param>
        /// <param name="zoom"></param>
        /// <returns></returns>
        Task<FeatureCollection> GetMapPart(float minLat,  float maxLat, float minLng, float maxLng, int zoom);
    }
}
