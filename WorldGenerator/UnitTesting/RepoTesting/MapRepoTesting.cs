using Microsoft.Extensions.Logging;
using FluentAssertions;
using Moq;
using NetTopologySuite.Features;
using NetTopologySuite.IO;
using WorldGenerator.Models;
using WorldGenerator.Repos;
using WorldGenerator.Utils.Interfaces;

namespace UnitTesting.RepoTesting
{
    public class MapRepoTesting
    {
        [Fact]
        public async Task MapRepoTest_GetMapPart_IfInvertedElementsSwapThem()
        {
            //Arrange
            var sql = GeoJsonMockData(out FeatureCollection targetResp, out Dictionary<string, string> param, out List<GeojsonDTO> dbResp);
            var mapRepo = MockMapRepo(sql, param, dbResp);

            //Act
            var response = await mapRepo.GetMapPart(0, 0.01f, 1, -1, 10);

            //Assert
            response.Should().BeEquivalentTo(targetResp);
        }

        [Fact]
        public void MapRepoTest_GetMapPart_IfZoomNegativeThrowError()
        {
            //Arrange
            var sql = GeoJsonMockData(out FeatureCollection targetResp, out Dictionary<string, string> param, out List<GeojsonDTO> dbResp);
            var mapRepo = MockMapRepo(sql, param, dbResp);

            //Act
            Func<Task<FeatureCollection>> response = async () =>  await mapRepo.GetMapPart(0.01f, 0, -1, 1, -10);

            //Assert
            response.Should().ThrowAsync<ArgumentException>();
        }

        [Fact]
        public async Task MapRepoTest_GetMapPart_ReturnSuccess()
        {
            //Arrange
            var sql = GeoJsonMockData(out FeatureCollection targetResp, out Dictionary<string, string> param, out List<GeojsonDTO> dbResp);
            var mapRepo = MockMapRepo(sql, param, dbResp);

            //Act
            var response = await mapRepo.GetMapPart(0.01f, 0, -1, 1, 10);

            //Assert
            response.Should().BeEquivalentTo(targetResp);
        }

        public static string GeoJsonMockData(out FeatureCollection target, out Dictionary<string, string> param, out List<GeojsonDTO> dbResp)
        {
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
                			geom::geometry && ST_MakeEnvelope(@maxLat, @minLat, @maxLng, @minLng, 4326)
                	)
                	GROUP BY w.id
                ) objects
                """;
            param = new()
            {
                { "minLat", "0" },
                { "maxLat", "0,01" },
                { "minLng", "-1" },
                { "maxLng", "1" }
            };

            var rawResp = "{\"type\": \"FeatureCollection\", \"features\": [{\"type\": \"Feature\", \"geometry\": {\"type\": \"Polygon\", \"coordinates\": [[[0, 0], [0, 0], [0.01, 0.01], [0.01, 0.01], [0.02, 0.01], [0.02, 0.01], [0, 0], [0, 0]]]}, \"properties\": {\"ele\": \"50\", \"natural\": \"water\"}}]}";
            dbResp =[new GeojsonDTO {Resp = rawResp}];

            var GJReader = new GeoJsonReader();
            target = GJReader.Read<FeatureCollection>(rawResp);
            return sql;
        }
    
        public static MapRepo MockMapRepo(string sql, Dictionary<string, string> param, List<GeojsonDTO> dbResp)
        {
            var mockDBHandler = new Mock<IDBHandler>();

            mockDBHandler.Setup(db => db.MakeQuery<GeojsonDTO>(sql, param)).ReturnsAsync(dbResp);
            var mockLogger = new Mock<ILogger>();

            var mapRepo = new MapRepo(mockDBHandler.Object, mockLogger.Object);
            return mapRepo;
        }
    }
}
