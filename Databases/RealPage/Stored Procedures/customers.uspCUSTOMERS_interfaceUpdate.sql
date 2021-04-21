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
-- Code Example    : [CUSTOMERS].dbo.[uspCUSTOMERS_interfaceUpdate] @IPN_InterfaceID=14
--                   
--
-- Revision History:
-- Author          : Naval Kishore
-- 12/21/2009      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_interfaceUpdate] (@CompanyID char(11),
													   @PropertyID char(11),
													   @InterfacedSystemID varchar(50),
													   @InterfacedSystemClientType varchar(30), 
													   @InterfacedSystemCode varchar(5),
													   @InterfacedSystemIDTypeCode varchar(5),
													   @IPVC_ModifiedByIDSeq bigint,
													   @IDSEQ bigint
													   )

AS
BEGIN 
  set nocount on;
	 set @PropertyID = nullif(@PropertyID,'');

    UPDATE  Customers.dbo.InterfacedSystemIdentifier
	SET 	InterfacedSystemID         = @InterfacedSystemID ,
		    InterfacedSystemClientType = @InterfacedSystemClientType,
		    InterfacedSystemCode       = @InterfacedSystemCode,
		    InterfacedSystemIDTypeCode = @InterfacedSystemIDTypeCode,
			ModifiedByUserIDSeq        = @IPVC_ModifiedByIDSeq,
	        ModifiedDate               = Getdate()
    WHERE  IDSEQ = @IDSEQ
    
---------------------------------------------------------------------------------
END
GO
