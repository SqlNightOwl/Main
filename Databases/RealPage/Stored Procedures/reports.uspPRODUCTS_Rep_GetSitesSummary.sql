SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [reports].[uspPRODUCTS_Rep_GetSitesSummary] (@IPVC_GROUPID bigint)
AS
BEGIN
  -----------------------------------------
  declare @SiteCount     int
  declare @ScreeningBit  char(1)
  declare @LI_ShowPPU	 int
----------------------------------------------------------------------------------
-- 
----------------------------------------------------------------------------------
	set @LI_ShowPPU = 0
	if exists (select Top 1 1
			   from  Quotes.dbo.QuoteItem QI  with (nolock) 
               inner join Products.dbo.Charge CH with (nolock)
			   on     QI.productcode    = CH.productcode
			   and    QI.PriceVersion   = CH.PriceVersion
               and    QI.Chargetypecode = CH.Chargetypecode
               and    QI.MeasureCode    = CH.MeasureCode
			   and	  QI.frequencycode  = CH.frequencycode	
			   and    CH.PriceByPPUPercentageEnabledFlag = 1
               and    QI.GroupIDSeq = @IPVC_GROUPID							   
              )
    begin
      set @LI_ShowPPU = 1
    end 
  -----------------------------------------
  set @ScreeningBit = '0'
  ----------------------------------------------------------------------------------
  if exists (select top 1 1
             from  Quotes.dbo.[Group]  with (nolock) 
             where IDSeq = @IPVC_GROUPID
             and   GroupType = 'PMC')
  begin
    select @SiteCount = count(IdSeq)
    from  Customers.dbo.Property  with (nolock) 
    where PMCIDSeq = (select top 1 Q.CustomerIDSeq
                      from Quotes.dbo.[Group] Q  with (nolock) 
                      where Q.IDSeq = @IPVC_GROUPID)
    and   StatusTypeCode = 'ACTIV'
    ----------------------------------
    select (select C.Name 
            from   Customers.dbo.Company C with (nolock)
            where  C.IDSeq = Q.CustomerIDSeq)                                  as [Name],
           (select Top 1 C.SiteMasterID 
            from   Customers.dbo.Company   C with (nolock)
            where  C.IDSeq = Q.CustomerIDSeq)                                  as SiteMasterID,
           ''                                                                  as OwnerName,
           isnull(A.City, '')                                                  as City,
           isnull(A.State, '')                                                 as State,
           '--'                                                                as Units,
           '--'                                                                as Beds,
           (case when @SiteCount=0 then '--'
                 else Products.dbo.fn_formatCurrency(@SiteCount,0,0)    
            end)                                                               as Sites,
           ''                                                                  as [Type],
           Case when (@LI_ShowPPU = 1) then	
           ''
		   else 'N/A' End					                                   as PPU,
		   Products.dbo.fn_formatCurrency(Q.ILFNetExtYearChargeAmount,1,2)     as ILF,
           Products.dbo.fn_formatCurrency(Q.AccessNetExtYear1ChargeAmount,1,2) as Access,
           @ScreeningBit                                                       as ScreeningBit,
           'PMC'                                                               as BundleType
    from Quotes.dbo.[Group]               Q  with (nolock) 
    left outer join Customers.dbo.Address A  with (nolock)  
    on    Q.IDSeq = @IPVC_GROUPID
    and   A.CompanyIDSeq = Q.CustomerIDSeq and A.AddressTypeCode = 'COM'    
    where Q.IDSeq = @IPVC_GROUPID
    order by [Name] asc
  end
  else
  begin
    if exists (select Top 1 1
               from  Quotes.dbo.QuoteItem Q  with (nolock) 
               inner join
                     Products.dbo.Product P with (nolock)
               on    Q.GroupIDSeq = @IPVC_GROUPID
               and   P.code = Q.productcode
               and   P.PriceVersion = Q.PriceVersion
               and   P.categorycode = 'SCR'
              )
    begin
      set @ScreeningBit = '1'
    end  
    --------------------------------------------------------
    if exists (select top 1 1
               from  Quotes.dbo.GroupProperties  with (nolock) 
               where GroupIDSeq = @IPVC_GROUPID
              )
    begin
      select P.Name                                                            as [Name],
           P.SiteMasterID                                                      as SiteMasterID,
           P.OwnerName                                                         as OwnerName,
           isnull(A.City, '')                                                  as City,
           isnull(A.State, '')                                                 as State,
           (case when (coalesce(GP.Units,P.Units))=0 then '--'
                 else Products.dbo.fn_formatCurrency(convert(varchar(50),coalesce(GP.Units,P.Units)),0,0)    
            end)                                                               as Units,                                                                       
           case when (P.StudentLivingFlag = 1 and coalesce(GP.Beds,P.Beds,0)> 0)
                 then Products.dbo.fn_formatCurrency(convert(varchar(50),coalesce(GP.Beds,P.Beds,0)),0,0)
                else '--'                   
           end                                                                 as Beds,
           '--'                                                                as Sites,
           GP.PriceTypeCode                                                    as [Type],
		   Case when (@LI_ShowPPU = 1) then	
           CAST(P.PPUPercentage AS VARCHAR(20))
		   else 'N/A' End					                                   as PPU,
           Products.dbo.fn_formatCurrency(GP.AnnualizedILFAmount, 1, 2)        as ILF,
           Products.dbo.fn_formatCurrency(GP.AnnualizedAccessAmount, 1, 2)     as Access,
           @ScreeningBit                                                       as ScreeningBit,
           'SITE'                                                              as BundleType
      from Quotes.dbo.GroupProperties   GP       with (nolock)  
      inner join Customers.dbo.Property P        with (nolock)  
      on   GP.GroupIDSeq = @IPVC_GROUPID 
      and  GP.PropertyIDSeq=P.IDSeq
      left outer join Customers.dbo.Address A    with (nolock)  
      on   A.PropertyIDSeq = P.IDSeq and A.PropertyIDSeq = GP.PropertyIDSeq
      and  A.AddressTypeCode = 'PRO'
      where GP.GroupIDSeq = @IPVC_GROUPID
      order by [Name] asc
    end
    else
    begin
      select 'None' as [Name],'' as SiteMasterID,'' as OwnerName,
             '' as City,'' as State,'' as Units,'' as Beds,'' as Sites,
             '' as [Type],'' as PPU,'' as ILF,'' as Access,'' as ScreeningBit,'' as BundleType

    end
    --------------------------------------------------------
  end

END
GO
