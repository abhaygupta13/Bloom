public without sharing class PdfControllerHelper {
    public Case caseRecord { get; set; }

    // Constructor for Visualforce Pages
    public PdfControllerHelper(ApexPages.StandardController controller) {
     List<Case> rec = [SELECT id from Case WHERE recordType.name ='Access Permit' AND ParentId !=NULL ORDER by createddate DESC LIMIT 1];
        if(rec.size() >0){
        initializeCase(rec[0].Id);
        }
    }

    // Constructor for Apex Calls
    public PdfControllerHelper(Id recordId) {
        initializeCase(recordId);
    }

    // Common method to fetch Case data
    private void initializeCase(Id recordId) {
        try {
            if (recordId != null) {
                caseRecord = [
                    SELECT Id, CaseNumber, Community_Name__c, Building_Phase__c, Unit_Name_Formula__c, 
                           Access_Permit_Preferred_Date__c, Permit_From_Date__c, Customer_Name__c,Permit_Expiry_Date__c,
                           Access_Permit_Company__c, Access_Permit_Category__c, Access_Permit_Description__c 
                    FROM Case WHERE Id = :recordId LIMIT 1
                ];
            } 
        } catch (Exception e) {
            System.debug('Exception in fetching Case record: ' + e.getMessage());
        }
    }
}