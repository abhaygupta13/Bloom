/*
* @Author : Shruti Kulkarni
* @CreatedDate : 4th June 2025
* @Description : Custom User object service class
*/
/*****************************************************************************************************
* Version       Author          Date            Comment                                                                       
* 1.0           Shrut Kulkarni  04JUNE2025      Initial Draft
*****************************************************************************************************/
public inherited sharing class CustomUserService {
    
    private static final string INTEGRATION_ACTION_UPDATE { get { return 'Update'; } }
    private static final string INTEGRATION_ACTION_INSERT { get { return 'Insert'; } }
    private static final string INTEGRATION_TYPE_USER_AB2C_INTEGRATION { get { return 'AB2C_USER_INTEGRATION'; } }
    
    public static CustomUserService instance;
    
    public static CustomUserService getInstance() {
        if(instance == null) {
            instance = new CustomUserService();
        }
        return instance;
    }
    
    /***
    * Get the Azure user record by Email
    * @param emailid email id
    * @return User__c
    */
    public User__c getUserByEmail(String emailId) {
        List<User__c> userByEmailId = [ SELECT  Is_Azure_Active__c, 
                                       Account__c,
                                       Contact__c,
                                       Contact__r.IsSuspended__c,
                                       Contact__r.Blacklisted__c,
                                       Contact__r.SuspensionTenure__c
                                       FROM User__c
                                       WHERE Email__c = :emailId
                                       LIMIT 1
                                      ];
        return userByEmailId.isEmpty() ? null : userByEmailId[0];
    }
    /***
    * Get the Azure user record by Contact Id
    * @param contactId contact id
    * @param emailId email id
    * @return User__c
    */
    public User__c getUserByContactIdOrEmail(String contactId, String emailId) {
        String userQuery = 'SELECT  Is_Azure_Active__c,' + 
            'Email__c,'+
            'Mobile_Number__c,' + 
            'Account__c,'+
            'Contact__c,'+
            'Contact__r.Name,'+
            'Contact__r.Email,'+
            'Contact__r.IsSuspended__c,'+
            'Contact__r.Blacklisted__c,'+
            'Contact__r.SuspensionTenure__c,'+
            'Azure_UserId__c'+
            ' FROM User__c';
        String queryFilter = ' WHERE (Azure_UserId__c!=null) AND   ';
        if(String.isNotBlank(contactId) && String.isBlank(emailId)) {
            queryFilter += 'Contact__c = :contactId LIMIT 1';
        } 
        if(String.isNotBlank(emailId) && String.isBlank(contactId)) {
            queryFilter += 'Email__c = :emailId LIMIT 1';
        }            
        if(String.isNotBlank(contactId) && String.isNotBlank(emailId)) {
            queryFilter += '(Contact__c = :contactId OR Email__c = :emailId) LIMIT 1';
        }
        
        userQuery += queryFilter;
        
        List<User__c> userByContactIdOrEmailId = Database.query(userQuery);
        
        return userByContactIdOrEmailId.isEmpty() ? null : userByContactIdOrEmailId[0];
    }
    
    /***
    * Get the user record by Azure User Id
    * @param azureUserId azure id
    * @return User__c
    */
    public User__c getUserByAzureToken(String azureUserId) {
        List<User__c> userByAzureId = [ SELECT Name,Is_Azure_Active__c,
                                       isActive__c ,
                                       Contact__c,
                                       Contact__r.AccountId,
                                       Contact__r.Email,
                                       Contact__r.IsSuspended__c,
                                       Contact__r.Blacklisted__c,
                                       Contact__r.SuspensionTenure__c,
                                       contact__r.BrokerContactRole__c,
                                       Contact__r.TerminationApprovalStatus__c,
                                       Contact__r.SuspensionStartDate__c,
                                       Contact__r.SuspensionEndDate__c,
                                       Contact__r.Account.TypeofEstablishment__c,
                                       Contact__r.Account.ShippingCountry
                                       FROM User__c
                                       WHERE Azure_UserId__c = :azureUserId
                                       LIMIT 1
                                      ];
        return userByAzureId.isEmpty() ? null : userByAzureId[0];
    }
    
    //BAPP : To get User by User Id
    public Map<Id, User__c> getUsersByIds(Set<Id> userIds) {
        if (userIds == null || userIds.isEmpty()) {
            return new Map<Id, User__c>();
        }
        return new Map<Id, User__c>(
            [
                SELECT Id,
                Username__c,
                Email__c,
                Temporary_Password__c,
                Contact__c,
                Contact__r.Name,
                User_Account__c,
                User_Account__r.Name
                FROM User__c
                WHERE Id IN :userIds
            ]
        );
    }
    
    public User__c getUserById(Id userId) {
        return [SELECT Id,
                Username__c,
                Email__c,
                Temporary_Password__c,
                Contact__c,
                Contact__r.Name,
                User_Account__c,
                User_Account__r.Name
                FROM User__c
                WHERE Id = :userId
               ];
    }
    
    // BAPP : To Update User__c records
    public List<User__c> updateUsers(List<User__c> userList) {
        if (userList != null && !userList.isEmpty()) {
            update userList;
        }
        return userList;
    }
    
    public User__c updateUser(User__c objUser){
        if(objUser != NULL ){
            objUser = updateUsers(new List<User__c>{objUser})[0];
        }
        return objUser;
    }
    
    
    // Update User__c records without trigger
    public List<User__c> updateUsersWithoutTrigger(List<User__c> userList) {
        if (userList != null && !userList.isEmpty()) {
            AzureUserTriggerHandler.isTriggerDisabled = true;
            update userList;
            AzureUserTriggerHandler.isTriggerDisabled = false;
        }
        return userList;
    }

    
    // This is Method is Used to fetch the Users by using Contact Ids -BAPP
    public List<User__c> getUsersByContactIds(Set<Id> ContactIds){
        List<User__c> userList=new   List<User__c>();
        userList=  [
            SELECT Id, Contact__c,
            Mobile_Number__c, User_Account__c, Email__c,
            Blacklisted__c, IsSuspended__c, IsActive__c
            FROM User__c
            WHERE Contact__c IN :ContactIds
        ];
        return userList;
    }
       //Insert Azure Users
    public List<User__c> insertContacts(List<User__c> UserList) {
        if (UserList != null && !UserList.isEmpty()) {
            insert UserList;  
        }
        return UserList;
    }
    
    public IntegrationRecord__c getIntegrationRecord(User__c objUser, String subActionType){
        Map<String,String> paramsMap = new Map<String,String>();
        IntegrationRecordService integService = IntegrationRecordService.getInstance();
        
        String actionType = String.isBlank(objUser.Azure_UserId__c) ? INTEGRATION_ACTION_INSERT : INTEGRATION_ACTION_UPDATE;
        String appType = objUser.User_Type__c.contains('Broker Agent') ? 'BAPP' : 'SAPP';
        
        paramsMap.put('Param1', 'DisablePasswordExpiration');
        paramsMap.put('Param2', 'emailAddress');
        paramsMap.put('Param3', Label.AzureUserEmail);
        paramsMap.put('Param4', objUser.Temporary_Password__c);
        paramsMap.put('Param5', 'false');
        paramsMap.put('Param6', objUser.Username__c);
        paramsMap.put('Param7', objUser.User_Account__c);
        paramsMap.put('Param8', appType);
        paramsMap.put('Param9', objUser.Contact__c);
        paramsMap.put('Param10', 'false');
        return integService.getIntegrationRecord(INTEGRATION_TYPE_USER_AB2C_INTEGRATION, actionType, subActionType, objUser.User_Type__c, 'User__c', objUser.Id, paramsMap);
    }
    
    public List<User__c> insertUsers(List<User__c> userList) {
        if (userList != null && !userList.isEmpty()) {
            insert userList;
        }
        return userList;
    }
    
    public User__c getAppRegistrationUser(AppRegistration__c objAppRegistration) {
        User__c objUser = new User__c();
        objUser.Name = objAppRegistration.FirstName__c + ' ' + objAppRegistration.LastName__c;
        objUser.Name__c = objAppRegistration.FirstName__c + ' ' + objAppRegistration.LastName__c;
        objUser.Username__c = objAppRegistration.Email__c;
        objUser.Mobile_Number__c = objAppRegistration.MobilePhoneNumber__c;
        objUser.Contact__c = objAppRegistration.Contact__c;
        objUser.Email__c = objAppRegistration.Email__c;
        objUser.Account__c = objAppRegistration.Account__c;
        objUser.User_Account__c = objAppRegistration.Account__c;
        objUser.User_Type__c = 'Owner';
        objUser.IsSendToAB2C__c = true;
        objUser.isActive__c = true;
        objUser.AppType__c = 'Super App';
        return objUser;
    }
    // BAPP - Fetch user by contact details
    public List<User__c> getUserByDetails(String email,String mobile,String emiratesId) {
        if (String.isBlank(email) ||String.isBlank(mobile) ||String.isBlank(emiratesId)) {
            return new List<User__c>();
        }
        return [SELECT Id,Name,Is_Azure_Active__c,UUID__c,Contact__c,Contact__r.Email,Contact__r.MobilePhone,Contact__r.Emirates_Id__c,Contact__r.EID_Expiry_Date__c,Contact__r.Blacklisted__c,Contact__r.IsSuspended__c,Contact__r.TerminationApprovalStatus__c,Contact__r.BrokerContactRole__c,
                Contact__r.SuspensionTenure__c,Contact__r.Account.TypeofEstablishment__c,Contact__r.Account.ShippingCountry FROM User__c WHERE Contact__r.Email = :email AND Contact__r.MobilePhone = :mobile AND Contact__r.Emirates_Id__c = :emiratesId AND IsActive__c = true LIMIT 1];
    }
    public List<User__c> getUserByUUID(String uuid) {
        if (String.isBlank(uuid)) {
            return new List<User__c>();
        }
        return [SELECT Id,Name,Is_Azure_Active__c,UUID__c,Contact__c,Contact__r.Email,Contact__r.MobilePhone,Contact__r.Emirates_Id__c,Contact__r.EID_Expiry_Date__c,Contact__r.Blacklisted__c,Contact__r.IsSuspended__c,Contact__r.TerminationApprovalStatus__c,
                Contact__r.BrokerContactRole__c,Contact__r.SuspensionTenure__c,Contact__r.Account.TypeofEstablishment__c,Contact__r.Account.ShippingCountry FROM User__c WHERE UUID__c = :uuid AND IsActive__c = true LIMIT 1];
    }
}