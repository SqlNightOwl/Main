SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [customers].[uspCUSTOMERS_InsertPriceCap](
                                                          @IPVC_CompanyIDSeq      varchar(11),
                                                          @IPVC_PriceCapBasisCode varchar(4),
                                                          @IPD_PriceCapPercent    numeric(30,5),
--                                                          @IPVC_PriceCapTerm      int = 1,
                                                          @IPVC_PriceCapStartDate datetime,   
                                                          @IPVC_ProductCodes      varchar(max),
                                                          @IPVC_PropertyIDSeqs    varchar(max),
                                                          @IPVS_PriceCapIDSeq     varchar(11),
														  @IPB_FlagActive	      bit,
                                                          @IPI_CreatedByID        bigint,
														  @IPVC_PriceCapNotes     varchar(max),
														  @IPVC_PriceCapEndDate   datetime
                                                     ) 

AS
BEGIN
          declare @LVI_PriceCapIDSeq bigint
		  declare @PriceCapNoteIDSeq bigint

-----------------------------------------------------------------------------------------
-- Insert into PriceCap
-----------------------------------------------------------------------------------------
if(@IPVS_PriceCapIDSeq = '')
begin
 insert into Customers.dbo.PriceCap
          (
                CompanyIDSeq,
                PriceCapBasisCode,
                PriceCapPercent,
--                PriceCapTerm,
                PriceCapStartDate,
                PriceCapEndDate,
				ActiveFlag,
                CreatedByID,
                CreatedDate            
          )
          values
          (
                @IPVC_CompanyIDSeq,
                @IPVC_PriceCapBasisCode,
                @IPD_PriceCapPercent,
--                @IPVC_PriceCapTerm,
                @IPVC_PriceCapStartDate,
--                dateadd(year,@IPVC_PriceCapTerm,@IPVC_PriceCapStartDate),
				@IPVC_PriceCapEndDate,
				@IPB_FlagActive,
                @IPI_CreatedByID,
                getdate()
          )

          select @LVI_PriceCapIDSeq = max(IDSeq) from Customers.dbo.PriceCap

end
else
begin


------------------------------------------------------------------------------------------
-- updating PriceCap 
------------------------------------------------------------------------------------------

update Customers.dbo.PriceCap
set PriceCapBasisCode   = @IPVC_PriceCapBasisCode,
    PriceCapPercent     = @IPD_PriceCapPercent,
--    PriceCapTerm        = @IPVC_PriceCapTerm,
    PriceCapStartDate   = @IPVC_PriceCapStartDate,
--    PriceCapEndDate     = dateadd(year,@IPVC_PriceCapTerm,@IPVC_PriceCapStartDate),
	PriceCapEndDate     = @IPVC_PriceCapEndDate,
    ModifiedByID        = @IPI_CreatedByID,
    ModifiedDate        = getdate(),
    ActiveFlag			= @IPB_FlagActive
where IDSeq = @IPVS_PriceCapIDSeq


delete from  Customers.dbo.PriceCapProducts where PriceCapIDSeq = @IPVS_PriceCapIDSeq
delete from  Customers.dbo.PriceCapProperties where PriceCapIDSeq = @IPVS_PriceCapIDSeq

delete from  Customers.dbo.PriceCapProductsHistory where PriceCapIDSeq = @IPVS_PriceCapIDSeq  
delete from  Customers.dbo.PriceCapPropertiesHistory where PriceCapIDSeq = @IPVS_PriceCapIDSeq 
delete from  Customers.dbo.PriceCapHistory where PriceCapIDSeq = @IPVS_PriceCapIDSeq 
delete from  Customers.dbo.PriceCapNote where PriceCapIDSeq = @IPVS_PriceCapIDSeq
delete from  Customers.dbo.PriceCapNoteHistory where PriceCapIDSeq = @IPVS_PriceCapIDSeq  

select @LVI_PriceCapIDSeq = @IPVS_PriceCapIDSeq

end


