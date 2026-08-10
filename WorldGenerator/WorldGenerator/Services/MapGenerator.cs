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
    public class MapGenerator(IPythonFeatcher featcher) : IMapGenerator
    {
        IPythonFeatcher _fetcher = featcher;

        /// <summary>
        /// Generate set of polygons, and divide them into plates
        /// </summary>
        /// <param name="platesNum"></param>
        /// <param name="segmentNum"></param>
        /// <param name="planetSize"></param>
        /// <returns></returns>
        /// <exception cref="NotImplementedException"></exception>
        public Task<FeatureCollection> GenerateTectonicPlates(int platesNum, int segmentNum, float planetSize)
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

                dynamic regions = voronoi["regions"];
                dynamic vertices = voronoi["vertices"];
                dynamic counts = voronoi["region_counts"];

                long platesIdsPtr = pointsToRegions.ctypes.data;
                int platesLength = pointsToRegions.size;
                long verticesPtr = vertices.ctypes.data;
                int verticesLength = vertices.size;
                long regionsPtr = vertices.ctypes.data;
                int regionsLength = vertices.size;
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

            //var regionsPy = pointsData[1].regions;
            //Int64[] regions = regionsPy.GetItem(0);

            //long verticesPtr = vertices.ctypes.data;
            //int verticesLength = vertices.count;

            #region adding points
            unsafe
            {
                ReadOnlySpan<float> vSpan = new ReadOnlySpan<float>(pointsData.verticesPtr, pointsData.verticesLength);

                //multuplying by 2 to get all 2 vertices of point
                for(int i = 0; i< pointsData.verticesLength; i+=Constants.PLATE_INPUT_BATCH*2)
                {
                    ReadOnlySpan<float> slice = vSpan.Slice(i, Constants.PLATE_INPUT_BATCH*2);
                    List<Point> features = [];
                    for(int j =0; j< slice.Length; j+=2)
                    {
                        features.Add(new Point(slice[j], slice[j + 1]));
                    }
                }
            }
            #endregion

            return null;
        }
    }
}
