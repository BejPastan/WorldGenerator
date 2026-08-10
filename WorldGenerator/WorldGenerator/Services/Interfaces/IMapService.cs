using NetTopologySuite.Features;
using WorldGenerator.Models;

namespace WorldGenerator.Services.Interfaces
{
    public interface IMapService
    {
        /// <summary>
        /// Get part of map in GeoJson format
        /// </summary>
        /// <param name="minLat"></param>
        /// <param name="maxLat"></param>
        /// <param name="minLng"></param>
        /// <param name="maxLng"></param>
        /// <param name="zoom"></param>
        /// <returns></returns>
        Task<FeatureCollection> GetMapPart(float minLat, float maxLat, float minLng, float maxLng, int zoom);

        #region inserting nodes
        /// <summary>
        /// Add nodes and return list of their ids
        /// </summary>
        /// <param name="nodes"></param>
        /// <returns></returns>
        public Task<List<Guid>> AddNodesBatch(List<NewNode> nodes);
        #endregion
        //adding Ways
        /// <summary>
        /// Add new Way from list of nodes
        /// </summary>
        /// <param name="nodes">List of nodes, both existing in databae, and new one</param>
        /// <returns></returns>
        Task<Guid> AddWay(List<Node> nodes, string wayName);

        /// <summary>
        /// Add ways and return list of their ids
        /// </summary>
        /// <param name="ways">List of new ways to add, with ids of nodes</param>
        /// <returns></returns>
        Task<List<Guid>> AddWaysBatch(List<NewWay> ways);
    }
}
