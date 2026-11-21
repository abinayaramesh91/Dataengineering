-- Question1 
-- Grain of sales fact table is booking_id
SELECT  [booking_id] --Unique ID
 --Dimensions columns
      ,[passenger_id]
      ,[flight_id]
      ,[booking_date]
      ,[travel_date]
      ,[fare_class]
       ,[booking_status] w

 --Additive measures columns
      ,[fare_amount]
      ,[tax_amount]
     
   --Non-  Additive measures columns
      ,[miles_earned]
  FROM [VayuAir].[dbo].[bronze_bookings]
  

  -- questions 2


  -- Drop foreign key from flights table
ALTER TABLE dw.flights
DROP CONSTRAINT FK_Flights_date;

-- Drop foreign key from fact_bookings (booking date)
ALTER TABLE dw.fact_bookings
DROP CONSTRAINT FK_booking_date;

-- Drop foreign key from fact_bookings (travel date)
ALTER TABLE dw.fact_bookings
DROP CONSTRAINT FK_travel_date;

-- Add foreign key constraint for Flight Date
ALTER TABLE dw.flights
ADD CONSTRAINT FK_Flights_date
FOREIGN KEY (flight_date)
REFERENCES dw.DimDate(DateID);


-- Add foreign key constraint for Booking Date
ALTER TABLE dw.fact_bookings
ADD CONSTRAINT FK_booking_date
FOREIGN KEY (booking_date)
REFERENCES dw.DimDate(DateID);


-- Add foreign key constraint for Travel Date
ALTER TABLE dw.fact_bookings
ADD CONSTRAINT FK_travel_date
FOREIGN KEY (travel_date)
REFERENCES dw.DimDate(DateID);

-- creating dimension tables and fact tables
  USE VayuAir;
  drop schema dw

  CREATE SCHEMA dw;
  Use schema dw;


  drop table dw.DimDate;

  CREATE TABLE dw.DimDate (
    DateKey INT PRIMARY KEY,
    DateID DATE NOT NULL UNIQUE,
    DayNumber INT,
    MonthNumber INT,
    MonthName VARCHAR(20),
    QuarterNumber INT,
    YearNumber INT
);


 CREATE TABLE dw.passengers (
passenger_key int identity(1,1) primary key,
passenger_id int ,
passenger_name varchar(50),
home_airport_code varchar(50),
frequent_flyer_tier varchar(50),
signup_date varchar(50)
);  

drop table dw.flights;

CREATE TABLE dw.flights
(
    flight_key INT IDENTITY(1,1) PRIMARY KEY,
    flight_id INT NOT NULL,
    flight_number VARCHAR(10),
    origin_airport_code VARCHAR(30),
    dest_airport_code VARCHAR(30),
    aircraft_code VARCHAR(30),
    flight_date DATE,

    -- Foreign key: Origin airport
    CONSTRAINT FK_origin_airport_code
        FOREIGN KEY (origin_airport_code)
        REFERENCES dw.airports(airport_code),

    -- Foreign key: Destination airport
    CONSTRAINT FK_dest_airport_code
        FOREIGN KEY (dest_airport_code)
        REFERENCES dw.airports(airport_code),

    -- Foreign key: Aircraft
    CONSTRAINT FK_aircraft
        FOREIGN KEY (aircraft_code)
        REFERENCES dw.aircraft(aircraft_code),

    -- Foreign key: Flight date
    CONSTRAINT FK_Flights_date
        FOREIGN KEY (flight_date)
        REFERENCES dw.DimDate(DateID)
);
GO

alter TABLE dw.flights
update CONSTRAINT FK_Flights_date
FOREIGN KEY (flight_date)
REFERENCES dw.DimDate_new(dateID),

create  table dw.aircraft(
aircraft_key int identity(1,1) primary key,
 aircraft_code varchar(30) not null,
model varchar(30),
manufacturer varchar(30),
seat_capacity varchar(30)
);

drop table dw.aircraft

