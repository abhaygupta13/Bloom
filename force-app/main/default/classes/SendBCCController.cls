/***
Class       : SubmitUnitHandler
Author      : Rajat Rastogi
Description : 
TestClass   : SendBCCControllerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.      V1.0             	 11/06/2024           Initial Version  
2.		V1.1				 16/01/2025			Implemented Send NOC Mass Email Functionality
****************************************************************************************************************/ 

public class SendBCCController {
    
    private static final String BATCH_PROCESSING = 'Records submitted successfully. We will send you a mail once the record will be completely processed.';
    
    @AuraEnabled
    public static List<Map<String,String>> getProjects(){
        HandoverService handoverService = HandoverService.getInstance();
        List<Map<String,String>> projectsMap = new List<Map<String,String>>();
        List<AggregateResult> results = HandoverService.getHandoversGroupByProject();
        for (AggregateResult ar : results) {
            Map<String,String> projMap = new Map<String,String>();
            projMap.put('label',(String)ar.get('projectName'));
            projMap.put('value',(String)ar.get('Project__c'));
            projectsMap.add(projMap);            
        }
        return projectsMap;
    }
    
    @AuraEnabled
    public static List<Map<String,String>> getBuildings(String projectId){
        HandoverService handoverService = HandoverService.getInstance();
        List<Map<String,String>> buildingsMap = new List<Map<String,String>>();
        List<AggregateResult> results = HandoverService.getHandoversGroupByBuilding();
        for (AggregateResult ar : results) {
            String projId = (String)ar.get('Project__c');
            if(projId == projectId){
                Map<String,String> buildMap = new Map<String,String>();
                buildMap.put('label',(String)ar.get('buildingName'));
                buildMap.put('value',(String)ar.get('Building_Phase__c'));
                buildingsMap.add(buildMap);  
            }
        }
        return buildingsMap;
    }
    
    @AuraEnabled
    public static List<UnitWrap> getUnits(String projectId, String buildingId){
        HandoverService handoverService = HandoverService.getInstance();
        DocumentService DocumentService = DocumentService.getInstance();
        UnitService UnitService = UnitService.getInstance();
        List<Unit__c> unitList = new List<Unit__c>();
        List<UnitWrap> unitWrapList = new List<UnitWrap>();
        System.debug('projectId- ' + projectId);
        System.debug('buildingId- ' + buildingId);
        
        if(String.isBlank(projectId) && String.isBlank(buildingId)){
            unitList = UnitService.getUnits();
        }else if(String.isNotBlank(buildingId)){
            unitList = UnitService.getUnitsWithBuilding(buildingId);
        }else if(String.isNotBlank(projectId)){
            unitList = UnitService.getUnitsWithProjectId(projectId);
        }
        System.debug('unitList = ' + unitList );
        Set<Id> handoverIds = new Set<Id>();
        for(Unit__c unit : unitList){
            if(!unit.Handovers__r.isEmpty()){
            	handoverIds.add(unit.Handovers__r[0].Id);	// using 0 index because there will be always one handover on one unit
            }
        }
        Map<String,String> contentDocIdToHandOverId = new Map<String,String>();
        List<Document__c> SOADocList = DocumentService.getDocumentWithContentVersion(handoverIds,  new String[]{HandoverConstants.HO_SOA});
        for(Document__c doc: SOADocList){
            contentDocIdToHandOverId.put(doc.Handover__c,doc.ContentDocumentId__c);
        }
        for(Unit__c unit : unitList){
            Handover__c handover = new Handover__c();
            if(!unit.Handovers__r.isEmpty()){
            	handover = unit.Handovers__r[0];	// using 0 index because there will be always one handover on one unit
            }
            UnitWrap unitWrapObj = new UnitWrap();
            unitWrapObj.Id = unit.Id;
            unitWrapObj.handoverName = handover.Name;
            if(contentDocIdToHandOverId.containsKey(handover.id)){
                unitWrapObj.contentDocId = contentDocIdToHandOverId.get(handover.id);
            }
            else{
                unitWrapObj.contentDocId = '';
            }
            unitWrapObj.handoverCustomerEmail = String.isNotBlank(handover.CustomerEmail__c) ? handover.CustomerEmail__c : '';
            unitWrapObj.unitName = unit.Name;
            unitWrapObj.unitStatus = String.isNotBlank(unit.Unit_Status__c) ? unit.Unit_Status__c : '';
            unitWrapObj.activeSalesOrder = String.isNotBlank(unit.Active_Sales_Order__r.Name) ? unit.Active_Sales_Order__r.Name : '';
            unitWrapObj.buildingName = String.isNotBlank(unit.BuildingSectionName__r.Name)? unit.BuildingSectionName__r.Name : '';
            unitWrapObj.OwnerName = String.isNotBlank(unit.Owner.Name) ? unit.Owner.Name : '' ;
            unitWrapObj.createdDate = String.valueOf(DateTime.valueOf(unit.CreatedDate));
            unitWrapList.add(unitWrapObj);
        }
        return unitWrapList;
    }
    
