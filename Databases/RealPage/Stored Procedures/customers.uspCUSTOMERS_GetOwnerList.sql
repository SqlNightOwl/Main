SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_GetOwnerList
-- Description     : This procedure gets the list of owners.
-- Input Parameters: 1. @IPVC_CompanyIDSeq varchar(11)
-- 
-- Code Example    : Exec CUSTOMERS.DBO.uspCUSTOMERS_GetOwnerList  
--                      @IPVC_CompanyIDSeq = 'A0000000001'
-- 
-- Revision History:
-- Author          : STA, SRA Systems Limited.
-- 03/12/2007      : Stored Procedure Created.
-- 01/19/2008	   : Naval Kishore Modified 
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_GetOwnerList] @IPVC_CompanyIDSeq varchar(11)
AS
BEGIN
  ------------------------------------------------------
--	SELECT  
--              CA.OwnerIDSeq     AS OwnerIDSeq,
--              C.[Name]          AS OwnerName
--
--  FROM
--              Company C
--
--  INNER JOIN  
--              CustomerOwner CA
--    ON        
--              C.IDSeq = CA.OwnerIDSeq
--
--  WHERE       CA.CustomerIDSeq = @IPVC_CompanyIDSeq
--  ORDER BY OwnerName

 SELECT 
                CO.OwnerIDSeq                                         AS OwnerIDSeq,
                CO.CustomerIDSeq                                      AS CustomerIDSeq,
                C.Name                                                AS OwnerName                
               
    FROM 
                Customers.dbo.CustomerOwner CO with (nolock)
    INNER JOIN  Customers.dbo.Company C with (nolock)
      ON        C.IDSeq = CO.OwnerIDSeq
      AND       C.OwnerFlag = 1
      AND       CO.CustomerIDSeq LIKE '%' + @IPVC_CompanyIDSeq + '%'
    Order By C.Name

  ------------------------------------------------------
END

GO
