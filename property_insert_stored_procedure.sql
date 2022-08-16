CREATE DEFINER=`dbmasteruser`@`%` PROCEDURE `property_insert_stored_procedure`(
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
    Declare userIdParam int;
    Declare propertyTypeIdParam int;
	Declare propertyManagerIdParam int;
	Declare amenityId int;
	Declare propertyFeatureId int;
		-- property amenities
	Declare propertyAmenityIndex int default 1;
    Declare propertyAmenityName varchar(55) default '';
		-- property feature
	Declare propertyFeatureIndex int default 1;
    Declare propertyFeatureName varchar(55) default '';
    
		-- property values
    Declare propertyNameValue varchar(55) default '';
    Declare constructionDateValue varchar(55) default '';
    Declare propertySqftValue varchar(55) default '';
    Declare propertyTypeValue varchar(55) default '';
    Declare propertyTaxcodeValue varchar(55) default '';
    Declare propertyPhoneValue varchar(55) default '';
    Declare propertyEmailValue varchar(55) default '';
    Declare propertyAmenitiesValue varchar(55) default '';
    Declare propertyManagerNameValue varchar(55) default '';
    Declare propertyFeatureTagsValue varchar(55) default '';
    Declare propertyDescriptionValue varchar(55) default '';
    Declare propertyAddressValue mediumtext default '';
	Declare sameAsPropertyAddressValue varchar(55) default 0;
    
    		-- pass condition data into variable
	select v.xml from `validate_import_table` v where v.username = usrName and v.date = (select max(date) from validate_import_table) into xml;
	select extractvalue(xml, 'count(/records/record)') into recordNumber;
	select max(date) from validate_import_table into recent;
			-- Find Client Id
	select c.client_id from `client` c, `user` u where c.user_id = u.df_user_id and u.user_email = usrName into clientIdParam;
	select u.df_user_id from `user` u where u.user_email = usrName ORDER BY u.df_user_id DESC LIMIT 1 into userIdParam;
    
	-- ----------------------------------------------------- INSERT -----------------------------------------------------

	WHILE x <= recordNumber DO
		SELECT extractvalue(xml, '/records/record[$x]/property_name') into propertyNameValue;
		SELECT extractvalue(xml, '/records/record[$x]/construction_date') into constructionDateValue;
		SELECT extractvalue(xml, '/records/record[$x]/property_sqft') into propertySqftValue;
		SELECT extractvalue(xml, '/records/record[$x]/property_type') into propertyTypeValue;
		SELECT extractvalue(xml, '/records/record[$x]/property_taxcode') into propertyTaxcodeValue;
		SELECT extractvalue(xml, '/records/record[$x]/property_phone') into propertyPhoneValue;
		SELECT extractvalue(xml, '/records/record[$x]/property_email') into propertyEmailValue;
		SELECT extractvalue(xml, '/records/record[$x]/property_amenities') into propertyAmenitiesValue;
		SELECT extractvalue(xml, '/records/record[$x]/property_manager') into propertyManagerNameValue;
		SELECT extractvalue(xml, '/records/record[$x]/property_feature_tags') into propertyFeatureTagsValue;
		SELECT extractvalue(xml, '/records/record[$x]/property_description') into propertyDescriptionValue;
		SELECT extractvalue(xml, '/records/record[$x]/property_address') into propertyAddressValue;
        SELECT extractvalue(xml, '/records/record[$x]/same_as_property_address') into sameAsPropertyAddressValue;
        
        IF (constructionDateValue = '') THEN
			SET constructionDateValue = NULL;
		ELSE 
			SET constructionDateValue = DATE_FORMAT(STR_TO_DATE(constructionDateValue,'%m/%d/%Y'), '%Y-%m-%d'); 
        END IF;

		If (sameAsPropertyAddressValue = '' OR TRIM(sameAsPropertyAddressValue) = 'false') THEN
			SET sameAsPropertyAddressValue = 0;
		ELSEIF (TRIM(sameAsPropertyAddressValue) = 'true') THEN
			SET sameAsPropertyAddressValue = 1;
        END IF;
        
			-- Find Property Type Id
		select pt.property_type_id from `property_type` pt where TRIM(pt.property_type_name) = TRIM(propertyTypeValue) into propertyTypeIdParam;
			-- Find Property Manager Id
		select pm.propertymanagerid from `property_manager` pm where TRIM(pm.name) = TRIM(propertyManagerNameValue) ORDER BY pm.propertymanagerid DESC LIMIT 1 into propertyManagerIdParam;

		-- INSERT property 
        INSERT INTO `property` (`property_type_id`, `property_client_id`, `property_manager_id`, `property_name`, `property_description`, `property_email`, 
        `property_office_number`, `property_lat_lang_address`, `property_latitude`, `property_longitude`,
        `property_age_date`, `property_tax_code`, `property_sqft`, `same_as_address`,
        `property_archived_flag`, `property_blocked_flag`, `active_flag`, `feature_tag`, `created_by`, `created_date`, `last_modified_by`) VALUES
		(propertyTypeIdParam, clientIdParam, propertyManagerIdParam, propertyNameValue, propertyDescriptionValue, propertyEmailValue, 
        propertyPhoneValue, propertyAddressValue, 0, 0,
        constructionDateValue, propertyTaxcodeValue, propertySqftValue, sameAsPropertyAddressValue, 
		0, 0, 1, NULL, userIdParam, CURRENT_TIMESTAMP(), userIdParam);
        
		-- INSERT Amenities
        
		call splitString(propertyAmenitiesValue, ',');
            -- temp_string : this is temperary table to store splited string
		while propertyAmenityIndex <= (select COUNT(*) from temp_string) do
			select vals from temp_string where id = propertyAmenityIndex into propertyAmenityName;

			select a.amenity_id from `amenities` a where TRIM(a.amenity_name) = TRIM(propertyAmenityName) into amenityId;
            insert into `property_amenities` (`property_id`, `amenities_id`, `created_by`, `created_date`, `last_modified_date`, `last_modified_by`)
				VALUES ((select MAX(property_id) from `property`), amenityId, userIdParam, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), userIdParam);
                
			set propertyAmenityIndex = propertyAmenityIndex + 1;
		end while;
		
			-- reset propertyAmenityIndex;
			set propertyAmenityIndex = 1;
        
        -- INSERT Feature tags
		call splitString(propertyFeatureTagsValue, ',');
		while propertyFeatureIndex <= (select COUNT(*) from temp_string) do
			select vals from temp_string where id = propertyFeatureIndex into propertyFeatureName;

			select pf.property_feature_id from `property_feature` pf where TRIM(pf.property_feature_name) = TRIM(propertyFeatureName) into propertyFeatureId;
            
            select propertyFeatureId;
            
            insert into `property_property_feature` (`property_feature_id`, `property_id`, `created_by`, `created_date`, `last_modified_date`, `last_modified_by`)
				VALUES (propertyFeatureId, (select MAX(property_id) from `property`), userIdParam, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), userIdParam);
                
			set propertyFeatureIndex = propertyFeatureIndex + 1;
		end while;
        
		-- reset buildingFeatureIndex;
		set propertyFeatureIndex = 1;
        
		SET x = x + 1;
    END WHILE;
END