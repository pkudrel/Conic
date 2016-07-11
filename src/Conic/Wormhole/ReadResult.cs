namespace Conic.Wormhole
{
    public struct ReadResult
    {
        public ReadResult(int imputLength, string value)
        {
            Value = value;
            ImputLength = imputLength;
        }

        public string Value { get; set; }
        public int ImputLength { get; set; }
    }
}