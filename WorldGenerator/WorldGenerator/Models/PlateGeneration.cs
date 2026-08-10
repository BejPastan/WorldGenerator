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
    }
}
