//============================ BCAPP_CreateOwnerUsersBatch =============================
/*
* @Author : Eagles 
* @CreatedDate : 18 OCT 2024
* @Name : BCAPP_CreateOwnerUsersBatch
* @Description : This APEX class is used to create the Users in Azure b2c for existing Owners.
*/
/*****************************************************************************************************
* Version       Author                  Date             Comment                                                                       
* 1.0           Eagles               18 OCT 2024       Initial draft 
*****************************************************************************************************/

global class BCAPP_CreateOwnerUsersBatch implements Database.Batchable<SObject>,Database.AllowsCallouts {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        
        String query = 'SELECT Tenant__c,Holiday_Homes__c,Owner__c,Id, FirstName, LastName, PersonEmail FROM Account WHERE Create_User__c=true';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> scope) {
        // Loop through the scope (list of Account records in this batch)
        BCAPP_Utility utiRef = new BCAPP_Utility();
        String userPrincipalName ='';
        String id ='';
        List<User__c> lstUsers = new List<User__c>();
        Map<Id,Account> accountMap = new  Map<Id,Account>();
        system.debug('@@##$$$'+scope);
        for (Account acRecord : scope) {           
            
            
            User__c userRecord=new User__c();
            userRecord.Account__c=acRecord.id;
            
            string name='';
            if(acRecord.FirstName!=null){
                name = acRecord.FirstName+' ';
            }
            name = name+acRecord.LastName;
            if (name != null && name.length() > 79) {
                name = name.substring(0, 79);
            }
            
            userRecord.Name=name;
            userRecord.isActive__c = true;
            userRecord.Email__c=acRecord.PersonEmail;
            userRecord.User_Account__c=acRecord.id;
            userRecord.Is_Azure_Active__c=true;
            userRecord.Username__c=userPrincipalName;
            userRecord.Is_Azure_Active__c = true;
            userRecord.isActive__c = true;
            userRecord.name__c = name;
            userRecord.Temporary_Password__c = utiRef.generateRandomPassword();
            userRecord.Username__c = userRecord.Email__c;
            
            if(acRecord.Owner__c){
                userRecord.User_Type__c='Owner';
            }
            if(acRecord.Tenant__c){
                userRecord.User_Type__c='Tenant';
            }
            if(acRecord.Holiday_Homes__c){
                userRecord.User_Type__c='Holiday Homes';
            }
            userRecord.User_Account__c =acRecord.Id;
            accountMap.put(acRecord.Id,acRecord);
            lstUsers.add(userRecord);              
        }
        
        if(lstUsers.size() > 0){
            INSERT lstUsers;
            
            List<Account> updateAccounts = new List<Account>();
            for(User__c u:lstUsers){
                MicrosoftAzureB2CUtility.createUser(u);
                Account acc = accountMap.get(u.Account__c);
                acc.user__c = u.Id;
                acc.Create_User__c=false;
                updateAccounts.add(acc);
            }
            update updateAccounts;
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        // Add any post-batch processing logic here
        System.debug('Batch job finished.');
    }
}