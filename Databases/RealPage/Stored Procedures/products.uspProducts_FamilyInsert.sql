SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspProducts_FamilyInsert
-- Description     : This procedure insert family details in family table
-- Input Parameters:   @IPVC_Name varchar(50),
--                     @IPVC_Code char(3),
--                     @IPVC_Description varchar(100)	
-- OUTPUT          : RecordSet of the ID, Name, Category, Family, Platform  of Products from Products..Product,
--                   Products..Family, Products..Category and Customers..Platform 
-- Code Example    :   Exec PRODUCTS.dbo.[uspPRODUCTS_ProductList]
--					   @IPVC_Name        =   'Asd',
--                     @IPVC_Code        =   'NewFamily', 
--                     @IPVC_Description      =   'Administrative Services'
	
-- Revision History:
-- Author          : Naval Kishore
-- 04/23/2007      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspProducts_FamilyInsert] (@IPVC_Name varchar(50),
                                                   @IPVC_Code char(3),
                                                   @IPVC_Description varchar(100)=null)
AS
BEGIN  
  BEGIN TRY
    BEGIN TRANSACTION 
      ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT [Name], Code FROM Products.dbo.Family WHERE [Name]=@IPVC_Name AND Code=@IPVC_Code)
BEGIN 
     INSERT INTO Products.dbo.Family ([Name], Code, [Description])
      VALUES (@IPVC_Name, @IPVC_Code, @IPVC_Description)
End
      ----------------------------------------------------------------------------
      
    

    COMMIT TRANSACTION
    ----------------------------------------------------------------------------    
  END TRY
  BEGIN CATCH

    SELECT 'Company Insert Section' as ErrorSection,XACT_STATE() as TransactionState,ERROR_MESSAGE() AS ErrorMessage; 
        -- XACT_STATE:
             -- If 1, the transaction is committable.
             -- If -1, the transaction is uncommittable and should be rolled back.
             -- XACT_STATE = 0 means that there is no transaction and COMMIT or ROLLBACK would generate an error.
        if (XACT_STATE()) = -1
        begin
          IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        end
        else if (XACT_STATE()) = 1
        begin
          IF @@TRANCOUNT > 0 COMMIT TRANSACTION;
        end     
  END CATCH
  ---------------------------------------------------------------------------------------
  ---Final Clean up
  IF @@TRANCOUNT > 0 COMMIT TRANSACTION;  
  --------------------------------------------------------------------------------------- 
 
END


--[dbo].[uspProducts_FamilyInsert] 'Admin' 'ADM' ''
GO
