using Python.Runtime;

namespace WorldGenerator.Models
{
    /// <summary>
    /// Result of plate generation, containing pointers and lengths for plates, vertices, regions, and counts.
    /// </summary>
    public struct PlateGenerationResult
    {
        /// <summary>
        /// pointer to list of plate ids for each small cell
        /// </summary>
        public long platesIdsPtr;
        /// <summary>
        /// length of list of plate ids for each small cell
        /// </summary>
        public int platesLength;
        /// <summary>
        /// pointer to list with all vertices of all small regions
        /// </summary>
        public long verticesPtr;
        /// <summary>
        /// length of list with all vertices of all small regions
        /// </summary>
        public int verticesLength;
        /// <summary>
        /// pointer to list with indices of vertices for each small region
        /// </summary>
        public long regionsPtr;
        /// <summary>
        /// length of list with indices of vertices for each small region
        /// </summary>
        public int regionsLength;
        /// <summary>
        /// pointer to list with sizes(number of nodes) of each small region
        /// </summary>
        public long countsPtr;
        /// <summary>
        /// length of list with sizes(number of nodes) of each small region
        /// </summary>
        public int countsLength;

        public PyObject plates;
        public PyObject vertices;
        public PyObject regions;
        public PyObject regionsCounts;
    }

    /// <summary>
    /// Message sent to the client to indicate progress of map generation, containing the next state and percentage completed.
    /// </summary>
    public class ProgressMessage
    {
        /// <summary>
        /// description of currently executing state, for example "Generating points", "Assigning points to regions", "Generating Voronoi diagram"
        /// </summary>
        public string nextState { get; set; }
        /// <summary>
        /// precent value of progress, from 0 to 1
        /// </summary>
        public float precent { get; set; }
    }

    /// <summary>
    /// Request obejct for plate generation, containing the number of plates, number of segments, and planet size.
    /// </summary>
    public class PlateGenerationRequest
    {
        /// <summary>
        /// Maxmium number of plates to generate, for example 10
        /// </summary>
        public int platesNum { get; set; }
        /// <summary>
        /// number of segments to generate, for example 1000, this segments are elemtn of plates
        /// </summary>
        public int segmentNum { get; set; }
        /// <summary>
        /// Size of planet in km
        /// </summary>
        public float planetSize { get; set; }
    }
}
