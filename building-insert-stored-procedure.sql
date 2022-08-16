CREATE DEFINER=`dbmasteruser`@`%` PROCEDURE `building_insert_stored_procedure`(
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
	Declare propertyIdParam int;
    Declare propertyManagerIdParam int;
    Declare amenityId int;
    Declare buildingFeatureId int;
		-- building amentities
	Declare buildingAmenityIndex int default 1;
    Declare buildingAmenityName varchar(55) default '';
		-- building feature
	Declare buildingFeatureIndex int default 1;
    Declare buildingFeatureName varchar(55) default '';
    
		-- building values
    Declare buildingNameValue varchar(55) default '';
    Declare propertyNameValue varchar(55) default '';
    Declare propertyManagerNameValue varchar(55) default '';
    Declare buildingAmenitiesValue varchar(55) default '';
    Declare buildingFeatureTagValue varchar(55) default '';
    Declare buildingAreaSqrtValue varchar(55) default '';
    Declare buildingDescriptionValue varchar(55) default '';
    Declare constructionDateValue varchar(55) default '';
    Declare buildingAddressValue mediumtext default '';
	Declare sameAsBuildingAddressValue varchar(55) default 0;
    
		-- pass condition data into variable
	select v.xml from `validate_import_table` v where v.username = usrName and v.date = (select max(date) from validate_import_table) into xml;
	select extractvalue(xml, 'count(/records/record)') into recordNumber;
    select max(date) from validate_import_table into recent;
			-- Find Client Id
	select c.client_id from `client` c, `user` u where c.user_id = u.df_user_id and u.user_email = usrName into clientIdParam;
    
	-- ----------------------------------------------------- INSERT -----------------------------------------------------
    
    WHILE x <= recordNumber DO
		-- SELECT row value
		SELECT extractvalue(xml, '/records/record[$x]/building_name') into buildingNameValue;
		SELECT extractvalue(xml, '/records/record[$x]/property_name') into propertyNameValue;
		SELECT extractvalue(xml, '/records/record[$x]/property_manager_name') into propertyManagerNameValue;
		SELECT extractvalue(xml, '/records/record[$x]/building_amenities') into buildingAmenitiesValue;
		SELECT extractvalue(xml, '/records/record[$x]/building_feature_tag') into buildingFeatureTagValue;
		SELECT extractvalue(xml, '/records/record[$x]/building_area_sqrt') into buildingAreaSqrtValue;
		SELECT extractvalue(xml, '/records/record[$x]/building_description') into buildingDescriptionValue;
		SELECT extractvalue(xml, '/records/record[$x]/construction_date') into constructionDateValue;
		SELECT extractvalue(xml, '/records/record[$x]/building_address') into buildingAddressValue; 
        SELECT extractvalue(xml, '/records/record[$x]/same_as_building_address') into sameAsBuildingAddressValue;
        
		If (sameAsBuildingAddressValue = '' OR TRIM(sameAsBuildingAddressValue) = 'false') THEN
			SET sameAsBuildingAddressValue = 0;
		ELSEIF (TRIM(sameAsBuildingAddressValue) = 'true') THEN
			SET sameAsBuildingAddressValue = 1;
        END IF;
        
		IF (constructionDateValue = '') THEN
			SET constructionDateValue = NULL;
		ELSE 
			SET constructionDateValue = DATE_FORMAT(STR_TO_DATE(constructionDateValue,'%m/%d/%Y'), '%Y-%m-%d'); 
        END IF;
        
			-- Find Building Property Id
		select p.property_id from `property` p where p.property_name = propertyNameValue and p.property_client_id = clientIdParam ORDER BY p.created_date DESC LIMIT 1 into propertyIdParam;
			-- Find Property Manager Id
		select u.df_user_id from `user` u, `user_client_role_mapping` uc where u.user_first_name = propertyManagerNameValue and u.df_user_id = uc.user_id and uc.role_id = 2 and uc.client_id = clientIdParam ORDER BY u.df_user_id DESC LIMIT 1 into propertyManagerIdParam;
        
        If (buildingAreaSqrtValue = '') then
			set buildingAreaSqrtValue = 0;
		end if;
        
		-- Insert Building
		INSERT INTO `building` (`building_property_id`, `building_client_id`, `building_manager_employee_id`, `building_name`, 
			-- `building_latitude`, `building_longitude`, 
            `building_sqft`, 
			`building_construction_date`,
            -- `building_street_address_1`, `building_street_address_2`,
            `building_zip`, `building_city`, `building_state`, `building_country`,
            `same_as_address`,
            -- `building_mail_street_address1`, `building_mail_street_address2`, `building_mail_zip_code`, `building_mail_city`, `building_mail_state`, `building_mail_country`, 
            `is_property_location`, `building_blocked_flag`, `building_archived_flag`, `building_description`, `building_lat_lang_address`, `created_by`, `created_date`, `last_modified_date`, `last_modified_by`) VALUES
			(propertyIdParam, clientIdParam, propertyManagerIdParam, buildingNameValue,
            buildingAreaSqrtValue,
            constructionDateValue, 
            0, '', '', '',
            sameAsBuildingAddressValue, 
            NULL, NULL, NULL, buildingDescriptionValue, buildingAddressValue, clientIdParam, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), clientIdParam);

		-- Insert Amenities
		call splitString(buildingAmenitiesValue, ',');
            -- temp_string : this is temperary table to store splited string
		while buildingAmenityIndex <= (select COUNT(*) from temp_string) do
			select vals from temp_string where id = buildingAmenityIndex into buildingAmenityName;

			select a.amenity_id from `amenities` a where TRIM(a.amenity_name) = TRIM(buildingAmenityName) into amenityId;
            insert into `building_amenities` (`building_id`, `amenities_id`, `created_by`, `created_date`, `last_modified_date`, `last_modified_by`)
				VALUES ((select MAX(building_id) from `building`), amenityId, clientIdParam, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), clientIdParam);
                
			set buildingAmenityIndex = buildingAmenityIndex + 1;
		end while;
		
			-- reset aptFeatureIndex;
		set buildingAmenityIndex = 1;
        
        -- Insert Feature
		call splitString(buildingFeatureTagValue, ',');
		while buildingFeatureIndex <= (select COUNT(*) from temp_string) do
			select vals from temp_string where id = buildingFeatureIndex into buildingFeatureName;

			select ba.building_feature_id from `building_feature` ba where TRIM(ba.building_feature_name) = TRIM(buildingFeatureName) into buildingFeatureId;
            insert into `building_building_feature_type` (`building_id`, `building_feature_type_id`)
				VALUES ((select MAX(building_id) from `building`), buildingFeatureId);
                
			set buildingFeatureIndex = buildingFeatureIndex + 1;
		end while;
        
		-- reset buildingFeatureIndex;
		set buildingFeatureIndex = 1;
        
		SET x = x + 1;
    END WHILE;

END