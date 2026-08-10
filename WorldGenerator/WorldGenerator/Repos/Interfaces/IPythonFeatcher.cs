using Python;
using Python.Runtime;

namespace WorldGenerator.Repos.Interfaces
{
    public interface IPythonFeatcher
    {
        public TResult ExecuteModule<TResult>(string fileName, Func<dynamic, TResult> func);
    }
}
