create proc SP_LogSearch @Keywords varchar(max),@Searchoption tinyint,@StartDate datetime=null,@EndDate datetime=null
as
declare @str varchar(max)='',@sql varchar(max)=''
if @Keywords<>'' Begin 
  While Charindex(',',@Keywords)>0 Begin
    if @Searchoption = 0
      set @str = @str + ' and ' + 'Text not like ''%'+replace(Substring(@Keywords,1,Charindex(',',@Keywords)-1 ),'''','''''')+'%'' '   
    else if @Searchoption = 1
      set @str = @str + ' and ' + 'Text like ''%'+replace(Substring(@Keywords,1,Charindex(',',@Keywords)-1 ),'''','''''')+'%'' '   
    set @Keywords = Substring(@Keywords,Charindex(',',@Keywords)+1,len(@Keywords) )
  end 
  if @Searchoption = 0
    set @str = @str + ' and ' + 'Text not like ''%'+replace(@Keywords,'''','''''')+'%'' '   
  else if @Searchoption = 1
    set @str = @str + ' and ' + 'Text like ''%'+replace(@Keywords,'''','''''')+'%'' '   
end
--select @str
    
create table #sqllogs(log_number int,log_date datetime,log_size   int)

INSERT into #sqllogs exec sp_enumerrorlogs
               
create table #temp(LogDate Datetime,ProcessesInfo varchar(max),Text varchar(max));
 
declare @sqllognumbermin int
declare @sqllognumbermax int
select @sqllognumbermin = min(log_number), @sqllognumbermax = max(log_number) from #sqllogs
declare @i int=@sqllognumbermin
 
while @i<=@sqllognumbermax begin
  if @StartDate>(select log_date from #sqllogs where log_number=@i)
    set @i=@sqllognumbermax+1
  else begin
    set @sql='insert into #temp EXEC master.dbo.xp_readerrorlog ' + cast(@i as varchar(5))
    exec (@sql)
  end
  set @i=@i+1
end
             
if @Searchoption =0
begin
  set @sql=
  '
    select * from #temp
      where LogDate between ISNULL('''+convert(varchar(40),ISNULL(@StartDate,0))+''',CONVERT(datetime,0)) and ISNULL('''+convert(varchar(40),ISNULL(@EndDate,100000))+''',CONVERT(datetime,100000)) ' + @str + '
        order by LogDate
  '
  exec(@sql)
end
else if @Searchoption=1 begin
  set @sql=
  '
    select * from #temp
      where LogDate between ISNULL('''+convert(varchar(40),ISNULL(@StartDate,0))+''',CONVERT(datetime,0)) and ISNULL('''+convert(varchar(40),ISNULL(@EndDate,100000))+''',CONVERT(datetime,100000)) ' + @str + '
        order by LogDate
  '
  exec(@sql)
end
else if @Searchoption=2
  select * from #temp
    where  LogDate between ISNULL(@StartDate,CONVERT(datetime,0)) and ISNULL(@EndDate,CONVERT(datetime,100000)) order by LogDate
drop table #temp;
GO
