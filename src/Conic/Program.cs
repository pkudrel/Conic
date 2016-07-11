using System;
using Conic.Misc;
using Conic.Wormhole;
using NLog;

namespace Conic
{
    internal class Program
    {
        private static readonly Logger _log = LogManager.GetCurrentClassLogger();

        private static void Main(string[] args)
        {
            var singleGlobalInstance = Attempt.Get(() => new SingleInstance()).Value;
            if (singleGlobalInstance == null)
            {
                if (!Environment.UserInteractive) return;
                Console.WriteLine("Another instance of the application is running.");
                return;
            }
            _log.Info("Start Conic ...");
            using (singleGlobalInstance)
            {
                var startUp = new StartUp();
                startUp.CreateManifestIfNotExists();
                var config = startUp.GetOrCreateConfig();
                var ws = new WormholeService(config.PipeName);
                ws.StartServer();
            }
        }
    }
}