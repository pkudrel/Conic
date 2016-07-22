using CommandLine;

namespace Conic.Args
{
    public class ChromeOptions
    {
        public class ConfigOptions
        {
            [Option("parent-window",
                HelpText = "Parent window number",
                Required = false,
                MetaValue = "FILE"
                )]
            public string ParentWindow { get; set; }

            [Option("chrome-extension",
                HelpText = "Chrome extension ID",
                Required = false,
                MetaValue = "FILE"
                )]
            public string ChromeExtension { get; set; }
        }
    }
}