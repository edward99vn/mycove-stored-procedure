CREATE DEFINER=`root`@`localhost` PROCEDURE `building_validation_stored_procedure`(
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
		-- building amentities
	Declare buildingAmentityIndex int default 1;
    Declare buildingAmentityName varchar(55) default '';
		-- building feature
	Declare buildingFeatureIndex int default 1;
    Declare buildingFeatureName varchar(55) default '';
    
		-- building values
    Declare buildingNameValue varchar(55) default '';
    Declare propertyNameValue varchar(55) default '';
    Declare propertyManagerNameValue varchar(55) default '';
    Declare buildingAmentitiesValue varchar(55) default '';
    Declare buildingFeatureTagValue varchar(55) default '';
    Declare buildingAreaSqrtValue varchar(55) default '';
    Declare buildingDescriptionValue varchar(55) default '';
    Declare constructionDateValue varchar(55) default '';
    Declare buildingAddressValue varchar(55) default '';
    
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
		SELECT extractvalue(xml, '/records/record[$x]/building_name') into buildingNameValue;
		SELECT extractvalue(xml, '/records/record[$x]/property_name') into propertyNameValue;
		SELECT extractvalue(xml, '/records/record[$x]/property_manager_name') into propertyManagerNameValue;
		SELECT extractvalue(xml, '/records/record[$x]/building_amentities') into buildingAmentitiesValue;
		SELECT extractvalue(xml, '/records/record[$x]/building_feature_tag') into buildingFeatureTagValue;
		SELECT extractvalue(xml, '/records/record[$x]/building_area_sqrt') into buildingAreaSqrtValue;
		SELECT extractvalue(xml, '/records/record[$x]/building_description') into buildingDescriptionValue;
		SELECT extractvalue(xml, '/records/record[$x]/construction_date') into constructionDateValue;
		SELECT extractvalue(xml, '/records/record[$x]/building_address') into buildingAddressValue;
        
		-- START validation
		SET x = x + 1;
        
		-- VALIDATE building name
        
		IF (buildingNameValue = '') THEN
			SET invalidRows = CONCAT(invalidRows, 'Building is null on row(s): ', x, '; ');
		END IF; 
        
		-- VALIDATE property name
        
        IF (propertyNameValue = '') THEN
			SET invalidRows = CONCAT(invalidRows, 'Property Name is null on row(s): ', x, '; ');
		ELSEIF ((select COUNT(*) from property where property_name = propertyNameValue and property_client_id = clientIdParam) = 0) THEN
			SET invalidRows = CONCAT(invalidRows, 'Property Name does not exist on row(s): ', x, '; ');
        END IF;
        
		-- VALIDATE property manager name
            
        IF (propertyManagerNameValue = '') THEN
			SET invalidRows = CONCAT(invalidRows, 'Property Manager Name is null on row(s): ', x, '; ');
		ELSEIF ((select COUNT(*) from user where user_first_name = propertyManagerNameValue) = 0) THEN
			SET invalidRows = CONCAT(invalidRows, 'Property Manager does not exist on row(s): ', x, '; ');
		ELSEIF ((select COUNT(*) from user_client_role_mapping 
					where user_id in (select df_user_id from user where user_first_name = propertyManagerNameValue) 
						and role_id = 2 and client_id = clientIdParam) = 0) THEN
			SET invalidRows = CONCAT(invalidRows, 'Property Manager does not belong to this client on row(s): ', x, '; ');
        END IF;
        
		-- VALIDATE building amentities
        
		IF (buildingAmentitiesValue = '') THEN
			SET invalidRows = CONCAT(invalidRows, 'Building Amentity is null on row(s): ', x, '; ');
		ELSE
			CALL splitString(buildingAmentitiesValue, ',');
				-- temp_string : this is temperary table to store splited string
            while buildingAmentityIndex <= (select COUNT(*) from temp_string) do
				select vals from temp_string where id = buildingAmentityIndex into buildingAmentityName;
				if ((SELECT COUNT(*) from amenities WHERE TRIM(amenity_name) = TRIM(buildingAmentityName)) = 0) then
                    SET invalidRows = CONCAT(invalidRows, 'Building Amentities [', TRIM(buildingAmentityName) ,'] does not exist on row(s): ', x, '; ');
				end if;
				set buildingAmentityIndex = buildingAmentityIndex + 1;
			end while;
            
			-- reset aptFeatureIndex;
			set buildingAmentityIndex = 1;
        END IF;
        
		-- VALIDATE building feature tag
        
		IF (buildingFeatureTagValue = '') THEN
			SET invalidRows = CONCAT(invalidRows, 'Building Feature is null on row(s): ', x, '; ');
		ELSE
			CALL splitString(buildingFeatureTagValue, ',');
				-- temp_string : this is temperary table to store splited string
            while buildingFeatureIndex <= (select COUNT(*) from temp_string) do
				select vals from temp_string where id = buildingFeatureIndex into buildingFeatureName;
				if ((SELECT COUNT(*) from building_feature WHERE TRIM(building_feature_name) = TRIM(buildingFeatureName)) = 0) then
                    SET invalidRows = CONCAT(invalidRows, 'Building Features [', TRIM(buildingFeatureName) ,'] does not exist on row(s): ', x, '; ');
				end if;
				set buildingFeatureIndex = buildingFeatureIndex + 1;
			end while;
            
			-- reset aptFeatureIndex;
			set buildingFeatureIndex = 1;
        END IF;
        
        -- VALIDATE building_area_sqrt

        IF (isNumberic(buildingAreaSqrtValue) != true and buildingAreaSqrtValue != '') THEN
			SET invalidRows = CONCAT(invalidRows, 'Building Area SQ.FT. is not an integer on row(s): ', x, '; ');
        END IF;
        
        -- VALIDATE building_address
        
        IF (buildingAddressValue = '') THEN
			SET invalidRows = CONCAT(invalidRows, 'Building address is null on row(s): ', x, '; ');	
        END IF;
        
    END WHILE;
    
	-- ----------------------------------------------------- END VALIDATION -----------------------------------------------------
	
    -- RETURN RESULT
    IF (invalidRows != '') THEN
    	UPDATE validate_import_table
		SET	status = 0, invalid_rows = invalidRows, error_message = 'Invalid data', notes = 'Building'
		WHERE username = usrName
			AND date = recent;
	ELSE
		UPDATE validate_import_table
        SET status = 1, notes = 'Building'
        WHERE username = usrName
			AND date = recent;
    END IF;

	-- Return 0 -> status: error
    -- Return 1 -> status: success
    SELECT v.status from `validate_import_table` v where v.date = recent into statusResponse;

	-- Turn on SQL SAFE UPDATES
    SET SQL_SAFE_UPDATES = 1;
END