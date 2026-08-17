/*****************************************************************************************
Class       : SalesTargetController
Author      : Vikas Baliyan
Description : SalesTargetController
Test Class  : SalesTargetControllerTest
Created Date: 23 DEC 2024 
*****************************************************************************************/
public without sharing class SalesTargetController {
    @AuraEnabled
    public static void createSalesTarget(List<SalesTarget__c> salesTargetList){
        try {
            SalesTargetService objSalesTarget = SalesTargetService.getInstance();
            UserService objUserService = UserService.getInstance();
            Set<String> salesManagerEmailSet = new Set<String>();
            for(SalesTarget__c salesTarget: salesTargetList){
                salesManagerEmailSet.add(salesTarget.ExternalIdentifier__c.split('_')[2]);
            }
            Map<String,String> userEmailToIdMap =  new Map<String,String>();
            for(User user : objUserService.getUsersByEmails(salesManagerEmailSet)){
                userEmailToIdMap.put(user.Email, user.Id);
            }

            for(SalesTarget__c salesTarget : salesTargetList){
                salesTarget.SalesManager__c = userEmailToIdMap.get(salesTarget.ExternalIdentifier__c.split('_')[2]);
            }
            objSalesTarget.upsertSalesTargetByExternalIdentifier(salesTargetList);
        } catch (Exception e) {
            throw new AuraHandledException('Error :'+e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getUsersByEmails(List<String> emails) {
        UserService objUserService = UserService.getInstance();
        Map<String, String> emailToNameMap = new Map<String, String>();
        for (User user : objUserService.getUsersByEmails(new Set<String>(emails))){
            emailToNameMap.put(user.Email, user.Name);
        }
        return emailToNameMap;
    }
}