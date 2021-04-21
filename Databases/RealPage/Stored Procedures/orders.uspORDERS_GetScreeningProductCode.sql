SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_GetScreeningProductCode]
-- Description     : Returns the product code based on the passed parameters
-- Input Parameters: 
-- 
------------------------------------------------------------------------------------------------------
-- Revision History:
-- Author          : Davon Cannon 
------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
-- Revision History: 
-- Author          : Bhavesh Shah 07/11/2008
--                 : Performance improvments.  Added PropertyIDSeq to Parameter and get code based on
--                 : that.  To be backward compatible, kept the PMCDBID and SiteDBID and getting
--                 : PropertyIDSeq based on that.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_GetScreeningProductCode] (
                          @IPVC_PMCDatabaseID           varchar(10) = null, 
                          @IPVC_SiteDatabaseID          varchar(10) = null,  
                          @LB_CreditUsed                bit, 
                          @LB_CriminalUsed              bit,
                          @IPVC_CountryCode             varchar(10),
                          @IPVC_PropertyIDSeq           varchar(22) = null)					
AS
BEGIN 
  set nocount on;
  ------------------------------------
  declare @LC_ProductCode  varchar(30)
  declare @LVC_MeasureCode varchar(5)
  declare @LVC_CodeSection varchar(100)
  ------------------------------------
  -- TO Be backward compatible.  If PropertyIDSeq is not found then get it based on PMCDatabaseID and SiteDatabaseID
  IF ( @IPVC_PropertyIDSeq is null )
  BEGIN
    IF ( @IPVC_PMCDatabaseID IS NULL OR @IPVC_SiteDatabaseID IS NULL )
    BEGIN
      set @LVC_CodeSection = 'Missing Parameters (PropertyID: ' + isnull(@IPVC_PropertyIDSeq, '') 
        + ' PMC ID:' + isnull(@IPVC_PMCDatabaseID, '') + ' Site ID: ' + isnull(@IPVC_SiteDatabaseID,'') + ')';

      Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
      RETURN;
    END

    SELECT TOP 1  @IPVC_PropertyIDSeq=prop.IDSeq
    from  Customers.dbo.[Property]   prop with (nolock)
    inner join Customers.dbo.Account acct with (nolock)
    on    acct.PropertyIDSeq = prop.IDSeq 
    and   prop.SiteMasterID  = @IPVC_SiteDatabaseID
    and   acct.ActiveFlag    = 1
    where prop.SiteMasterID  = @IPVC_SiteDatabaseID
    and   acct.ActiveFlag    = 1;
  END
  -------------------------------------------------------------
  IF @IPVC_PropertyIDSeq is null 
  BEGIN
    set @LVC_CodeSection = 'No property exists (PropertyID: ' + isnull(@IPVC_PropertyIDSeq, '') 
        + ' PMC ID:' + isnull(@IPVC_PMCDatabaseID, '') + ' Site ID: ' + isnull(@IPVC_SiteDatabaseID,'') + ')';

    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return;
  END
  ------------------------------------
  select TOP 1  @LC_ProductCode = oi.ProductCode,
               @LVC_MeasureCode = oi.MeasureCode
  from  Orders.dbo.[Order] o WITH (NOLOCK)
  inner join 
        Orders.dbo.OrderItem  oi WITH (NOLOCK)
  on    oi.OrderIDSeq  = o.OrderIDSeq
  and   oi.StatusCode  <> 'EXPD'
  and   oi.Measurecode = 'TRAN'
  and   Coalesce(oi.canceldate,oi.ActivationEndDate) >= Getdate()
  and   o.PropertyIDSeq = @IPVC_PropertyIDSeq
  inner join 
        Products.dbo.ScreeningProductMapping pmap WITH (NOLOCK)
  on    pmap.ProductCode      = oi.ProductCode
  and   pmap.CreditUsedFlag   = @LB_CreditUsed
  and   pmap.CriminalUsedFlag = @LB_CriminalUsed
  and   (@IPVC_CountryCode    = '' OR pmap.CountryCode = @IPVC_CountryCode)
  where
          o.PropertyIDSeq       = @IPVC_PropertyIDSeq
    and   pmap.CreditUsedFlag   = @LB_CreditUsed
    and   pmap.CriminalUsedFlag = @LB_CriminalUsed
    and   (@IPVC_CountryCode = '' or pmap.CountryCode = @IPVC_CountryCode)
    and   oi.StatusCode  <> 'EXPD'
    and   oi.Measurecode = 'TRAN'
    and   Coalesce(oi.canceldate,oi.ActivationEndDate) >= Getdate()
  order by pmap.Priority ASC ---> This is important clause
  -----------------------------------------------------------------------
  /* 
  ----This Error Should not Thrown from This Proc.
  --- UI will take care of Logging an error after exact match 1,1 / 1,0/ 0,1 combination fails
  if @LC_ProductCode is null
  begin
    set @LVC_CodeSection = 'No order exists (PropertyID: ' + isnull(@IPVC_PropertyIDSeq, '') 
        + ' PMC ID:' + isnull(@IPVC_PMCDatabaseID, '') + ' Site ID: ' + isnull(@IPVC_SiteDatabaseID,'') + ')'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
  end
  */
  -----------------------------------------------------------------------
  ---Final Select 
  select @LC_ProductCode as ProductCode, @LVC_MeasureCode as MeasureCode
  -----------------------------------------------------------------------
  /*
  ---Sample Select Records for Screening products
  DMD-LSD-SCR-SCR-ELDS          	LeasingDesk Screening Enterprise
  DMD-LSD-SCR-SCR-SCSC          	LeasingDesk Screening
  DMD-LSD-SCR-SCR-SCMC          	LeasingDesk Screening Multistate Criminal Search
  DMD-LSD-SCR-SCR-SMCT          	LeasingDesk Screening (Credit & Criminal)
  DMD-LSD-SCR-SCR-SCEP          	LeasingDesk Screening Premium Eviction
  DMD-LSD-SCR-SCR-SCCP          	LeasingDesk Screening Premium Criminal
  DMD-LSD-SCR-SCR-SCNS          	LeasingDesk Screening National Sex Offender Search
  DMD-LSD-SCR-SCR-LDCS          	LeasingDesk Screening Combo
  DMD-LSD-SCR-SCR-SEFS          	LeasingDesk Screening eForms & eSignatures
  DMD-LSD-SCR-SCR-SCCL          	LeasingDesk Screening Criminal Classification
  DMD-LSD-SCR-SRP-SBCR          	LeasingDesk Screening Business Credit Report
  DMD-LSD-SCR-SRP-SCCR          	LeasingDesk Screening Canadian Credit Report


  select code, displayname 
  from products.dbo.product 
  where disabledflag = 0 and familycode = 'LSD' and SOCFlag = 1
  order by sortseq
  */
END

GO
