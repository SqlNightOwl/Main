SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_CompanyRegionalOfficeInsert
-- Description     : This procedure gets called for Creation of Brand Company Regional Office
--                    This procedure takes care of Inserting Only Company Regional Office Record
-- Input Parameters: As Below in Sequential order.
-- Code Example    : Exec CUSTOMERS.DBO.uspCUSTOMERS_CompanyRegionalOfficeInsert  Passing Input Parameters
-- Revision History:
-- Author          : SRS
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_CompanyRegionalOfficeInsert] (@IPVC_CompanyIDSeq               varchar(50),       --> CompanyID (Mandatory) 
                                                                   @IPBI_RegionalOfficeID           bigint,            --> Mandatory. Call from Select CUSTOMERS.dbo.fnGetNextAvailableRegionalOfficeID(@IPVC_CompanyIDSeq)
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
  --Safety check Operation.
  if exists(select top 1 1 
            from   Customers.dbo.CompanyRegionalOffice CRO with (nolock)
            where  CRO.CompanyIdSeq = @IPVC_CompanyIDSeq
            and    CRO.RegionalOfficeIDSeq=@IPBI_RegionalOfficeID
           )
  begin
    exec Customers.dbo.uspCUSTOMERS_CompanyRegionalOfficeUpdate @IPVC_CompanyIDSeq=@IPVC_CompanyIDSeq,
                                                                @IPBI_RegionalOfficeID=@IPBI_RegionalOfficeID,
                                                                @IPVC_RegionalOfficeDescription=@IPVC_RegionalOfficeDescription,
                                                                @IPBI_UserIDSeq = @IPBI_UserIDSeq
  end
  else
  begin 
    Insert into Customers.dbo.CompanyRegionalOffice(CompanyIDSeq,RegionalOfficeIDSeq,RegionalOfficeDescription,CreatedByIDSeq,CreatedDate,SystemLogDate)
    select @IPVC_CompanyIDSeq as CompanyIDSeq,@IPBI_RegionalOfficeID as RegionalOfficeID,@IPVC_RegionalOfficeDescription as RegionalOfficeDescription,
           @IPBI_UserIDSeq as CreatedByIDSeq,@LDT_SystemDate as CreatedDate,@LDT_SystemDate as SystemLogDate
  end
END
GO
