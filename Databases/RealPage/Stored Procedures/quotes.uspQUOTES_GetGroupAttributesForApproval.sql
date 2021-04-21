SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-----------------------------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : [uspQUOTES_GetGroupAttributesForApproval]
-- Description     : This procedure shall be called from UI before Approval.
--                   This procedure will get Flags that are stored in database for the Quote at each Group Level.
--                   
-- Input Parameters: @IPVC_QuoteIDSeq      VARCHAR(50)
-- 
-- OUTPUT          : Result set to show in UI.
-- Code Example    : 
/*
Exec QUOTES.dbo.[uspQUOTES_GetGroupAttributesForApproval]  @IPVC_QuoteIDSeq    = 'Q1107000106'
Exec QUOTES.dbo.[uspQUOTES_GetGroupAttributesForApproval]  @IPVC_QuoteIDSeq    = 'Q1107000106',@IPVC_GroupIDSeq=39418
Exec QUOTES.dbo.[uspQUOTES_GetGroupAttributesForApproval]  @IPVC_QuoteIDSeq    = 'Q1107000106',@IPVC_GroupIDSeq=39427
*/
-- Revision History: 
-- 07/01/2011      : SRS - Created TFS 738 Enhancement for AutoFulfill at Group Level
-----------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_GetGroupAttributesForApproval] (@IPVC_QuoteIDSeq           varchar(50),
                                                                  @IPVC_GroupIDSeq           varchar(50) = '' ---> UI will Pass GroupID if the same information specific to the group
                                                                                                               --- needs to be displayed for More-->Bundle Configuration Link
                                                                  )
AS
BEGIN
  set nocount on; 
  select @IPVC_GroupIDSeq = nullif(ltrim(rtrim(@IPVC_GroupIDSeq)),'')
  ----------------------------------------------------------------------------------------------------
  ;with GRP_CTE (QuoteIDSeq,GroupIDSeq,GroupName,GroupDescription,
                 AutoFulfillILFFlag,AutoFulfillACSANCFlag,ProductConfigAutoFulfillFlag,AutoFulfillStartDate)
   as (select G.QuoteIDSeq                         as QuoteIDSeq,     
              G.IDSeq                              as GroupIDSeq,                                                                      
              G.Name                               as GroupName,
              G.Description                        as GroupDescription,
              G.AutoFulfillILFFlag                 as AutoFulfillILFFlag,
              G.AutoFulfillACSANCFlag              as AutoFulfillACSANCFlag,
              (case when exists (select top 1 1
                                 from   Quotes.dbo.QuoteItem QI with (nolock)
                                 inner join
                                        Products.dbo.Product P with (nolock)
                                 on     QI.ProductCode   = P.Code
                                 and    QI.PriceVersion  = P.PriceVersion                                 
                                 and    QI.GroupIDseq    = G.IDSeq
                                 and    QI.QuoteIDSeq    = @IPVC_QuoteIDSeq
                                 and    QI.GroupIDseq    = coalesce(@IPVC_GroupIDSeq,QI.GroupIDseq)  
                                 and    P.AutoFulfillFlag= 1
                                )
                      then 1
                   else 0
             end)                                  as ProductConfigAutoFulfillFlag,
             G.AutoFulfillStartDate                as AutoFulfillStartDate
       from  Quotes.dbo.[Group] G with (nolock)
       where  G.QuoteIDSeq = @IPVC_QuoteIDSeq
       and    G.IDSeq      = coalesce(@IPVC_GroupIDSeq,G.IDSeq)  
      )
  select  GRP_CTE.QuoteIDSeq                                         as QuoteIDSeq ---->UI already knows this value. If needed  UI can hold it in hidden variable.
         ,GRP_CTE.GroupIDSeq                                         as GroupIDSeq ---->UI to hold this as hidden value. This is primary key to Group Table.
                                                                                   ---  UI will pass this back as input parameter to uspQUOTES_SetGroupAttributesForApproval 
         ,GRP_CTE.GroupName                                          as GroupName
         ,GRP_CTE.GroupDescription                                   as GroupDescription
         ,GRP_CTE.AutoFulfillILFFlag	                             as AutoFulfillILFFlag
         ,GRP_CTE.AutoFulfillACSANCFlag                              as AutoFulfillACSANCFlag
         ,GRP_CTE.ProductConfigAutoFulfillFlag                       as ProductConfigAutoFulfillFlag
         ,GRP_CTE.AutoFulfillStartDate                               as AutoFulfillStartDate
  from GRP_CTE;
  ----------------------------------------------------------------------------------------------------
END
GO
