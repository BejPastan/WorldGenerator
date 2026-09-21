namespace WorldGenerator.Models
{
    public enum TagElementType
    {
        Node,
        Way,
        Relation,
        Empty
    }

    public class Tag
    {
        public Guid? Id { get; set; } = null;
        public string Key { get; set; } = string.Empty;
        public string Value { get; set; } = string.Empty;
        public virtual Guid ElementId { get; set; }
        public virtual TagElementType ElementType { get; }
    }

    public class NodeTag : Tag
    {
        public override TagElementType ElementType { get; } = TagElementType.Node;
        public override Guid ElementId 
        { 
            get => NodeId; 
            set 
            {
                NodeId = value;
            } 
        }
        public Guid NodeId { get; set; }//set ElementId from NodeId, and return NodeId from ElementId
    }

    public class WayTag : Tag
    {
        public override TagElementType ElementType { get; } = TagElementType.Way;

        public override Guid ElementId
        {
            get => WayId;
            set
            {
                WayId = value;
            }
        }
        public Guid WayId { get; set; }
    }

    public class RelationTag : Tag
    {
        public override TagElementType ElementType { get; } = TagElementType.Relation;
        public override Guid ElementId
        {
            get => RelationId;
            set
            {
                RelationId = value;
            }
        }
        public Guid RelationId { get; set; }
    }

}