    @AuraEnabled
    public static List<HandoverNOCWrap> getNOCUnits(String projectId, String buildingId){
        HandoverService handoverService = HandoverService.getInstance();
        DocumentService DocumentService = DocumentService.getInstance();
        List<Handover__c> handoverList = new List<Handover__c>();
        List<HandoverNOCWrap> hoWrapList = new List<HandoverNOCWrap>();
        System.debug('projectId- ' + projectId);
        System.debug('buildingId- ' + buildingId);
        if(String.isBlank(projectId) && String.isBlank(buildingId)){
            handoverList = HandoverService.getNOCHandoversBasedOnProjectAndBuilding(); // add new
        }
        else if(String.isNotBlank(buildingId)){
            handoverList = HandoverService.getNOCHandoversBasedOnBuilding(buildingId); // add new
            
        }else if(String.isNotBlank(projectId)){
            handoverList = HandoverService.getNOCHandoversBasedOnProject(projectId); // add new
        }

        System.debug('handoverList = ' + handoverList );
        Set<Id> handoverIds = new Set<Id>();
        for(Handover__c handover : handoverList){
            handoverIds.add(handover.Id);
        }
        
        //List<Document__c> contentDocIdToHandOverId = new List<Document__c>();
        List<Document__c> SOADocList = DocumentService.getDocumentWithContentVersion(handoverIds,  new String[]{HandoverConstants.HO_SOA,HandoverConstants.HO_CHO_DeSnagging_Report});
        System.debug(SOADocList.size()+'SOADocList'+SOADocList);
        for(Handover__c handover : handoverList){
            HandoverNOCWrap hoWrapObj = new HandoverNOCWrap();
            hoWrapObj.Id = handover.Id;
            hoWrapObj.handoverName = handover.Name;
            hoWrapObj.handoverCustomerEmail = String.isNotBlank(handover.CustomerEmail__c) ? handover.CustomerEmail__c : '';
            hoWrapObj.unitName = handover.Name;
            hoWrapObj.unitStatus = String.isNotBlank(handover.Unit__r.Unit_Status__c) ? handover.Unit__r.Unit_Status__c : '';
            hoWrapObj.activeSalesOrder = String.isNotBlank(handover.Sales_Order__r.Name) ? handover.Sales_Order__r.Name : '';
            hoWrapObj.buildingName = String.isNotBlank(handover.Building_Phase__r.Name)? handover.Building_Phase__r.Name : '';
            hoWrapObj.OwnerName = String.isNotBlank(handover.Owner_Name__c) ? handover.Owner_Name__c : '' ;
            hoWrapObj.createdDate = String.valueOf(DateTime.valueOf(handover.CreatedDate));
            hoWrapObj.SOADocId = '';
            hoWrapObj.QASnagDocId = '';
            for(Document__c objDocument : SOADocList){
                if(objDocument.Handover__c == handover.Id && objDocument.Document_Name__c == HandoverConstants.HO_SOA){
                    hoWrapObj.SOADocId = objDocument.Id;
                }
                else if(objDocument.Handover__c == handover.Id && objDocument.Document_Name__c == HandoverConstants.HO_CHO_DeSnagging_Report){
                    hoWrapObj.QASnagDocId = objDocument.Id;
                }
            }
            System.debug('hoWrapObj'+hoWrapObj.SOADocId+''+hoWrapObj.QASnagDocId);
            hoWrapList.add(hoWrapObj);
        }
        return hoWrapList;
    }
    
