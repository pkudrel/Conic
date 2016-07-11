using System;
using System.IO;
using System.Linq;
using System.Runtime.Serialization.Json;
using System.Text;

namespace Conic.Misc
{
    public class Json<T> where T : class
    {
        private const string _INDENT_STRING = "    ";

        private static string FormatJson(string json)
        {
            var indentation = 0;
            var quoteCount = 0;
            var nl = Environment.NewLine;
            var result =
                from ch in json
                let quotes = ch == '"' ? quoteCount++ : quoteCount
                let lineBreak =
                    ch == ',' && quotes%2 == 0
                        ? ch + nl + string.Concat(Enumerable.Repeat(_INDENT_STRING, indentation))
                        : null
                let openChar =
                    ch == '{' || ch == '['
                        ? ch + nl + string.Concat(Enumerable.Repeat(_INDENT_STRING, ++indentation))
                        : ch.ToString()
                let closeChar =
                    ch == '}' || ch == ']'
                        ? nl + string.Concat(Enumerable.Repeat(_INDENT_STRING, --indentation)) + ch
                        : ch.ToString()
                select lineBreak ?? (openChar.Length > 1
                    ? openChar
                    : closeChar);

            return string.Concat(result);
        }

        /// <summary>
        /// DeSerializes an object from JSON
        /// </summary>
        public static T Deserialize(string json)
        {
            using (var stream = new MemoryStream(Encoding.Default.GetBytes(json)))
            {
                var serializer = new DataContractJsonSerializer(typeof(T));
                return serializer.ReadObject(stream) as T;
            }
        }

        /// <summary>
        /// Serialize object to string
        /// </summary>
        /// <param name="obj"></param>
        /// <returns></returns>

        public static string Serialize(T obj)
        {
            var serializer = new DataContractJsonSerializer(typeof(T));
            using (var stream = new MemoryStream())
            {
                serializer.WriteObject(stream, obj);
                var txt = Encoding.Default.GetString(stream.ToArray())
                    .Replace(@"\/", "/"); //Ugly hack 
                return FormatJson(txt);
            }
        }
    }
}