using System;
using System.Windows.Forms;
using NamedPipeWrapper;
using Newtonsoft.Json;
using Message = Conic.Example.WinForm.Models.Message;

namespace Conic.Example.WinForm
{
    public partial class MainForm : Form
    {
        private const string _PIPE_NAME = "default.conic.pipename";
        private readonly NamedPipeClient<string> _client = new NamedPipeClient<string>(_PIPE_NAME);

        public MainForm()
        {
            InitializeComponent();
            splitContainer1.FixedPanel = FixedPanel.Panel2;
        }


        private void ActiveClient()
        {
            _client.ServerMessage += OnServerMessage;
            _client.AutoReconnect = true;
            _client.Start();
        }

        private void DeactiveClient()
        {
            _client.ServerMessage -= OnServerMessage;
            _client.Stop();
        }

        private void OnServerMessage(NamedPipeConnection<string, string> connection, string txt)
        {
            var message = JsonConvert.DeserializeObject<Message>(txt);
            var msg = $"Chrome: {message.Text}";
            if (!log.InvokeRequired)
                AppendLog(msg);
            else
                log.Invoke(new MethodInvoker(() => { AppendLog(msg); }));
        }

        private void SendMessage()
        {
            var message = textBoxMessage.Text;
            _client.PushMessage(JsonConvert.SerializeObject(new Message(textBoxMessage.Text)));
            AppendLog($"Me: {message} ");
            textBoxMessage.Text = "";
        }

        private void AppendLog(string msg)
        {
            log.AppendText(msg + Environment.NewLine);
        }

        private void MainForm_Load(object sender, EventArgs e)
        {
            ActiveClient();
        }


        private void MainForm_Closing(object sender, EventArgs e)
        {
            DeactiveClient();
        }

        private void buttonSend_Click(object sender, EventArgs e)
        {
            SendMessage();
        }

        private void textBoxMessage_OnKeyPress(object sender, KeyPressEventArgs e)
        {
            if (e.KeyChar == (char) Keys.Return)

            {
                SendMessage();
            }
        }
    }
}