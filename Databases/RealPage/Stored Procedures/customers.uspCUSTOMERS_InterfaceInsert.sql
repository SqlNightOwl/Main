SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCUSTOMERS_GetRelatedOtherAccounts]
-- Description     : This procedure Selects [uspCUSTOMERS_InterfaceInsert] in Customer and Property Table
--Input Parameter  : @IPVC_CustomerIDSEQ           bigint, 
--                  
--
-- Code Example    : [CUSTOMERS].dbo.[uspCUSTOMERS_InterfaceInsert] @IPN_InterfaceID=14
--                   
--
-- Revision History:
-- Author          : Naval Kishore
-- 12/21/2009      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_InterfaceInsert] (@CompanyID char(11),
													   @PropertyID char(11),
													   @InterfacedSystemID varchar(50),
													   @InterfacedSystemClientType varchar(30), 
													   @InterfacedSystemCode varchar(5),
													   @InterfacedSystemIDTypeCode varchar(5),
													   @IPVC_CreatedByUserID bigint
													   )

AS
BEGIN 
  set nocount on;
	 set @PropertyID = nullif(@PropertyID,'');

	INSERT INTO Customers.dbo.InterfacedSystemIdentifier 
				(
				CompanyIDSeq,
				PropertyIDSeq,
				InterfacedSystemID,
				InterfacedSystemClientType,
				InterfacedSystemCode,
				InterfacedSystemIDTypeCode,
				CreatedByUserIDSeq,
				CreatedDate				
				)
	VALUES	    (
				@CompanyID,
				@PropertyID,
				@InterfacedSystemID,
				@InterfacedSystemClientType,
				@InterfacedSystemCode,
				@InterfacedSystemIDTypeCode,
				@IPVC_CreatedByUserID,
				Getdate()
				)
       
---------------------------------------------------------------------------------
END
GO
