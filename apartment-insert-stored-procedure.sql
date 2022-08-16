CREATE DEFINER=`dbmasteruser`@`%` PROCEDURE `apartment_insert_stored_procedure`(
	-- Add the parameters for the stored procedure here
	IN usrName varchar(55),
	OUT statusResponse INT
)
BEGIN
	-- DECLARE VARIABLE
	Declare xml longtext default '';
    Declare x INT default 1;
    Declare recordNumber integer default 0;    
    Declare recent datetime;
    
		-- param
    Declare clientIdParam int;
    Declare buildingIdParam int;
    Declare apartmentFeatureId int;
    Declare apartmentTypeId int;

		-- apartment value
	Declare apartmentBuildingValue varchar(55) default '';
	Declare apartmentNameValue varchar(55) default '';
	Declare apartmentNumberValue varchar(55) default '';
	Declare apartmentDescriptionValue varchar(55) default '';
	Declare apartmentSqftValue varchar(55) default '';
	Declare apartmentCommonChargeAmountValue varchar(55) default '';
	Declare apartmentRentValue varchar(55) default '';
	Declare apartmentFeatureValue varchar(55) default '';
	Declare apartmentVacentFlagValue varchar(55) default '';
	Declare apartmentTypeValue varchar(55) default '';
    
		-- apartment feature
	Declare aptFeatureIndex int default 1;
	Declare aptFeatureName varchar(55) default '';
    
		-- pass condition data into variable
	select max(date) from validate_import_table into recent;
	select v.xml from `validate_import_table` v where v.username = usrName and v.date = recent into xml;
	select extractvalue(xml, 'count(/records/record)') into recordNumber;
	select c.client_id from `client` c, `user` u where c.user_id = u.df_user_id and u.user_email = usrName into clientIdParam;

    -- ----------------------------------------------------- INSERT -----------------------------------------------------
	WHILE x <= recordNumber DO
		-- SELECT row value
		SELECT extractvalue(xml, '/records/record[$x]/apartment_building') into apartmentBuildingValue;
        SELECT extractvalue(xml, '/records/record[$x]/apartment_name') into apartmentNameValue;
        SELECT extractvalue(xml, '/records/record[$x]/apartment_number') into apartmentNumberValue;
        SELECT extractvalue(xml, '/records/record[$x]/apartment_description') into apartmentDescriptionValue;
        SELECT extractvalue(xml, '/records/record[$x]/apartment_sqft') into apartmentSqftValue;
        SELECT extractvalue(xml, '/records/record[$x]/apartment_common_charge_ammount') into apartmentCommonChargeAmountValue;
        SELECT extractvalue(xml, '/records/record[$x]/apartment_rent') into apartmentRentValue;
        SELECT extractvalue(xml, '/records/record[$x]/appartment_feature') into apartmentFeatureValue;
        SELECT extractvalue(xml, '/records/record[$x]/apartment_vacent_flag') into apartmentVacentFlagValue;
        SELECT extractvalue(xml, '/records/record[$x]/apartment_type') into apartmentTypeValue;
        
			-- Find Apartment Building
		select b.building_id from `building` b where b.building_name = apartmentBuildingValue and b.building_client_id = clientIdParam ORDER BY b.created_date DESC LIMIT 1 into buildingIdParam;
			-- Find Apartment Type Id
		select at.room_type_id from `appartment_type` at where at.room_type_name = apartmentTypeValue into apartmentTypeId;
				
		-- Insert apartment
        insert into `apartment` (`apartment_name`, `apartment_building_id`, `apartment_number`, `apartment_description`, `apartment_sqft`, `apartment_common_charge_ammount`, `apartment_rent`, `apartment_blocked_flag`, `apartment_archived_flag`, `apartment_vacent_flag`, `apartment_type_id`, `apartment_client_id`, `created_by`, `created_date`, `last_modified_date`, `last_modified_by`)
			values (apartmentNameValue, buildingIdParam, apartmentNumberValue, apartmentDescriptionValue, apartmentSqftValue, convert(apartmentCommonChargeAmountValue, float), apartmentRentValue, 0, 1, 1, apartmentTypeId, clientIdParam, clientIdParam, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), clientIdParam);

		-- Insert apartment feature
		call splitString(apartmentFeatureValue, ',');
            -- temp_string : this is temperary table to store splited string
		while aptFeatureIndex <= (select COUNT(*) from temp_string) do
			select vals from temp_string where id = aptFeatureIndex into aptFeatureName;
			select af.appartment_feature_id from `appartment_feature` af where TRIM(af.appartment_feature_name) = TRIM(aptFeatureName) into apartmentFeatureId;
			insert into `apartment_apartment_feature` (`appartment_id`, `appartment_feature_id`)  VALUES ((select MAX(apartment_id) from `apartment`), apartmentFeatureId);
                
			set aptFeatureIndex = aptFeatureIndex + 1;
		end while;
		-- reset aptFeatureIndex;
		set aptFeatureIndex = 1;
				
		SET x = x + 1;
    END WHILE;
    
END