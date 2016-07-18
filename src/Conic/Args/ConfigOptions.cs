using System.Collections.Generic;
using CommandLine;
using CommandLine.Text;

namespace Conic.Args
{
    [Verb("init-config", HelpText = "Create or override config file")]
    public class ConfigOptions
    {
        [Option("pipe",
            HelpText =
                "Named pipe to to stream the data to external application",
            Required = true,
            MetaValue = "FILE"
            )]
        public string PipeName { get; set; }




        [Usage(ApplicationAlias = "conic")]
        public static IEnumerable<Example> Examples
        {
            get
            {
                yield return
                    new Example("Normal scenario",
                        new ConfigOptions
                        {
                            PipeName = "example.conic.pipe"
                        });
            }
        }
    }
}