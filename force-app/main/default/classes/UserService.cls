/*
* @Author : Biswajeet Samal
* @CreatedDate : 7th AUG 2024
* @Description : User object service class
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           Biswajeet   07AUG2024        Initial draft 
* 2.0           Jayprakash  20AUG2024        Implemented GIS Integration
*****************************************************************************************************/
public inherited sharing class UserService {
    
    private static UserService instance;
    
    private UserService() {
        
    }
    
    public static UserService getInstance() {
        if(instance == null) {
            instance = new UserService();
        }
        return instance;
    }
    
    public Boolean hasBypassEmail() {
        return FeatureManagement.checkPermission('BypassEmail');
    }
    
    public Boolean hasBypassIntegration() {
        return FeatureManagement.checkPermission('BypassIntegration');
    }
    
    public Boolean hasBypassTrigger() {
        return FeatureManagement.checkPermission('BypassTrigger');
    }
    
    public User getUsersById(Id userId) {
        return [SELECT Id, Name, Name_In_Arabic__c, ProfileId, BusinessHour__c, Title, Email, Phone, ClickToDialSkill__c FROM User WHERE Id =: userId];
    }
    
    public List<User> getUsersByIds(Set<Id> userIds) {
        return [SELECT Id, Name, ProfileId, Title, BusinessHour__c, Email FROM User WHERE Id IN :userIds];
    }

    public List<User> getUsersByEmails(Set<String> salesManagerEmailSet){
        return [SELECT Id, Name, ProfileId, Email, BusinessHour__c, isActive FROM User WHERE Email IN :salesManagerEmailSet];
    }
     public List<User> getUsersByEmail(String userEmail){
        return [SELECT Id FROM User WHERE Email = :userEmail AND isActive = true LIMIT 1];
    }
    
    
    public List<User> getUserIdByUserName(String userName) {

        return [SELECT Id FROM User WHERE username=:userName];
    
    }
    //BAPP
    public List<User> getUsersByTitles(List<String> titles) {
        return [SELECT Id, Name, Title, Email, Phone, ProfileId FROM User WHERE Title IN :titles];
    }
    //Rushikesh
    public List<User> getActiveUsersWithEmailByIds(Set<Id> userIds) {
        if (userIds == null || userIds.isEmpty()) {
            return new List<User>();
        }
        return [
            SELECT Id, Name, Email
            FROM User
            WHERE Id IN :userIds
            AND IsActive = true
            AND Email != null
        ];
    }

    public Map<Id, User> getActiveUsersByIds(Set<Id> userIds) {
        Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Name, Email, Phone, MobilePhone FROM User WHERE Id = :userIds AND isActive = true]);
        return userMap;
    }
}