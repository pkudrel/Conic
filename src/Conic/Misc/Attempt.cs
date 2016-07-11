using System;
using System.Runtime.ExceptionServices;

namespace Conic.Misc
{
    /// <summary>
    /// Utility and extension methods for convenient and easy to read error handling.
    /// </summary>
    /// <remarks>
    /// Credits to: https://github.com/Core-Techs/Common/blob/master/CoreTechs.Common/Attempt.cs
    /// </remarks>
    public class Attempt
    {
        private readonly ExceptionDispatchInfo _exDispatchInfo;

        private readonly Lazy<TimeSpan> _lazyDuration;

        internal Attempt(DateTimeOffset beginDateTime, ExceptionDispatchInfo exInfo = null)
        {
            _lazyDuration = new Lazy<TimeSpan>(() => EndDateTime - BeginDateTime);
            EndDateTime = DateTimeOffset.Now;
            BeginDateTime = beginDateTime;
            _exDispatchInfo = exInfo;
        }

        /// <summary>
        /// When the attempt began.
        /// </summary>
        public DateTimeOffset BeginDateTime { get; }

        /// <summary>
        /// The exception that was thrown.
        /// </summary>
        public Exception Exception => _exDispatchInfo?.SourceException;

        /// <summary>
        /// How long the attempt took.
        /// </summary>
        public TimeSpan Duration => _lazyDuration.Value;

        /// <summary>
        /// When the attempt ended.
        /// </summary>
        public DateTimeOffset EndDateTime { get; }

        /// <summary>
        /// Invokes the factory, suppressing any thrown exception.
        /// </summary>
        /// <param name="factory"></param>
        /// <param name="default">The result value when not successful.</param>
        public static Attempt<T> Get<T>(Func<T> factory, T @default = default(T))
        {
            var begin = DateTimeOffset.Now;
            T result;

            try
            {
                result = factory();
            }
            catch (Exception ex)
            {
                var exInfo = ExceptionDispatchInfo.Capture(ex);
                return new Attempt<T>(begin, @default, exInfo);
            }

            return new Attempt<T>(begin, result);
        }
    }

    public class Attempt<T> : Attempt
    {
        internal Attempt(DateTimeOffset beginDateTime, T value, ExceptionDispatchInfo exception = null)
            : base(beginDateTime, exception)
        {
            Value = value;
        }

        /// <summary>
        /// The value that was created by the factory.
        /// </summary>
        public T Value { get; }
    }
}