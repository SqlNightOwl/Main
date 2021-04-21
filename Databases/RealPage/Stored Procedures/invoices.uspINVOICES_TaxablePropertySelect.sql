SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspINVOICES_TaxablePropertySelect
-- Description     : This procedure gets the address for the property for which quote is created.
-- Revision History:
-- Author          : Kiran Kusumba
-- 01/15/2008      : Stored Procedure Created.
-- 02/22/2010      : Naval Kishore Modified to add TaxwareCompanyCode.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_TaxablePropertySelect] (@IPVC_CompanyID varchar(20),
                                                            @IPVC_PropertyID varchar(20) = '')
AS
BEGIN 
   ----------------------------------------------------------------------------
   --Assigning null value to the inpur parameter if empty string is passed
   set @IPVC_PropertyID=nullif(@IPVC_PropertyID,'')
   ----------------------------------------------------------------------------
   -- Declaring and Assigning Local Variable
   Declare @LC_AddressTypeCode char(3)
   Select @LC_AddressTypeCode = (Case when @IPVC_PropertyID is null then  'COM'   
                                      else 'PRO' end)
   -----------------------------------------------------------------------------   
   select  City,  
           State,  
           Zip,
           CountryCode                        As CountryCode,  
           CompanyIDSeq                       as CustomerNumber,  
           15000                              as TaxWareCode,  
           0.00                               as FreightAmount,  
           1000                               as NetChargeAmount,
		   case when (CountryCode='USA') then   '01'  else '10' end         as TaxwareCompanyCode   
   from    CUSTOMERS.dbo.Address with (nolock)  
   where   CompanyIDSeq    = @IPVC_CompanyID
   and     isnull(PropertyIDSeq,'null') = isnull(@IPVC_PropertyID,'NULL') 
   and     AddressTypeCode = @LC_AddressTypeCode       
END
--exec uspINVOICES_TaxablePropertySelect @IPVC_CompanyID = 'C0000010385', @IPVC_PropertyID = 'P0000046253'  
--exec [INVOICES].[dbo].uspINVOICES_TaxablePropertySelect 'C0901000031','P0901053620'

 

GO
