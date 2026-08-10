using NetTopologySuite.Features;
using NetTopologySuite.Geometries;
using Python.Runtime;
using System.Runtime.InteropServices;
using WorldGenerator.Models;
using WorldGenerator.Repos.Interfaces;
using WorldGenerator.Services.Interfaces;
using WorldGenerator.Utils;

namespace WorldGenerator.Services
{
    public class MapGenerator(IPythonFeatcher featcher, IMapService mapService) : IMapGenerator
    {
        IPythonFeatcher _fetcher = featcher;
        IMapService _mapService = mapService;

        /// <summary>
        /// Generate set of polygons, and divide them into plates
        /// </summary>
        /// <param name="platesNum"></param>
        /// <param name="segmentNum"></param>
        /// <param name="planetSize"></param>
        /// <returns></returns>
        /// <exception cref="NotImplementedException"></exception>
        public async Task<FeatureCollection> GenerateTectonicPlates(int platesNum, int segmentNum, float planetSize)
        {
            Func<dynamic, PlateGenerationResult> generatePoints = (dynamic pyModule) =>
            {
                PyObject points = pyModule.generate_uniform_points_on_sphere(segmentNum, planetSize, 0);
                //here insert callback?
                PyObject regionPoints = pyModule.generate_random_points_on_sphere(platesNum, planetSize);
                //here insert callback?
                dynamic pointsToRegions = pyModule.assign_points_to_regions(points, regionPoints);
                //here insert callback?
                regionPoints.Dispose();
                dynamic voronoi = pyModule.generate_voronoi(points, planetSize);

                dynamic regions = voronoi["regions"];//indices of cells
                dynamic vertices = voronoi["vertices"];//all vertices of all regions
                dynamic counts = voronoi["region_counts"];//list of number of vertices in each region

                long platesIdsPtr = pointsToRegions.ctypes.data;
                int platesLength = pointsToRegions.size;
                long verticesPtr = vertices.ctypes.data;
                int verticesLength = vertices.size;
                long regionsPtr = regions.ctypes.data;
                int regionsLength = regions.size;
                long countsPtr = vertices.ctypes.data;
                int countsLength = vertices.size;

                return new PlateGenerationResult
                {
                    platesIdsPtr = platesIdsPtr,
                    platesLength = platesLength,
                    verticesPtr = platesIdsPtr,
                    verticesLength = verticesLength,
                    regionsPtr = regionsPtr,
                    regionsLength = regionsLength,
                    countsPtr = countsPtr,
                    countsLength = countsLength,
                };
            };

            //Generate points
            PlateGenerationResult pointsData = _fetcher.ExecuteModule("PlateGeneration", generatePoints);

            //list of all generated points

            int totalPoints = pointsData.verticesLength / 2;

            #region adding points

                

                //multiplying by 2 to get all 2 vertices of point
            List<Guid> pointsIds = new List<Guid>();
            for (int i = 0; i< totalPoints; i+=Constants.PLATE_INPUT_BATCH*2)
            {
                List<NewNode> nodes = new List<NewNode>();
                unsafe
                {
                    ReadOnlySpan<float> vSpan = new ReadOnlySpan<float>((void*)pointsData.verticesPtr, totalPoints);
                    ReadOnlySpan<float> slice = vSpan.Slice(i, Constants.PLATE_INPUT_BATCH * 2);
                    for(int j =0; j< slice.Length; j+=2)
                    {
                        nodes.Add(new NewNode(new Point(slice[j], slice[j + 1])));
                    }
                    //save points to database
                }
                List<Guid> ids = await _mapService.AddNodesBatch(nodes);
                pointsIds.AddRange(ids);
            }
            #endregion
            //adding ways
            //for

            //adding relations

            //adding tags to ways

            //adding tags to relations


            return null;
        }
    }
}
