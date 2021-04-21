SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-------------------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_ValidateCompanyPropertyForJumpTo
-- Description     : This procedure will accept CompanyIDSeq,
--                   1. validate if it is a PMC and return the same CompanyIDSeq as PMC
--                   2. validate if CompanyIDSeq passed is only a Owner and return the corresponding PMC ID
--                   3. If @IPVC_ValidateIDSeq is a property, then return a corresponding PMC ID
----------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_ValidateCompanyPropertyForJumpTo] (@IPVC_ValidateIDSeq   varchar(50))					
AS
BEGIN
  set nocount on;
  declare @LVC_RecordType varchar(1);
  select  @IPVC_ValidateIDSeq = ltrim(rtrim(@IPVC_ValidateIDSeq));
  select  @LVC_RecordType     = substring(@IPVC_ValidateIDSeq,1,1)

  if (@LVC_RecordType = 'C')
  begin
    ---------------------
    If exists (select top 1 1 from CUSTOMERS.dbo.Company with (nolock)
               where  PMCFlag = 1
               and    IDSeq   = @IPVC_ValidateIDSeq
              )
    begin
      select @IPVC_ValidateIDSeq as CompanyIDSeq
      return;
    end
    -------------------------
    else if exists(select top 1 1 from CUSTOMERS.dbo.Company with (nolock)
                   where  PMCFlag = 0 and OwnerFlag = 1
                   and    IDSeq   = @IPVC_ValidateIDSeq
                  )
    begin
      select top 1 CustomerIDSeq as CompanyIDSeq
      from   CUSTOMERS.dbo.CustomerOwner with (nolock)
      where  OwnerIDSeq = @IPVC_ValidateIDSeq
      return;
    end
    -------------------------  
	else if exists (select top 1 1 from CUSTOMERS.dbo.Company with (nolock)
               where  VendorFlag = 1
               and    IDSeq   = @IPVC_ValidateIDSeq
              )
    begin
      select @IPVC_ValidateIDSeq as CompanyIDSeq
      return;
    end
	-------------------------
    else
    begin
      select '' as CompanyIDSeq
      return;
    end
    -------------------------
  end
  else if (@LVC_RecordType = 'P')
  begin
    if exists (select top 1 1 from CUSTOMERS.dbo.Property with (nolock)
               where  IDSeq = @IPVC_ValidateIDSeq
              )
    begin
      select top 1 PMCIDSeq as CompanyIDSeq
      from   CUSTOMERS.dbo.Property with (nolock)
      where  IDSeq = @IPVC_ValidateIDSeq
    end
    else
    begin
      select '' as CompanyIDSeq
    end
  end
  else 
  begin
    select '' as CompanyIDSeq
  end
END

GO
