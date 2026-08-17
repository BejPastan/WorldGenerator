using NetTopologySuite.Geometries;

using System.ComponentModel.DataAnnotations.Schema;

namespace WorldGenerator.Models
{
    /// <summary>
    /// Base node class
    /// </summary>
    public class Node
    {
        /// <summary>
        /// Id of Node
        /// </summary>
        public virtual Guid? Id { get; set; } = null;
        /// <summary>
        /// Name of node
        /// </summary>
        public virtual string? Name { get; set; } = null;
        /// <summary>
        /// Id of tile(readonly)
        /// </summary>
        public virtual string? TileId { get; set; } = null;
        /// <summary>
        /// Geography data of point
        /// </summary>
        [Column(TypeName = "geography")]
        public virtual Point? Geom { get; set; } = null;
    }

    public class UpdateNode(Guid id) : Node
    {
        public override Guid? Id { get; set; } = id;//how to force this to not be null?
        public override string Name { get; set; } = string.Empty;
        public override Point? Geom { get; set; } = null;
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

    public class NodeExtended : Node
    {
        List<Tag> tags = new List<Tag>();
    }

    public class WayNode : Node
    {
        public int sequenceId {  get; set; }
    }
}
