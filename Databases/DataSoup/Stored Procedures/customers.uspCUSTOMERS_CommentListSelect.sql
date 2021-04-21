SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_CommentListSelect
-- Description     : This procedure gets the list of Comments 
--                   for the specific Customer.
--
-- Input Parameters: As below
-- 
-- OUTPUT          : RecordSet 
--
-- Code Example Scenarios : 
-- Customer-->Comment Section : 
/*
Customer-->Comment Section
Search will have Comment Type : Drop down
                 Property ID  : Text Box
                 Account Name : Text Box
                 User Name    : Drop down (call uspCUSTOMERS_GetCustomerCommentUsers @IPVC_CompanyIDSeq to populate drop down)
                 Comment Level: Drop down with values as ALL ( Internal code is All),Company (Internal Code is AHOFF),Property (Internal Code is APROP)

Scenario 1  :  Blind Search Under Customer-->Comment Section C0901005742 : Page View
Exec CUSTOMERS.dbo.uspCUSTOMERS_CommentListSelect @IPI_PageNumber=1,@IPI_RowsPerPage=8,@IPVC_CommentTypeCode='',@IPVC_AccountName='',@IPVC_UserID='',@IPVC_CustomerIDSeq='C0901005742',@IPVC_PropertyIDSeq='',@IPVC_AccountTypeCode='ALL'
Scenario 1.1:  Search Under Customer C0901005742 -->Comment Section : Scrollable View
Exec CUSTOMERS.dbo.uspCUSTOMERS_CommentListSelect @IPI_PageNumber=1,@IPI_RowsPerPage=999999999,@IPVC_CommentTypeCode='',@IPVC_AccountName='',@IPVC_UserID='',@IPVC_CustomerIDSeq='C0901005742',@IPVC_PropertyIDSeq='',@IPVC_AccountTypeCode='ALL'
Scenario 1.2:  Search Under Customer-->Comment Section  C0901005742, drop down Comment Type = 'Accounts Receivables' selected : Page View
Exec CUSTOMERS.dbo.uspCUSTOMERS_CommentListSelect @IPI_PageNumber=1,@IPI_RowsPerPage=999999999,@IPVC_CommentTypeCode='ACTR',@IPVC_AccountName='',@IPVC_UserID='',@IPVC_CustomerIDSeq='C0901005742',@IPVC_PropertyIDSeq='',@IPVC_AccountTypeCode='ALL'
Scenario 1.3:  Search Under Customer-->Comment Section  C0901005742, Property ID : P0901048131 input in text box
Exec CUSTOMERS.dbo.uspCUSTOMERS_CommentListSelect @IPI_PageNumber=1,@IPI_RowsPerPage=999999999,@IPVC_CommentTypeCode='',@IPVC_AccountName='',@IPVC_UserID='',@IPVC_CustomerIDSeq='C0901005742',@IPVC_PropertyIDSeq='P0901048131',@IPVC_AccountTypeCode='ALL'
Scenario 1.4:  Search Under Customer-->Comment Section  C0901005742, Account Name : ACACIA CLIFF input in text box
Exec CUSTOMERS.dbo.uspCUSTOMERS_CommentListSelect @IPI_PageNumber=1,@IPI_RowsPerPage=999999999,@IPVC_CommentTypeCode='',@IPVC_AccountName='ACACIA CLIFF',@IPVC_UserID='',@IPVC_CustomerIDSeq='C0901005742',@IPVC_PropertyIDSeq='',@IPVC_AccountTypeCode='ALL'
Scenario 1.5:  Search Under Customer-->Comment Section  C0901005742, User Name : Anand Chakravarthy  selected by drop down
Exec CUSTOMERS.dbo.uspCUSTOMERS_CommentListSelect @IPI_PageNumber=1,@IPI_RowsPerPage=999999999,@IPVC_CommentTypeCode='',@IPVC_AccountName='',@IPVC_UserID='130',@IPVC_CustomerIDSeq='C0901005742',@IPVC_PropertyIDSeq='',@IPVC_AccountTypeCode='ALL'
Scenario 1.5:  Search Under Customer-->Comment Section  C0901005742, Comment Level : 'Company'  selected by drop down
Exec CUSTOMERS.dbo.uspCUSTOMERS_CommentListSelect @IPI_PageNumber=1,@IPI_RowsPerPage=999999999,@IPVC_CommentTypeCode='',@IPVC_AccountName='',@IPVC_UserID='130',@IPVC_CustomerIDSeq='C0901005742',@IPVC_PropertyIDSeq='',@IPVC_AccountTypeCode='AHOFF'
Scenario 1.6:  Search Under Customer-->Comment Section  C0901005742, Comment Level : 'Property'  selected by drop down
Exec CUSTOMERS.dbo.uspCUSTOMERS_CommentListSelect @IPI_PageNumber=1,@IPI_RowsPerPage=999999999,@IPVC_CommentTypeCode='',@IPVC_AccountName='',@IPVC_UserID='130',@IPVC_CustomerIDSeq='C0901005742',@IPVC_PropertyIDSeq='',@IPVC_AccountTypeCode='APROP'

Account-->Comment Section 
Search will have Comment Type : Drop down                                  
                 User Name    : Drop down (call uspCUSTOMERS_GetCustomerCommentUsers @IPVC_CompanyIDSeq to populate drop down)
At the exact Account Page , UI already knows CompanyID, PropertyID if property Account, and AccountTypeCode as AHOFF or APROP
Hence in the search section
                 Property ID  : Text Box  (should not be available)
                 Account Name : Text Box  (should not be available)               
                 Comment Level: Drop down (should not be available) 

Scenario 2  : Blind Search Under Account-->Comment Section   For Company Level Account A0901031932 : Page View
              Here the CompanyId is C0901005742,@IPVC_AccountTypeCode = 'AHOFF' PropertyID = '', 
Exec CUSTOMERS.dbo.uspCUSTOMERS_CommentListSelect @IPI_PageNumber=1,@IPI_RowsPerPage=8,@IPVC_CommentTypeCode='',@IPVC_AccountName='',@IPVC_UserID='',@IPVC_CustomerIDSeq='C0901005742',@IPVC_PropertyIDSeq='',@IPVC_AccountTypeCode='AHOFF'
Scenario 1.1:  Search Under Account-->Comment Section  For Company Level Account A0901031932 : Scrollable View
Exec CUSTOMERS.dbo.uspCUSTOMERS_CommentListSelect @IPI_PageNumber=1,@IPI_RowsPerPage=999999999,@IPVC_CommentTypeCode='',@IPVC_AccountName='',@IPVC_UserID='',@IPVC_CustomerIDSeq='C0901005742',@IPVC_PropertyIDSeq='',@IPVC_AccountTypeCode='AHOFF'
Scenario 1.2:  Search Under Account-->Comment Section  For Company Level Account A0901031932, drop down Comment Type = 'Accounts Receivables' selected : Page View
Exec CUSTOMERS.dbo.uspCUSTOMERS_CommentListSelect @IPI_PageNumber=1,@IPI_RowsPerPage=8,@IPVC_CommentTypeCode='ACTR',@IPVC_AccountName='',@IPVC_UserID='',@IPVC_CustomerIDSeq='C0901005742',@IPVC_PropertyIDSeq='',@IPVC_AccountTypeCode='AHOFF'
Scenario 1.5:  Search Under Account-->Comment Section  For Company Level Account A0901031932, User Name : Anand Chakravarthy  selected by drop down
Exec CUSTOMERS.dbo.uspCUSTOMERS_CommentListSelect @IPI_PageNumber=1,@IPI_RowsPerPage=8,@IPVC_CommentTypeCode='',@IPVC_AccountName='',@IPVC_UserID='130',@IPVC_CustomerIDSeq='C0901005742',@IPVC_PropertyIDSeq='',@IPVC_AccountTypeCode='AHOFF'

Scenario 3  : Blind Search Under Account-->Comment Section   For Property Level Account A0901012638 : Page View
              Here the CompanyId is C0901005742,@IPVC_AccountTypeCode = 'APROP' PropertyID = 'P0901048131', 
Exec CUSTOMERS.dbo.uspCUSTOMERS_CommentListSelect @IPI_PageNumber=1,@IPI_RowsPerPage=8,@IPVC_CommentTypeCode='',@IPVC_AccountName='',@IPVC_UserID='',@IPVC_CustomerIDSeq='C0901005742',@IPVC_PropertyIDSeq='P0901048131',@IPVC_AccountTypeCode='APROP'
Scenario 1.1:  Search Under Account-->Comment Section  For Company Level Account A0901031932 : Scrollable View
Exec CUSTOMERS.dbo.uspCUSTOMERS_CommentListSelect @IPI_PageNumber=1,@IPI_RowsPerPage=999999999,@IPVC_CommentTypeCode='',@IPVC_AccountName='',@IPVC_UserID='',@IPVC_CustomerIDSeq='C0901005742',@IPVC_PropertyIDSeq='P0901048131',@IPVC_AccountTypeCode='APROP'
Scenario 1.2:  Search Under Account-->Comment Section  For Company Level Account A0901031932, drop down Comment Type = 'Accounts Receivables' selected : Page View
Exec CUSTOMERS.dbo.uspCUSTOMERS_CommentListSelect @IPI_PageNumber=1,@IPI_RowsPerPage=8,@IPVC_CommentTypeCode='ACTR',@IPVC_AccountName='',@IPVC_UserID='',@IPVC_CustomerIDSeq='C0901005742',@IPVC_PropertyIDSeq='P0901048131',@IPVC_AccountTypeCode='APROP'
Scenario 1.5:  Search Under Account-->Comment Section  For Company Level Account A0901031932, User Name : Anand Chakravarthy  selected by drop down
Exec CUSTOMERS.dbo.uspCUSTOMERS_CommentListSelect @IPI_PageNumber=1,@IPI_RowsPerPage=8,@IPVC_CommentTypeCode='',@IPVC_AccountName='',@IPVC_UserID='130',@IPVC_CustomerIDSeq='C0901005742',@IPVC_PropertyIDSeq='P0901048131',@IPVC_AccountTypeCode='APROP'
*/
-- 
-- Revision History:
-- Author          : Anand Chakravarthy.
-- 05/25/2010      : created Defect7854
-- 06/10/2010      : SRS Modified for better search

