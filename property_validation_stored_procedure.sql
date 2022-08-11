CREATE DEFINER=`root`@`localhost` PROCEDURE `property_validation_stored_procedure`(
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
    Declare valueReturn int;
    Declare invalidRows longtext default '';
    
		-- param
	Declare clientIdParam int default 0;
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
	Declare sameAsBuildingAddressValue varchar(55) default 0;
    
		-- pass condition data into variable
	select v.xml from `validate_import_table` v where v.username = usrName and v.date = (select max(date) from validate_import_table) into xml;
	select extractvalue(xml, 'count(/records/record)') into recordNumber;
	select max(date) from validate_import_table into recent;
			-- Find Client Id
	select c.client_id from `client` c, `user` u where c.user_id = u.df_user_id and u.user_email = usrName into clientIdParam;
        
	-- Turn off SQL SAFE UPDATES
    SET SQL_SAFE_UPDATES = 0;
    
	-- ----------------------------------------------------- VALIDATION -----------------------------------------------------
    
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
        SELECT extractvalue(xml, '/records/record[$x]/same_as_building_address') into sameAsBuildingAddressValue;
        
		-- START validation
		SET x = x + 1;
        
		If (sameAsBuildingAddressValue = '') THEN
			SET sameAsBuildingAddressValue = 0;
        END IF;
        
		-- VALIDATE property name
        
        IF (propertyNameValue = '' ) THEN
			SET invalidRows = CONCAT(invalidRows, 'Property Name is null on row(s): ', x, '; ');
        END IF;
        
        -- VALIDATE constructionDateValue	(Not Required)
        
        -- VALIDATE propertySqftValue
        
		IF (isNumberic(propertySqftValue) != true AND propertySqftValue != '') THEN
			SET invalidRows = CONCAT(invalidRows, 'Property SQ.FT. is not an integer on row(s): ', x, '; ');
        END IF;
        
        -- VALIDATE propertyTypeValue
        
        IF (propertyTypeValue = '') THEN
			SET invalidRows = CONCAT(invalidRows, 'Property Type is null on row(s): ', x, '; ');
		ELSEIF ((select COUNT(*) from property_type where TRIM(property_type_name) = TRIM(propertyTypeValue)) = 0) THEN
			SET invalidRows = CONCAT(invalidRows, 'Property Type does not exist on row(s): ', x, '; ');
        END IF;
        
        -- VALIDATE propertyTaxcodeValue (Not Required, but limit 10 digits)
        
        -- VALIDATE propertyPhoneValue
        
        IF (propertyPhoneValue = '') THEN
			SET invalidRows = CONCAT(invalidRows, 'Property Phone is null on row(s): ', x, '; ');
		ELSEIF (isNumberic(propertyPhoneValue) != true) THEN
			SET invalidRows = CONCAT(invalidRows, 'Property Phone is not an integer on row(s): ', x, '; ');
		END IF;
        
        -- VALIDATE propertyEmailValue
        
        IF (propertyEmailValue = '' ) THEN
			SET invalidRows = CONCAT(invalidRows, 'Property Email is null on row(s): ', x, '; ');
        END IF;
        
        -- VALIDATE propertyAmenitiesValue
        
        IF (propertyAmenitiesValue = '') THEN
			SET invalidRows = CONCAT(invalidRows, 'Property Amenities is null on row(s): ', x, '; ');
		ELSE
			CALL splitString(propertyAmenitiesValue, ',');
			-- temp_string : this is temperary table to store splited string
			while propertyAmenityIndex <= (select COUNT(*) from temp_string) do
				select vals from temp_string where id = propertyAmenityIndex into propertyAmenityName;
				if ((SELECT COUNT(*) from amenities WHERE TRIM(amenity_name) = TRIM(propertyAmenityName)) = 0) then
                    SET invalidRows = CONCAT(invalidRows, 'Property Amenities [', TRIM(propertyAmenityName) ,'] does not exist on row(s): ', x, '; ');
				end if;
				set propertyAmenityIndex = propertyAmenityIndex + 1;
			end while;
            
			-- reset propertyAmenityIndex;
			set propertyAmenityIndex = 1;
        END IF;
        
        -- VALIDATE propertyManagerNameValue
        
        IF (propertyManagerNameValue = '') THEN
			SET invalidRows = CONCAT(invalidRows, 'Property Manager Name is null on row(s): ', x, '; ');
		ELSEIF ((select COUNT(*) from user where user_first_name = propertyManagerNameValue) = 0) THEN
			SET invalidRows = CONCAT(invalidRows, 'Property Manager does not exist on row(s): ', x, '; ');
		ELSEIF ((select COUNT(*) from user_client_role_mapping 
					where user_id in (select df_user_id from user where user_first_name = propertyManagerNameValue) 
						and role_id = 2 and client_id = clientIdParam) = 0) THEN
			SET invalidRows = CONCAT(invalidRows, 'Property Manager does not belong to this client on row(s): ', x, '; ');
        END IF;
        
        -- VALIDATE propertyFeatureTagsValue
        
        IF (propertyFeatureTagsValue = '') THEN
			SET invalidRows = CONCAT(invalidRows, 'Property Feature Tags is null on row(s): ', x, '; ');
        ELSE
			CALL splitString(propertyFeatureTagsValue, ',');
				-- temp_string : this is temperary table to store splited string
			while propertyFeatureIndex <= (select COUNT(*) from temp_string) do
				select vals from temp_string where id = propertyFeatureIndex into propertyFeatureName;
				if ((SELECT COUNT(*) from property_feature WHERE TRIM(property_feature_name) = TRIM(propertyFeatureName)) = 0) then
                    SET invalidRows = CONCAT(invalidRows, 'Property Features [', TRIM(propertyFeatureName) ,'] does not exist on row(s): ', x, '; ');
				end if;
				set propertyFeatureIndex = propertyFeatureIndex + 1;
			end while;
            
			-- reset propertyFeatureIndex;
			set propertyFeatureIndex = 1;
        END IF;
        
		-- VALIDATE propertyDescriptionValue
        
        -- VALIDATE propertyAddressValue
        
		IF (propertyAddressValue = '') THEN
			SET invalidRows = CONCAT(invalidRows, 'Property address is null on row(s): ', x, '; ');	
        END IF;
        
		-- VALIDATE same_as_building_address
        
        IF (sameAsBuildingAddressValue != '1' AND sameAsBuildingAddressValue != '0' AND TRIM(sameAsBuildingAddressValue) != 'true' AND TRIM(sameAsBuildingAddressValue) != 'false') THEN
			SET invalidRows = CONCAT(invalidRows, 'Same As Building Address is not one of the following: 1, 0, true, false, null on rows(s): ', x, '; ');
        END IF;
        
    END WHILE;

	-- ----------------------------------------------------- END VALIDATION -----------------------------------------------------
    
    -- RETURN RESULT
    IF (invalidRows != '') THEN
    	UPDATE validate_import_table
		SET	status = 0, invalid_rows = invalidRows, error_message = 'Invalid data', notes = 'Property'
		WHERE username = usrName
			AND date = recent;
	ELSE
		UPDATE validate_import_table
        SET status = 1, notes = 'Property'
        WHERE username = usrName
			AND date = recent;
    END IF;
    
	-- Return 0 -> status: error
    -- Return 1 -> status: success
    SELECT v.status from `validate_import_table` v where v.date = recent into statusResponse;

	-- Turn on SQL SAFE UPDATES
    SET SQL_SAFE_UPDATES = 1;
END