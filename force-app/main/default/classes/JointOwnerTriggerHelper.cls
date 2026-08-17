/*
* @Author : Jayprakash Bharti
* @CreatedDate : 26th AUG 2024
* @Description : JointOwner object trigger helper
*/
/*****************************************************************************************************
* Version       Author      	Date             Comment                                                                       
* 1.0           Jayprakash   	26AUG2024        
*****************************************************************************************************/

public class JointOwnerTriggerHelper {
    
    public static void errorMessageOnJointOwnerDelete(Map<Id, JointOwner__c> oldMap){        
        Map<id,Salesorder__c>salesorderMap = new Map<id,Salesorder__c>([SELECT Id, Status__c FROM Salesorder__c WHERE id=:oldMap.keyset()]);     
        for(JointOwner__c jc:oldMap.values()){
            if(salesorderMap.ContainsKey(jc.SalesOrder__c) &&salesorderMap.get(jc.SalesOrder__c).Status__c!='Booked' ){
                jc.addError('You do not have rights to delete record at current Sales Order status.');
            }
        }
    }
    
    public static void updateJointOwnerDetails(List<JointOwner__c> newList){
        SalesOrderService objSalesOrderService = SalesOrderService.getInstance();
        Set<Id> salesOrderIds = new Set<Id>();
        for(JointOwner__c objJointOwner :newList){
            if(objJointOwner.SalesOrder__c != NULL){
                salesOrderIds.add(objJointOwner.SalesOrder__c);
            }
        }
        if(!salesOrderIds.isEmpty()){
            Map<Id, SalesOrder__c> objSalesOrderMap = new Map<Id, SalesOrder__c>(objSalesOrderService.getSalesOrdersByIds(salesOrderIds));
            List<Account> accList = new List<Account>();
            AccountService objAccountService = AccountService.getInstance();
            for(JointOwner__c objJointOwner :newList){
                if(objJointOwner.SalesOrder__c != NULL && objJointOwner.Account__c != NULL){
                    accList.add(new Account(Id = objJointOwner.Account__c, SAP_Company_Code__c = objSalesOrderMap.get(objJointOwner.SalesOrder__c).Company_Code__c, Send_To_SAP__c = true));
                }
            }
            objAccountService.updateAccountsWithoutTrigger(accList);
        }
    }
    
    public static void updateJointOwnerSequence(List<JointOwner__c> newList, Map<Id, JointOwner__c> oldMap){
        Set<Id> salesOrderIds = new Set<Id>();
        for(JointOwner__c objJointOwner :newList){
            if((objJointOwner.SalesOrder__c != NULL && oldMap == NULL)
               || (objJointOwner.SalesOrder__c != NULL && oldMap != NULL && oldMap.get(objJointOwner.Id).IsActive__c != objJointOwner.IsActive__c)){
                   salesOrderIds.add(objJointOwner.SalesOrder__c);
               }
        }
        if(!salesOrderIds.isEmpty()){
            JointOwnerService objJointOwnerService = JointOwnerService.getInstance();
            SalesOrderService objSalesOrderService = SalesOrderService.getInstance();
            List<SalesOrder__c> salesOrderList = objSalesOrderService.getSalesOrdersWithJointOwner(salesOrderIds);
            List<JointOwner__c> jointOwnerList = new List<JointOwner__c>();
            for(SalesOrder__c objSalesOrder :salesOrderList){
                Integer i = 1;
                for(JointOwner__c objJointOwner :objSalesOrder.Joint_OwnersSalesOrder__r){
                    if(objJointOwner.IsActive__c){
                        objJointOwner.Sequence__c = 'JointOwner'+ i +':';
                        i++;
                    }else{
                        objJointOwner.Sequence__c = NULL;
                    }
                    jointOwnerList.add(objJointOwner);
                }
            }
            objJointOwnerService.updateJointOwnersWithoutTrigger(jointOwnerList);
        }
    }
    
    public static void handleBeforeInsertFieldUpdates(List<JointOwner__c> newList) {
        MetadataService objMetadataService = MetadataService.getInstance();
        for(JointOwner__c joRec : newList){
            if(String.isNotBlank(joRec.Nationality__c)){
                joRec.NationalityInArabic__c = objMetadataService.getNationalityInArabic(joRec.Nationality__c);
            }
        }
    }
    
    public static void handleBeforeUpdateFieldUpdates(List<JointOwner__c> newList, Map<Id, JointOwner__c> oldMap) {
        MetadataService objMetadataService = MetadataService.getInstance();
        for(JointOwner__c joRec : newList){
            if(String.isNotBlank(joRec.Nationality__c) && joRec.Nationality__c != oldMap.get(joRec.Id).Nationality__c){
                joRec.NationalityInArabic__c = objMetadataService.getNationalityInArabic(joRec.Nationality__c);
            }
        }
    }
}