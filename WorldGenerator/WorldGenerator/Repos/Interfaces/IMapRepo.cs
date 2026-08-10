using NetTopologySuite.Features;
using WorldGenerator.Models;

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

        #region Way Operations
        /// <summary>
        /// Add new way to repo
        /// </summary>
        /// <param name="nodes">Nodes from which way is built</param>
        /// <param name="wayName">name for new way</param>
        /// <returns></returns>
        Task<Guid> AddWay(List<Node> nodes, string wayName);
        #endregion

        #region Node Operations
        /// <summary>
        /// Add new node to database and return node id
        /// </summary>
        /// <param name="node"></param>
        /// <returns></returns>
        Task<Guid> AddNode(NewNode node);

        /// <summary>
        /// 
        /// </summary>
        /// <param name="nodes"></param>
        /// <returns></returns>
        public async Task<List<Guid>> AddNodesBatch(List<NewNode> nodes)
        #endregion
    }
}
