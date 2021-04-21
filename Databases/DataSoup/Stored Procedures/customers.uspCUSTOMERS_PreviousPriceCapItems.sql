SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCUSTOMERS_PreviousPriceCapItems]
-- Description     : This procedure returns recordset of previously added CustomerID, ProductCode,ProductName,PropertyIDSeq,PropertyName
--                    pertaining to the passed CustomerId, ProductCodes and Product Ids
-- Input Parameters: 	@IPVC_CustomerID varchar(11),
--                    @IPVC_ProductCodes  varchar(2000),
--                    @IPVC_PropertyIDs   varchar(2000)
-- 
-- OUTPUT          : RecordSet of ID,AccountName,City,State,Zip,AccountTypeCode,Units,PPU
-- Code Example    : Exec CUSTOMERS.DBO.[uspCUSTOMERS_PreviousPriceCapItems] @IPVC_CustomerID='C0000000984',    
--                                                                @IPVC_ProductCodes='|DMD-OSD-PAY-PAY-PRAI|DMD-OSD-PAY-PAY-PACH|PRM-LEG-LEG-LEG-LCAP|PRM-LEG-LEG-LEG-LHFL|',   
--                                                                @IPVC_PropertyIDs='|P0000000249|P0000000021|P0000000009|P0000000010|P0000000011|P0000000012|P0000000013|',    
-- 
-- 
-- Revision History:
-- Author          : KRK   
-- 05/15/2007      : Stored Procedure Created.
--
------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [customers].[uspCUSTOMERS_PreviousPriceCapItems](                    
                                                                      @IPVC_CustomerID varchar(11),
                                                                      @IPVC_ProductCodes  varchar(2000),
                                                                      @IPVC_PropertyIDs   varchar(2000) 
                                                               ) 

AS
BEGIN      
        create table #PCProducts
        (
             CustomerID  varchar(11),
             ProductCode varchar(30),                   
             ProductName varchar(255)
        )  
        
        insert into #PCProducts
        (
             CustomerID,
             ProductCode,
             ProductName           
        )  
        select
             @IPVC_CustomerID,
             ProductCode,
             dbo.fnProductName(ProductCode)
        from dbo.fnSplitProductCodes('|'+@IPVC_ProductCodes) 

        --select * from #PCProducts

        create table #PCProperties
        (
             CustomerID    varchar(11),
             PropertyIDSeq varchar(11),                   
             PropertyName  varchar(255)
        ) 

        insert into  #PCProperties
        (
             CustomerID,
             PropertyIDSeq,                   
             PropertyName
        ) 
        select 
             @IPVC_CustomerID,
             PropertyID,
             dbo.fnPropertyName(PropertyID)                
        from dbo.fnSplitPropertyID('|'+@IPVC_PropertyIDs)
     
        create table #TempPCItems
        (
            CustomerID    varchar(11),
            ProductCode   varchar(30),
            PropertyIDSeq varchar(11),
            ProductName   varchar(255),
            PropertyName   varchar(255),
        )

        insert into #TempPCItems
        (
            CustomerID,
            ProductCode,
            PropertyIDSeq,
            ProductName,
            PropertyName 
        )          
        select tproducts.CustomerID,
               tproducts.ProductCode,
               tproperties.PropertyIDSeq,
               tproducts.ProductName,
               tproperties.PropertyName
        from #PCProducts   tproducts 
        inner join    #PCProperties tproperties
        on  tproducts.CustomerID = tproperties.CustomerID

        create table #OriginalItems
        (
              CustomerID varchar(11),
              ProductCode varchar(30),
              PropertyIDSeq varchar(11)
        )
 
        insert into #OriginalItems
        (
              CustomerID,
              ProductCode,
              PropertyIDSeq
        )
        select pprod.CompanyIDSeq,
               pprod.ProductCode,
               pprop.PropertyIDSeq
        from Customers.dbo.PriceCapProperties pprop
        left outer join Customers.dbo.PriceCapProducts pprod
        on  pprop.CompanyIDSeq = pprod.CompanyIDSeq 
        where pprop.CompanyIDSeq =   @IPVC_CustomerID   
    

        select distinct * from
        ( 
            select oitems.CustomerID,
                   titems.ProductCode,
                   titems.ProductName,
                   titems.PropertyIDSeq,
                   titems.PropertyName
            from #OriginalItems oitems 
            inner join #TempPCItems titems
            on (oitems.CustomerID = titems.CustomerID
            and oitems.ProductCode = titems.ProductCode
            and oitems.PropertyIDSeq = titems.PropertyIDSeq)
        )tbl   

        drop table #PCProducts
        drop table #PCProperties
        drop table #OriginalItems
end                

--Exec [uspCUSTOMERS_PreviousPriceCapItems] C0000000984, '|DMD-OSD-PAY-PAY-PRAI|DMD-OSD-PAY-PAY-PACH|PRM-LEG-LEG-LEG-LCAP|PRM-LEG-LEG-LEG-LHFL|', '|P0000000249|P0000000021|P0000000009|P0000000010|P0000000011|P0000000012|P0000000013|'

GO
