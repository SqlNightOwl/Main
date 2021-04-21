SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspCUSTOMERS_GetDatabaseIDsFromSiebelID]
-- Description     : Returns the databases for Siebel ID passed
-- Input Parameters: 
--                  @IPVC_SiebelID - SiebelID or AccountIDSeq
--                  @IPC_AccountType - Indicates type of ID passed in.
--                        C = Comapny SiebelID
--                        A = Company AccountIDSeq
--                        S = Site AccountIDSeq
--                        null/empty = Property SiebelID
--
-- EXEC CUSTOMERS.DBO.[uspCUSTOMERS_GetDatabaseIDsFromSiebelID] 'A0804026174', 'A'
-- EXEC CUSTOMERS.DBO.[uspCUSTOMERS_GetDatabaseIDsFromSiebelID] 'A0806000112', 'S'
-- EXEC CUSTOMERS.DBO.[uspCUSTOMERS_GetDatabaseIDsFromSiebelID] '1100443', 'C'
------------------------------------------------------------------------------------------------------
-- Revision History:
-- Author          : Davon Cannon 
------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
-- Revision History:
-- Author          : Bhavesh Shah 07/18/2008
--                 : Added Code to get SitemasterID be account number.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_GetDatabaseIDsFromSiebelID] 
(
  @IPVC_SiebelID     varchar(50),
  @IPC_AccountType   char(1)
)					
AS
BEGIN 
  set nocount on;
  ---------------------------------------
  --Local Variables
  ---------------------------------------
  DECLARE @LV_CompanyDBID    varchar(30);
  DECLARE @LV_PropertyDBID   varchar(30);
  DECLARE @LV_ComapnyIDSeq   varchar(22);
  DECLARE @LV_PropertyIDSeq  varchar(22);
  DECLARE @LV_AccountIDSeq   varchar(22);
  -------------------------------------------------------------------------------
  ---> Company's Siebel ID was passed in. Use it to get Sitemaster ID
  -------------------------------------------------------------------------------
  if @IPC_AccountType = 'C'  
  begin
    select
      @LV_ComapnyIDSeq   = C.IDSeq,
      @LV_PropertyIDSeq  = null,
      @LV_CompanyDBID    = C.SiteMasterID,
      @LV_PropertyDBID   = '',
      @LV_AccountIDSeq   = A.IDSeq
    from CUSTOMERS.dbo.Company C WITH (NOLOCK)
    left outer join 
         CUSTOMERS.dbo.Account A WITH (NOLOCK)
    ON   C.IDSeq = A.CompanyIDSeq     
    AND  A.Accounttypecode = 'AHOFF'
    AND  A.PropertyIDSeq is null
    AND  A.ActiveFlag      = 1
    where (C.SiebelID      = @IPVC_SiebelID OR A.IDSeq       = @IPVC_SiebelID);
  end
  -------------------------------------------------------------------------------
  ---> Company OMS Account ID was passed in.  Use it to get Sitemaster ID.
  -------------------------------------------------------------------------------
  else if @IPC_AccountType = 'A' 
  begin
    select 
      @LV_ComapnyIDSeq   = C.IDSeq,
      @LV_PropertyIDSeq  = null,
      @LV_CompanyDBID    = C.SiteMasterID,
      @LV_PropertyDBID   = '',
      @LV_AccountIDSeq   = A.IDseq
    from CUSTOMERS.dbo.Company C WITH (NOLOCK)
    left outer join 
         CUSTOMERS.dbo.Account A WITH (NOLOCK)
    ON   C.IDSeq = A.CompanyIDSeq     
    AND  A.Accounttypecode = 'AHOFF'
    AND  A.PropertyIDSeq is null
    AND  A.ActiveFlag      = 1
    where (C.SiebelID      = @IPVC_SiebelID OR A.IDSeq       = @IPVC_SiebelID);
    
    ---If Not Company Based Account, then Try Sitebased account
    IF (@LV_ComapnyIDSeq IS NULL OR NULLIF(@LV_CompanyDBID, '') IS NULL)
    begin
      select 
         @LV_ComapnyIDSeq  = C.IDSeq,
         @LV_PropertyIDSeq = P.IDSeq,
         @LV_CompanyDBID   = C.SiteMasterID,
         @LV_PropertyDBID  = P.SiteMasterID,
         @LV_AccountIDSeq  = A.IDseq
      from CUSTOMERS.dbo.Company    C WITH (NOLOCK)
      INNER JOIN 
         CUSTOMERS.dbo.[Property] P WITH (NOLOCK)
      ON   C.IDSeq = P.PMCIDSeq
      left outer join 
         CUSTOMERS.dbo.Account    A WITH (NOLOCK)
      ON   C.IDSeq           = A.CompanyIDSeq 
      AND  P.IDSeq           = A.PropertyIDSeq
      AND  A.Accounttypecode = 'APROP'    
      and  A.ActiveFlag      = 1
      where 
          (P.SiebelID       = @IPVC_SiebelID OR A.IDSeq       = @IPVC_SiebelID);
    end
  end
  -------------------------------------------------------------------------------
  ---> Property(Site) OMS Account ID was passed in.  Use it to get Sitemaster ID.
  -------------------------------------------------------------------------------
  else if @IPC_AccountType = 'S' 
  begin
    select 
      @LV_ComapnyIDSeq  = C.IDSeq,
      @LV_PropertyIDSeq = P.IDSeq,
      @LV_CompanyDBID   = C.SiteMasterID,
      @LV_PropertyDBID  = P.SiteMasterID,
      @LV_AccountIDSeq  = A.IDseq
    from CUSTOMERS.dbo.Company    C WITH (NOLOCK)
    INNER JOIN 
         CUSTOMERS.dbo.[Property] P WITH (NOLOCK)
    ON   C.IDSeq = P.PMCIDSeq
    left outer join 
         CUSTOMERS.dbo.Account    A WITH (NOLOCK)
    ON   C.IDSeq           = A.CompanyIDSeq 
    AND  P.IDSeq           = A.PropertyIDSeq
    AND  A.Accounttypecode = 'APROP'    
    and  A.ActiveFlag      = 1
    where 
         (P.SiebelID       = @IPVC_SiebelID OR A.IDSeq       = @IPVC_SiebelID);
  end
  else
  -------------------------------------------------------------------------------
  ---> Property's Siebel ID was passed in. Use it to get Sitemaster ID.
  -------------------------------------------------------------------------------
  begin 
    select 
      @LV_ComapnyIDSeq   = cmp.IDSeq,
      @LV_PropertyIDSeq  = prop.IDSeq,
      @LV_CompanyDBID    = cmp.SiteMasterID, 
      @LV_PropertyDBID   = prop.SitemasterID,
      @LV_AccountIDSeq   = act.IDseq
    from CUSTOMERS.dbo.[Property] prop WITH (NOLOCK)
    INNER JOIN 
         CUSTOMERS.dbo.Company    cmp  WITH (NOLOCK)
    ON   prop.PMCIDSeq = cmp.IDSeq    
    left outer join 
         CUSTOMERS.dbo.Account    act  WITH (NOLOCK)
    ON   act.CompanyIDSeq  = cmp.IDSeq 
    AND  act.PropertyIDSeq = prop.IDSeq
    AND  act.Accounttypecode = 'APROP'
    and  act.ActiveFlag    = 1
    where 
          (prop.SiebelID   = @IPVC_SiebelID OR act.IDSeq       = @IPVC_SiebelID)
    and   prop.PMCIDSeq = cmp.IDSeq;
  end
  ----------------------------------------------------------------------
  ---Error Section
  IF (@LV_ComapnyIDSeq IS NULL OR NULLIF(@LV_CompanyDBID, '') IS NULL)
  BEGIN 
    DECLARE @LVC_CodeSection varchar(100);
    set @LVC_CodeSection = 'Unable to find Company ID. SiebelID: ' + ISNULL(@IPVC_SiebelID, '') + ' AccountType: ' + ISNULL(@IPC_AccountType, '');
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
  END
  ELSE
  ----------------------------------------------------------------------
  -- IF NO Error, return Final select
  BEGIN
    SELECT 
      @LV_CompanyDBID    as CompanyDBID, 
      @LV_PropertyDBID   as PropertyDBID,
      @LV_ComapnyIDSeq   as CompanyIDSeq,
      @LV_AccountIDSeq   as AccountIDSeq,
      @LV_PropertyIDSeq  as PropertyIDSeq;
  END 
 ----------------------------------------------------------------------
END

GO
