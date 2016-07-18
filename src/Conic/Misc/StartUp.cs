using System;
using System.IO;
using System.Reflection;
using System.Text;
using Conic.Args;
using Conic.Manifest;

namespace Conic.Misc
{
    internal class StartUp
    {
        private const string _CONIC_CONFIG_JSON = "conic.config.json";
        private const string _MANIFEST_FILE = "manifest.json";

        private string AppDirectoryPath
            =>
                Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);

        private string PathToConfigFile => Path.Combine(AppDirectoryPath, _CONIC_CONFIG_JSON);
        private string PathToManifestFile => Path.Combine(AppDirectoryPath, _MANIFEST_FILE);
        private string PathToConnectorExeFile => Assembly.GetExecutingAssembly().Location;

        public Tuple<bool, Config> GetConfig()
        {
            if (File.Exists(PathToConfigFile))
            {
                var txt = File.ReadAllText(PathToConfigFile);
                var obj = Json<Config>.Deserialize(txt);
                return new Tuple<bool, Config>(true, obj);
            }
            return new Tuple<bool, Config>(false, null);
        }


        public void CreateManifest(ManifestOptions manifestOptions)
        {
            var m = new ManifestService(PathToConnectorExeFile, PathToManifestFile);
            m.CreateManifestUpdateRegistry(manifestOptions.Name, manifestOptions.ExtensionId);
        }

        public void CreateConfig(ConfigOptions configOptions)
        {
            var result = new Config
            {
                PipeName = configOptions.PipeName
            };
            var txt = Json<Config>.Serialize(result);
            File.WriteAllText(PathToConfigFile, txt, Encoding.UTF8);
        }
    }
}