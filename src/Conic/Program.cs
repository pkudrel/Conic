using System;
using System.IO;
using System.Linq;
using System.Text;
using CommandLine;
using Conic.Args;
using Conic.Misc;
using NLog;

namespace Conic
{
    internal class Program
    {
        private static readonly Logger _log = LogManager.GetCurrentClassLogger();

        public static void Main(string[] args)
        {
            var singleGlobalInstance = Attempt.Get(() => new SingleInstance()).Value;
            if (singleGlobalInstance == null)
            {
                if (!Environment.UserInteractive) return;
                Console.WriteLine("Another instance of the application is running.");
                return;
            }
            _log.Info("Start Conic ...");


            if (args.Any())
            {
                var sb = new StringBuilder();
                var writer = new StringWriter(sb);

                var parser = new Parser(with =>
                {
                    with.EnableDashDash = true;
                    with.IgnoreUnknownArguments = false;
                    with.HelpWriter = writer;
                });


                var result = parser.ParseArguments<ManifestOptions, ConfigOptions>(args);
                result
                    .WithParsed<ManifestOptions>(opts => { Console.WriteLine("InitOptions"); })
                    .WithParsed<ConfigOptions>(opts => { Console.WriteLine("ConfigOptions"); })
                    .WithNotParsed(opts =>
                    {
                        WriteErrors(sb);
                    });
                ;
            }
            else
            {
                Console.WriteLine("start ");
                //    using (singleGlobalInstance)
                //    {
                //        var startUp = new StartUp();
                //        startUp.CreateManifestIfNotExists();
                //        var config = startUp.GetOrCreateConfig();
                //        var ws = new WormholeService(config.PipeName);
                //        ws.StartServer();
                //    }
            }
        }

        private static void WriteErrors(StringBuilder sb)
        {
            var r = sb.ToString().Split(new[] {Environment.NewLine}, StringSplitOptions.None);
            r[0] = "Conic - Chrome native messaging connector";
            r[1] = "Copyright (c) 2016 Piotr Kudrel";
            foreach (var s in r)
            {
                Console.Error.WriteLine(s);
            }
        }
    }
}