-------------------------------------------------------------------------------------------

         
          -- Adding to PriceCapProducts

          insert into Customers.dbo.PriceCapProducts
          (
                  PriceCapIDSeq,
                  CompanyIDSeq,
                  FamilyCode,  
                  ProductCode,
                  productName
           )
           select 
                  @LVI_PriceCapIDSeq,
                  @IPVC_CompanyIDSeq, 
                  dbo.fnGetFamilyCode(ProductCode),
                  ProductCode,
                  dbo.fnProductName(ProductCode)
           from   dbo.fnSplitProductCodes ('|'+@IPVC_ProductCodes)
   
          -- Adding to PriceCapProductsHistory

          insert into Customers.dbo.PriceCapProductsHistory
          (
                  PriceCapIDSeq,
                  CompanyIDSeq,
                  FamilyCode,  
                  ProductCode,
                  productName ,
                  LogDate  
           )
           select 
                  @LVI_PriceCapIDSeq,
                  @IPVC_CompanyIDSeq, 
                  dbo.fnGetFamilyCode(ProductCode),
                  ProductCode,
                  dbo.fnProductName(ProductCode),
                  getdate()
           from   dbo.fnSplitProductCodes ('|'+@IPVC_ProductCodes)

          -- Adding to PriceCapProperties

           insert into Customers.dbo.PriceCapProperties
           (
                  PriceCapIDSeq,
                  CompanyIDSeq,                  
                  PropertyIDSeq
           )
           select
                  @LVI_PriceCapIDSeq,
                  @IPVC_CompanyIDSeq,
                  case when(PropertyID='NULL') then NULL else PropertyID end
           from   dbo.fnSplitPropertyID ('|'+@IPVC_PropertyIDSeqs)            




---------------------------------------------------------------------------------------------------
          -- Adding to PriceCapPropertiesHistory

           insert into Customers.dbo.PriceCapPropertiesHistory
           (
                  PriceCapIDSeq,
                  CompanyIDSeq,                  
                  PropertyIDSeq
           )
           select
                  @LVI_PriceCapIDSeq,
                  @IPVC_CompanyIDSeq,
                 case when(PropertyID='NULL') then NULL else PropertyID end
           from   dbo.fnSplitPropertyID ('|'+@IPVC_PropertyIDSeqs)            


           update Customers.dbo.PriceCap set PriceCapName = dbo.fnGetPriceCapName(@LVI_PriceCapIDSeq) where IDSeq = @LVI_PriceCapIDSeq 

           insert into Customers.dbo.PriceCapHistory
           (
                  PriceCapIDSeq,
                  CompanyIDSeq,
                  PriceCapName,
                  PriceCapBasisCode,
                  PriceCapPercent,
--                  PriceCapTerm,
                  priceCapStartDate,
                  PriceCapEndDate,
                  LogDate,
                  CreatedByID,
                  CreatedDate  
           )  
           values
           (
                  @LVI_PriceCapIDSeq,
                  @IPVC_CompanyIDSeq,
                  dbo.fnGetPriceCapName(@LVI_PriceCapIDSeq),
                  @IPVC_PriceCapBasisCode,
                  @IPD_PriceCapPercent,
--                  @IPVC_PriceCapTerm,
                  @IPVC_PriceCapStartDate,
--                  dateadd(year,@IPVC_PriceCapTerm,@IPVC_PriceCapStartDate),
				  @IPVC_PriceCapEndDate,
                  getdate(),
                  @IPI_CreatedByID,
                  getdate()
           )

---------------------------------------------------------------------------------------------------
          -- Adding to PriceCapNote Table

			insert into Customers.dbo.PriceCapNote
           (
                  PriceCapIDSeq,
                  [Description],                  
                  CreatedByID,
				  CreatedDate,
				  ModifiedByID,
				  ModifiedDate
           )
           select
                  @LVI_PriceCapIDSeq,
				  PriceCapNotes,
                  @IPI_CreatedByID,
				  getdate(),
				  @IPI_CreatedByID,
                  getdate()
           from   dbo.fnSplitPriceCapNotes ('|'+@IPVC_PriceCapNotes)  

select @PriceCapNoteIDSeq = scope_identity()

---------------------------------------------------------------------------------------------------
          -- Adding to PriceCapNoteHistory Table

			insert into Customers.dbo.PriceCapNoteHistory
           (
				  PriceCapNoteIDSeq,
                  PriceCapIDSeq,
                  [Description],                  
                  CreatedByID,
				  CreatedDate,
				  ModifiedByID,
				  ModifiedDate,
				  LogDate
           )
           select
				  @PriceCapNoteIDSeq,
                  @LVI_PriceCapIDSeq,
				  PriceCapNotes,
                  @IPI_CreatedByID,
				  getdate(),
				  @IPI_CreatedByID,
                  getdate(),
				  getdate()
           from   dbo.fnSplitPriceCapNotes ('|'+@IPVC_PriceCapNotes)            
          



end                

--Exec uspCUSTOMERS_InsertPriceCap

--exec CUSTOMERS.dbo.uspCUSTOMERS_InsertPriceCap 'C0000001635','DISC',0,0,'','|PRM-LEG-LEG-LEG-LAAP|PRM-LEG-LEG-LEG-LAAR|PRM-LEG-LEG-LEG-LAGL|','|P0000015710|P0000019787|P0000019796|'

GO
