/***
Class       : RaiseServiceRequestHandler
Author      : Smaartt
Description : 
TestClass   : RaiseServiceRequestHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              12/12/23           Initial Version  

****************************************************************************************************************/

public without sharing class RaiseServiceRequestHandler{
    
    @AuraEnabled(cacheable=true)
    public static String validationOnReceitpMaturityDate(String receiptId,Date newMaturidateValue){
        
        String message ='New Maturity Date should be more 10 days';
        List<ReceiptAcknowledgement__c>receiptList =[SELECT Id,Name,MaturityDate__c FROM ReceiptAcknowledgement__c where id=:receiptId ];
        if(receiptList[0].MaturityDate__c!=null && receiptList[0].MaturityDate__c.addDays(10)>=newMaturidateValue){
            return message;
        }
        
        return null;
        
    }
    
    @AuraEnabled(cacheable=true)
    public static String getreceipts(String SalesorderId){
        system.debug(SalesorderId);
        Integer rowIndex = 0;
        List<ReceiptWrap> recWrapList = new List<ReceiptWrap>();
        try {
            
            for(ReceiptAcknowledgement__c a : [SELECT Id,Name,PaymentType__c,ReferenceNumber__c,MaturityDate__c,Amount__c,SalesOrder__c,Status__c FROM ReceiptAcknowledgement__c where SalesOrder__c =: SalesorderId AND Status__c = 'Received' ]){
                recWrapList.add(new ReceiptWrap(a.Id,a.ReferenceNumber__c,a.Status__c,a.PaymentType__c,a.Amount__c,a.MaturityDate__c,rowIndex));
                rowIndex++;
            }
            return JSON.serialize(recWrapList);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    public class ReceiptWrap{
        public String Id;
        public String ReferenceNumber ;
        public String Status;
        public String type ;
        public Decimal Amount ;
        public Date MaturityDate;
        public Boolean isSelected;
        public Integer index;
        public ReceiptWrap(String Id,String ReferenceNumber ,String Status,String type,Decimal Amount,Date MaturityDate, Integer index){
            this.Id = Id;
            this.ReferenceNumber = ReferenceNumber;
            this.Status =Status;
            this.type = type;
            this.Amount = Amount;
            this.MaturityDate = MaturityDate;
            
            this.isSelected = false;
            this.index = index;
        }
        
    }
    @AuraEnabled
    public Static string CreateCaseWithServiceReqLines(Case caseinfo, List<Service_Request_Lines__c> SRLines,String caseRecordType){
        system.debug(caseinfo);
        system.debug(SRLines);
        String objectApiName = 'Case';        
        Id recordTypeIdofCase = Schema.SObjectType.Case.getRecordTypeInfosByName().get(caseRecordType).getRecordTypeId();
        
        Savepoint sp = Database.setSavepoint();
        caseinfo.RecordTypeId =recordTypeIdofCase;
        insert caseinfo;       
        for(Service_Request_Lines__c sr : SRLines){
            sr.Case__c = caseinfo.Id;
        }
        try{
            insert SRLines; 
            return caseinfo.Id;
        }catch(Exception e){   
            
            Database.rollback(sp);
            
            throw new AuraHandledException(e.getMessage());
            
            
        }               
    }
    @AuraEnabled
    public static Id createCaseComplaint(String recordTypeId,String caseSubstatus,String caseStatus, String caseType, String Description,String internalComments, String salesOrderId, String caseOwner, SalesOrderOtherCharges__c salesorderothercharge) {
        
        Id recordTypeIdofCase =Schema.SObjectType.Case.getRecordTypeInfosByName().get(recordTypeId).getRecordTypeId();
        //Id ownerId;
        
        if(caseOwner != null){
            //ownerId = [SELECT Id FROM User WHERE Name = :caseOwner LIMIT 1].Id;
            
            Case newCase = new Case(
                RecordTypeId = recordTypeIdofCase,
                Type = recordTypeId,
                SubType__c = caseType,
                Origin = 'Email',
                Description = Description,
                Comments = internalComments,
                Sales_Order__c = salesOrderId,
                //OwnerId = ownerId,
                Status= caseStatus,
                Subject=(Description != null && Description.length() > 250) ? Description.substring(0, 250) : Description,
                Case_Sub_Status__c = caseSubstatus
            );
            
            insert newCase;
            
            System.debug(salesorderothercharge);
            salesorderothercharge.Case__c = newCase.id;
            
            List<Salesorder__c>salesorderdetail = [Select id,Account__c From Salesorder__c Where id=:salesOrderId  LIMIT 1];
            
            
            
            salesorderothercharge.Account__c = salesorderdetail[0].Account__c;
            if(salesorderothercharge.Amount__c!=null ){
                insert salesorderothercharge;
            }
            
            
            return newCase.Id;
        }
        return null;
    }
    
    @AuraEnabled
    public static Id createCaseGeneral(String recordTypeId,String caseSubstatus,String caseStatus, String caseType, String Description,String internalComments, String salesOrderId, SalesOrderOtherCharges__c salesorderothercharge,List<String>joinwerOwnerids) {
        System.debug(joinwerOwnerids);
        Id recordTypeIdofCase = Schema.SObjectType.Case.getRecordTypeInfosByName().get(recordTypeId).getRecordTypeId();
        List<JointOwner__c>jointownerList = new List<JointOwner__c>();
        
        Case newCase = new Case(
            RecordTypeId = recordTypeIdofCase,
            Type = recordTypeId,
            SubType__c = caseType,
            Origin = 'Email',
            Description = Description,
            Comments = internalComments,
            Sales_Order__c = salesOrderId,
            
            Subject=(Description != null && Description.length() > 250) ? Description.substring(0, 250) : Description,
            Status= caseStatus,
            Case_Sub_Status__c = caseSubstatus            
        );
        
        insert newCase;
        
        if(salesorderothercharge != null && salesorderothercharge.Amount__c!=null){
            salesorderothercharge.Case__c = newCase.id;
            List<Salesorder__c>salesorderdetail = [Select id,Account__c From Salesorder__c Where id=:salesOrderId  LIMIT 1];
            if(salesorderdetail.size()>0)
                salesorderothercharge.Account__c = salesorderdetail[0].Account__c;
            insert salesorderothercharge;
            
        }
        try{
            if(joinwerOwnerids!=null){
                for(JointOwner__c jc: [Select id,Name,Case__c From JointOwner__c where id=:joinwerOwnerids]){
                    jc.Case__c = newCase.id;
                    jointownerList.add(jc);
                    
                }
            }
            if(jointownerList.size()>0){
                update jointownerList;
            }}
        catch (Exception e) {
            // Log the exception details for debugging
            System.debug('Error Message: ' + e.getMessage());
            System.debug('Error Stack Trace: ' + e.getStackTraceString());
            
            throw new AuraHandledException('An error occurred while updating JointOwner records. Please contact your administrator.');
        }
        
        return newCase.Id;
    }
    
    
    
    @AuraEnabled(cacheable=true)
    public static List<CaseTypeConfig__mdt> getCaseRecordTypes() {
        
        List<CaseTypeConfig__mdt>GetCaseAllrecordTypes = [SELECT id,Case_Type__c,MasterLabel FROM CaseTypeConfig__mdt];
        return GetCaseAllrecordTypes;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<CaseTypeConfig__mdt> getPicklistFieldValueOnCaseRecordType(String selectedRecordTypeId) {
        System.debug(selectedRecordTypeId);
        
        List<CaseTypeConfig__mdt> fieldValuesForRecordType = [SELECT Id, Case_Type__c, Case_Sub_Type__c,Case_status__c,Case_Sub_Status__c, Case_Reason__c,Default_Charge_Type__c,Default_Charge_Amount__c, MasterLabel 
                                                              FROM CaseTypeConfig__mdt 
                                                              WHERE Case_Type__c = :selectedRecordTypeId];
        
        System.debug('FieldValuesForRecordType: ' + fieldValuesForRecordType);
        return fieldValuesForRecordType;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Case_Creation_User_Config__mdt>getDefaultUserOnCaseSubType(String selectedRecordType,String caseSubtype) {
        
        
        List<Case_Creation_User_Config__mdt> fieldValuesForRecordType = [SELECT Id,Default_Owner__c,Record_Type__c, MasterLabel FROM Case_Creation_User_Config__mdt 
                                                                         WHERE Record_Type__c = :selectedRecordType AND MasterLabel=:caseSubtype];
        
        System.debug('FieldValuesForRecordType: ' + fieldValuesForRecordType);
        return fieldValuesForRecordType;
    }
    @AuraEnabled
    public static List<SalesOrder__c>getSalesordetailonRecord(string salesorderId) {
        List<Salesorder__c>salesorderdetail = [Select id,Name,Account__r.Name,Account__r.PersonMobilePhone,Account__r.PersonEmail From Salesorder__c where id=:salesorderId AND Account__r.isPersonAccount=true];
        if(salesorderdetail.size()>0)
            return salesorderdetail;
        else
            return null;
        
        
    }
    
    @AuraEnabled
    public static List<JointOwner__c>getSalesorderJointOwner(string salesorderId) {
        List<JointOwner__c>JointOwnerdetail = [Select id,Name,Account__r.Name,SharePercentage__c,SalesOrder__c From JointOwner__c where SalesOrder__c =:salesorderId AND IsActive__c=true];
        if(JointOwnerdetail.size()>0)
            return JointOwnerdetail;
        else
            return null;
        
        
    }
    @AuraEnabled
    public Static List<Case> caseduplicationcheck(string salesorderId,string casetype,string casesubtype){        
        Id caseRecId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(casetype).getRecordTypeId(); 
        List<Case> Clist = [Select id,CaseNumber,Sales_Order__c,RecordTypeid,Case_Sub_Status__c,Type,Status from case where Sales_Order__c =:salesorderId And RecordTypeId =:caseRecId And Type=:casesubtype And Status != 'Closed'];
        return Clist;                
        
    }
}