------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_CommentListSelect]  (@IPI_PageNumber        bigint,           --> (Scrollable View) pass in 1; else it is the page number.
                                                          @IPI_RowsPerPage       bigint,           --> (Scrollable View) pass in higher number 999999999; For (Page wise View) it is 8 Records per page.
                                                          @IPVC_CommentTypeCode  varchar(10),      --> Commenttypecode pertaining to Drop down search. If none, pass in ''
                                                          @IPVC_AccountName      varchar(100),     --> For Search in Account page pass in '' as search by Accountname is not valid for Account-->Comment Section. So Remove Textbox for Account Name in Search section for Account-->Comment Section.
                                                                                                     --  Search by AccountName text box is valid only in Customer-->Comment Section; default is ''.
                                                          @IPVC_UserID           varchar(50),      --> UserID of user pertaining to drop down username selection;default is '' if none is selected.
                                                          @IPVC_CustomerIDSeq    varchar(50),      --> Always pass in CompanyIDSeq (this is applicable in both customer-->Commetn section or Account-->Comment Section);UI always knows this.
                                                          @IPVC_PropertyIDSeq    varchar(50)= NULL,--> Pass in PropertyIDSeq ie Pxxxxx and NOT Axxxxx if Account is pertaining to Property Account in Account-->Comment Section
                                                                                                      --  Pass in '' if Account is pertaining to Company Account  Account-->Comment Section
                                                                                                      --  In Customer-->Comment Section, provide Textbox Property ID:  before Account Name: Text box. Pass '' if user did not enter anything. Else pass Pxxxx ID that user keys in
                                                          @IPVC_AccountTypeCode  varchar(50)='ALL' --> Default is 'ALL' for search in Customer-->Comment Section
                                                                                                      --Show Comment Level: drop down only in Customer-->Comment Section
                                                                                                      -- If drop down selected is All, then pass All; If drop down selected is Company, then pass AHOFF;If drop down selected is Property, then pass APROP
                                                                                                      -- For Account--Comment Section, This drop down does not show up; But internally pass AHOFF if Account is Company Account; Pass APROP if Account is Property Account
                                                         ) ---WITH RECOMPILE                                                          
