using System;
using System.IO;
using System.Linq;
using System.Text;
using CommandLine;
using Conic.Args;
using Conic.Misc;
using Conic.Wormhole;
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

            var startUp = new StartUp();

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
                    .WithParsed<ManifestOptions>(opts => { startUp.CreateManifest(opts); })
                    .WithParsed<ConfigOptions>(opts => { startUp.CreateConfig(opts); })
                    .WithNotParsed(opts => { WriteErrors(sb); });
                ;
            }
            else
            {
                using (singleGlobalInstance)
                {
                    var result   = startUp.GetConfig();
                    if (result.Item1)
                    {
                        var ws = new WormholeService(result.Item2.PipeName);
                        ws.StartServer();
                    }
                    else
                    {
                        if (!Environment.UserInteractive) return;
                        Console.WriteLine("Config file not found.");
       
                    }
                }
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