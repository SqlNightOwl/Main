SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_CompanyRegionalOfficeUpdate
-- Description     : This procedure gets called for Update of existing Regional Office of Company
--                    This procedure takes care of Update Only Company Regional Office Record
-- Input Parameters: As Below in Sequential order.
-- Code Example    : Exec CUSTOMERS.DBO.uspCUSTOMERS_CompanyRegionalOfficeUpdate  Passing Input Parameters
-- Revision History:
-- Author          : SRS
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_CompanyRegionalOfficeUpdate] (@IPVC_CompanyIDSeq               varchar(50),       --> CompanyID (Mandatory) 
                                                                   @IPBI_RegionalOfficeID           bigint,            --> Mandatory. UI knows as part of resultset from EXEC CUSTOMERS.dbo.uspCUSTOMERS_AddressSelect call
                                                                   @IPVC_RegionalOfficeDescription  varchar(255)='',   --> This is optional; Extra user entered Description
                                                                   @IPBI_UserIDSeq                  bigint             --> This is UserID of person logged on and creating this Address in OMS.(Mandatory)
                                                                  )
as
BEGIN
  set nocount on;
  -----------------------------------------------
  declare @LDT_SystemDate      datetime
  -----------------------------------------------
  select @LDT_SystemDate      = Getdate(),
         @IPVC_RegionalOfficeDescription = LTRIM(RTRIM(NULLIF(@IPVC_RegionalOfficeDescription,'')))
  -----------------------------------------------
  Update Customers.dbo.CompanyRegionalOffice
  set    RegionalOfficeDescription = @IPVC_RegionalOfficeDescription,
         ModifiedByIDSeq      = @IPBI_UserIDSeq,
         ModifiedDate         = @LDT_SystemDate,
         SystemLogDate        = @LDT_SystemDate
  where  CompanyIdSeq         = @IPVC_CompanyIDSeq
  and    RegionalOfficeIDSeq  = @IPBI_RegionalOfficeID
END
GO
