using System.IO;
using System.Text;
using Conic.Misc;
using NLog;
using Registry = Microsoft.Win32.Registry;

namespace Conic.Manifest
{
    public class ManifestService
    {
        private const string _MANIFEST_COMPANY_NAME = @"default.conic.host";
        private const string _MANIFEST_COMMUNICATION_TYPE = @"stdio";

        private const string _CHROME_EXTENSION_REGISTRY_KEY =
            @"HKEY_CURRENT_USER\SOFTWARE\Google\Chrome\NativeMessagingHosts";

        private const string _MANIFEST_DESCRIPTION =
            @"Read more: https://developer.chrome.com/extensions/nativeMessaging";


        private static readonly Logger _log = LogManager.GetCurrentClassLogger();
        private readonly HostDefinitionValidator _hostDefinitionValidator = new HostDefinitionValidator();
        private readonly string _pathToConnectorExeFile;
        private readonly string _pathToManifestFile;


        public ManifestService(string pathToConnectorExeFile, string pathToManifestFile)
        {
            _pathToConnectorExeFile = pathToConnectorExeFile;
            _pathToManifestFile = pathToManifestFile;
        }

        /// <summary>
        /// Update registry if:
        /// - key does not exists
        /// - hoste name was changed or
        /// - path to manifest file was changed
        /// </summary>
        /// <param name="hostName"></param>
        /// <param name="pathToManifestFile"></param>
        private void UpdateRegistry(string pathToManifestFile, string hostName = _MANIFEST_COMPANY_NAME)
        {
            var path = $@"{_CHROME_EXTENSION_REGISTRY_KEY}\{hostName}";
            var val = Registry.GetValue(path, "", string.Empty);
            if (val == null)
            {
                Registry.SetValue(path, "", pathToManifestFile);
                return;
            }
            var s = val.ToString();
            if (s != pathToManifestFile)
            {
                Registry.SetValue(path, "", pathToManifestFile);
            }
        }

        public void CreateManifestUpdateRegistry(string name, string extensionId)
        {
            _log.Info("Create new manifest");
            var definition = new MessagingHostDefinition(
                name,
                _MANIFEST_DESCRIPTION,
                _pathToConnectorExeFile,
                _MANIFEST_COMMUNICATION_TYPE,
                extensionId);
            var src = Json<MessagingHostDefinition>.Serialize(definition);
            File.WriteAllText(_pathToManifestFile, src, Encoding.UTF8);
            _log.Trace($"Manifest file path: {_pathToManifestFile}; Name: '{definition.Name}'");
            _log.Trace("Updating registry.");
            UpdateRegistry(_pathToManifestFile, name);
            _log.Info("Manifest file was created");
        }
    }
}