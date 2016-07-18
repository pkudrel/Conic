using System.Collections.Generic;
using CommandLine;
using CommandLine.Text;

namespace Conic.Args
{
    [Verb("init-manifest", HelpText = "Create or override manifest file")]
    public class ManifestOptions
    {
        [Option("name",
            HelpText =
                "Name of the native messaging host. Clients pass this string to runtime.connectNative or runtime.sendNativeMessage.",
            Required = true
            )]
        public string Name { get; set; }


        [Option("extension-id", HelpText = "Extension id that can use conic host", Required = true)]
        public string ExtensionId { get; set; }


        [Usage(ApplicationAlias = "conic")]
        public static IEnumerable<Example> Examples
        {
            get
            {
                yield return
                    new Example("Normal scenario",
                        new ManifestOptions
                        {
                            Name = "example.host",
                            ExtensionId = "example.id"
                        });
            }
        }
    }
}