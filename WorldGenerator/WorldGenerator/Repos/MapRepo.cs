using Dapper;
using NetTopologySuite.Features;
using NetTopologySuite.IO;
using NetTopologySuite.IO.Converters;
using System.Text.Json;
using WorldGenerator.Models;
using WorldGenerator.Repos.Interfaces;
using WorldGenerator.Utils;
using WorldGenerator.Utils.Interfaces;

namespace WorldGenerator.Repos
{
    public class MapRepo : IMapRepo
    {
        public MapRepo(IDBHandler db, ILogger<MapRepo> logger)
        {
            _options = new JsonSerializerOptions
            {
                DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingNull,
                Converters = { new GeoJsonConverterFactory() },
                PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower
            };
            _db = db;
            _logger = logger;
        }

        readonly IDBHandler _db;
        readonly ILogger _logger;
        readonly JsonSerializerOptions _options;

        /// <inheritdoc/>
        public async Task<Guid> AddWay(List<Node> nodes, string wayName)
        {
            #region setting converter

            #endregion

            var sql = new Lazy<string>(() => SqlLoader.Load("AddWayToMap.sql"));

            var json = JsonSerializer.Serialize(nodes, _options);

            DynamicParameters param = new();
            param.Add("way_name", wayName);
            param.Add("objects_array", json);
            var resp = await _db.MakeQuery<WaysNodes>(sql.Value, param);
            _logger.LogInformation($"AddWay: {wayName} with nodes: {json}");
            _logger.LogInformation($"AddWay: DB Response: {JsonSerializer.Serialize(resp)}");
            var wayNode = resp.FirstOrDefault();
            if(wayNode != null)
            {
                return wayNode.WayId??throw new Exception("Error ocured when adding new way");
            }
            else
            {
                throw new Exception("Error ocured when adding new way");
            }
        }

        /// <inheritdoc/>
        public async Task<FeatureCollection> GetMapPart(float minLat, float maxLat, float minLng, float maxLng, int zoom)
        {
            if (zoom < Constants.MIN_ZOOM || zoom > Constants.MAX_ZOOM)
            {
                throw new ArgumentException($"Zoom value must be between {Constants.MIN_ZOOM} and {Constants.MAX_ZOOM}");
            }
            var sql = new Lazy<string>(() => SqlLoader.Load("GetMapGeojson.sql"));

            if (minLat > maxLat) {
                (maxLat, minLat) = (minLat, maxLat);
            }
            if (minLng > maxLng) {
                (maxLng, minLng) = (minLng, maxLng);
            }

            DynamicParameters param = new();
            param.Add("minLat", minLat);
            param.Add("maxLat", maxLat);
            param.Add("minLng", minLng);
            param.Add("maxLng", maxLng);
            var resp = await _db.MakeQuery<GeojsonResp>(sql.Value, param);
            var result = resp.FirstOrDefault();
            if(result == null)
            {
                _logger.LogInformation("Returned Empty Map");
                result = new();
            }
            var GJReader = new GeoJsonReader();
            var mapPart = GJReader.Read<FeatureCollection>(result.Resp);
            return mapPart;
        }

        #region Nodes operations
        /// <inheritdoc/>
        public async Task<Guid> AddNode(NewNode node)
        {
            var sql = """
                INSERT INTO Nodes (name, geom) VALUES (@name, ST_SetSRID(ST_MakePoint(@lng, @lat), 4326)) RETURNING id;
                """;
            var param = new DynamicParameters();
            param.Add("name", node.Name);
            param.Add("lat", node.Geom.Y);
            param.Add("lng", node.Geom.X);

            var resp = await _db.MakeQuery<Guid>(sql, param);
            var result = resp.FirstOrDefault();
            if (result == Guid.Empty)
            {
                throw new Exception("Error ocured when adding new node");
            }
            return result;
        }

