SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
exec QUOTES.dbo.uspQUOTES_CopyBundleWithinQuote @IPVC_ExistingQuoteID= 'Q0905000026',@IPBI_ExistingBundleID=4090
*/
-----------------------------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : uspQUOTES_CopyBundleWithinQuote
-- Description     : This procedure copies high level info of existing Bundle with in a Quote and creates a template Bundle.
-- Input Parameters: @IPVC_ExistingQuoteID -- Existing QuoteID which feed info for Template Quote to be created.
--                   @IPVC_CreatedBy       -- Name of User who is creating the Template Quote.
--                   @IPI_CopyGroupPropertiesFlag = 1 or 0. 1 will copy GroupProperties too. 0 will not.
-- OUTPUT          : Rowset.
--  
--                   
-- Code Example    : exec QUOTES.dbo.uspQUOTES_CopyBundleWithinQuote --                       
--                        @IPVC_ExistingQuoteID  ='Q0000000049',
--                        @IPBI_ExistingBundleID ='1234'
-- Revision History:
-- Author          : SRS
-- 05/26/2008      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_CopyBundleWithinQuote] (@IPVC_ExistingQuoteID      varchar(50),
                                                          @IPBI_ExistingBundleID     bigint                                                        
                                                         )
AS
BEGIN
  set nocount on;
  declare @LBI_NewGroupID  bigint
  --------------------------------------------------
  if not exists (select top 1 1 from Quotes.dbo.[Group] G with (nolock)
                 where  G.Quoteidseq =  @IPVC_ExistingQuoteID
                 and    G.IDseq      =  @IPBI_ExistingBundleID
                 )
     OR
     exists     (select top 1 1 from Quotes.dbo.Quote Q with (nolock)
                 where  Q.Quoteidseq      =  @IPVC_ExistingQuoteID
                 and    Q.Quotestatuscode in ('CNL','APR')
                )
  begin
    ---Do Nothing and Return
    return;
  end
  -------------------------------------------------
  DECLARE @NewGroupTable TABLE(NewGroupID bigint)
  --------------------------------------------------
  ---Step 1 : Quotes.dbo.Group
  begin TRY 
    Insert Into Quotes.dbo.[Group](QuoteIDSeq,DiscAllocationCode,Name,Description,CustomerIDSeq,OverrideFlag,Sites,Units,Beds,PPUPercentage,
                                   ILFExtYearChargeAmount,ILFDiscountPercent,ILFDiscountAmount,ILFNetExtYearChargeAmount,
                                   AccessExtYear1ChargeAmount,AccessExtYear2ChargeAmount,AccessExtYear3ChargeAmount,
                                   AccessDiscountPercent,AccessDiscountAmount,AccessNetExtYear1ChargeAmount,AccessNetExtYear2ChargeAmount,AccessNetExtYear3ChargeAmount,
                                   ShowDetailPriceFlag,PreConfiguredBundleCode,PreConfiguredBundleFlag,AllowProductCancelFlag,GroupType,
                                   CustomBundleNameEnabledFlag,ExcludeForBookingsFlag)
    OUTPUT  Inserted.IDSeq into @NewGroupTable(NewGroupID)
    select Top 1 
           QuoteIDSeq,DiscAllocationCode,Name,Description,CustomerIDSeq,OverrideFlag,0 as Sites,0 as Units,0 as Beds,100 as PPUPercentage,
           0 as ILFExtYearChargeAmount,0 as ILFDiscountPercent, 0 as ILFDiscountAmount,0 as ILFNetExtYearChargeAmount,
           0 as AccessExtYear1ChargeAmount,0 as AccessExtYear2ChargeAmount,0 as AccessExtYear3ChargeAmount,
           0 as AccessDiscountPercent,0 as AccessDiscountAmount,0 as AccessNetExtYear1ChargeAmount,0 as AccessNetExtYear2ChargeAmount,0 as AccessNetExtYear3ChargeAmount,
           ShowDetailPriceFlag,PreConfiguredBundleCode,PreConfiguredBundleFlag,AllowProductCancelFlag,GroupType,
           CustomBundleNameEnabledFlag,ExcludeForBookingsFlag
    from   Quotes.dbo.[Group] G with (nolock)
    where  G.Quoteidseq =  @IPVC_ExistingQuoteID
    and    G.IDseq      =  @IPBI_ExistingBundleID   
  end TRY
  begin CATCH
    EXEC CUSTOMERS.[dbo].[uspCUSTOMERS_RaiseError] 'Copy Bundle within a Quote Section'
    Return;
  end CATCH
  --------------------------------------------------
  select @LBI_NewGroupID = NewGroupID from @NewGroupTable
  ---Step 1 : Quotes.dbo.QuoteItem
  begin TRY
    Insert into Quotes.dbo.QuoteItem(QuoteIDSeq,GroupIDSeq,ProductCode,ChargeTypeCode,FrequencyCode,MeasureCode,FamilyCode,PublicationYear,PublicationQuarter,
                                     PreConfiguredBundleCode,PreConfiguredBundleFlag,AllowProductCancelFlag,PriceVersion,Sites,Units,Beds,PPUPercentage,Quantity,MinUnits,MaxUnits,
                                     Multiplier,QuantityEnabledFlag,ChargeAmount,ExtChargeAmount,ExtSOCChargeAmount,ExtYear1ChargeAmount,ExtYear2ChargeAmount,
                                     ExtYear3ChargeAmount,DiscountPercent,DiscountAmount,TotalDiscountPercent,TotalDiscountAmount,NetChargeAmount,NetExtChargeAmount,
                                     NetExtYear1ChargeAmount,NetExtYear2ChargeAmount,NetExtYear3ChargeAmount,CapMaxUnitsFlag,DollarMinimum,DollarMaximum,UnitOfMeasure,
                                     CCTransactionPercent,CredtCardPricingPercentage,ExcludeForBookingsFlag,CrossFireMaximumAllowableCallVolume)
    select QuoteIDSeq,@LBI_NewGroupID as GroupIDSeq,ProductCode,ChargeTypeCode,FrequencyCode,MeasureCode,FamilyCode,PublicationYear,PublicationQuarter,
           PreConfiguredBundleCode,PreConfiguredBundleFlag,AllowProductCancelFlag,PriceVersion,0 Sites,0 Units,0 Beds,100 PPUPercentage,Quantity,MinUnits,MaxUnits,
           0 as Multiplier,QuantityEnabledFlag,ChargeAmount,0 ExtChargeAmount,0 ExtSOCChargeAmount,0 ExtYear1ChargeAmount,0 ExtYear2ChargeAmount,
           0 ExtYear3ChargeAmount,DiscountPercent,DiscountAmount,0 TotalDiscountPercent,0 TotalDiscountAmount,
           NetChargeAmount,0 NetExtChargeAmount,
           0 NetExtYear1ChargeAmount,0 NetExtYear2ChargeAmount,0 NetExtYear3ChargeAmount,
           CapMaxUnitsFlag,DollarMinimum,DollarMaximum,0 UnitOfMeasure,
           CCTransactionPercent,CredtCardPricingPercentage,ExcludeForBookingsFlag,CrossFireMaximumAllowableCallVolume
    from  Quotes.dbo.Quoteitem QI With (nolock)
    where QI.Quoteidseq =  @IPVC_ExistingQuoteID
    and   QI.GroupIDSeq =  @IPBI_ExistingBundleID 
  end TRY
  begin CATCH
    EXEC CUSTOMERS.[dbo].[uspCUSTOMERS_RaiseError] 'Copy Quoteitem for Copy Bundle within a Quote Section' 
    return;             
  end CATCH 
  -------------------------------------------------------------------------------------------------
  ---Final Update to realign GroupNames for the current Quote
  -------------------------------------------------------------
  if exists (select Top 1 1 
             from   QUOTES.DBO.[Group] (nolock) 
             where  QuoteIDSeq = @IPVC_ExistingQuoteID 
             and    IDSeq      = @IPBI_ExistingBundleID
             and    charindex('Custom Bundle',name)=1
            ) 
  begin
    begin TRY 
      Update G
      set    G.Name        = S.NewName
      from   QUOTES.DBO.[Group] G (nolock)
      Inner Join
              (select T2.QuoteIDSeq,
                      T2.IDSeq as GroupID,
                      T2.Name  as OldName,
        	      'Custom Bundle ' + 
                       convert(varchar(50),(select count(*) 
                                            from QUOTES.DBO.[Group] (nolock) T1 
                                            where T1.QuoteIDSeq = T2.QuoteIDSeq
                                            and   T1.QuoteIDSeq = @IPVC_ExistingQuoteID
                                            and   T2.QuoteIDSeq = @IPVC_ExistingQuoteID
                                            and   T1.IDSeq     <= T2.IDSeq
                                            and   charindex('Custom Bundle',T1.name)=1 
                                           )
                               )        as NewName
               from  QUOTES.DBO.[Group] (nolock) T2
               where QuoteIDSeq = @IPVC_ExistingQuoteID
               and   charindex('Custom Bundle',T2.name)=1
              ) S
      on    G.QuoteIDSeq = S.QuoteIDSeq
      and   G.IDSeq      = S.GroupID
      and   G.Name       = S.OldName
      and   G.QuoteIDSeq = @IPVC_ExistingQuoteID
      where G.QuoteIDSeq = @IPVC_ExistingQuoteID
    end TRY
    begin CATCH
      EXEC CUSTOMERS.[dbo].[uspCUSTOMERS_RaiseError] 'Group Update To realign GroupNames Section - 1'              
    end CATCH
  end
