// 

using System;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Security.AccessControl;
using System.Security.Principal;
using System.Threading;

namespace Conic.Misc
{
    /// <summary>
    /// 
    /// </summary>
    /// <remarks>
    /// Thanks to: http://stackoverflow.com/a/7810107/64334
    /// </remarks>
    public class SingleInstance : IDisposable
    {
        private const int _DEFAULT_TIMEOUT = 1;
        public bool HasHandle = false;
        private Mutex _mutex;

        private void InitMutex(Guid appGuid)
        {
            var mutexId = $"Global\\{{{appGuid}}}";
            _mutex = new Mutex(false, mutexId);

            var allowEveryoneRule = new MutexAccessRule(new SecurityIdentifier(WellKnownSidType.WorldSid, null), MutexRights.FullControl, AccessControlType.Allow);
            var securitySettings = new MutexSecurity();
            securitySettings.AddAccessRule(allowEveryoneRule);
            _mutex.SetAccessControl(securitySettings);
        }

        public SingleInstance(int timeOut = _DEFAULT_TIMEOUT) : this(Assembly.GetEntryAssembly(), timeOut) { }
        public SingleInstance(Assembly assembly, int timeOut = _DEFAULT_TIMEOUT) : this(GetAssemblyId(assembly), timeOut) { }

        public SingleInstance(Guid id, int timeOut = _DEFAULT_TIMEOUT)
        {
            InitMutex(id);
            try
            {
                HasHandle = _mutex.WaitOne(timeOut <= 0 ? Timeout.Infinite : timeOut, false);

                if (!HasHandle)
                    throw new TimeoutException("Timeout waiting for exclusive access on SingleInstance");
            }
            catch (AbandonedMutexException)
            {
                HasHandle = true;
            }
        }

        private static Guid GetAssemblyId(Assembly assembly)
        {
            var appGuid = ((GuidAttribute)assembly.GetCustomAttributes(typeof(GuidAttribute), false)
                    .GetValue(0)).Value;
            return new Guid(appGuid);
        }

        public void Dispose()
        {
            if (_mutex == null) return;
            if (HasHandle)
                _mutex.ReleaseMutex();
            _mutex.Dispose();
        }
    }
}