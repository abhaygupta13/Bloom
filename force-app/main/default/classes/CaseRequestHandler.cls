//============================ CaseRequestHandler =============================
/*
* @Author : Eagles 
* @CreatedDate : 04 Sept 2024
* @Name : CaseRequestHandler 
* @Description : 
*/
/*****************************************************************************************************
* Version       Author                  Date             Comment                                                                       
* 1.0           Eagles               04 Sept 2024        Initial draft 
*****************************************************************************************************/

public class CaseRequestHandler {

       public static void handleAssignment(List<Case> newCases,Map<Id, Case> oldCaseMap) {
        List<Customer_Document__c> requestDocumentList = new List<Customer_Document__c>();

        Set<Id> serviceCatalogIds = new Set<Id>(); 

      for (Case caseRecord : newCases) {
            
            if (caseRecord.Service_Catalog__c !=null && caseRecord.Status == 'Submitted' && oldCaseMap.get(caseRecord.Id).Status != 'Submitted') {
                if (caseRecord.Service_Catalog__c != null) {
                    serviceCatalogIds.add(caseRecord.Service_Catalog__c);
                }
            }
        }
        if (!serviceCatalogIds.isEmpty()) {
            List<Action_Items__c> taskManagers = [
                SELECT Id, Service_Catalog__c, On_Submit__c ,OwnerId
                FROM Action_Items__c 
                WHERE Service_Catalog__c IN :serviceCatalogIds
            ];
            
            
            Map<id,Service_Catalog__c> mapServiceCatelog=new Map<id,Service_Catalog__c>([select id,(select id,Name from Service_Catolog_Documents__r) from Service_Catalog__c where id in:serviceCatalogIds]);

            Map<Id, Action_Items__c> taskManagerMap = new Map<Id, Action_Items__c>();

            for (Action_Items__c taskManager : taskManagers) {
                if (taskManager.On_Submit__c == true) {
                    taskManagerMap.put(taskManager.Service_Catalog__c, taskManager);
                }
            }

            for (Case caseRecord : newCases) {
                if (caseRecord.Status == 'Submitted' && serviceCatalogIds.contains(caseRecord.Service_Catalog__c)) {
                    if (taskManagerMap.containsKey(caseRecord.Service_Catalog__c)) {
                    Action_Items__c taskManager=  taskManagerMap.get(caseRecord.Service_Catalog__c);
                        caseRecord.ownerId =taskManager.OwnerId;
                    }
                }
            }
        }

    }


    public static void handleSubmittedCases(List<Case> newCases) {
        List<Customer_Document__c> requestDocumentList = new List<Customer_Document__c>();

        Set<Id> serviceCatalogIds = new Set<Id>();

        for (Case caseRecord : newCases) {
            serviceCatalogIds.add(caseRecord.Service_Catalog__c);
        }
        if (!serviceCatalogIds.isEmpty()) {
            List<Action_Items__c> taskManagers = [
                SELECT Id, Service_Catalog__c, On_Submit__c ,OwnerId
                FROM Action_Items__c 
                WHERE Service_Catalog__c IN :serviceCatalogIds
            ];
            
            List<String> lstUserType = newCases[0].User_Type__c.split(';');

            Map<id,Service_Catalog__c> mapServiceCatelog=new Map<id,Service_Catalog__c>([select id,(select id,Name,Required_For__c from Service_Catolog_Documents__r ) from Service_Catalog__c where id in:serviceCatalogIds]);

            Map<Id, Action_Items__c> taskManagerMap = new Map<Id, Action_Items__c>();

            for (Action_Items__c taskManager : taskManagers) {
                if (taskManager.On_Submit__c == true) {
                    taskManagerMap.put(taskManager.Service_Catalog__c, taskManager);
                }
            }

            for (Case caseRecord : newCases) {
         
                    Service_Catalog__c serviceCatelog= mapServiceCatelog.get(caseRecord.Service_Catalog__c);
                    
                    if(serviceCatelog.Service_Catolog_Documents__r.size()>0){
                      
                        for(Service_Catolog_Documents__c document : serviceCatelog.Service_Catolog_Documents__r){
                            if(document.Required_For__c!=null && lstUserType.contains(document.Required_For__c.split(';')[0] )){
                                Customer_Document__c doc=new Customer_Document__c();
                                doc.Name=document.name;
                                doc.Service_Catolog_Documents__c  =document.Id;
                                 doc.Case__c=caseRecord.Id;
                                requestDocumentList.add(doc);
                            }
                            
                        }
                    }
                    
                }
            }
        

        
        if (!requestDocumentList.isEmpty()) {
            insert requestDocumentList;
        } 
    }
}