else
  begin
    begin TRY 
        Declare @IniStr varchar(2000),@IntVal varchar(3)

		select @IniStr  = [Name] 
        from   QUOTES.DBO.[Group] G (nolock) 
        where  QuoteIDSeq = @IPVC_ExistingQuoteID 
           and IDSeq      = @IPBI_ExistingBundleID

		set @IntVal = substring(@IniStr,len(@IniStr),len(@IniStr)-1)
		--============================================================
		--  If the last string value is integer then increment by 1
		-- else concatenate by 1
		--============================================================
		if (isnumeric(@IntVal)=1)
		 begin
	        set @IntVal = (select count(idseq)-1 from QUOTES.DBO.[Group] G (nolock) where  QuoteIDSeq = @IPVC_ExistingQuoteID  and charindex(substring(@IniStr,1,len(@IniStr)-1),G.name)=1 )
		    Set @IniStr = substring(@IniStr,1,len(@IniStr)-1) + cast(@IntVal as varchar(3))
		 end
		else
		 begin
		   Set @IniStr =  @IniStr + convert(varchar,(select count(idseq)-1 
													 from QUOTES.DBO.[Group] G (nolock) 
													 where  QuoteIDSeq = @IPVC_ExistingQuoteID  
                                                     and charindex(substring(@IniStr,1,len(@IniStr)-1),G.name)=1 )
											         )
		 end

		  Update G    
		  set    G.Name = @IniStr  
		  from   QUOTES.DBO.[Group] G (nolock)
		  where  IDSeq = @LBI_NewGroupID

    end TRY
    begin CATCH
      EXEC CUSTOMERS.[dbo].[uspCUSTOMERS_RaiseError] 'Group Update To realign GroupNames Section - 2'              
    end CATCH
  end
  -------------------------------------------------------------------------------------------------  
  ---Pricing Engine Call to set things straight
  exec Quotes.dbo.uspQUOTES_SyncGroupAndQuote @IPVC_QuoteID=@IPVC_ExistingQuoteID,@IPI_GroupID=@LBI_NewGroupID;
  --------------------------------------------------
END

GO