create  table dw.airports(
airport_key int identity(1,1) primary key,
airport_code varchar(30) not null,
airport_name varchar(30),
city varchar(30),
country varchar(30),
region varchar(30)
);

ALTER TABLE dw.airports
ADD CONSTRAINT UQ_airports_airport_code
UNIQUE (airport_code);
GO

ALTER TABLE dw.aircraft
ADD CONSTRAINT UQ_aircraft_code
UNIQUE (aircraft_code);

drop table  dw.fact_bookings;
create table dw.fact_bookings(
       booking_key int identity(1,1) primary key,
       booking_id int not null
      ,passenger_key int
      ,flight_key int 
      ,booking_date date 
      ,travel_date date
      ,fare_class varchar(30)
      ,fare_amount decimal
      ,tax_amount decimal
      ,booking_status  varchar(30)
      ,miles_earned int );

      ALTER TABLE dw.fact_bookings
 ADD CONSTRAINT FK_passenger_key
 FOREIGN KEY (passenger_key)
        REFERENCES dw.passengers(passenger_key)

   ALTER TABLE dw.fact_bookings
 ADD CONSTRAINT FK_flight_key
 FOREIGN KEY (flight_key)
        REFERENCES dw.flights(flight_key)

  ALTER TABLE dw.fact_bookings
 ADD CONSTRAINT FK_booking_date
 FOREIGN KEY (booking_date)
        REFERENCES dw.DimDate(dateID)

          ALTER TABLE dw.fact_bookings
 ADD CONSTRAINT FK_travel_date
 FOREIGN KEY (travel_date)
        REFERENCES dw.DimDate(dateID)

  -- questions 3
  --Loading data from Bronze
 -- Loading dim_date table

 INSERT INTO dw.DimDate
(
    DateKey,
    DateID,
    DayNumber,
    MonthNumber,
    MonthName,
    QuarterNumber,
    YearNumber
)
SELECT DISTINCT
    CONVERT(INT, CONVERT(CHAR(8), d.DateValue, 112)),
    d.DateValue,
    DAY(d.DateValue),
    MONTH(d.DateValue),
    DATENAME(MONTH, d.DateValue),
    DATEPART(QUARTER, d.DateValue),
    YEAR(d.DateValue)
FROM
(
    SELECT CAST(booking_date AS DATE) AS DateValue
    FROM dbo.bronze_bookings

    UNION

    SELECT CAST(travel_date AS DATE)
    FROM dbo.bronze_bookings

    UNION

    SELECT CAST(flight_date AS DATE)
    FROM dbo.bronze_flights
) d
WHERE d.DateValue IS NOT NULL;

select * from dw.flights;
select * from bronze_flights;
 -- Loading dimpassengers table


INSERT INTO dw.passengers
(
    passenger_id,
    passenger_name,
    home_airport_code,
    frequent_flyer_tier,
    signup_date
)
SELECT DISTINCT
    passenger_id,
    passenger_name,
    home_airport_code,
    frequent_flyer_tier,
    signup_date
FROM dbo.bronze_passengers;


 -- Loading dimairports table

insert into dw.airports 
(    [airport_code]
      ,[airport_name]
      ,[city]
      ,[country]
      ,[region]
      )

select distinct
[airport_code]
      ,[airport_name]
      ,[city]
      ,[country]
      ,[region]
     from dbo.bronze_airports 

 -- Loading dimaircraft table

   insert into dw.aircraft(
   [aircraft_code]
      ,[model]
      ,[manufacturer]
      ,[seat_capacity]
      )
      select distinct
        [aircraft_code]
      ,[model]
      ,[manufacturer]
      ,[seat_capacity]
       from dbo.bronze_aircraft

 -- Loading dimflight table

 insert into dw.flights 
(
      [flight_id]
      ,[flight_number]
      ,[origin_airport_code]
      ,[dest_airport_code]
      ,[aircraft_code]
      ,[flight_date]
      )
      select distinct 
       [flight_id]
      ,[flight_number]
      ,[origin_airport_code]
      ,[dest_airport_code]
      ,[aircraft_code]
      ,[flight_date]
      from dbo.bronze_flights

 -- Loading dimfact table

