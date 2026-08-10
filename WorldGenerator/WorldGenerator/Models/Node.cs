using NetTopologySuite.Geometries;

using System.ComponentModel.DataAnnotations.Schema;

namespace WorldGenerator.Models
{
    /// <summary>
    /// Base node class
    /// </summary>
    public class Node
    {
        public virtual Guid? Id { get; set; } = null;
        public virtual string? Name { get; set; } = null;
        public virtual string? TileId { get; set; } = null;
        [Column(TypeName = "geography")]
        public virtual Point? Geom { get; set; } = null;
    }

    /// <summary>
    /// Class used for adding new nodes to DB
    /// </summary>
    public class NewNode(Point point) : Node
    {
        public override string Name { get; set; } = string.Empty;
        public override Point Geom { get; set; } = point;
    }

    /// <summary>
    /// Class used for adding new ways, as existing node
    /// </summary>
    public class NodeToReference : Node
    {
        public NodeToReference(Guid id)
        {
            if(id == Guid.Empty)
            {
                throw new ArgumentException("Id cannot be empty", nameof(id));
            }
            Id = id;
        }

        public override Guid? Id { get; set; }
    }
}
