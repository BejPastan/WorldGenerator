using Dapper;
using NetTopologySuite.Features;
using NetTopologySuite.IO;
using WorldGenerator.Models;
using WorldGenerator.Repos.Interfaces;
using WorldGenerator.Utils;
using WorldGenerator.Utils.Interfaces;

namespace WorldGenerator.Repos
{
    public class MapRepo(IDBHandler db, ILogger<MapRepo> logger) : IMapRepo
    {
        readonly IDBHandler _db = db;
        readonly ILogger _logger = logger;


        public async Task<FeatureCollection> GetMapPart(float minLat, float maxLat, float minLng, float maxLng, int zoom)
        {
            if (zoom < Constants.MIN_ZOOM || zoom > Constants.MAX_ZOOM)
            {
                throw new ArgumentException($"Zoom value must be between {Constants.MIN_ZOOM} and {Constants.MAX_ZOOM}");
            }
            #region SQL
            string sql = """
                                SELECT jsonb_build_object
                (
                	'type', 'FeatureCollection',
                	'features', jsonb_agg
                	(
                		to_jsonb(objects)
                	)
                ) as resp
                FROM 
                (	
                	SELECT 
                		'Feature'as type, 
                		ST_AsGeoJSON(ST_MakePolygon(ST_MakeLine(n.geom::geometry ORDER BY wn.sequence_id ASC))::geography)::jsonb as geometry, 
                		jsonb_object_agg(wt.k, wt.v) as properties
                	FROM Ways w 
                	LEFT JOIN WaysNodes wn ON wn.way_id = w.id 
                	LEFT JOIN Nodes n ON n.id = wn.node_id 
                	LEFT JOIN WaysTags wt ON wt.way_id = w.id
                	WHERE EXISTS 
                	(
                		SELECT 1 FROM WaysNodes wn 
                		JOIN Nodes n ON n.id = wn.node_id 
                		WHERE 
                			wn.way_id = w.id AND 
                			geom::geometry && ST_MakeEnvelope(@minLng, @minLat, @maxLng, @maxLat, 4326)
                	)
                	GROUP BY w.id
                ) objects
                """;
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
            var resp = await _db.MakeQuery<GeojsonDTO>(sql, param);
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
