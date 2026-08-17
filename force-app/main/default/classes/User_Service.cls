public class User_Service {

private static User_Service instance;
    
    public User_Service() {
        
    }

    public static User_Service getInstance() { 
        if(instance == null) {
            instance = new User_Service();
        }
        return instance;
    }

public List<User__c> getUsersByAzure(String principalId){
    List<User__c> userList=new   List<User__c>();
    userList=  [select id,Account__c from User__c where Account__c=:principalId and Is_Azure_Active__c=true];
    return userList;
}

    public List<User__c> getUsersByEmail(string email){
    List<User__c> userList=new   List<User__c>();
    userList=  [select id,Account__c from User__c where Email__c=:email and Is_Azure_Active__c=true];
    return userList;
}
    public List<User__c> getUsersByAccountId(Set<Id> accountIds ){
    return  [select deviceRegistrationId__c,User_Account__c from User__c where  User_Account__c IN:accountIds];
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

    public void createUser(User__c request){
    insert request;
}

public void updateUser(User__c request){    
    update request;
}

}