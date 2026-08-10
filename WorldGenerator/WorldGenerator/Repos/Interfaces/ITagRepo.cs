using WorldGenerator.Models;

namespace WorldGenerator.Repos.Interfaces
{
    public interface ITagRepo
    {
        public Task<List<Guid>> AddTagBatch<T>(List<T> toAdd) where T : Tag;
    }
}