AS
BEGIN        
  set nocount on;
  SET CONCAT_NULL_YIELDS_NULL ON;
  -----------------------------------------  
  select @IPVC_CustomerIDSeq  = nullif(ltrim(rtrim(@IPVC_CustomerIDSeq)),''),
         @IPVC_PropertyIDSeq  = nullif(ltrim(rtrim(@IPVC_PropertyIDSeq)),''),
         @IPVC_UserID         = nullif(@IPVC_UserID,''),
         @IPVC_CommentTypeCode= nullif(ltrim(rtrim(@IPVC_CommentTypeCode)),''),
         @IPVC_AccountName    = ltrim(rtrim(@IPVC_AccountName))
  ----------------------------------------- 
  declare @rowstoprocess bigint
  select  @rowstoprocess = (@IPI_PageNumber)*@IPI_RowsPerPage
  SET ROWCOUNT @rowstoprocess;  
  ----------------------------------------------------------------
  ---Get Records based on search criteria
  ----------------------------------------------------------------
  ;WITH tablefinal AS
         (Select  CC.IDSeq                                                         as ID,
                  CC.CommentTypeCode                                               as CommentTypeCode,
                  CT.Name                                                          as CommentTypeName,
                  coalesce(P.Name,C.Name)                                          as AccountName,                  
                  CC.Name                                                          as CommentName, 
                  (case when UM.IDSeq is not null 
                          then
                             UM.FirstName + ' '+ UM.LastName
                        else UC.FirstName + ' '+ UC.LastName 
                   end)                                                            as [UserName],
                  convert(varchar(50),coalesce(CC.ModifiedDate,CC.CreatedDate),22) as [CommentDate],  
                  CC.CreatedByIDSeq                                                as CreatedByIDSeq,
                  UC.FirstName + ' '+ UC.LastName                                  as CreatedByUserName,  -->Future use
                  convert(varchar(50),CC.CreatedDate,22)                           as CreatedDate,        -->Future use
                  CC.ModifiedByIDSeq                                               as ModifiedByIDSeq,
                  UM.FirstName + ' '+ UM.LastName                                  as ModifiedByUserName, -->Future use
                  (case when UM.IDSeq is not null 
                          then convert(varchar(50),CC.ModifiedDate,22)        
                        else NULL
                   end)                                                            as ModifiedDate,       -->Future use
                  CC.CompanyIDSeq                                                  as CompanyIDSeq,
                  CC.PropertyIDSeq                                                 as PropertyIDSeq,
                  CC.AccountIDSeq                                                  as AccountIDSeq,
                  row_number() OVER(ORDER BY CC.[CommentTypeCode] asc,CC.CreatedByIDSeq desc,P.Name asc)   
                                                                                   as [RowNumber],
                  Count(1) OVER()                                                  as TotalCountForPaging             
           from   CUSTOMERS.dbo.CustomerComment CC    with (nolock)
           inner join
                  CUSTOMERS.dbo.CommentType CT with (nolock)
           on     CC.CommentTypeCode = CT.Code 
           and    CC.CompanyIDSeq    = coalesce(@IPVC_CustomerIDSeq,CC.CompanyIDSeq)
           and    coalesce(CC.PropertyIDSeq,'0')   = coalesce(@IPVC_PropertyIDSeq,coalesce(CC.PropertyIDSeq,'0'))
           and    CC.CommentTypeCode = coalesce(@IPVC_CommentTypeCode,CC.CommentTypeCode)
           and    ((@IPVC_AccountTypeCode = 'ALL')
                     OR
                   (CC.AccountTypeCode = @IPVC_AccountTypeCode)
                  )
           inner join
                  Security.dbo.[User] UC with (nolock)           
           on     CC.CreatedByIDSeq = UC.IDSeq
           and    ((CC.CreatedByIDSeq = coalesce(@IPVC_UserID,CC.CreatedByIDSeq))
                     OR
                   (coalesce(CC.modifiedByIDSeq,CC.CreatedByIDSeq) = coalesce(@IPVC_UserID,coalesce(CC.modifiedByIDSeq,CC.CreatedByIDSeq)))
                  )
           inner join 
                  CUSTOMERS.dbo.Company C with (nolock)
           on     CC.CompanyIDSeq = C.IDSeq
           left outer join
                  CUSTOMERS.dbo.Property P with (nolock)
           on     CC.PropertyIDSeq = P.IDSeq
           left outer Join
                  Security.dbo.[User] UM with (nolock)               
           on     CC.modifiedByIDSeq  = UM.IDSeq
           and    ((CC.CreatedByIDSeq = coalesce(@IPVC_UserID,CC.CreatedByIDSeq))
                     OR
                   (coalesce(CC.modifiedByIDSeq,CC.CreatedByIDSeq) = coalesce(@IPVC_UserID,coalesce(CC.modifiedByIDSeq,CC.CreatedByIDSeq)))
                  )
           where  CC.CompanyIDSeq    = coalesce(@IPVC_CustomerIDSeq,CC.CompanyIDSeq)
           and    coalesce(CC.PropertyIDSeq,'0')   = coalesce(@IPVC_PropertyIDSeq,coalesce(CC.PropertyIDSeq,'0'))
           and    CC.CommentTypeCode = coalesce(@IPVC_CommentTypeCode,CC.CommentTypeCode)
           and    ((@IPVC_AccountTypeCode = 'ALL')
                     OR
                   (CC.AccountTypeCode = @IPVC_AccountTypeCode)
                  )
           and    ((CC.CreatedByIDSeq = coalesce(@IPVC_UserID,CC.CreatedByIDSeq))
                     OR
                   (coalesce(CC.modifiedByIDSeq,CC.CreatedByIDSeq) = coalesce(@IPVC_UserID,coalesce(CC.modifiedByIDSeq,CC.CreatedByIDSeq)))
                  )
           and    coalesce(P.Name,C.Name) like '%' + @IPVC_AccountName + '%'
         )
  select tablefinal.[ID],
         tablefinal.CommentTypeCode,
         tablefinal.CommentTypeName,
         tablefinal.AccountName,
         tablefinal.CommentName,
         tablefinal.UserName,
         tablefinal.CreatedByIDSeq,
         tablefinal.ModifiedByIDSeq,
         tablefinal.[CommentDate],
         tablefinal.CompanyIDSeq,
         tablefinal.PropertyIDSeq,
         tablefinal.AccountIDSeq,
         tablefinal.TotalCountForPaging
  from   tablefinal
  where  tablefinal.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
  and    tablefinal.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage;
  -----------------------------------------------
END
GO
