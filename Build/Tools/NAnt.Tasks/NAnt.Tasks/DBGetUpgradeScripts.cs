using System.IO;
using NAnt.Core;
using NAnt.Core.Attributes;
using NAnt.Core.Types;

namespace NAnt.Tasks
{
    [TaskName("DBGetUpgradeScripts")]
    public class DBGetUpgradeScripts : Task
    {
        [TaskAttribute("OutputFileSetId", Required = true)]
        public string OutputFileSetId { get; set; }

        [TaskAttribute("ConnectionString", Required = true)]
        public string ConnectionString { get; set; }

        [TaskAttribute("UpgradeScriptsFolder", Required = true)]
        public string UpgradeScriptsFolder { get; set; }

        [TaskAttribute("SchemaName", Required = false)]
        public string SchemaName { get; set; }

        public DBGetUpgradeScripts()
        {
            SchemaName = "dbo";
        }

        protected override void ExecuteTask()
        {
            var files = new DirectoryInfo(UpgradeScriptsFolder).GetFiles();
            var includeArray = new FileSet.Include[files.Length];
            for (int index = 0; index < includeArray.Length; ++index)
            {
                var include = new FileSet.Include {Pattern = files[index].Name};
                includeArray[index] = include;
            }
            string[] existingUpdates = DatabaseGateway.GetExistingUpdates(SchemaName + ".[SchemaChanges]", ConnectionString);
            var excludeArray = new FileSet.Exclude[existingUpdates.Length];
            for (int index = 0; index < excludeArray.Length; ++index)
            {
                var exclude = new FileSet.Exclude {Pattern = existingUpdates[index]};
                excludeArray[index] = exclude;
            }
            var fileSet = Project.DataTypeReferences[OutputFileSetId] as FileSet;
            if (fileSet == null)
            {
                throw new BuildException(string.Format("The fileset {0} does not exist in this project. " +
                                                       "Make sure that the Attribute OutputFileSetId refers to an existing FileSet in the Build file.",
                                            OutputFileSetId));
            }
            fileSet.BaseDirectory = new DirectoryInfo(UpgradeScriptsFolder);
            fileSet.IncludeElements = includeArray;
            fileSet.ExcludeElements = excludeArray;
            Project.DataTypeReferences[OutputFileSetId] = fileSet;
        }
    }
}