Public without sharing class SearchControllerFmApp {

  public SearchControllerFmApp(){
       
        String appAuthHeader = ApexPages.currentPage().getHeaders().get('X-App-Auth');
         System.debug('appAuthHeader1==='+appAuthHeader);
      	List<User__c> lstUser = [select Id from User__c where Azure_UserId__c=:appAuthHeader];
		if (appAuthHeader == null || lstUser.isEmpty()) {
            // Invalid or missing token, restrict access
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unauthorized access.'));
            // Optionally, redirect or log the access attempt
            throw new AuraHandledException('Access restricted to the mobile app.');
        }
    }
    @AuraEnabled(cacheable=false)
    public static String getAuthHeader() {
        String appAuthHeader = ApexPages.currentPage().getHeaders().get('X-App-Auth');
        System.debug('appAuthHeader2==='+appAuthHeader);
        return appAuthHeader;
    }
    @AuraEnabled(cacheable=true)
    public static List<Case> searchRecords(String searchTerm, String loginuserId, String permitType) {
    List<Case> checkinPermitCases=new List<Case>();
    List<Case> checkoutPermitCases=new List<Case>();
    Id accessPermitRT = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Access_Permit').getRecordTypeId();
    
    if (String.isBlank(searchTerm)) {
        return new List<Case>();
    }
    // Prepare SOQL query
    String searchQuery = '%' + searchTerm + '%';
    Boolean isCheckin = (permitType == 'checkin');
    // Query cases based on criteria
    List<Case> cases = [
        SELECT Id, Project__r.Gate_Name__c, Request_Number__c, Unit_Name_Formula__c,Permit_Validaity__c,
               Access_Permit_Category__c, ParentId, Access_Permit_Company__c,ParentRequestNumber__c,Frequency__c,
               Case_Sub_Status__c, Status, Service_Request_Category__c,Parent.Request_Number__c,Visitor_Checkout_Time__c
        FROM Case
        WHERE recordTypeId =:accessPermitRT
              AND ((Unit__r.Name LIKE :searchQuery )OR (Request_Number__c LIKE :searchQuery) Or 
              (Parent.Request_Number__c LIKE :searchQuery))
    ];

        for(Case rec:cases){             
            System.debug('SearchRecord');   
            if(isCheckin && rec.parentid==NULL && rec.Status=='Submitted' &&
             (rec.Frequency__c=='One time' || rec.Permit_Validaity__c=='1' || rec.Access_Permit_Category__c=='Delivery')){
                    checkinPermitCases.add(rec);
            }else if(isCheckin && rec.parentid==NULL && rec.Status=='Approved' && rec.Frequency__c=='Recurring' &&
                    (rec.Case_Sub_Status__c=='Checked Out' || rec.Case_Sub_Status__c=='Pending Check-In')){
                    checkinPermitCases.add(rec);
            }else if(!isCheckin && rec.parentid!=NULL  && rec.Status=='Approved' && rec.Visitor_Checkout_Time__c==NULL && 
                    rec.Case_Sub_Status__c=='Checked-in'){
                 checkoutPermitCases.add(rec);
            }
        }
        return (isCheckin) ? checkinPermitCases : checkoutPermitCases;
    }

	@AuraEnabled(cacheable=true)
    public static case getCaseDetails(Id caseId) {
        return [
            SELECT Id, Unit_Name_Formula__c,Service_Types__c,Request_Number__c,Unit_Name__c,Community_Name__c,
            CaseNumber,User_Type__c,Customer_Name__c,Case_Sub_Status__c,
            Access_Permit_Company__c,Status,
            Permit_Validaity__c,CreatedDate,LastModifiedDate,
            Access_Permit_Category__c,Unit__r.BuildingSectionName__r.Name,Access_Permit_Preferred_Date__c,
            Visitor_Plate_Number__c,Visitor_Mobile_Number__c,Visitor_Plate_Source__c,Frequency__c,
            Visitor_Plate_Code__c,Visitor_Emirates_ID__c,Visitor_Trade_license_expiry_date__c,Permit_Expiry_Date__c,
            Account.Name,Origin,Unit__r.Project__r.Gate_Name__c,Access_Permit_Description__c FROM Case
            WHERE Id = :caseId
        ];
    }
    @AuraEnabled
    public static void saveCheckoutDetails(Id caseId,boolean checkoutTime) {
         List<Case> updateCase=new List<Case>();
         Id ParentId;
         for (Case rec:[SELECT id,Visitor_Check_in_Time__c,ParentId,Status,Parent.Access_Permit_Category__c,Permit_Validaity__c,
                       Parent.Frequency__c,parent.Permit_To_Date__c From Case Where
                       Id=:caseId ]){
                if(rec.Visitor_Check_in_Time__c !=NULL){
                    rec.Visitor_Checkout_Time__c=Datetime.valueof(System.now().addHours(4).format('yyyy-MM-dd HH:mm:ss', UserInfo.getTimeZone().getID()));
                    rec.status='Closed';
                    updateCase.add(rec);
                    ParentId=rec.ParentId;
                }
                if((rec.Parent.Access_Permit_Category__c == 'Delivery' ||
                   (rec.Parent.Access_Permit_Category__c == 'Maintenance'  && (rec.Parent.Frequency__c=='One time' || rec.Permit_Validaity__c=='1'))  ||  
                    rec.Parent.Access_Permit_Category__c == 'Soft services' && rec.Parent.Frequency__c=='One time')){
                    updateCase.add(New Case(Id=rec.ParentId ,status='Closed',Case_Sub_Status__c='Checked Out'));
                }else if(rec.Parent.Frequency__c=='Recurring'){
                    Case record=new Case();
                    record.id=ParentId;
                    record.Case_Sub_Status__c='Checked Out';
                    if(rec.Parent.Permit_To_Date__c==System.today()){
                        record.status='Closed';
                    }
                     updateCase.add(record);
                }
          } 
          try{
               update updateCase;
          }Catch(Exception e){ 
            system.debug('Errorr-->'+e);
          }
    }
    @AuraEnabled
	public static String saveCaseDetails(CaseDetailsWrapper details) {
    Case getCase; 
    Boolean isOneTime=False;
    if(details.actionlevel=='Approved'){

        if (String.isBlank(details.emiratesId)) {
          throw new MyCustomException('Emirates ID is required.');
        }
        if (String.isBlank(details.plateSource)) {
             throw new MyCustomException('Plate Source is required.');
        }
        if (String.isBlank(details.plateCode)) {
            throw new MyCustomException('Plate Code is required.');
        }
        if (String.isBlank(details.plateNumber)) {
            throw new MyCustomException('Plate Number is required.');
        }
        if (String.isBlank(details.mobileNumber)) {
            throw new MyCustomException('Mobile Number is required.');
        }
        if(details.mobileNumber.length() != 9 && details.mobileCode=='+971 (UAE)') {
            throw new MyCustomException('Mobile Number should be 9 digit.');
        }
    }
    Case caseRecord = [
                       SELECT Access_Permit_Case_Count__c, Access_Permit_Category__c, Access_Permit_Preferred_Date__c,
                       Frequency__c,Permit_Validaity__c,Permit_Expiry_Date__c
                       FROM Case 
                       WHERE Id = :details.caseId Limit 1
                       ];
    if(caseRecord.Permit_Expiry_Date__c != null && caseRecord.Permit_Expiry_Date__c <System.today() ){
         throw new MyCustomException('Permit Expiry date is in the past.');
    }
    if((caseRecord.Access_Permit_Category__c == 'Delivery' ||
        (caseRecord.Access_Permit_Category__c == 'Maintenance'  && caseRecord.Frequency__c=='One time')  ||  
         caseRecord.Access_Permit_Category__c == 'Soft services' && caseRecord.Frequency__c=='One time')){
          isOneTime=True;
      }
        String caseRecordId =createCases(details,isOneTime);
        return caseRecordId;
    }

    public static string createCases(CaseDetailsWrapper details,Boolean isOneTime){
    List<case> updateCase=New List<case>();
            // Fetch the original case record
            Case originalCase = [SELECT 
                                    Subject, Unit__c,Project__c,Building_Phase__c,RequestType__c,
                                    Description, User_Type__c,Service_Catalog__c,Access_Permit_Company__c,
                                    Status, Service_Request_Category__c,RecordTypeId,Access_Permit_Description__c,
                                    Priority,Permit_From_Date__c,Permit_To_Date__c,Access_Permit_Category__c,Service_Types__c,
                                    Origin, Frequency__c,Permit_Validaity__c,Access_Permit_Preferred_Date__c,
                                    Type, 
                                    AccountId, 
                                    ContactId
                                 FROM Case 
                                 WHERE Id = : details.caseId
                                 LIMIT 1];

            // Clone the case and clear non-clonable fields
            Case newCase = originalCase.clone(false);  // false to avoid deep cloning of related lists
            newCase.Status = 'New'; // Set status to default for new cases
            newCase.Visitor_Trade_license_expiry_date__c = details.tradeCommercialNumber;
            newCase.Visitor_Emirates_ID__c = details.emiratesId;
            newCase.Visitor_Mobile_Number__c=details.mobileCode+'-'+details.mobileNumber;
            newCase.Status=details.actionlevel;
            newCase.Visitor_Plate_Code__c=details.plateCode;
            newCase.Visitor_Plate_Number__c=details.plateNumber;
            newCase.Visitor_Plate_Source__c=details.plateSource;
            newCase.ParentId=details.caseId;
            newCase.Visitor_Check_in_Time__c = Datetime.valueof(System.now().addHours(4).format('yyyy-MM-dd HH:mm:ss', UserInfo.getTimeZone().getID()));
            newCase.RecordtypeId=originalCase.RecordtypeId;
            newCase.Type='Gate Pass';
            newCase.Case_Sub_Status__c = 'Checked-in';
        try{ 
            if(details.actionlevel !='Rejected'){
                  insert newCase;
            }
            
           
            if((isOneTime || originalCase.Permit_Validaity__c=='1' || originalCase.Access_Permit_Category__c=='Delivery') &&
               (details.actionlevel !='Rejected')){
                    Case rec=new case(id=details.caseId,Status='Approved',Case_Sub_Status__c='Checked-in');
                    update rec;
            }
            if(originalCase.Frequency__c=='Recurring'){
                    Case rec=new case(id=details.caseId,Case_Sub_Status__c='Checked-in');
                    update rec;
            }
            if(details.actionlevel=='Rejected' && (isOneTime || originalCase.Permit_Validaity__c=='1' || originalCase.Access_Permit_Category__c=='Delivery')){
                 Case rec=new case(id=details.caseId,Status='Rejected',Rejection_Reason__c='Details are not proper');
                 update rec;
            }
            return newCase.Id;
        }catch (Exception e) {
            throw new AuraHandledException('Error cloning case: ' + e.getMessage());
        }
       
    }
@AuraEnabled(cacheable=true)
    public static List<case> getchildCases(id parentcaseId){
        return [SELECT id, Visitor_Checkout_Time__c,Visitor_Check_in_Time__c,
                Visitor_Mobile_Number__c,
                Visitor_Emirates_ID__c,Visitor_Plate_Number__c From 
                case WHERE parentid=:parentcaseId Order by createddate ASC];
    }
  public class CaseDetailsWrapper {
    @AuraEnabled
    public String tradeCommercialNumber { get; set; }
    @AuraEnabled
    public String emiratesId { get; set; }
    @AuraEnabled
    public String vechilePlate { get; set; }
    @AuraEnabled
    public String mobileNumber { get; set; }
    @AuraEnabled
    public String mobileCode { get; set; }
    @AuraEnabled
    public String actionlevel { get; set; }
    @AuraEnabled
    public String checkinTime { get; set; }
    @AuraEnabled
    public String caseId { get; set; }
    @AuraEnabled
    public String plateNumber { get; set; }
    @AuraEnabled
     public String plateSource { get; set; }
    @AuraEnabled
     public String plateCode { get; set; }
    @AuraEnabled
    public List<String> contentDocumentIds { get; set; }

    public CaseDetailsWrapper() {}

    public CaseDetailsWrapper(String tradeCommercialNumber, String caseId,String mobileNumber,String mobileCode,String EmiratesId,
                              String VechilePlate, List<String> contentDocumentIds,String actionlevel,String checkinTime) {

            this.tradeCommercialNumber = tradeCommercialNumber;
            this.EmiratesId = EmiratesId;
            this.VechilePlate = VechilePlate;
            this.mobileNumber = mobileNumber;
            this.caseId = caseId;
            this.contentDocumentIds = contentDocumentIds;
            this.actionlevel=actionlevel;
            this.mobileCode=mobileCode;
            this.checkinTime=String.valueof(DateTime.now());
    }
  }
  @AuraEnabled(cacheable=true)
    Public static list<ContentDocument> getDocument(String recordId){
     Set<id> ContentDocumentId= New Set<Id>();
        for(ContentDocumentLink rec:[SELECT ContentDocumentId FROM contentDocumentLink WHERE LinkedEntityId=:recordId]){
                                     ContentDocumentId.add(rec.ContentDocumentId);
        }
        return [SELECT id,Title FROM ContentDocument WHERE id=:ContentDocumentId];
  }
   public class MyCustomException extends Exception {}

}