    @AuraEnabled
    public static List<HandoverWrap> getUnitToMakeReady(String projectId, String buildingId){
        HandoverService handoverService = HandoverService.getInstance();
        DocumentService DocumentService = DocumentService.getInstance();
        List<Handover__c> handoverList = new List<Handover__c>();
        List<HandoverWrap> hoWrapList = new List<HandoverWrap>();
        System.debug('projectId- ' + projectId);
        System.debug('buildingId- ' + buildingId);
        if(String.isBlank(projectId) && String.isBlank(buildingId)){
            handoverList = HandoverService.getHandoversBasedOnProjectAndBuilding(); // add new
        }
        else if(String.isNotBlank(buildingId)){
            handoverList = HandoverService.getHandoversBasedOnBuilding(buildingId); // add new
            
        }else if(String.isNotBlank(projectId)){
            handoverList = HandoverService.getHandoversBasedOnProject(projectId); // add new
        }

        System.debug('handoverList = ' + handoverList );
        Set<Id> handoverIds = new Set<Id>();
        for(Handover__c handover : handoverList){
            handoverIds.add(handover.Id);
        }
        List<String> docName = DocumentService.getDocWithProfileAccess(HandoverConstants.Profile_Operations_Team);
        List<Document__c> docList = DocumentService.getDocumentsByHandoverAndName(handoverIds,  docName);
        system.debug('docList--->'+docList);
        
               
        for(Handover__c handover : handoverList){
            HandoverWrap hoWrapObj = new HandoverWrap();
            for(Document__c doc:docList){
                if(doc.Handover__c == handover.id){
                    if(doc.Document_Name__c == HandoverConstants.SPA){
                        hoWrapObj.SPADocId = String.isNotBlank(doc.ContentDocumentId__c) ? doc.ContentDocumentId__c : '';
                    }
                    /*if(doc.Document_Name__c == HandoverConstants.Emirates_Id){
                        hoWrapObj.emiratesDocId = String.isNotBlank(doc.ContentDocumentId__c) ? doc.ContentDocumentId__c : '';
                    }
                    if(doc.Document_Name__c == HandoverConstants.Passport){
                        hoWrapObj.passportDocId = String.isNotBlank(doc.ContentDocumentId__c) ? doc.ContentDocumentId__c : '';
                    }*/
                }
            }
            hoWrapObj.Id = handover.Id;
            hoWrapObj.handoverName = handover.Name;
            hoWrapObj.handoverCustomerEmail = String.isNotBlank(handover.CustomerEmail__c) ? handover.CustomerEmail__c : '';
            hoWrapObj.unitName = handover.Name;
            hoWrapObj.unitStatus = String.isNotBlank(handover.Unit__r.Unit_Status__c) ? handover.Unit__r.Unit_Status__c : '';
            hoWrapObj.activeSalesOrder = String.isNotBlank(handover.Sales_Order__r.Name) ? handover.Sales_Order__r.Name : '';
            hoWrapObj.buildingName = String.isNotBlank(handover.Building_Phase__r.Name)? handover.Building_Phase__r.Name : '';
            hoWrapObj.OwnerName = String.isNotBlank(handover.Owner_Name__c) ? handover.Owner_Name__c : '' ;
            hoWrapObj.createdDate = String.valueOf(DateTime.valueOf(handover.CreatedDate));
            hoWrapList.add(hoWrapObj);
        }
        return hoWrapList;
    }
    
    @AuraEnabled    
    public static String sendBCCMailToCustomer(List<Id> unitIds) {
        HandoverBCCAndOrientationEmailBatch batch = new HandoverBCCAndOrientationEmailBatch(unitIds, HandoverConstants.BCC);
        Id batchJobId = Database.executeBatch(batch, 1);
        return BATCH_PROCESSING;
    }
    
    @AuraEnabled    
    public static String sendNOCMailToCustomer(List<Id> handoverIds) {
        System.debug('handoverIds'+handoverIds);
        HandoverBCCAndOrientationEmailBatch batch = new HandoverBCCAndOrientationEmailBatch(handoverIds, HandoverConstants.NOC);
        Id batchJobId = Database.executeBatch(batch, 50);
        return BATCH_PROCESSING;
    }
    
    @AuraEnabled    
    public static String sendOrientationMailToCustomer(List<Id> handoverIds){
        HandoverBCCAndOrientationEmailBatch batch = new HandoverBCCAndOrientationEmailBatch(handoverIds, HandoverConstants.Orientation);
        Id batchJobId = Database.executeBatch(batch, 1);
        return BATCH_PROCESSING;
    }
    
    
    public class UnitWrap
    {
        @AuraEnabled public String Id;
        @AuraEnabled public String handoverName;
        @AuraEnabled public String contentDocId;
        @AuraEnabled public String handoverCustomerEmail;
        @AuraEnabled public String unitName;
        @AuraEnabled public String unitStatus;
        @AuraEnabled public String activeSalesOrder;
        @AuraEnabled public String buildingName;
        @AuraEnabled public String OwnerName;
        @AuraEnabled public String createdDate;
    }
    
    public class HandoverWrap
    {
        @AuraEnabled public String Id;
        @AuraEnabled public String handoverName;
        @AuraEnabled public String contentDocId;
        @AuraEnabled public String handoverCustomerEmail;
        @AuraEnabled public String unitName;
        @AuraEnabled public String unitStatus;
        @AuraEnabled public String activeSalesOrder;
        @AuraEnabled public String buildingName;
        @AuraEnabled public String OwnerName;
        @AuraEnabled public String createdDate;
        @AuraEnabled public String SPADocId;
    }
    
    public class HandoverNOCWrap
    {
        @AuraEnabled public String Id;
        @AuraEnabled public String handoverName;
        @AuraEnabled public String handoverCustomerEmail;
        @AuraEnabled public String unitName;
        @AuraEnabled public String unitStatus;
        @AuraEnabled public String activeSalesOrder;
        @AuraEnabled public String buildingName;
        @AuraEnabled public String OwnerName;
        @AuraEnabled public String createdDate;
        @AuraEnabled public String SOADocId;
        @AuraEnabled public String QASnagDocId;
    }
}