        /// <inheritdoc/>
        public async Task<List<Guid>> AddNodesBatch(List<NewNode> nodes)
        {
            var sql = new Lazy<string>(() => SqlLoader.Load("AddBatchNodes.sql"));
            var param = new DynamicParameters();
            var json = JsonSerializer.Serialize(nodes, _options);
            param.Add("objects_array", json);
            var nodesIds = await _db.MakeQuery<Guid>(sql.Value, param);
            var result = nodesIds.ToList();
            return result;
        }

        /// <inheritdoc/>
        public async Task<NodeExtended> GetNode(Guid id)
        {
            var sql = "SELECT n.id as id, n.name as name, n.geom as geom, n.tile_id as tileId, nt.k as \"Tags.Key\", nt.v as \"Tags.Value\" FROM Nodes n LEFT JOIN NodesTags nt ON nt.node_id = n.id WHERE n.id =@id";
            var param = new DynamicParameters();
            param.Add("id", id);
            var result = await _db.MakeNestedQuery<NodeExtended>(sql, param);
            return result.FirstOrDefault();
        }
        public async Task<Node> EditNode(UpdateNode node)
        {
            bool anyUpdate = false;
            string sql = "UPDATE Nodes SET ";
            var param = new DynamicParameters();
            if(node.Name != null)
            {
                sql += "name = @name ";
                param.Add("name", node.Name);
                anyUpdate = true;
            }
            if(node.Geom != null)
            {
                sql += "geom = ST_SetSRID(ST_MakePoint(@lng, @lat), 4326) ";
                param.Add("lat", node.Geom.Y);
                param.Add("lng", node.Geom.X);
                anyUpdate = true;
            }
            if(anyUpdate)
            {
                sql += "WHERE id=@id RETURNING id, name, tile_id, geom;";
                var result = await _db.MakeQuery<Node>(sql, param);
                return result.FirstOrDefault();
            }
            else
            {
                throw new ArgumentException("at least one data to change need to be given");
            }

        }

        public Task<bool> DeleteNode(Guid id)
        {
            throw new NotImplementedException();
        }

        #endregion

        #region Ways operations

        /// <inheritdoc/>
        public async Task<List<Guid>> AddWaysBatch(List<NewWay> ways)
        {
            var sql = new Lazy<string>(() => SqlLoader.Load("AddWaysToMapBatch.sql"));
            var param = new DynamicParameters();
            var json = JsonSerializer.Serialize(ways, _options);
            param.Add("objects_array", json);
            var waysIds = await _db.MakeQuery<Guid>(sql.Value, param);
            var result = waysIds.ToList();
            return result;
        }


        public async Task<WayExtended> GetWay(Guid id)
        {
            string sql = "SELECT w.name AS name, w.id AS id, n.geom AS \"Nodes.Geom\", n.id AS \"Nodes.id\", tg.k AS \"Tags.Key\", tg.v AS \"Tags.Value\", tr.tile_id AS \"Traversal.TileId\" FROM Ways w LEFT JOIN WaysNodes wn ON wn.way_id = w.id LEFT JOIN Nodes n ON n.id = wn.node_id LEFT JOIN Traversal tr ON tr.way_id = w.id LEFT JOIN WaysTags tg ON tg.way_id = w.id WHERE w.id = @id";

            var param = new DynamicParameters();
            param.Add("id", id);
            var response = await _db.MakeNestedQuery<WayExtended>(sql, param);
            return response.FirstOrDefault();
        }

        #endregion

        #region Relations operations

        public async Task<List<Guid>> AddRelationsBatch(List<NewRelation> relations)
        {
            var sql = new Lazy<string>(() => SqlLoader.Load("AddRelationsBatch.sql"));
            var param = new DynamicParameters();
            var json = JsonSerializer.Serialize(relations, _options);
            param.Add("objects_array", json);
            var relationsIds = await  _db.MakeQuery<Guid>(sql.Value, param);
            var result = relationsIds.ToList();
            return result;
        }

        #endregion
    }
}