INSERT INTO dw.fact_bookings
(
    booking_id,
    passenger_key,
    flight_key,
    booking_date_key,
    travel_date_key,
    fare_class,
    fare_amount,
    tax_amount,
    booking_status,
    miles_earned
)
SELECT
    b.booking_id,
    p.passenger_key,
    f.flight_key,
    bd.DateKey,
    td.DateKey,
    b.fare_class,
    b.fare_amount,
    b.tax_amount,
    b.booking_status,
    b.miles_earned

FROM dbo.bronze_bookings b

INNER JOIN dw.passengers p
    ON b.passenger_id = p.passenger_id

INNER JOIN dw.flights f
    ON b.flight_id = f.flight_id

INNER JOIN dw.DimDate bd
    ON CAST(b.booking_date AS DATE) = bd.DateID

INNER JOIN dw.DimDate td
    ON CAST(b.travel_date AS DATE) = td.DateID;

--Question 3:   
--- creating Snowflake tables like region-->

  drop table dw.dimregion
   
CREATE TABLE [dw].[dimregion]
	([region_key] [int] IDENTITY(1,1) NOT NULL,
	[region] [varchar](30) NOT NULL
    CONSTRAINT [PK_dimregion] PRIMARY KEY ([region_key])
   )


drop table dw.dimcountry

CREATE TABLE [dw].[dimcountry]
	([country_key] [int] IDENTITY(1,1) NOT NULL,
	[country] [varchar](30) NOT NULL,
    [region_key] [int]  NOT NULL,

    CONSTRAINT [PK_dimcountry] PRIMARY KEY ([country_key]),
     -- Foreign key: Destination airport
    CONSTRAINT FK_region
        FOREIGN KEY (region_key)
        REFERENCES dw.dimregion(region_key)
        )

CREATE TABLE [dw].dimcity
	([city_key] [int] IDENTITY(1,1) NOT NULL,
	city [varchar](30) NOT NULL,
    [country_key] [int]  NOT NULL,

    CONSTRAINT [PK_dimcity] PRIMARY KEY ([city_key]),

      -- Foreign key: Destination airport
    CONSTRAINT FK_Country
        FOREIGN KEY ([country_key])
        REFERENCES dw.dimcountry(country_key)
   )
 
ALTER TABLE dw.airports
ADD 
   CONSTRAINT FK_region1
        FOREIGN KEY (region_key)
        REFERENCES dw.dimregion(region_key)

select * from  dw.dimcountry where country is null


insert into dw.dimregion(region)
select distinct 
LTRIM(RTRIM(b.[region]))
FROM bronze_airports b
WHERE b.[region] IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM [dw].[dimregion] r
      WHERE r.[region] = LTRIM(RTRIM(b.[region]))
  );
  select * from dw.dimcountry

  insert into dw.dimcountry(country,region_key)
SELECT DISTINCT
    LTRIM(RTRIM(b.[country])),
    r.[region_key]
FROM [bronze_airports] b
JOIN [dw].[dimregion] r
    ON r.[region] = LTRIM(RTRIM(b.[region]))
WHERE b.country IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM [dw].dimcountry c
      WHERE c.country = LTRIM(RTRIM(b.country))
      and r.region_key=c.region_key)  
  ;

  select * from dw.dimcity;
  select * from dw.dimcountry;
  select * from dw.dimregion;


insert into dw.dimcity(city,country_key)
SELECT DISTINCT
    LTRIM(RTRIM(b.city)),
    r.country_key
FROM [bronze_airports] b
JOIN [dw].dimcountry r
    ON r.country = LTRIM(RTRIM(b.country))
