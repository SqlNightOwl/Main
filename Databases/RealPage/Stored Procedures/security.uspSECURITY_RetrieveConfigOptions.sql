SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Johan Williams
-- Create date: May 16, 2002
-- Description:	Simply retrieves all configuration
--				options for a given source.
-- =============================================
CREATE PROCEDURE [security].[uspSECURITY_RetrieveConfigOptions]
	-- Add the parameters for the stored procedure here
	(@bySource varchar(255) = null)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	if(@bySource is not null and @bySource <> '')
		begin
			-- Retrieves all configuration options by Source/PageName

			SELECT	[IDSeq],[PageName],[ConfigOption],
					[ConfigValue]
			FROM	[SECURITY].[dbo].[ConfigOptions]
			WHERE	[pageName] = @bySource;
		end
END
GO
