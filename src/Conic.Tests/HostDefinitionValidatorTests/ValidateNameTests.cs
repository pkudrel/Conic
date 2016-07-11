using Conic.Manifest;
using Xunit;

namespace Conic.Tests.HostDefinitionValidatorTests
{
    public class ValidateNameTests
    {
        private readonly HostDefinitionValidator _hostDefinitionValidator;

        public ValidateNameTests()
        {
            _hostDefinitionValidator = new HostDefinitionValidator();
        }

        private MessagingHostDefinition CreateManifest(string name)
        {
            return new MessagingHostDefinition(name,
                string.Empty,
                string.Empty,
                string.Empty, string.Empty);
        }

        private bool Act(string name)
        {
            var m = CreateManifest(name);
            return _hostDefinitionValidator.Validate(m);
        }

        [Theory]
        [InlineData("name")]
        [InlineData("name_")]
        [InlineData("name_name")]
        [InlineData("name.name")]
        [InlineData("name.name.name")]
        [InlineData("name_name_name")]
        public void this_name_should_be_valid(string name)
        {
            var res = Act(name);
            Assert.Equal(true, res);
        }


        [Theory]
        [InlineData("name_.")]
        [InlineData("naMe_.")]
        [InlineData("na..me")]
        [InlineData(".name")]
        [InlineData(".name.")]
        [InlineData("na-me")]
        [InlineData("nAme")]
        public void this_name_should_be_not_valid(string name)
        {
            var res = Act(name);
            Assert.Equal(false, res);
        }
    }
}