WHERE b.country IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM [dw].dimcity c
      WHERE c.city = LTRIM(RTRIM(b.city))
      and r.country_key=c.country_key)  
  ;


  ------ SCD Type 2

  select * from dw.passengers order by passenger_id;

  alter table dw.passengers
  add
  is_active BIT NOT NULL
        CONSTRAINT DF_DimPassenger_is_active DEFAULT 1,
    effective_from date NOT NULL
        CONSTRAINT DF_DimPassenger_effective_from
        DEFAULT SYSDATETIME(),
 effective_to date ;


  select * from dbo.stg_passenger_updates;
    select * from dw.passengers;

DECLARE @EffectiveDate DATE = CAST(GETDATE() AS DATE);

MERGE dw.passengers AS dp
USING stg_passenger_updates AS stg
    ON dp.Passenger_ID = stg.Passenger_ID
    AND dp.is_active = 1

WHEN MATCHED AND
(
    ISNULL(dp.frequent_flyer_tier, '') <> ISNULL(stg.frequent_flyer_tier, '')
    OR
    ISNULL(dp.home_airport_code, '') <> ISNULL(stg.home_airport_code, '')
)
THEN
    UPDATE SET
        dp.is_active = 0,
        dp.effective_to = @EffectiveDate

when Not matched by target then
insert (passenger_id,passenger_name,home_airport_code,
frequent_flyer_tier, effective_from,effective_to)
values(
--SELECT ISNULL(MAX(passenger_id), 100) +1 FROM dw.passengers) ,
        stg.passenger_id, stg.passenger_name, stg.home_airport_code, stg.frequent_flyer_tier, @EffectiveDate, NULL      

    );

 --Partition 

CREATE PARTITION FUNCTION pf_FlightDate (INT)
AS RANGE RIGHT FOR VALUES
(
    20240201,
    20240301,
    20240401,
    20240501
);
GO

CREATE PARTITION SCHEME ps_FlightDate
AS PARTITION pf_FlightDate
ALL TO ([PRIMARY]);
GO


SELECT
    name,
    type_desc
FROM sys.key_constraints
WHERE parent_object_id =
    OBJECT_ID('dw.fact_bookings')
AND type = 'PK';

ALTER TABLE dw.fact_bookings
DROP CONSTRAINT PK_fact_bookings;
GO

ALTER TABLE dw.fact_bookings
ADD CONSTRAINT PK_fact_bookings
PRIMARY KEY NONCLUSTERED (booking_id);
GO


ALTER TABLE dw.fact_bookings
DROP CONSTRAINT CX_fact_bookings_DateKey;
GO
select * from dw.fact_bookings  

CREATE CLUSTERED INDEX CX_fact_bookings_DateKey
ON dw.fact_bookings
(
    booking_date_key,
    booking_id
)
ON ps_FlightDate(booking_date_key);
GO

SELECT
    i.name AS IndexName,
    i.type_desc,
    ds.name AS DataSpaceName
FROM sys.indexes i
JOIN sys.data_spaces ds
    ON i.data_space_id = ds.data_space_id
WHERE i.object_id = OBJECT_ID('dw.fact_bookings');

-- Data contract

--medallion layer (bronze, silver, or gold)
--Bronze is the Raw layer with tables like flight,airports,aircraft,passengers and booking table
--Silver contains all dim tables and fact tables with relationship .
-- It is hybrid schema . Mostly star schemand and only dimairports has snowflake like structure .
--e.g.,dimregion,dimpassengers,dimflights,dimdate,dimcountry,dimcity
-- Gold layer is fact_bookings table
--e.g.,fact_bookings

fare_class

Only the following values are allowed:

ECONOMY,PREMIUM_ECONOMY,BUSINESS,FIRST

booking_status

Only the following values are allowed:

PENDING,CONFIRMED ,CANCELLED,CHECKED_IN,COMPLETED


booking_id must be unique and not NULL.

passenger_id must not be NULL.

flight_id must not be NULL.

booking_date must be a valid date.

fare_class must contain one of the approved values.

booking_status must contain one of the approved values.

ticket_price must be greater than or equal to zero.

discount_amount must be greater than or equal to zero when provided.

Passenger and flight identifiers must resolve to valid business records during downstream validation.