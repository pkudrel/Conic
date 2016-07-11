using System.Collections.Generic;
using System.Runtime.Serialization;

namespace Conic.Manifest
{
    [DataContract]
    public class MessagingHostDefinition
    {
        public MessagingHostDefinition(
            string name,
            string extensionDescription,
            string pathToConnector,
            string connectionType,
            string chromeExtensionId)
        {
            AllowedOrigins = new List<string>();
            Name = name;
            Description = extensionDescription;
            Path = pathToConnector;
            Type = connectionType;
            AddAllowedOrigin(chromeExtensionId);
        }

        /// <summary>
        /// Name of the native messaging host.
        /// Clients pass this string to runtime.connectNative or runtime.sendNativeMessage.
        /// This name can only contain lowercase alphanumeric characters, underscores and dots.
        /// The name cannot start or end with a dot, and a dot cannot be followed by another dot.
        /// </summary>
        [DataMember(Name = "name")]
        public string Name { get; set; }

        /// <summary>
        /// Short application description.
        /// </summary>
        [DataMember(Name = "description")]
        public string Description { get; set; }

        /// <summary>
        /// Path to the native messaging host binary.
        /// On Windows it can be relative to the directory in which the manifest file is located.
        /// The host process is started with the current directory set to the directory that contains the host binary.
        /// For example if this parameter is set to C:\Application\nm_host.exe then it will be started with current directory
        /// C:\Application\.
        /// </summary>
        [DataMember(Name = "path")]
        public string Path { get; set; }

        /// <summary>
        /// Type of the interface used to communicate with the native messaging host.
        /// Currently there is only one possible value for this parameter: stdio.
        /// It indicates that Chrome should use stdin and stdout to communicate with the host.
        /// </summary>
        [DataMember(Name = "type")]
        public string Type { get; set; }

        /// <summary>
        /// List of extensions that should have access to the native messaging host.
        /// Wildcards such as chrome-extension://*/* are not allowed.
        /// </summary>
        [DataMember(Name = "allowed_origins")]
        public List<string> AllowedOrigins { get; set; }


        public void AddAllowedOrigin(string chromeExtensionId)
        {
            AllowedOrigins.Add($@"chrome-extension://{chromeExtensionId}/");
        }
    }
}