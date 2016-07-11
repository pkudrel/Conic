using System;
using System.Text;
using NamedPipeWrapper;
using NLog;

namespace Conic.Wormhole
{

    /// <summary>
    /// WormholeService:
    /// - creates NamedPipeServer
    /// - waits on the StandardInput for a message, reads it, and puts it on pipe
    /// - waits on pipe for message and puts it on the StandardOutput
    /// </summary>
    public class WormholeService
    {
        private static readonly Logger _log = LogManager.GetCurrentClassLogger();
        //private static readonly Logger _log = LogManager.CreateNullLogger();
        private readonly string _pipeName;

        public WormholeService(string pipeName)
        {
            _pipeName = pipeName;
        }

        public void StartServer()
        {
            _log.Debug($"Start pipe server. Pipe name: '{_pipeName}'");
            var server = new NamedPipeServer<string>(_pipeName);

            server.ClientConnected += OnClientConnected;
            server.ClientDisconnected += OnClientDisconnected;
            server.ClientMessage += OnClientMessage;
            server.Error += OnError;

            try
            {
                server.Start();
                while (true)
                {
                    var r = Read();
                    if (r.ImputLength == 0) break;
                    server.PushMessage(r.Value);
                }
            }
            catch (Exception e)
            {
                _log.Error(e);
            }
            finally
            {
                server.ClientConnected -= OnClientConnected;
                server.ClientDisconnected -= OnClientDisconnected;
                server.ClientMessage -= OnClientMessage;
                server.Error -= OnError;
                server.Stop();
            }
            _log.Debug($"Stop pipe server. Pipe name: '{_pipeName}'");
        }

        private void OnError(Exception exception)
        {
            _log.Error(exception);
        }

        private void OnClientMessage(NamedPipeConnection<string, string> connection, string message)
        {
            _log.Trace(
                $"OnClientMessage; ConnectionName: {connection.Name}, ConnectionId: {connection.Id}, MessageLength: {message.Length}");
            Write(message);
        }


        private void OnClientDisconnected(NamedPipeConnection<string, string> connection)
        {
            _log.Debug($"Client {connection.Id} is now disconnected!");
        }

        private void OnClientConnected(NamedPipeConnection<string, string> conn)
        {
            _log.Debug($"Client {conn.Id} is now connected!");
        }

        /// <summary>
        /// Write message to standard output
        /// Remember: First 4 bytes contains message length
        /// </summary>
        /// <param name="message"></param>
        private void Write(string message)
        {
            _log.Trace($"Begin write to standardOutput message; Length: {message.Length}");
            var buff = Encoding.UTF8.GetBytes(message);
            using (var stdout = Console.OpenStandardOutput())
            {
                stdout.Write(BitConverter.GetBytes(buff.Length), 0, 4); //Write the length
                stdout.Write(buff, 0, buff.Length); //Write the message
                stdout.Flush();
            }
            _log.Trace("End write to standardOutput message");
        }

        /// <summary>
        /// Read  message from standard input
        /// Remember: First 4 bytes contains message length
        /// </summary>
        private ReadResult Read()
        {
            _log.Trace("Begin read from StandardInput");
            int length;
            string input;
            using (var stdin = Console.OpenStandardInput())
            {
                var buff = new byte[4];
                stdin.Read(buff, 0, 4);
                length = BitConverter.ToInt32(buff, 0);
                buff = new byte[length];
                stdin.Read(buff, 0, length);
                input = Encoding.UTF8.GetString(buff);
                _log.Trace($"End read from StandardInput. Message length: {input.Length}");
            }
            return new ReadResult(length, input);
        }
    }
}