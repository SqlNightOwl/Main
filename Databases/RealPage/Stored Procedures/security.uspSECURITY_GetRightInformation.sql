SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : SECURITY
-- Procedure Name  : uspSECURITY_GetRightInformation
-- Description     : Get Individual Right details
-- Input Parameters: 
-- Code Example    : EXEC [SECURITY].dbo.[uspSECURITY_RightsList]  1

-- Revision History:
-- Author          : dnethunuri
-- 11/22/2010      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [security].[uspSECURITY_GetRightInformation] (@IPN_RightIDSeq bigint)
AS
BEGIN
 
  SELECT  Code, [Name]
  FROM    Rights 
  WHERE   IDSeq = @IPN_RightIDSeq
  
END
GO
