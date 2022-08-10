CREATE DEFINER=`root`@`localhost` PROCEDURE `apartment_validation_stored_procedure`( 	
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
	select v.xml from `validate_import_table` v where v.username = usrName and v.date = (select max(date) from validate_import_table) into xml;
	select extractvalue(xml, 'count(/records/record)') into recordNumber;
    select max(date) from validate_import_table into recent;
		-- Find Client Id
	select c.client_id from `client` c, `user` u where c.user_id = u.df_user_id and u.user_email = usrName into clientIdParam;
	
    -- Turn off SQL SAFE UPDATES
    SET SQL_SAFE_UPDATES = 0;
    
    -- ----------------------------------------------------- VALIDATION -----------------------------------------------------
    
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
        
        -- START validation
		SET x = x + 1;

			-- validate apartment building
        IF (apartmentBuildingValue = '') THEN
			SET invalidRows = CONCAT(invalidRows, 'Apartment Building is null on row(s): ', x, '; ');
		ELSEIF ((select COUNT(*) from building where building_name = apartmentBuildingValue) = 0) THEN
			SET invalidRows = CONCAT(invalidRows, 'Apartment Building does not exist on row(s): ', x, '; ');
		ELSEIF ((select COUNT(*) from building where building_name = apartmentBuildingValue and building_client_id = clientIdParam) = 0) THEN
			SET invalidRows = CONCAT(invalidRows, 'Apartment Building does not exist on row(s): ', x, '; ');
        END IF;
                
			-- validate apartment name
		IF (apartmentNameValue = '') THEN
			SET invalidRows = CONCAT(invalidRows, 'Apartment Name is null on row(s): ', x, '; ');
		END IF;
		
			-- validate apartment number
		IF (apartmentNumberValue = '') THEN
			SET invalidRows = CONCAT(invalidRows, 'Apartment Number is null on row(s): ', x, '; ');
		END IF;
        
			-- apartmentDescriptionValue not required
        
			-- validate apartment sqft
		IF (apartmentSqftValue = '') THEN
			SET invalidRows = CONCAT(invalidRows, 'Apartment SQ.FT. is null on row(s): ', x, '; ');
		ELSEIF (isNumberic(apartmentSqftValue) != true) THEN
			SET invalidRows = CONCAT(invalidRows, 'Apartment SQ.FT. is not an integer on row(s): ', x, '; ');
        END IF;
        
			-- apartmentCommonChargeAmountValue not required
        
			-- validate apartment rent
        IF (apartmentRentValue = '') THEN
			SET invalidRows = CONCAT(invalidRows, 'Apartment Rent is null on row(s): ', x, '; ');
		ELSEIF (isNumberic(apartmentRentValue) != true) THEN
			SET invalidRows = CONCAT(invalidRows, 'Apartment Rent is not an integer on row(s): ', x, '; ');
        END IF;
        
			-- validate apartment feature
        IF (apartmentFeatureValue = '') THEN
			SET invalidRows = CONCAT(invalidRows, 'Apartment Feature is null on row(s): ', x, '; ');
		ELSE
            call splitString(apartmentFeatureValue, ',');
            -- temp_string : this is temperary table to store splited string
			while aptFeatureIndex <= (select COUNT(*) from temp_string) do
				select vals from temp_string where id = aptFeatureIndex into aptFeatureName;
				if ((SELECT COUNT(*) from appartment_feature WHERE TRIM(appartment_feature_name) = TRIM(aptFeatureName)) = 0) then
                    SET invalidRows = CONCAT(invalidRows, 'Apartment Feature [', TRIM(aptFeatureName) ,'] does not exist on row(s): ', x, '; ');
				end if;
				set aptFeatureIndex = aptFeatureIndex + 1;
			end while;
            
			-- reset aptFeatureIndex;
			set aptFeatureIndex = 1;
        END IF;
        
			-- validate apartment vacent flag
		IF (apartmentVacentFlagValue != 0 AND apartmentVacentFlagValue != 1 AND apartmentVacentFlagValue != '') THEN
			SET invalidRows = CONCAT(invalidRows, 'Apartment Vacent Flag is not one of the following: 1, 0, null on rows(s): ', x, '; ');
        END IF;
        
			-- validate apartment type
        IF (apartmentTypeValue = '') THEN
			SET invalidRows = CONCAT(invalidRows, 'Apartment Type is null on row(s): ', x, '; ');
		ELSEIF ((SELECT COUNT(*) FROM appartment_type WHERE room_type_name = apartmentTypeValue) = 0) THEN
			SET invalidRows = CONCAT(invalidRows, 'Apartment Type does not exist on row(s): ', x, '; ');
        END IF;
        
	END WHILE;
    -- ----------------------------------------------------- END VALIDATION -----------------------------------------------------
    
    -- RETURN RESULT
    IF (invalidRows != '') THEN
    	UPDATE validate_import_table
		SET	status = 0, invalid_rows = invalidRows, error_message = 'Invalid data', notes = 'Apartment'
		WHERE username = usrName
			AND date = recent;
	ELSE
		UPDATE validate_import_table
        SET status = 1, notes = 'Apartment'
        WHERE username = usrName
			AND date = recent;
    END IF;
    
    -- Return 0 -> status: error
    -- Return 1 -> status: success
    SELECT v.status from `validate_import_table` v where v.date = recent into statusResponse;
   
	-- Turn on SQL SAFE UPDATES
    SET SQL_SAFE_UPDATES = 1;
END