SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  :  CUSTOMERS
-- Procedure Name  :  [uspCUSTOMERS_UpdateSiebelID]
-- Description     :  Updates the siebel ID for the account
--
-- Code Example    : Exec CUSTOMERS.DBO.[uspCUSTOMERS_UpdateSiebelID]  
--                        @IPVC_CompanyIDSeq       = 'C0000000001',
--                        @IPVC_PropertyIDSeq       = 'P0000000001',
--                        @IPVC_SiebelRowID       = '434234001',
-- 
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_UpdateSiebelID] (@IPVC_CompanyIDSeq    varchar(50),
                                                      @IPVC_PropertyIDSeq   varchar(50),
                                                      @IPVC_SiebelRowID     varchar(50),
                                                      @IPVC_Sieb77AddrID    varchar(50) = ''
                                                     )
AS
BEGIN
  set nocount on;
  select @IPVC_Sieb77AddrID = nullif(@IPVC_Sieb77AddrID,'');
  ------------------------------------------------------------
  if isnull(@IPVC_PropertyIDSeq,'') <> ''
  begin
    update CUSTOMERS.DBO.[Property]
    set SiebelRowID = @IPVC_SiebelRowID
    where IDSeq     = @IPVC_PropertyIDSeq

    update CUSTOMERS.DBO.Account
    set    SiebelRowID = @IPVC_SiebelRowID
    where  PropertyIDSeq = @IPVC_PropertyIDSeq
    and    CompanyIDSeq  = @IPVC_CompanyIDSeq
    and    Accounttypecode = 'APROP'

    Update CUSTOMERS.dbo.Address
    set    Sieb77AddrID    = @IPVC_Sieb77AddrID
    where  CompanyIDSeq    = @IPVC_CompanyIDSeq
    and    PropertyIDSeq   = @IPVC_PropertyIDSeq 
    and    Addresstypecode = 'PRO'
    and    (@IPVC_Sieb77AddrID <> '' and @IPVC_Sieb77AddrID is not null)
    
  end
  else
  begin
    update CUSTOMERS.DBO.Company
    set    SiebelRowID = @IPVC_SiebelRowID
    where  IDSeq = @IPVC_CompanyIDSeq

    update CUSTOMERS.DBO.Account
    set    SiebelRowID = @IPVC_SiebelRowID
    where  CompanyIDSeq = @IPVC_CompanyIDSeq
    and    PropertyIDSeq is null
    and    Accounttypecode = 'AHOFF'

    Update CUSTOMERS.dbo.Address
    set    Sieb77AddrID    = @IPVC_Sieb77AddrID
    where  CompanyIDSeq    = @IPVC_CompanyIDSeq    
    and    Addresstypecode = 'COM'
    and    (@IPVC_Sieb77AddrID <> '' and @IPVC_Sieb77AddrID is not null)
  end
END

GO
