SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_GetReasonCategoryForAddView]
-- Description     : This proc gets called from the following locations
--                   1) From Reason Search Maintenance Screen                 1. More-->View or More-->Edit. In this case, @IPVC_ReasonCode is known to UI and should be passed.
--                   2) From Reason Category Matrix Search Maintenance Screen 1. More-->View or More-->Edit. In this case, @IPVC_ReasonCode is known to UI and should be passed.
--                      In the above 1), 2) scenario, when More-->View then results of this proc is bound and shown in the Modal with only Cancel Button.
--                      In the above 1), 2) scenario, when More-->Edit then results of this proc is bound,and shown in the Modal as follows
--                             with Reason Name Editable (so user can change the reason name)
--                                  ReasonCode Not Editable  
--                                  previously associated Active Categories for the reason on RHS (this will internally have reasoncategoryidseq not null,ActiveFlag =1)
--                                  previously associated InActive Categories for the reason on LHS (this will internally have reasoncategoryidseq not null,ActiveFlag =0)
--                                  any Remaining Unassociated Category available on LHS (this will internally have reasoncategoryidseq as  -1)
--                             if atleast one row on RHS, then Active check Box will be Checked by Default.
--                             if no rows on RHS, then Active check Box will be UNChecked by Default.
--                             then if user checks Active Check box when it is in UNChecked, then UI will move all rows that internally have IDSeq not null and ActiveFlag=0 alone to RHS

--                           and finally with Save, Cancel Button.

--                   3) From Add-->Reason. In this case,@IPVC_ReasonCode is NOT known to UI and should be passed as blank.
--                      In this Scenario, results of the proc are bound in the modal (ie.ReasonName and Code will be Blank and Editable),available categories on LHS and nothing on RHS.

-- Parameters      : @IPVC_ReasonCode (Optional)
-- Syntax examples : 
/*
EXEC ORDERS.dbo.uspORDERS_GetReasonCategoryForAddView @IPVC_ReasonCode = 'CNQT' -- For above 1), 2) scenarios

EXEC ORDERS.dbo.uspORDERS_GetReasonCategoryForAddView @IPVC_ReasonCode = '' -- For above 3) scenarios Add--> reason (ie new reason)

*/
------------------------------------------------------------------------------------------------------------------------------------------
CREATE procedure [orders].[uspORDERS_GetReasonCategoryForAddView] (@IPVC_ReasonCode varchar(20)= '' --> blank for Add-->Reason ie Scenari 3),Mandatory for More-->View Scenario 1),2) above.
                                                               )  																
