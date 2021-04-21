SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCUSTOMERS_GetSiteCustomerList]
-- Description     : This procedure gets Customer Details pertaining to passed 
--                        CustomerName,CustomerID
-- Input Parameters:   @IPI_PageNumber       as  int, 
--                     @IPI_RowsPerPage      as  int, 
--                     @IPVC_CustomerID      as  varchar,
--                     @IPVC_CustomerName    as  varchar
 
-- OUTPUT          : RecordSet of the ID, Name of Customers from Customers..Company,

-- Code Example    :   Exec CUSTOMERS.dbo.[uspCUSTOMERS_GetSiteCustomerList]
--                     @IPI_RowsPerPage       =   10, 
--                     @IPVC_CustomerID       =   'C0000245873' 
--                     @IPVC_CustomerName     =   '4000 NORTH' 

	
-- Revision History:
-- Author          : KRK
-- 05/14/2006      : Stored Procedure Created.
-- 05/17/2007      : Modified to get address fields.
-- 01/22/2008	   : Naval Kishore Modified SP for adding new parameter @IPVC_CurrentCustomerID
-- 09/01/2011	   : Mahaboob modified the Procedure to List "Customers of Vendor type" also. Defect #987
------------------------------------------------------------------------------------------------------
CREATE procedure [customers].[uspCUSTOMERS_GetSiteCustomerList] (     @IPI_PageNumber int, 
                                                                @IPI_RowsPerPage int, 
                                                                @IPVC_CustomerID varchar(11),  
                                                                @IPVC_CustomerName varchar(100),
																@IPVC_CurrentCustomerID  varchar(11) 
                                                          )
AS
BEGIN
  -----------------------------------------------------------------------------------------
  SELECT * FROM (
    ---------------------------------------------------------------------------------
    SELECT TOP 
                (@IPI_RowsPerPage * @IPI_PageNumber) 
                C.IDSeq                                       as CompanyID,
                C.Name                                        as CompanyName,
                A.addressline1							                  as AddressLine1,
                A.City                                        as City, 
                A.State                                       as [State],
                A.Zip                                         as Zip, 		            
                row_number() over(order by C.Name)            as RowNumber
    FROM        
                Customers.dbo.Company c

    INNER JOIN  Customers.dbo.Address A 
      ON        A.CompanyIDSeq = C.IDSeq
      AND       A.AddressTypeCode = 'COM'      

    WHERE   
                C.Name like  '%' + @IPVC_CustomerName + '%'
    AND         C.IDSeq like  '%' + @IPVC_CustomerID + '%'
	AND         C.IDSeq <> @IPVC_CurrentCustomerID     
    --AND         C.PMCFlag = 1

 ) tbl
    ---------------------------------------------------------------------------------
  WHERE RowNumber > (@IPI_PageNumber-1) * @IPI_RowsPerPage
  -----------------------------------------------------------------------------------------

  -----------------------------------------------------------------------------------------
  SELECT        COUNT(*) 
  FROM          Customers.dbo.Company c

  INNER JOIN    Customers.dbo.Address A 
    ON          A.CompanyIDSeq = C.IDSeq
    AND         A.AddressTypeCode = 'COM'      
  
  WHERE         C.Name like  '%' + @IPVC_CustomerName + '%'
    AND         C.IDSeq like  '%' + @IPVC_CustomerID + '%' 
	AND         C.IDSeq <> @IPVC_CurrentCustomerID     
    --AND         C.PMCFlag = 1
END


--exec [dbo].[uspCUSTOMERS_GetSiteCustomerList] 1,10,'',''




GO
