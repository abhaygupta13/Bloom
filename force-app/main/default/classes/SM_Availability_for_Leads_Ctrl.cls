/***
Class       : SM_Availability_for_Leads_Ctrl
Author      : Smaartt
Description : fetching user details.
TestClass   : SM_Availability_for_Leads_CtrlTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version_DevInitials     Date                Details
1.          V1.0              27/04/23           Initial Version 
****************************************************************************************************************/

public without sharing class  SM_Availability_for_Leads_Ctrl {
 @AuraEnabled
    public static List<User> getUserRecords(){
        List<User> users = new List<User>([SELECT Id, Name, Email, Phone, UserRoleId, UserRole.Name, ProfileId, Profile.Name, 
                                           Start_Date__c, End_Date__c
                                           FROM User where Profile.Name = 'Sales Manager']);
        return users;
    }
    
    @AuraEnabled   
    public static void updateUsers(List<User> updatedUserList) {
        System.debug('updatedUserList '+updatedUserList);
        update updatedUserList; 
        //return true;
    }
}