CREATE DEFINER=`root`@`localhost` PROCEDURE `property_manager_insert_stored_procedure`(
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
    Declare createdUserIdParam int;
    Declare createdPmIdParam int;
    Declare propertiesCountParam int default 0;
    
		-- Property Manager values
    Declare propertyManagerNameValue varchar(55) default '';
    Declare propertyManagerEmailValue varchar(55) default '';
    Declare propertyNameValue varchar(55) default '';
    Declare propertyManagerPhoneValue varchar(55) default '';
    
		-- pass condition data into variable
	select v.xml from `validate_import_table` v where v.username = usrName and v.date = (select max(date) from validate_import_table) into xml;
	select extractvalue(xml, 'count(/records/record)') into recordNumber;
	select max(date) from validate_import_table into recent;
			-- Find Client Id
	select c.client_id from `client` c, `user` u where c.user_id = u.df_user_id and u.user_email = usrName into clientIdParam;
    
	-- ----------------------------------------------------- INSERT -----------------------------------------------------

	WHILE x <= recordNumber DO
		SELECT extractvalue(xml, '/records/record[$x]/property_manager_name') into propertyManagerNameValue;
		SELECT extractvalue(xml, '/records/record[$x]/property_manager_email') into propertyManagerEmailValue;
		SELECT extractvalue(xml, '/records/record[$x]/property_name') into propertyNameValue;
		SELECT extractvalue(xml, '/records/record[$x]/property_manager_phone') into propertyManagerPhoneValue;
        
        -- INSERT data into User table
        
        INSERT INTO `user` (`password`, `user_email`, `user_first_name`, `user_last_name`, `user_avatar_url`, `user_display_name`, `user_phone`, `user_title`, `user_date_of_birth`, `user_card_holder_name`, `user_card_number`, `user_card_cvv`, `user_card_expiry_month`, `user_card_expiry_year`, `user_card_type_id`, `user_card_details_address_1`, `user_card_details_address_2`, `user_card_details_zip_code`, `user_card_details_city`, `user_card_details_state`, `user_card_details_country`, `is_trial`, `is_triggered`, `user_blocked_flag`, `user_archived_flag`, `user_created_datetime`, `signup_active_flag`, `is_active`, `email_verified`) VALUES
		(NULL, propertyManagerEmailValue, propertyManagerNameValue, NULL, NULL, propertyManagerNameValue, propertyManagerPhoneValue, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0, 0, 0, CURRENT_TIMESTAMP(), 0, 1, 0);

			-- backup created user id
			select df_user_id from user where user_email = propertyManagerEmailValue ORDER BY df_user_id DESC limit 1 into createdUserIdParam;

		-- INSERT data into Property Manager table
        
		INSERT INTO `property_manager` (`name`, `emailid`, `location`, `propertiescount`, `phonenumber`, `joindate`, `activeflag`, `parentid`) VALUES
		(propertyManagerNameValue, propertyManagerEmailValue, NULL, NULL, propertyManagerPhoneValue, NULL, 1, createdUserIdParam);
        
			-- backup created PM id
			select propertymanagerid from property_manager where emailid = propertyManagerEmailValue ORDER BY propertymanagerid DESC limit 1 into createdPmIdParam;
        
        -- UPDATE the role for PM
        
        INSERT INTO `user_client_role_mapping` (`user_id`, `client_id`, `role_id`, `created_by`, `last_modified_by`, `last_modified_date_time`) VALUES
		(createdUserIdParam, clientIdParam, 2, NULL, NULL, current_timestamp());
        
        -- UPDATE property manager for property
        
        UPDATE `property` SET property_manager_id = createdPmIdParam WHERE property_name = propertyNameValue AND property_client_id = clientIdParam;
        
        -- UPDATE properties count for PM
        
        SELECT COUNT(p.property_id) FROM property p, property_manager pm WHERE p.property_manager_id = pm.propertymanagerid AND pm.parentid=createdUserIdParam and p.active_flag=1 AND p.property_client_id=clientIdParam into propertiesCountParam;
        UPDATE `property_manager` SET propertiescount = propertiesCountParam WHERE emailid = propertyManagerEmailValue;
        
		SET x = x + 1;
    END WHILE;
END