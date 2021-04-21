SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCUSTOMERS_GetRelatedOtherAccounts]
-- Description     : This procedure Selects CustomBundlesProductBreakDownTypeCode in Customer and Property Table
--Input Parameter  : @IPVC_CustomerIDSEQ           bigint, 
--                  
--
-- Code Example    : [CUSTOMERS].dbo.[uspCUSTOMERS_GetRelatedInterfaceDetails] @IPN_InterfaceID=14
--                   
--
-- Revision History:
-- Author          : Naval Kishore
-- 12/21/2009      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_GetRelatedInterfaceDetails] @IPN_InterfaceID   int

AS
BEGIN 
  set nocount on;
 
    SELECT InterfacedSystemID,
		   InterfacedSystemClientType,
		   InterfacedSystemCode,
		   InterfacedSystemIDTypeCode 
	FROM Customers.dbo.InterfacedSystemIdentifier with (nolock)
    WHERE  IDSEQ = @IPN_InterfaceID
    
---------------------------------------------------------------------------------
END
GO
