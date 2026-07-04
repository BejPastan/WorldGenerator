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
                Converters = { new GeoJsonConverterFactory() }
            };
            _db = db;
            _logger = logger;
        }

        readonly IDBHandler _db;
        readonly ILogger _logger;
        readonly JsonSerializerOptions _options;


        public async Task<string> AddWay(List<Node> nodes, string wayName)
        {
            #region setting converter

            #endregion

            var sql = new Lazy<string>(() => SqlLoader.Load("AddWayToMap.sql"));

            var json = JsonSerializer.Serialize(nodes, _options);

            DynamicParameters param = new();
            param.Add("objects_array", json);
            param.Add("way_name", wayName);
            var resp = await _db.MakeQuery<WaysNodes>(sql.Value, param);
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
            var resp = await _db.MakeQuery<GeojsonDTO>(sql.Value, param);
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
    }
}
