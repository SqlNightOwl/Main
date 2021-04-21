SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


----------------------------------------------------------------------------------------------------
-- Database  Name  : SECURITY
-- Procedure Name  : uspSECURITY_UpdateRightDetails
-- Description     : Update Right details
-- Input Parameters: 
-- Code Example    : EXEC SECURITY.dbo.uspSECURITY_UpdateRightDetails  @IPN_RightIDSeq = 1, @IPVC_RightName = 'View Credit Memos', 
--							@IPVC_RightCode = 'ViewCredit', @IPVC_LoggedInUser = 'RRI\dnethunuri'

-- Revision History:
-- Author          : dnethunuri
-- 11/22/2010      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [security].[uspSECURITY_UpdateRightDetails] (                                                          
                                                            @IPN_RightIDSeq		BIGINT, 
															@IPVC_RightName		VARCHAR(50), 
															@IPVC_RightCode		VARCHAR(20), 
															@IPVC_LoggedInUser VARCHAR(50)
                                                         
)
AS
BEGIN

---------------------------------------------------------------------------
  DECLARE @LN_CreatedByID BIGINT
  ---------------------------------------------------------------------------
  SELECT  @LN_CreatedByID = IDSeq
  FROM    [User]
  WHERE   NTUser = @IPVC_LoggedInUser 
    ---------------------------------------------------------------
    UPDATE  [Rights] 
    SET 
		[Name] = @IPVC_RightName,
		ModifiedDate = GETDATE(), 
		ModifiedByIDSeq = @LN_CreatedByID 
    WHERE IDSeq = @IPN_RightIDSeq AND Code = @IPVC_RightCode
    ---------------------------------------------------------------
    SELECT  @IPN_RightIDSeq
 

END
GO
