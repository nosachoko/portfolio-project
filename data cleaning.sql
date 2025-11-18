/* 
data cleaning in sql
*/

 -- select the database you will using
 use covid19;

/* 
imported `nashville_housing _data` into our covid19 database
*/

  
 SELECT * FROM covid19.`nashville_housing _data`;
  
  -- Renaming the ï»¿UniqueID to UniqueID
  ALTER TABLE nashville_housing_data
CHANGE COLUMN ï»¿UniqueID  UniqueID int;


-- Populate/fill propertyaddress data showing  blank spaces
/*
  just noticed that some parcelid data have two
  duplicated values linking to the propertyaddress with one having a value,
  while other does not. we want to fill the empty space of the property address
  with same address of the other duplicated values having same parcelid
  */
select *
from `nashville_housing _data`
where propertyaddress = ''
order by parcelid;

select *
from `nashville_housing _data`
-- where propertyaddress = '';
order by parcelid;
-- doing a self join of same table
-- joining both table and identify which column is blank in any of the propertyaddress table using 
-- adding to identify the number of column that is blank and the required values needed to populate it from the other propertyaddress column
   
select a.parcelid, a.propertyaddress, b.parcelid, b.propertyaddress, 
coalesce(nullif(a.propertyaddress, ''), b.propertyaddress)
from `nashville_housing _data`  a
join `nashville_housing _data`  b
	on a.parcelid = b.parcelid
    and a.uniqueid <> b.uniqueid
    where a.propertyaddress = '';
    
update  `nashville_housing _data`  a
join `nashville_housing _data`  b
	on a.parcelid = b.parcelid
    and a.uniqueid <> b.uniqueid
set a.propertyaddress = coalesce(nullif(a.propertyaddress, ''), b.propertyaddress)
where trim(a.propertyaddress) = '';

-- Breaking out address into individual columns(address, city, state)
select propertyaddress
from  `nashville_housing _data`;
-- -- i will be using a substrings and also character select to break the address, city, state
select
substring(propertyaddress, 1, locate(',', propertyaddress)) as address
from `nashville_housing _data`;
-- -- looking for the postion of the comma i want to remove it
select
substring(propertyaddress, 1, locate(',', propertyaddress)) as address,
locate(',', propertyaddress)
from `nashville_housing _data`;
-- -- removing the comma
select
substring(propertyaddress, 1, locate(',', propertyaddress) -1) as address
from `nashville_housing _data`;
-- -- filtering out the city after the comma i.e  Extract everything after the comma
select
substring(propertyaddress, 1, locate(',', propertyaddress) -1) as address,
substring(propertyaddress, locate(',', propertyaddress) + 1) as city
from `nashville_housing _data`;
-- -- creating two new columns and updating them
ALTER TABLE `nashville_housing _data`
ADD COLUMN address VARCHAR(255),
ADD COLUMN city VARCHAR(255);
UPDATE `nashville_housing _data`
SET 
  address = TRIM(SUBSTRING(propertyaddress, 1, LOCATE(',', propertyaddress) - 1)),
  city = TRIM(SUBSTRING(propertyaddress, LOCATE(',', propertyaddress) + 1));

-- splitting address, city, state out of the OwnerAddress column
-- -- using substring and substring_index to split
select owneraddress
from `nashville_housing _data`;

SELECT
  SUBSTRING(owneraddress, 1, LOCATE(',', owneraddress) - 1) AS Street,
  SUBSTRING(
    owneraddress,
    LOCATE(',', owneraddress) + 2,
    LOCATE(',', owneraddress, LOCATE(',', owneraddress) + 1) - LOCATE(',', owneraddress) - 2
  ) AS City,
  SUBSTRING_INDEX(owneraddress, ',', -1) AS State
FROM `nashville_housing _data`;

-- -- using substring_index
SELECT
  SUBSTRING_INDEX(owneraddress, ',', 1) AS Street,
  SUBSTRING_INDEX(SUBSTRING_INDEX(owneraddress, ',', 2), ',', -1) AS City,
  SUBSTRING_INDEX(owneraddress, ',', -1) AS State
FROM `nashville_housing _data`;

-- updatinga and altering our table 
ALTER TABLE `nashville_housing _data`
ADD COLUMN OwnerStreet VARCHAR(255),
ADD COLUMN OwnerCity VARCHAR(255),
ADD COLUMN OwnerState VARCHAR(255);

UPDATE `nashville_housing _data`
SET 
  OwnerStreet = SUBSTRING_INDEX(owneraddress, ',', 1),
  OwnerCity = SUBSTRING_INDEX(SUBSTRING_INDEX(owneraddress, ',', 2), ',', -1),
  OwnerState = SUBSTRING_INDEX(owneraddress, ',', -1);


-- Change Y and N to yes and in 'sold as vacant' field
select distinct(soldasvacant), count(soldasvacant)
from `nashville_housing _data`
group by soldasvacant
order by 2;
-- -- using a casestatement to change the y and n to yes and not
select soldasvacant,
	case when soldasvacant = 'y' then 'yes'
		 when soldasvacant = 'n' then 'No'
        else soldasvacant
        end
from `nashville_housing _data`;

-- updating our table
update `nashville_housing _data`
set soldasvacant = case when soldasvacant = 'y' then 'yes'
		 when soldasvacant = 'n' then 'No'
        else soldasvacant
        end
;

-- REMOVE DUPLICATE
-- using a cte table
WITH RowNumcte AS (
  SELECT *,
    ROW_NUMBER() OVER (
      PARTITION BY parcelid, propertyaddress, saledate, legalreference
      ORDER BY uniqueid
    ) AS row_num
  FROM `nashville_housing _data`
)
SELECT *
FROM RowNumcte
WHERE row_num > 1
ORDER BY propertyaddress;

-- delete unused columns

select *
from `nashville_housing _data`;

 alter table `nashville_housing _data`
 drop column owneraddress, 
 drop column TaxDistrict, 
 drop column propertyaddress;


