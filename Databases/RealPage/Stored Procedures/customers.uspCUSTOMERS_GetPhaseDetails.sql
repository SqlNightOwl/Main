SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_GetPhaseDetails
-- Description     : This procedure gets Phase Details pertaining to passed CustomerID

-- Code Example    : Exec CUSTOMERS.DBO.[uspCUSTOMERS_GetPhaseDetails] @IPVC_CustomerIDSeq  ='C0801000098',
--                                                                     @IPVC_PropertyIDSeq ='P0801000251',
--                                                                     @IPVC_AddressLine1='9956 Queens Quarter Dr',
--                                                                     @IPVC_AddressLine2 = '',
--                                                                     @IPVC_City = 'Frisco',
--								       @IPVC_State= 'TX',
--								       @IPVC_Zip  = '75034-1233',
--								       @IPVC_Country = 'United States',
--								       @IPVC_Phase   = 'Phase'         
-- 
-- 
-- Revision History:
-- Author          : Anand Chakravarthy
-- 25/02/2008      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_GetPhaseDetails] (@IPVC_CustomerIDSeq    varchar(20), 
                                                       @IPVC_PropertyIDSeq    varchar(50),
                                                       @IPVC_AddressLine1     varchar(200),
                                                       @IPVC_AddressLine2     varchar(100)='',
                                                       @IPVC_City             varchar(70),
                                                       @IPVC_State            char(2),
                                                       @IPVC_Zip              varchar(10),
                                                       @IPVC_Country          varchar(70),
                                                       @IPVC_Phase            varchar(20)='' 
                                                       ) 
AS
BEGIN 
  --If Phase exists for same Property addresstypecode = 'PRO',Addressline1,Addressline2,City,State,Zip,Country
  -- under the same PMC for any other property other Passed @IPVC_PropertyIDSeq
  -- then select P.Phase,Addr.PropertyIdSeq to UI to stop entering the same Phase.
  ------------------------------------------------------------------------------
  set nocount on;
  select @IPVC_AddressLine1 = coalesce(Nullif(ltrim(rtrim(@IPVC_AddressLine1)),''),'ABCDEF'),  
         @IPVC_AddressLine2 = coalesce(Nullif(ltrim(rtrim(@IPVC_AddressLine2)),''),'ABCDEF'), 
         @IPVC_City         = coalesce(Nullif(ltrim(rtrim(@IPVC_City)),''),'ABCDEF'),
         @IPVC_State        = coalesce(Nullif(ltrim(rtrim(@IPVC_State)),''),'ABCDEF'), 
         @IPVC_Zip          = coalesce(Nullif(ltrim(rtrim(@IPVC_Zip)),''),'ABCDEF'),
         @IPVC_Country      = coalesce(Nullif(ltrim(rtrim(@IPVC_Country)),''),'ABCDEF'),
         @IPVC_Phase        = coalesce(Nullif(ltrim(rtrim(@IPVC_Phase)),''),'ABCDEF')
  ------------------------------------------------------------------------------

  select P.Phase,Addr.PropertyIdSeq 
  from   Customers.dbo.property P    with (nolock)
  inner join 
         Customers.dbo.Address  Addr with (nolock)
  on    P.PMCIDSeq           = Addr.CompanyIDSeq
  and   P.IDSeq              = Addr.PropertyIDSeq
  and   Addr.CompanyIDSeq    = @IPVC_CustomerIDSeq
  and   P.PMCIDSeq           = @IPVC_CustomerIDSeq
  and   Addr.Addresstypecode = 'PRO'
  and   Addr.PropertyIDSeq is not null
  and   P.StatusTypeCode     = 'ACTIV'
  and   P.IDSeq              <> @IPVC_PropertyIDSeq
  and   Addr.PropertyIDSeq   <> @IPVC_PropertyIDSeq  
  ---------------------------------------------------
  and   coalesce(Nullif(ltrim(rtrim(Addr.Addressline1)),''),'ABCDEF')  = @IPVC_AddressLine1
  and   coalesce(Nullif(ltrim(rtrim(Addr.Addressline2)),''),'ABCDEF')  = @IPVC_AddressLine2
  and   coalesce(Nullif(ltrim(rtrim(Addr.City)),''),'ABCDEF')          = @IPVC_City
  and   coalesce(Nullif(ltrim(rtrim(Addr.State)),''),'ABCDEF')         = @IPVC_State
  and   coalesce(Nullif(ltrim(rtrim(Addr.Zip)),''),'ABCDEF')           = @IPVC_Zip
  and   coalesce(Nullif(ltrim(rtrim(Addr.Country)),''),'ABCDEF')       = @IPVC_Country
  and   coalesce(Nullif(ltrim(rtrim(P.Phase)),''),'ABCDEF')            = @IPVC_Phase
  and   Addr.CompanyIDSeq = @IPVC_CustomerIDSeq
  and   P.PMCIDSeq        = @IPVC_CustomerIDSeq
  ---------------------------------------------------
  where Addr.CompanyIDSeq = @IPVC_CustomerIDSeq
  and   P.PMCIDSeq        = @IPVC_CustomerIDSeq
END
GO
