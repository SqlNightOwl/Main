SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [customers].[uspCUSTOMERS_AlreadyAddedPriceCapItems](                    
                                                                      @IPVC_CustomerID    varchar(50),
                                                                      @IPVC_ProductCodes  varchar(max),
                                                                      @IPVC_PropertyIDs   varchar(max),
                                                                      @IPVC_StartDate     Datetime,
																	  @IPVC_EndDate       Datetime,
                                                                      @IPBI_PriceCapIDSEq bigint
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
              case when(PropertyID='NULL') then '0' else PropertyID end,
             dbo.fnPropertyName( case when(PropertyID='NULL') then '0' else PropertyID end)                         
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
        left join    #PCProperties tproperties
        on  tproducts.CustomerID = tproperties.CustomerID

        create table #OriginalItems
        (
              CustomerID		  varchar(11),
              ProductCode		  varchar(30),
              PropertyIDSeq		  varchar(11),
              PriceCapStartDate   varchar(30),
              PriceCapEndDate     varchar(30),
              PriceCapIDSeq		  bigint
        )
 
        insert into #OriginalItems
        (
              CustomerID,
              ProductCode,
              PropertyIDSeq,
              PriceCapStartDate,
              PriceCapEndDate,
              PriceCapIDSeq
        )
        select pprod.CompanyIDSeq,
               pprod.ProductCode,
               isnull(pprop.PropertyIDSeq,0),
               convert(varchar(20),pc.PriceCapStartDate,101) as PriceCapStartDate,
			   convert(varchar(20),pc.PriceCapEndDate,101) as PriceCapEndDate,
               pc.idseq
        from Customers.dbo.PriceCap pc  with (nolock)
		left outer join 
             Customers.dbo.PriceCapProducts pprod  with (nolock)
          on pc.idseq           = pprod.pricecapidseq 
         and pc.CompanyIDSeq = pprod.CompanyIDSeq 
        left outer join 
             Customers.dbo.PriceCapProperties pprop  with (nolock)
          on pc.idseq        = pprop.pricecapidseq
         and pc.companyidseq = pprop.companyidseq
        
		where 
          (not exists
            (select top 1 1 
             from Customers.dbo.PriceCap pcc with (nolock)
             where pcc.idseq = pc.idseq
               and
                  (
                    (@IPVC_StartDate < pc.PriceCapStartDate and DATEADD(yy,1,@IPVC_StartDate) <= pc.PriceCapStartDate)
                      OR
                    (@IPVC_StartDate > pc.PriceCapEndDate)

                  ) 
				and
                  (
                    (@IPVC_EndDate < pc.PriceCapEndDate and DATEADD(yy,1,@IPVC_EndDate) <= pc.PriceCapEndDate)
                      OR
                    (@IPVC_EndDate > pc.PriceCapStartDate)

                  ) 
            )
          )
        and  pprod.CompanyIDSeq =   @IPVC_CustomerID
        and  pc.activeflag = 1
        order by pc.IDSeq desc
 
       
---------------------------------------------------------------------------------------------------
--     FINAL SELECT
---------------------------------------------------------------------------------------------------
        select distinct * from
        ( 
            select oitems.CustomerID,
                   oitems.ProductCode,
                   titems.ProductName,
                   oitems.PriceCapStartDate,
                   oitems.PriceCapEndDate
            from #OriginalItems oitems 
            inner join #TempPCItems titems
            on (oitems.CustomerID = titems.CustomerID
            and oitems.ProductCode = titems.ProductCode
            and  isnull(oitems.PropertyIDSeq,'0') = isnull(titems.PropertyIDSeq,'0'))
            where 
                 (not exists
                           (
                            select top 1 1 
                            from Customers.dbo.PriceCap pc with (nolock)
                            inner join 
                                 Customers.dbo.PriceCapProducts pcpr  with (nolock) 
                               on pc.IDSEq = pcpr.PriceCapIDSEq 
                            left join 
                                 Customers.dbo.PriceCapProperties pcp  with (nolock) 
                               on pcp.PriceCapIDSEq = pc.IDSeq   and isnull(oitems.PropertyIDSeq,0) = isnull(pcp.PropertyIDSeq,0) 
                            where pc.IDSEq                 = isnull(nullif(@IPBI_PriceCapIDSEq,''),0)
                              and oitems.CustomerID        = pc.CompanyIDSeq
                              and oitems.ProductCode       = pcpr.ProductCode
                              and oitems.PriceCapStartDate = pc.PriceCapStartDate
                              and oitems.PriceCapEndDate   = pc.PriceCapEndDate
                             
                              and  pc.activeflag = 1
                           )
                  )   
        )tbl   
        
        drop table #PCProducts
        drop table #PCProperties
        drop table #OriginalItems
        drop table #TempPCItems
         
end                

--Exec uspCUSTOMERS_AlreadyAddedPriceCapItems C0000000984, '|DMD-OSD-PAY-PAY-PRAI|DMD-OSD-PAY-PAY-PACH|PRM-LEG-LEG-LEG-LCAP|PRM-LEG-LEG-LEG-LHFL|', '|P0000000249|P0000000021|P0000000009|P0000000010|P0000000011|P0000000012|P0000000013|'
GO
