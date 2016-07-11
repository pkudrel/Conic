using System.IO;
using Conic.Misc;
using NLog;
using Registry = Microsoft.Win32.Registry;

namespace Conic.Manifest
{
    public class ManifestService
    {
        private const string _MANIFEST_COMPANY_NAME = @"default.conic.host";

        private const string _MANIFEST_COMMUNICATION_TYPE = @"stdio";
        private const string _CHROME_EXTENSION_ID_MAIN = @"you-should-change-this-to-your-extension-id";

        private const string _CHROME_EXTENSION_REGISTRY_KEY =
            @"HKEY_CURRENT_USER\SOFTWARE\Google\Chrome\NativeMessagingHosts";

        private const string _MANIFEST_DESCRIPTION =
            @"Read more: https://developer.chrome.com/extensions/nativeMessaging";


        private static readonly Logger _log = LogManager.GetCurrentClassLogger();
        private readonly HostDefinitionValidator _hostDefinitionValidator = new HostDefinitionValidator();
        private readonly string _pathToConnectorExeFile;
        private readonly string _pathToManifestFile;
        private MessagingHostDefinition _definition;

        public ManifestService(string pathToConnectorExeFile, string pathToManifestFile)
        {
            _pathToConnectorExeFile = pathToConnectorExeFile;
            _pathToManifestFile = pathToManifestFile;
        }

        public void InitializeManifest()
        {
            _log.Trace("Checking manifest state");
            if (!File.Exists(_pathToManifestFile))
            {
                _log.Trace("Manifest file does not exist. Creating new one.");
                _definition = CreateManifest();
                var src = Json<MessagingHostDefinition>.Serialize(_definition);
                File.WriteAllText(_pathToManifestFile, src);
            }
            else
            {
                var txt = File.ReadAllText(_pathToManifestFile);
                _definition = Json<MessagingHostDefinition>.Deserialize(txt);
            }
            _log.Trace($"Manifest file path: {_pathToManifestFile}; Name: '{_definition.Name}'");
            if (_hostDefinitionValidator.Validate(_definition))
            {
                _log.Trace("Manifest file is valid. Updating registry.");
                UpdateRegistry(_pathToManifestFile, _definition.Name);
            }
            else
            {
                _log.Error("Host definition is not valid.");
            }
        }


        private MessagingHostDefinition CreateManifest()
        {
            return new MessagingHostDefinition(
                _MANIFEST_COMPANY_NAME,
                _MANIFEST_DESCRIPTION,
                _pathToConnectorExeFile,
                _MANIFEST_COMMUNICATION_TYPE,
                _CHROME_EXTENSION_ID_MAIN);
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
    }
}