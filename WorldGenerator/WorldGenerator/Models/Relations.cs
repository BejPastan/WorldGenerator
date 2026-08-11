namespace WorldGenerator.Models
{
    /// <summary>
    /// DTO for relation
    /// </summary>
    public class Relation
    {
        public Guid? Id { get; set; } = null;
        public string ? Name { get; set; } = null;
    }

    /// <summary>
    /// Object required for inserting new relation into database
    /// </summary>
    public class NewRelation
    {
        public string Name { get; set; } = null!;
        public List<NewRelationElement>? Elements { get; set; } = new List<NewRelationElement>();
    }

    /// <summary>
    /// DTO for relation element
    /// </summary>
    public class RelationElement
    {
        public Guid? Id { get; set; } = null;
        public Guid Relation_Id { get; set; }
        public Guid Way_Id { get; set; }
        /// <summary>
        /// flag if given polygon is inner or outer polygon of relation. True if inner, false if outer
        /// </summary>
        public bool Type { get; set; }
    }

    /// <summary>
    /// class to hold data  required for inserting new relation element
    /// </summary>
    public struct NewRelationElement
    {
        public Guid? Relation_Id { get; set; }
        public Guid Way_Id { get; set; }
        /// <summary>
        /// flag if given polygon is inner or outer polygon of relation. True if inner, false if outer
        /// </summary>
        public bool Type { get; set; }
    }
}
