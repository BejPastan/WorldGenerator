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

        public delegate void ProgressEvent(ProgressMessage message, string connectionId);

        /// <summary>
        /// Generate set of polygons, and divide them into plates
        /// </summary>
        /// <param name="platesNum"></param>
        /// <param name="segmentNum"></param>
        /// <param name="planetSize"></param>
        /// <returns></returns>
        /// <exception cref="NotImplementedException"></exception>
        public async Task<List<Guid>> GenerateTectonicPlates(int platesNum, int segmentNum, float planetSize, string connectionId)
        {
            Func<dynamic, PlateGenerationResult> generatePoints = (dynamic pyModule) =>
            {
                PyObject points = pyModule.generate_uniform_points_on_sphere(segmentNum, planetSize, 0);//generating segments points
                progressMessage?.Invoke(new ProgressMessage { nextState = "Generating plates points", precent = 0.20f }, connectionId);
                PyObject regionPoints = pyModule.generate_random_points_on_sphere(platesNum, planetSize);//generating plates points
                progressMessage?.Invoke(new ProgressMessage { nextState = "Assigning segments to plates", precent = 0.30f }, connectionId);
                dynamic pointsToRegions = pyModule.assign_points_to_regions(points, regionPoints);//assigning segments to plates
                regionPoints.Dispose();
                progressMessage?.Invoke(new ProgressMessage { nextState = "generating segments borders", precent = 0.50f }, connectionId);
                dynamic voronoi = pyModule.generate_voronoi(points, planetSize);
                points.Dispose();

                dynamic regions = voronoi[1];//indices of cells, regions
                dynamic vertices = voronoi[0];//all vertices of all regions, vertices
                dynamic counts = voronoi[2];//list of number of vertices in each region, regions_counts

                long platesIdsPtr = pointsToRegions.ctypes.data;//plates for WAYS not for vertices
                int platesLength = pointsToRegions.size;
                long verticesPtr = vertices.ctypes.data;
                int verticesLength = vertices.size;
                long regionsPtr = regions.ctypes.data;
                int regionsLength = regions.size;
                long countsPtr = counts.ctypes.data;
                int countsLength = counts.size;

                return new PlateGenerationResult
                {
                    platesIdsPtr = platesIdsPtr,
                    platesLength = platesLength,
                    verticesPtr = verticesPtr,
                    verticesLength = verticesLength,
                    regionsPtr = regionsPtr,
                    regionsLength = regionsLength,
                    countsPtr = countsPtr,
                    countsLength = countsLength,

                    //hold to preserve data
                    plates = pointsToRegions,
                    vertices = vertices,
                    regions = regions,
                    regionsCounts = counts
                };
            };

            //Generate points
            PlateGenerationResult pointsData = _fetcher.ExecuteModule("PlateGeneration", generatePoints);

            progressMessage?.Invoke(new ProgressMessage { nextState = "Saving segments", precent = 0.70f }, connectionId);

            //list of all generated points

            int totalPoints = pointsData.verticesLength / 2;
            int totalRegions = pointsData.countsLength;

            #region adding points

            //multiplying by 2 to get all 2 vertices of point
            List<Guid> pointsIds = new List<Guid>();
            for (int i = 0; i< pointsData.verticesLength; i+=Constants.PLATE_INPUT_BATCH*2)
            {
                List<NewNode> nodes = new List<NewNode>();
                unsafe
                {
                    ReadOnlySpan<double> vSpan = new ReadOnlySpan<double>((void*)pointsData.verticesPtr, pointsData.verticesLength);
                    ReadOnlySpan<double> slice = vSpan.Slice(i, Math.Min(Constants.PLATE_INPUT_BATCH * 2, pointsData.verticesLength - i));//probably somwhere here
                    for(int j =0; j< slice.Length; j+=2)
                    {
                        nodes.Add(new NewNode(new Point(slice[j], slice[j + 1])));
                    }
                    //save points to database
                }
                try
                {
                    List<Guid> ids = await _mapService.AddNodesBatch(nodes);
                    pointsIds.AddRange(ids);
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Error adding nodes batch starting at index {i}: {ex.Message}");
                    throw;
                }
            }

            pointsData.vertices.Dispose();
            #endregion
            //adding ways
            progressMessage?.Invoke(new ProgressMessage { nextState = "Savaing plates", precent = 0.90f }, connectionId);

            Dictionary<int, List<NewRelationElement>> regionToPlate = new Dictionary<int, List<NewRelationElement>>();
            for (int i = 0; i < platesNum; i++)
            {
                regionToPlate.Add(i, new List<NewRelationElement>());
            }
            for (int i =0; i< totalRegions; i+=Constants.PLATE_INPUT_BATCH)
            {
                List<NewWay> ways = new List<NewWay>();
                unsafe
                {
                    ReadOnlySpan<int> rSpan = new ReadOnlySpan<int>((void*)pointsData.countsPtr, totalRegions);
                    ReadOnlySpan<int> slice = rSpan.Slice(i, Math.Min(Constants.PLATE_INPUT_BATCH, totalRegions - i));
                    ReadOnlySpan<int> iSpan = new ReadOnlySpan<int>((void*)pointsData.regionsPtr, pointsData.regionsLength);
                    for(int j =0; j< slice.Length; j++)
                    {
                        int count = slice[j];
                        List<Guid> nodes = new();
                        for(int k =0; k< count; k++)
                        {
                            int index = iSpan[i + k];
                            nodes.Add(pointsIds[index]);
                        }
                        ways.Add(new NewWay() { Nodes_Ids = nodes, Name = $"Element_{i + j}" });
                    }
                }
                List<Guid> waysIds = await _mapService.AddWaysBatch(ways);//new ways ids
                //assigning ways to plates
                unsafe
                {
                    ReadOnlySpan<int> pSpan = new ReadOnlySpan<int>((void*)pointsData.platesIdsPtr, pointsData.platesLength);
                    ReadOnlySpan<int> slice = pSpan.Slice(i, Math.Min(Constants.PLATE_INPUT_BATCH, totalRegions - i));
                    for(int j =0; j< waysIds.Count; j++)
                    {
                        int plateIndex = slice[j];
                        regionToPlate[plateIndex].Add(new NewRelationElement() { Way_Id = waysIds[j], Type = true });
                    }
                }
            }
            List<Guid> relationIds = new List<Guid>();
            for (int i = 0; i< platesNum; i++)
            {
                regionToPlate.TryGetValue(i, out List<NewRelationElement> elements);
                var relation = new NewRelation() { Elements = elements, Name = $"Plate_{i}" };
                var id = await _mapService.AddRelationsBatch(new List<NewRelation>() { relation });
                relationIds.AddRange(id);
            }
            return relationIds;
        }
    }
}
