SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCUSTOMERS_AlreadyAddedinterface]
-- Description     : This procedure Selects [uspCUSTOMERS_AlreadyAddedinterface] in Customer and Property Table
--Input Parameter  : @IPVC_CustomerIDSEQ           bigint, 
--                  
--
-- Code Example    : [CUSTOMERS].dbo.[uspCUSTOMERS_AlreadyAddedinterface] @IPN_InterfaceID=14
--                   
--
-- Revision History:
-- Author          : Naval Kishore
-- 12/21/2009      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_AlreadyAddedinterface] 
													  (@CompanyID char(11),
													   @PropertyID char(11) = '',
													   @InterfacedSystemID varchar(50),
													   @InterfacedSystemCode varchar(5),
													   @InterfacedSystemIDTypeCode varchar(5)
													   )
AS
BEGIN 
  set nocount on;
	 
    SELECT IDSeq
	FROM Customers.dbo.InterfacedSystemIdentifier with (nolock)
	WHERE  CompanyIDSeq = @CompanyID
	 and  isnull(PropertyIDSeq,'') = @PropertyID
	 and   InterfacedSystemID = @InterfacedSystemID
	 and   InterfacedSystemCode = @InterfacedSystemCode
	 and   InterfacedSystemIDTypeCode = @InterfacedSystemIDTypeCode
   
---------------------------------------------------------------------------------
END
GO
