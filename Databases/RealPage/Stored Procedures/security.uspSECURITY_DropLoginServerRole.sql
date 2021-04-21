SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : SECURITY
-- Procedure Name  : [uspSECURITY_DropLoginServerRole]
-- Description     : This procedure removes the specified users from the specified server role.
-- Input Parameters: 
--                   @Role VARCHAR(50)                  -> The role that the login(s) will be removed.
--                   @Login VARCHAR(100) = NULL         -> The single login that will be removed from the specfied role. 
--	                                                   All logins in the specified role will be removed if this is 
--                                                           NOT provided.
--                   @ExceptionLogins VARCHAR(255) = ''	-> A comma delimited list (ex: Login1, Login2, Login3) of logins to 
--                                                           OMIT if the @Login parameter is NOT provided.
-- 
-- OUTPUT          : RecordSet of the login(s) that were removed from the specified role.
--
-- Code Example (to remove a single login)
--		EXEC uspSECURITY_DropLoginServerRole @Role = 'sysadmin', @Login = 'Login1'
-- Code Example (to remove ALL logins mapped to role)
--		EXEC uspSECURITY_DropLoginServerRole @Role = 'sysadmin'
-- Code Example (to remove ALL logins mapped to role except specfied logins)
--		EXEC uspSECURITY_DropLoginServerRole @Role = 'sysadmin', @ExceptionLogins = 'Login1, Login2'
-- 
-- Revision History:
-- Author         : Brent Mitchell
-- 09/15/2009     : Created
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [security].[uspSECURITY_DropLoginServerRole]
	(@Role              VARCHAR(50),
  	 @Login             VARCHAR(100) = NULL,
	 @ExceptionLogins   VARCHAR(255) = ''
        )
AS

BEGIN
        SET NOCOUNT ON;
	-------------------------------------------------------------------------------------------------------------
	-- Determine if role passed in exists.
	-------------------------------------------------------------------------------------------------------------
	DECLARE @ErrorMessage VARCHAR(50)

	IF NOT EXISTS(SELECT * FROM sys.server_principals WHERE [Name] = @Role)
	BEGIN
		SET @ErrorMessage = 'The role name ' + @Role + ' does NOT exist.'

		RAISERROR(@ErrorMessage, 16, 1)
		RETURN
	END
	-------------------------------------------------------------------------------------------------------------
	-- Only drop the login from the specified role if the @Login parameter was passed.
	-------------------------------------------------------------------------------------------------------------
	IF @Login IS NOT NULL
	BEGIN
		IF EXISTS(SELECT * FROM sys.server_principals WHERE [Name] = @Login)
		BEGIN
			EXEC sp_dropsrvrolemember @Login, @Role
			SELECT @Login
		END

		ELSE
		BEGIN
			SET @ErrorMessage = 'The login name ' + @Login + ' does NOT exist.'

			RAISERROR(@ErrorMessage, 16, 1)
			RETURN
		END
	END

	ELSE

	-------------------------------------------------------------------------------------------------------------
	-- Drop ALL logins from the specified role if the @Login parameter was NOT passed.
	-------------------------------------------------------------------------------------------------------------
	BEGIN
		DECLARE 
			@RowIndex INT,
			@RowCount INT,
			@LoginToRemove VARCHAR(100),
			@DefaultExceptionLogins VARCHAR(MAX),
			@ServerName VARCHAR(50)

		SELECT @ServerName = @@SERVERNAME
		SET @DefaultExceptionLogins = 
			'''sa'', ''one_1_audit'', ''omsbuilduser'', ''' 
                        + 'BUILTIN\Administrators'',''NT AUTHORITY\SYSTEM'',''NT AUTHORITY\NETWORK SERVICE'', ''' 
			+ @ServerName + '\SQLServer2005MSSQLUser$' + @ServerName    + '$MSSQLSERVER'', '''
                        + @ServerName + '\SQLServer2005MSFTEUser$' + @ServerName    + '$MSSQLSERVER'', ''' 
			+ @ServerName + '\SQLServer2005SQLAgentUser$' + @ServerName + '$MSSQLSERVER'', '

		SET @ExceptionLogins = '''' + REPLACE(@ExceptionLogins, ',', ''', ''') + ''''

		DECLARE @LoginsInRole TABLE
		(
			IDSeq INT NOT NULL IDENTITY(1, 1),
			[Login] VARCHAR(100)
		)

		INSERT INTO @LoginsInRole
		(
			[Login]
		)
		EXEC 
		(
			'SELECT 
				[Login] = mem.name
                         FROM 
				sys.server_role_members srm with (nolock)
				INNER JOIN sys.server_principals rol with (nolock) ON (rol.principal_id = srm.role_principal_id)
				INNER JOIN sys.server_principals mem with (nolock) ON (mem.principal_id = srm.member_principal_id)
			 WHERE 
				rol.name = ''' + @Role + '''' + 
				' AND mem.name NOT IN (' + @DefaultExceptionLogins + @ExceptionLogins + ')'
		)

		SET @RowIndex = 1
		SELECT @RowCount = (SELECT MAX(IDSeq) FROM @LoginsInRole)

		WHILE @RowIndex <= @RowCount
		BEGIN
			SELECT @LoginToRemove = [Login] FROM @LoginsInRole WHERE IDSeq = @RowIndex
			EXEC sp_dropsrvrolemember @LoginToRemove, @Role

			SET @RowIndex = @RowIndex + 1
		END
		
		SELECT [Login] FROM @LoginsInRole
	END
END
GO
