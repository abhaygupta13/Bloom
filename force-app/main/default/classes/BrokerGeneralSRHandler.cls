/*
* @Author : Samiksha Mahajan
* @CreatedDate : 9th Sept 2026
* @Description : Broker Related Service Request HAndler      
*/
/*****************************************************************************************************
* Version       Author          Date             Comment
* 1.0           Samiksha      09Sept2026

*****************************************************************************************************/
public class BrokerGeneralSRHandler {
 private static BrokerGeneralSRHandler instance;
    private static final string BROKER_GENERAL_REQUEST_RT { get { return 'Broker_General_Services'; } }
    private static final string MTD_BLOOM_PARTNER_EMAIL_TEMPLATE_ID {get { return 'BloomPartnerEmailTemplateID';}}
    private static final String MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
   
    
        public static BrokerGeneralSRHandler getInstance() { 
        if(instance == null) {
            instance = new BrokerGeneralSRHandler();
        }
        return instance;
    }
    
        public  void createFirstTask(List<Case> listOfCases) {
        ServiceRequestTaskHandler obj = ServiceRequestTaskHandler.getInstance();
        obj.createNewAndCloseCurrentTask(listOfCases);
    }
    
     public Case createCaseRecord(SalesOrder__c salesOrderObj, ServiceCatalog__c sc, Id accountId, Id unitId, String selectedType, String description, String origin, Boolean stopEmailsToCustomer) {
        AccountService accService = AccountService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        
        Case newCase = new Case();
        newCase.AccountId = salesOrderObj != null ? salesOrderObj.Account__c : accountId;
        newCase.Project__c = salesOrderObj != null ? salesOrderObj.Project__c : null;
        newCase.RecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, sc.RecordTypeDevName__c);
        newCase.Unit__c = salesOrderObj != null ? salesOrderObj.Unit__c : unitId;
        newCase.Origin = origin;
        newCase.ServiceCatalog__c = sc.Id;
        newCase.CaseType__c = selectedType;
        newCase.Description = description;
        newCase.SubType__c = sc.SubCategory__c;    
        newCase.Status = 'New';
        
       
                    
                    String subjectPrefix = 'Broker Enquiry';
        
        if (salesOrderObj != null ) {
            newCase.Subject = subjectPrefix + ' - ' + salesOrderObj.Account__r.Name +'-'+ salesOrderObj.Unit__r.Name;
            newCase.ContactId = accService.getRelatedContact(salesOrderObj.Account__r.Id);
            newCase.CustomerName__c = accService.getRelatedContactName(salesOrderObj.Account__r.Id);
            newCase.Sales_Order__c = salesOrderObj.Id;
            newCase.RequesterContactNumber__c = salesOrderObj.Account__r.isPersonAccount ? salesOrderObj.Account__r.PersonMobilePhone : null;
        }       
        else if(salesOrderObj == null){
            Datetime todaysDateTime = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day());
            String formattedinstallmentDate = todaysDateTime.format('dd-MM-yyyy');
            newCase.Subject = subjectPrefix + ' - ' + formattedinstallmentDate;
        }
        newCase.StopEmailsToCustomer__c = stopEmailsToCustomer;
        newCase = CaseService.getInstance().insertCase(newCase);
        return newCase; 
    }
       public String validateEligibility(Case caseObj){
        String message;
           
        return message;
    }
  
      
    public  Map<String, Object> validateCaseForNextReview(Case caseRecord) {
        CaseService caseServiceObj = CaseService.getInstance();
        Map<String, Object> response = new Map<String, Object>();
        response.put('status', 'success');
        response.put('message', 'Case has been updated successfully');
        
        if (caseRecord == null) {
            response.put('status', 'error');
            response.put('message', 'Invalid Case ID.');
            return response;
        }
        if(caseRecord.RequesterName__c == null || caseRecord.RequesterEmail__c == null || caseRecord.Requester_Phone__c == null || caseRecord.Description == null){
            response.put('status', 'error');
            response.put('message', 'Please fill all the required Information : Name,Email,Phone and Description');
            return response;
           }
               
        if(response.get('status') == 'success'){
            if(caseRecord.Step__c == '1'){
                
            //    sendBloomPartnerEmail(new List<Case>{caseRecord});
                ServiceRequestTaskHandler.getInstance().createNewAndCloseCurrentTask(new List<Case>{caseRecord});
               // AssignmentRuleHandler.genericCaseAssignmentBAPP((new List<Id>{caseRecord.Id}));
            sendBloomPartnerEmail(new List<Case>{caseRecord});
            }
            else{
                
                ServiceRequestTaskHandler.getInstance().createNewAndCloseCurrentTask(new List<Case>{caseRecord});
                
                
            }
        }
        
        if (response.get('status') == 'error') {
            return response;
        }
        return response;
    }
    public void sendBloomPartnerEmail(List<Case> caseList) {

    MetadataService objMetadataService = MetadataService.getInstance();
    EmailService objEmailService = EmailService.getInstance();
    AccountService accService = AccountService.getInstance();

    Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
    Id emailTemplateId = objMetadataService.getAppSettingTextValue(MTD_BLOOM_PARTNER_EMAIL_TEMPLATE_ID);

    List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();

    for(Case caseObj : caseList){
        String customerEmail = caseObj.RequesterEmail__c;

        List<String> toAddress = new List<String>{ customerEmail };

        Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessageWithoutTargetObjectId(emailTemplateId,noReplyOWDId,caseObj.Id,toAddress,null,null);

        if(email != null){
            emailList.add(email);
        }
    }

    //if(!emailList.isEmpty()){
        objEmailService.sendEmail(emailList);
   // }
}
}