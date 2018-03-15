
IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id = OBJECT_ID('tempdb..#Description')) DROP TABLE #Description
GO
CREATE TABLE #Description ([Description] NVARCHAR(500))
GO
----------------------------------------
----------------------------------------
INSERT INTO #Description VALUES('Create table SchemaChanges')
GO

CREATE TABLE [dbo].[SchemaChanges](
	[MajorReleaseNumber] [varchar](5) NULL,
	[MinorReleaseNumber] [varchar](5) NULL,
	[BuildReleaseNumber] [varchar](5) NULL,
	[RevisionReleaseNumber] [varchar](5) NULL,
	[ScriptName] [varchar](50) NULL,
	[Description] [nvarchar](500) NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO