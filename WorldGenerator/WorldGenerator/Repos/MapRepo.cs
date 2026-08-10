using Dapper;
using NetTopologySuite.Features;
using NetTopologySuite.IO;
using NetTopologySuite.IO.Converters;
using System.Drawing;
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


        public async Task<FeatureCollection> GetMapPart(float minLat, float maxLat, float minLng, float maxLng, int zoom)
        {
            if (zoom < Constants.MIN_ZOOM || zoom > Constants.MAX_ZOOM)
            {
                throw new ArgumentException($"Zoom value must be between {Constants.MIN_ZOOM} and {Constants.MAX_ZOOM}");
            }
            #region SQL
            var sql = new Lazy<string>(() => SqlLoader.Load("GetMapGeojson.sql"));
            #endregion

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
                _logger.LogInformation("Return Empty Map");
                result = new();
            }
            var GJReader = new GeoJsonReader();
            var mapPart = GJReader.Read<FeatureCollection>(result.Resp);
            return mapPart;
        }

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
            if (result == null)
            {
                throw new Exception("Error ocured when adding new node");
            }
            return result;
        }

        public async Task<List<Guid>> AddNodesBatch(List<NewNode> nodes)
        {

        }
    }
}
