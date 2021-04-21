SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspCUSTOMERS_GetDatabaseIDsFromSiebelIDTEST]
-- Description     : Returns the databases for Siebel ID passed
-- Input Parameters: 
--                  @IPVC_SiebelID - SiebelID or AccountIDSeq
--                  @IPC_AccountType - Indicates type of ID passed in.
--                        C = Comapny SiebelID
--                        A = Company AccountIDSeq
--                        S = Site AccountIDSeq
--                        null/empty = Property SiebelID
--
-- EXEC CUSTOMERS.DBO.[uspCUSTOMERS_GetDatabaseIDsFromSiebelIDTEST] 'A0804026174', 'A'
-- EXEC CUSTOMERS.DBO.[uspCUSTOMERS_GetDatabaseIDsFromSiebelIDTEST] 'A0806000112', 'S'
-- EXEC CUSTOMERS.DBO.[uspCUSTOMERS_GetDatabaseIDsFromSiebelIDTEST] '1100443', 'C'
------------------------------------------------------------------------------------------------------
-- Revision History:
-- Author          : Davon Cannon 
------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
-- Revision History:
-- Author          : Bhavesh Shah 07/18/2008
--                 : Added Code to get SitemasterID be account number.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_GetDatabaseIDsFromSiebelIDTEST] 
(
  @IPVC_SiebelID     varchar(20),
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
  DECLARE @LVC_OMSAccountTypecode varchar(20);

  select
      @LV_ComapnyIDSeq   = C.IDSeq,
      @LV_PropertyIDSeq  = Coalesce(P.IDSeq,NULL),
      @LV_CompanyDBID    = C.SiteMasterID,
      @LV_PropertyDBID   = coalesce(nullif(P.SiteMasterID,''),''),
      @LV_AccountIDSeq   = A.IDSeq
    from CUSTOMERS.dbo.Company  C WITH (NOLOCK)
    Left Outer Join
         CUSTOMERS.dbo.Property P WITH (NOLOCK)
    ON   C.IDSeq = P.PMCIDSeq
    Left Outer Join
         CUSTOMERS.dbo.Account    A  WITH (NOLOCK)
    ON   A.CompanyIDSeq  = C.IDSeq 
    AND  coalesce(A.PropertyIDSeq,'') = coalesce(P.IDSeq,'')
    and  A.ActiveFlag    = 1
    where (
            (C.SiebelId = @IPVC_SiebelID OR C.Sitemasterid = @IPVC_SiebelID)
              OR
            (P.SiebelId = @IPVC_SiebelID OR P.Sitemasterid = @IPVC_SiebelID)
              Or
            (A.SiebelId = @IPVC_SiebelID OR A.Sitemasterid = @IPVC_SiebelID OR A.IDSeq = @IPVC_SiebelID)
          ) 

  ----------------------------------------------------------------------
  ---Error Section
  IF @LV_ComapnyIDSeq IS NULL OR NULLIF(@LV_CompanyDBID, '') IS NULL
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
