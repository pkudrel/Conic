using System;
using System.Text.RegularExpressions;
using NLog;

namespace Conic.Manifest
{
    public class HostDefinitionValidator
    {
        private static readonly Logger _log = LogManager.GetCurrentClassLogger();
        private readonly Regex _rx = new Regex("^[a-z0-9_\\.]+$");

        public bool Validate(MessagingHostDefinition messagingHostDefinition)
        {
            var validName = ValidateName(messagingHostDefinition.Name);
            if (validName)
            {
                return true;
            }
            _log.Error(
                $"Host name: {messagingHostDefinition.Name} definition is not valid: " +
                "Read more: https://developer.chrome.com/extensions/nativeMessaging");
            return false;
        }

        /// <summary>
        /// This name can only contain lowercase alphanumeric characters, underscores and dots.
        /// The name cannot start or end with a dot, and a dot cannot be followed by another dot.
        /// </summary>
        private bool ValidateName(string name)
        {
            //This name can only contain lowercase alphanumeric characters, underscores and dots.
            if (!_rx.IsMatch(name)) return false;

            //The name cannot start or end with a dot
            if (name.StartsWith(".", StringComparison.Ordinal)) return false;
            if (name.EndsWith(".", StringComparison.Ordinal)) return false;

            // dot cannot be followed by another dot.
            if (name.Contains("..")) return false;

            return true;
        }
    }
}