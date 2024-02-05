CREATE FUNCTION [dbo].[parseJSON]( @JSON NVARCHAR(MAX))
RETURNS @hierarchy TABLE
  (
   element_id INT IDENTITY(1, 1) NOT NULL,
   sequenceNo [int] NULL,
   parent_ID INT,
   Object_ID INT,
   NAME NVARCHAR(2000),
   StringValue NVARCHAR(MAX) NOT NULL,
   ValueType VARCHAR(10) NOT null
  )
AS
BEGIN
  DECLARE
    @FirstObject INT,
    @OpenDelimiter INT,
    @NextOpenDelimiter INT,
    @NextCloseDelimiter INT,
    @Type NVARCHAR(10),
    @NextCloseDelimiterChar CHAR(1),
    @Contents NVARCHAR(MAX),
    @Start INT,
    @end INT,
    @param INT,
    @EndOfName INT,
    @token NVARCHAR(200),
    @value NVARCHAR(MAX),
    @SequenceNo int,
    @name NVARCHAR(200),
    @parent_ID INT,
    @lenJSON INT,
    @characters NCHAR(36),
    @result BIGINT,
    @index SMALLINT,
    @Escape INT
   
 
  DECLARE @Strings TABLE 
    (
     String_ID INT IDENTITY(1, 1),
     StringValue NVARCHAR(MAX)
    )
  SELECT
    @characters='0123456789abcdefghijklmnopqrstuvwxyz',
    @SequenceNo=0, 
    @parent_ID=0;
  WHILE 1=1
    BEGIN
      SELECT
        @start=PATINDEX('%[^a-zA-Z]["]%', @json collate SQL_Latin1_General_CP850_Bin);
      IF @start=0 BREAK
      IF SUBSTRING(@json, @start+1, 1)='"'
        BEGIN
          SET @start=@Start+1;
          SET @end=PATINDEX('%[^\]["]%', RIGHT(@json, LEN(@json+'|')-@start) collate SQL_Latin1_General_CP850_Bin);
        END
      IF @end=0
        BREAK
      SELECT @token=SUBSTRING(@json, @start+1, @end-1)
      
      SELECT @token=REPLACE(@token, FROMString, TOString)
      FROM
        (SELECT
          '\"' AS FromString, '"' AS ToString
         UNION ALL SELECT '\\', '\'
         UNION ALL SELECT '\/', '/'
         UNION ALL SELECT '\b', CHAR(08)
         UNION ALL SELECT '\f', CHAR(12)
         UNION ALL SELECT '\n', CHAR(10)
         UNION ALL SELECT '\r', CHAR(13)
         UNION ALL SELECT '\t', CHAR(09)
        ) substitutions
      SELECT @result=0, @escape=1
      WHILE @escape>0
        BEGIN
          SELECT @index=0,
          @escape=PATINDEX('%\x[0-9a-f][0-9a-f][0-9a-f][0-9a-f]%', @token collate SQL_Latin1_General_CP850_Bin)
          IF @escape>0
            BEGIN
              WHILE @index<4
                BEGIN
                  SELECT
                    @result=@result+POWER(16, @index)
                    *(CHARINDEX(SUBSTRING(@token, @escape+2+3-@index, 1),
                                @characters)-1), @index=@index+1 ;
        
                END
              SELECT @token=STUFF(@token, @escape, 6, NCHAR(@result))
            END
        END
      INSERT INTO @Strings (StringValue) SELECT @token
      SELECT @JSON=STUFF(@json, @start, @end+1,
                    '@string'+CONVERT(NVARCHAR(5), @@identity))
    END
  WHILE 1=1
  BEGIN
 
  SELECT @parent_ID=@parent_ID+1
  SELECT @FirstObject=PATINDEX('%[{[[]%', @json collate SQL_Latin1_General_CP850_Bin)--object or array
  IF @FirstObject = 0 BREAK
  IF (SUBSTRING(@json, @FirstObject, 1)='{')
    SELECT @NextCloseDelimiterChar='}', @type='object'
  ELSE
    SELECT @NextCloseDelimiterChar=']', @type='array'
  SELECT @OpenDelimiter=@firstObject
 
  WHILE 1=1
    BEGIN
      SELECT
        @lenJSON=LEN(@JSON+'|')-1
      SELECT
        @NextCloseDelimiter=CHARINDEX(@NextCloseDelimiterChar, @json,
                                      @OpenDelimiter+1)
      SELECT @NextOpenDelimiter=PATINDEX('%[{[[]%',
             RIGHT(@json, @lenJSON-@OpenDelimiter)collate SQL_Latin1_General_CP850_Bin)--object
      IF @NextOpenDelimiter=0
        BREAK
      SELECT @NextOpenDelimiter=@NextOpenDelimiter+@OpenDelimiter
      IF @NextCloseDelimiter<@NextOpenDelimiter
        BREAK
      IF SUBSTRING(@json, @NextOpenDelimiter, 1)='{'
        SELECT @NextCloseDelimiterChar='}', @type='object'
      ELSE
        SELECT @NextCloseDelimiterChar=']', @type='array'
      SELECT @OpenDelimiter=@NextOpenDelimiter
    END
  SELECT
    @contents=SUBSTRING(@json, @OpenDelimiter+1,
                        @NextCloseDelimiter-@OpenDelimiter-1)
  SELECT
    @JSON=STUFF(@json, @OpenDelimiter,
                @NextCloseDelimiter-@OpenDelimiter+1,
                '@'+@type+CONVERT(NVARCHAR(5), @parent_ID))
  WHILE (PATINDEX('%[A-Za-z0-9@+.e]%', @contents collate SQL_Latin1_General_CP850_Bin))<>0
    BEGIN
      IF @Type='Object'
        BEGIN
          SELECT
            @SequenceNo=0,@end=CHARINDEX(':', ' '+@contents)
          SELECT  @start=PATINDEX('%[^A-Za-z@][@]%', ' '+@contents collate SQL_Latin1_General_CP850_Bin)
          SELECT @token=SUBSTRING(' '+@contents, @start+1, @End-@Start-1),
            @endofname=PATINDEX('%[0-9]%', @token collate SQL_Latin1_General_CP850_Bin),
            @param=RIGHT(@token, LEN(@token)-@endofname+1)
          SELECT
            @token=LEFT(@token, @endofname-1),
            @Contents=RIGHT(' '+@contents, LEN(' '+@contents+'|')-@end-1)
          SELECT  @name=stringvalue FROM @strings
            WHERE String_ID=@param
        END
      ELSE
        SELECT @Name=null,@SequenceNo=@SequenceNo+1
      SELECT
        @end=CHARINDEX(',', @contents)
      IF @end=0
        SELECT  @end=PATINDEX('%[A-Za-z0-9@+.e][^A-Za-z0-9@+.e]%', @Contents+' ' collate SQL_Latin1_General_CP850_Bin)
          +1
       SELECT
         @start=PATINDEX('%[^A-Za-z0-9@+.e][A-Za-z0-9@+.e][\-]%', ' '+@contents collate SQL_Latin1_General_CP850_Bin)
      SELECT
        @Value=RTRIM(SUBSTRING(@contents, @start, @End-@Start)),
        @Contents=RIGHT(@contents+' ', LEN(@contents+'|')-@end)
      IF SUBSTRING(@value, 1, 7)='@object'
        INSERT INTO @hierarchy
          (NAME, SequenceNo, parent_ID, StringValue, Object_ID, ValueType)
          SELECT @name, @SequenceNo, @parent_ID, SUBSTRING(@value, 8, 5),
            SUBSTRING(@value, 8, 5), 'object'
      ELSE
        IF SUBSTRING(@value, 1, 6)='@array'
          INSERT INTO @hierarchy
            (NAME, SequenceNo, parent_ID, StringValue, Object_ID, ValueType)
            SELECT @name, @SequenceNo, @parent_ID, SUBSTRING(@value, 7, 5),
              SUBSTRING(@value, 7, 5), 'array'
        ELSE
          IF SUBSTRING(@value, 1, 7)='@string'
            INSERT INTO @hierarchy
              (NAME, SequenceNo, parent_ID, StringValue, ValueType)
              SELECT @name, @SequenceNo, @parent_ID, stringvalue, 'string'
              FROM @strings
              WHERE String_ID=SUBSTRING(@value, 8, 5)
          ELSE
            IF @value IN ('true', 'false')
              INSERT INTO @hierarchy
                (NAME, SequenceNo, parent_ID, StringValue, ValueType)
                SELECT @name, @SequenceNo, @parent_ID, @value, 'boolean'
            ELSE
              IF @value='null'
                INSERT INTO @hierarchy
                  (NAME, SequenceNo, parent_ID, StringValue, ValueType)
                  SELECT @name, @SequenceNo, @parent_ID, @value, 'null'
              ELSE
                IF PATINDEX('%[^0-9]%', @value collate SQL_Latin1_General_CP850_Bin)>0
                  INSERT INTO @hierarchy
                    (NAME, SequenceNo, parent_ID, StringValue, ValueType)
                    SELECT @name, @SequenceNo, @parent_ID, @value, 'real'
                ELSE
                  INSERT INTO @hierarchy
                    (NAME, SequenceNo, parent_ID, StringValue, ValueType)
                    SELECT @name, @SequenceNo, @parent_ID, @value, 'int'
      if @Contents=' ' Select @SequenceNo=0
    END
  END
INSERT INTO @hierarchy (NAME, SequenceNo, parent_ID, StringValue, Object_ID, ValueType)
  SELECT '-',1, NULL, '', @parent_ID-1, @type
--
   RETURN
END