use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[EventFieldDetail]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [mkt].[EventFieldDetail]
GO
CREATE TABLE [mkt].[EventFieldDetail] (
	[Field] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ControlType] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[MaxLength] [int] NULL ,
	[OrdinalPosition] [tinyint] NULL ,
	[IsConfigurable] [bit] NOT NULL ,
	CONSTRAINT [PK_EventFieldDetail] PRIMARY KEY  CLUSTERED 
	(
		[Field]
	)  ON [PRIMARY] ,
	CONSTRAINT [CK_EventFieldDetail_IsConfigurable] CHECK (case when charindex('user',[Field])=(1) then (1) when charindex([Field],'is_a_member;has_opted_in')>(0) then (1) else (0) end=(1))
) ON [PRIMARY]
GO
setuser N'mkt'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[EventFieldDetail].[IsConfigurable]'
GO
setuser
GO