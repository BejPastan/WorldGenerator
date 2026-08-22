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
        #endregion

        #region Node Operations
        /// <summary>
        /// Add new node to database and return node id
        /// </summary>
        /// <param name="node"></param>
        /// <returns></returns>
        Task<Guid> AddNode(NewNode node);

        /// <summary>
        /// return single Node
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        Task<NodeExtended> GetNode(Guid id);

        /// <summary>
        /// Edit Node data, and return new object
        /// </summary>
        /// <param name="node"></param>
        /// <returns></returns>
        Task<Node> EditNode(UpdateNode node);

        /// <summary>
        /// Delete node and return boolean flag of success
        /// </summary>
        /// <param name="id">id of node to delete</param>
        /// <returns></returns>
        Task<bool> DeleteNode(Guid id);

        /// <summary>
        /// Add nodes and return list of their ids
        /// </summary>
        /// <param name="nodes"></param>
        /// <returns></returns>
        public Task<List<Guid>> AddNodesBatch(List<NewNode> nodes);

        #endregion

        #region Ways Operations
        /// <summary>
        /// Add new way to repo
        /// </summary>
        /// <param name="nodes">Nodes from which way is built</param>
        /// <param name="wayName">name for new way</param>
        /// <returns></returns>
        Task<Guid> AddWay(List<Node> nodes, string wayName);

        /// <summary>
        /// Add ways and return list of their ids
        /// </summary>
        /// <param name="ways">List of new ways to add, with ids of nodes</param>
        /// <returns></returns>
        Task<List<Guid>> AddWaysBatch(List<NewWay> ways);

        Task<WayExtended> GetWay(Guid id);
        #endregion

        #region Relation Operations
        public Task<List<Guid>> AddRelationsBatch(List<NewRelation> relations);
        #endregion
    }
}
