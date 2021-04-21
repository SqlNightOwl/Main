SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : SECURITY
-- Procedure Name  : uspSECURITY_UserInsert
-- Description     : This procedure inserts/updates an user.
-- Input Parameters: 	@IPN_UserIDSeq    bigint, 
--                    @IPVC_NTUser      varchar(50), 
--                    @IPVC_FirstName   varchar(50), 
--                    @IPVC_LastName    varchar(50), 
--                    @IPVC_Title       varchar(50),
--                    @IPVC_Email       varchar(50), 
--                    @IPVC_CreatedByUser    varchar(50),
--                    @IPVC_Department  varchar(70)
-- 
-- OUTPUT          : RecordSet of ID created
-- Code Example    : 
-- 
-- Revision History:
-- Author          : RealPage
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [security].[uspSECURITY_UserInsert]  (  @IPN_UserIDSeq    bigint, 
                                                @IPVC_NTUser      varchar(50), 
                                                @IPVC_FirstName   varchar(50), 
                                                @IPVC_LastName    varchar(50), 
                                                @IPVC_Title       varchar(50),
                                                @IPVC_Email       varchar(50), 
                                                @IPVC_CreatedByUser    varchar(50),
                                                @IPVC_Department  varchar(70)
                                              )
AS
BEGIN
  ---------------------------------------------------------------------------
  DECLARE @LN_CreatedByID BIGINT
  ---------------------------------------------------------------------------
  SELECT  @LN_CreatedByID = IDSeq
  FROM    [User]
  WHERE   NTUser = @IPVC_CreatedByUser
  ---------------------------------------------------------------------------
  IF @IPN_UserIDSeq <> 0
  ---------------------------------------------------------------------------
  BEGIN
    ---------------------------------------------------------------
    UPDATE  [User] 
    SET     FirstName       = @IPVC_FirstName, 
            LastName        = @IPVC_LastName, 
            Title           = @IPVC_Title, 
            Email           = @IPVC_Email, 
            ModifiedDate    = getdate(),
            ModifiedByIDSeq = @LN_CreatedByID,
            Department      = @IPVC_Department
    WHERE   IDSeq           = @IPN_UserIDSeq
    ---------------------------------------------------------------
    DELETE  UserRoles
    WHERE   UserIDSeq = @IPN_UserIDSeq
    ---------------------------------------------------------------
    SELECT  @IPN_UserIDSeq
  ---------------------------------------------------------------------------
  END
  ---------------------------------------------------------------------------
  ELSE IF NOT EXISTS (SELECT 1 FROM [User] WHERE NTUser = @IPVC_NTUser)
  ---------------------------------------------------------------------------
  BEGIN
    ---------------------------------------------------------------
    INSERT INTO [User] (  
                          NTUser, FirstName, LastName, Title, Email, 
                          CreatedDate, CreatedByIDSeq, ModifiedDate,
                          ModifiedByIDSeq, ActiveFlag, Department
                        )
    VALUES            (
                          @IPVC_NTUser, @IPVC_FirstName, 
                          @IPVC_LastName, @IPVC_Title, @IPVC_Email, 
                          getdate(), @LN_CreatedByID,
                          getdate(), @LN_CreatedByID, 1, 
                          @IPVC_Department
                      )
    ---------------------------------------------------------------
    SELECT @@IDENTITY
    ---------------------------------------------------------------
  END
  ELSE
  ---------------------------------------------------------------
  BEGIN
    SELECT 0
  END
  ---------------------------------------------------------------
END




 
GO
