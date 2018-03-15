using System.Collections.Generic;
using System.Data;
using System.Data.Common;
using System.Data.SqlClient;

namespace NAnt.Tasks
{
    public class DatabaseGateway
    {
        public static string[] GetExistingUpdates(string tableName, string connectionString)
        {
            using (var connection = new SqlConnection(connectionString))
            {
                var sqlCommand = new SqlCommand(string.Format("SELECT CASE WHEN object_id('{0}') IS NULL THEN 0 ELSE 1 END", tableName), connection)
                    {
                        CommandType = CommandType.Text
                    };
                connection.Open();
                if ((int)sqlCommand.ExecuteScalar() == 0)
                    return new List<string>().ToArray();
            }
            string str = string.Format("SELECT [ScriptName] FROM {0}", tableName);
            var command = new SqlCommand
                {
                    CommandType = CommandType.Text,
                    CommandText = str,
                    Connection = new SqlConnection(connectionString)
                };
            var dbDataReader = ExecuteDataReader(command);
            var list = new List<string>();
            while (dbDataReader.Read())
            {
                string @string = dbDataReader.GetString(0);
                list.Add(@string);
            }
            dbDataReader.Dispose();
            return list.ToArray();
        }

        private static DbDataReader ExecuteDataReader(SqlCommand command)
        {
            command.Connection.Open();
            try
            {
                return command.ExecuteReader(CommandBehavior.CloseConnection);
            }
            catch
            {
                if (command.Connection.State == ConnectionState.Open)
                    command.Connection.Close();
                throw;
            }
        }
    }
}
