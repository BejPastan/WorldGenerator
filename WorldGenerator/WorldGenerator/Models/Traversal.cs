namespace WorldGenerator.Models
{
    public class Traversal
    {
        public Guid Id { get; set; }
        public Guid Way_Id { get; set; }
        /// <summary>
        /// spatial index of tile
        /// </summary>
        public long Tile_Id { get; set; }

    }
}