AS
BEGIN
  set nocount on;
  ----------------------------------------------------------------
  declare @LVC_ReasonName  varchar(255);
  declare @LVC_ReasonCode  varchar(20);

  select @IPVC_ReasonCode = nullif(@IPVC_ReasonCode,'')
  ----------------------------------------------------------------
  if (@IPVC_ReasonCode is null or @IPVC_ReasonCode = '') --->Scenario 3) Add--> New Reason
  begin
    select ''                      as reasonname,  ---> Modal Reason Name Text Box. UI will always bind the value of first row value ReasonName of the resultset for ReasonName
                                                     -- (User will then enter a valid reason). user cannot leave it blank. 
                                                     -- Upon Save Pass this back  to SET proc XML 
           ''                      as reasoncode,  ---> Modal Reason Code Text Box. UI will always bind the value of first row value ReasonName of the resultset for reasoncode
                                                    -- (User will then enter a valid 4 digit code): UI will limit to mandatory 4 digit alpha or alpha numeric code.
                                                    --  Upon Save Pass this back  to SET proc XML 
           ''                      as reasoncategoryidseq, ---> UI to hold this internally on Left hand Side (LHS). -1 denotes no previous Reason Category Association.
                                                    --  When user moves this category from LHS to RHS and then Upon Save Pass this back  to SET proc XML 
           C.Code                  as categorycode, ---> UI to hold this internally on Left hand Side (LHS).
                                                    --  When user moves this category from LHS to RHS and then Upon Save Pass this CategoryCode back  to SET proc XML 
           C.CategoryName          as categoryname, ---> UI will show this on Left hand Side (LHS).
                                                    --  When user moves this category Name from LHS to RHS and then show in RHS and then Upon Save Pass this CategoryName back  to SET proc XML 
           1                       as internalflag, ---> UI will hold this internally on Left hand Side (LHS).
                                                    --  When user moves this category  from LHS to RHS and then show in RHS with default checked for internal based on internal flag value.
                                                    --   User can then change this value. Upon Save Pass the final user setting for internalflag back  to SET proc XML 
           0                       as ActiveFlag,    ---> UI will hold this internally on Left hand Side (LHS).
                                                    --  When user moves this category  from LHS to RHS and then UI will automatically flip this to ActiveFlag = 1 internally for this reasonCategory record.
                                                    --  then user moves this category from RHS to LHS, then UI will automatically flip this to ActiveFlag = 0 internally for this reasonCategory record.
                                                    --   Upon Save for all the reason Category records on RHS, UI will send ActiveFlag = 1
           1                       as UserEditableFlag --> UI will hot this internally. By default it is 1. However for certain pre-populated reason category records, this will be 0.
                                                       --- When a specific category is available in RHS with setting as UserEditableFlag = 1, then user cannot move this record from RHS to LHS. ie. They cannot edit or Deactivate this record.
                                                       ---  Only when record has UserEditableFlag=0, one can move from RHS to LHS.
    from  ORDERS.dbo.Category C with (nolock)
    Order by C.categoryname asc;
  end
  else if (@IPVC_ReasonCode is not null and @IPVC_ReasonCode <> '') --->Scenario 1), 2) above
  begin
    select Top 1 @LVC_ReasonCode = R.Code,
                 @LVC_ReasonName = R.ReasonName
    from   ORDERS.dbo.Reason R with (nolock)
    where  R.Code        = @IPVC_ReasonCode

    ---Select all Categories for LHS along with matching in ReasonCategory for RHS.
    -- a) reasoncategoryidseq = -1 denotes no previous association. These will have Activeflag also as 0. These stay in LHS.
    -- b) reasoncategoryidseq <> -1 and Activeflag = 0, denotes previous active association, but currently inactive. These stay in LHS.
    -- c) reasoncategoryidseq <> -1 and Activeflag = 1, denotes current active association. These automatically move to RHS in Modal.

    -- d) If there are No records in RHS, Active Flag  will be unchecked by default.
    -- d.1) As soon as one record from LHS is moved to RHS, Active Flag Check box will be turned on by default.
    -- d.2) However, if user happens to check Active flag, then UI will prompt for a message and then move all records that have reasoncategoryidseq <> -1 and activeflag=0
    --       from LHS to RHS.
    select @LVC_ReasonName                        as reasonname,
           @LVC_ReasonCode                        as reasoncode, 
           coalesce(RC.IDSeq,'-1')                as reasoncategoryidseq,
           C.Code                                 as categorycode,
           C.CategoryName                         as categoryname,
           (case when RC.IDSeq is not null
                   then RC.internalflag
                 else 1
            end)                                  as internalflag,
           (case when RC.IDSeq is not null
                   then RC.ActiveFlag
                 else 0
            end)                                  as activeflag,
           (case when RC.IDSeq is not null
                   then RC.usereditableflag
                 else 1
            end)                                  as usereditableflag          
    from   ORDERS.dbo.Category C with (nolock)
    left outer join
           ORDERS.dbo.ReasonCategory RC with (nolock)
    on     C.Code = RC.categorycode
    and    RC.ReasonCode = @IPVC_ReasonCode -->@IPVC_ReasonCode is mandatory for  1), 2) above  More-->Edit or More-->View
    order by C.categoryname asc;

  end
END
GO
