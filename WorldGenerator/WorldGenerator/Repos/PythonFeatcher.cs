using Python.Runtime;
using WorldGenerator.Repos.Interfaces;

namespace WorldGenerator.Repos
{
    public class PythonFeatcher : IPythonFeatcher, IDisposable
    {
        public PythonFeatcher(IPythonSetting config)
        {
            Runtime.PythonDLL = config.GetPythonPath();
            InitializeGIL();
        }

        nint _gilTs;
        private void InitializeGIL()
        {
            PythonEngine.Initialize();
            using(Py.GIL())
            {
                dynamic sys = Py.Import("sys");
                sys.path.append($"{AppDomain.CurrentDomain.BaseDirectory}/Resources/Python");
            }
            _gilTs = PythonEngine.BeginAllowThreads();
        }

        /// <summary>
        /// Wrapper for executing python
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <typeparam name="TResult">Output data type</typeparam>
        /// <param name="fileName"></param>
        /// <param name="func"></param>
        /// <returns></returns>
        public TResult ExecuteModule<TResult>(string fileName, Func<dynamic, TResult> func)
        {
            TResult result;
            using (Py.GIL())
            {
                dynamic pyModule = Py.Import(fileName);//importing module
                result = func.Invoke(pyModule);//Invoking function, and returning result
            }
            return result;
        }

        private bool disposedValue;

        protected virtual void Dispose(bool disposing)
        {
            if (!disposedValue)
            {
                if (disposing)
                {
                    PythonEngine.EndAllowThreads(_gilTs);
                    PythonEngine.Shutdown();
                }

                disposedValue = true;
            }
        }

        public void Dispose()
        {
            // Do not change this code. Put cleanup code in 'Dispose(bool disposing)' method
            Dispose(disposing: true);
            GC.SuppressFinalize(this);
        }
    }
}
