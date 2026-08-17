/*****************************************************************************************
Class       : ProjectService
Author      : Biswajeet
Description : Project service class
Test Class  : ProjectServiceTest
Created Date: 29 AUG 2024
*****************************************************************************************/
public inherited sharing class ProjectService {
    
    private static ProjectService instance;
    
    private ProjectService() {}
    public static ProjectService getInstance() { 
        if(instance == null) {
            instance = new ProjectService();
        }
        return instance;
    }
    
    public  List<Project__c> fetchProjects(Boolean isEnableMIP){
        
        String query = 'SELECT Name, Community_Image_Url__c FROM Project__c WHERE isEnabledMIP__c=true';
        
        /*if (isEnableMIP != null && isEnableMIP) {
query += ' WHERE isEnabledMIP__c=true';
}
*/
        
        
        return Database.query(query);
        
    }
    
    public  List<Project__c> getCommunityAppProjects(){
        return [select Id, Name, Community_Image_Url__c FROM Project__c WHERE AvailableForCommunityApp__c = true];
    }
    
    //get Projects by Ids
    public List<Project__c> getProjectsByIds(Set<Id> projectIds){
        return [SELECT Id, HandoverNoticeCalculationDays__c,IsByPassHOStatus__c, Contractor__c, ChequeWithdrawalFee__c
                FROM Project__c WHERE Id IN: projectIds];            
    }
    
    //get Projects by Ids
    public Map<Id, Project__c> getProjectsByIdsMap(Set<Id> projectIds){
        Map<Id, Project__c> projectMap = new Map<Id, Project__c>([SELECT Id, HandoverNoticeCalculationDays__c, Contractor__c FROM Project__c WHERE Id IN: projectIds]);
        return projectMap;            
    }
    
    //Update Project
    public Project__c updateProject(Project__c project){
        if(project != NULL){
            update project;
        }
        return project;
    }
    
    //Update Projects
    public List<Project__c> updateProjects(List<Project__c> projectList){
        if(projectList != NULL && !projectList.isEmpty()){
            update projectList;
        }
        return projectList;
    }
    
    
    public List<Project__c> getProjects(){
        return [SELECT Id, Name, ProjectNameArabic__c FROM Project__c WHERE IsAvailableForSales__c = true ORDER BY Name];
    }
    
    public List<Project__c> getActiveProjects(){
        return [SELECT Id, Name FROM Project__c WHERE IsActive__c = true  WITH SECURITY_ENFORCED ORDER BY Name];
    }
    public Project__c getProjectDetailsWithUnitsAndDocuments(String projectRecordId, String salesOrderStatus, String documentName){
        return [SELECT Id, Name, ProjectRegistrationDate__c, ProjectRegistrationRemark__c, ProjectRegistrationNumber__c,
                (SELECT Id, Name, RegistrationDate__c, Active_Sales_Order__c, ADM_Fee_Included__c, Active_Sales_Order__r.Name, Active_Sales_Order__r.SoldDate__c, 
                 Status__c, Active_Sales_Order__r.UnitRegistrationDate__c, Active_Sales_Order__r.DocumentUploadedDate__c, ADMPlotNumber__c,
                 Active_Sales_Order__r.FundMovedToGRDate__c, Active_Sales_Order__r.ADM_Fee_Included__c,Active_Sales_Order__r.Status__c
                 FROM UnitsProject__r) /*, 
WHERE Active_Sales_Order__c != null AND Active_Sales_Order__r.Status__c != null), 
(SELECT Id, Name, Project__c, ContentDocumentId__c, DocumentType__r.Type__c
FROM Documents__r 
WHERE ContentDocumentId__c != null AND DocumentType__c != null AND Document_Name__c =:documentName)*/
                FROM Project__c 
                WHERE Id = :projectRecordId];
    }
    public Project__c getProjectWithSoldUnits(String projectRecordId, String salesOrderStatus){
        return [SELECT Id, Name, ProjectRegistrationDate__c, ProjectRegistrationRemark__c,
                (SELECT Id, Name, RegistrationDate__c, Active_Sales_Order__c, ADM_Fee_Included__c, Active_Sales_Order__r.Name, Active_Sales_Order__r.SoldDate__c, 
                 Status__c, Active_Sales_Order__r.UnitRegistrationDate__c, Active_Sales_Order__r.DocumentUploadedDate__c, ADMPlotNumber__c,
                 Active_Sales_Order__r.FundMovedToGRDate__c, Active_Sales_Order__r.ADM_Fee_Included__c, Active_Sales_Order__r.Status__c, Active_Sales_Order__r.ADMFeeAmount__c, Active_Sales_Order__r.FundMovedtoGR__c,
                 Active_Sales_Order__r.ADM_Fee_Cleared_Amount__c, Active_Sales_Order__r.ADMFeeWaivedAmount__c
                 FROM UnitsProject__r 
                 WHERE Active_Sales_Order__c != null AND Active_Sales_Order__r.Status__c = :salesOrderStatus AND Active_Sales_Order__r.FundReleaseRequested__c = TRUE AND Active_Sales_Order__r.FundMovedToGRDate__c = null)
                FROM Project__c 
                WHERE Id = :projectRecordId];
    }
    
    public Project__c getProjectWithUnits(String projectRecordId, String salesOrderStatus){
        return [SELECT Id, Name, ProjectRegistrationDate__c, ProjectRegistrationRemark__c,
                (SELECT Id, Name, RegistrationDate__c, Active_Sales_Order__c, ADM_Fee_Included__c, Active_Sales_Order__r.Name, Active_Sales_Order__r.SoldDate__c, 
                 Status__c, Active_Sales_Order__r.UnitRegistrationDate__c, Active_Sales_Order__r.DocumentUploadedDate__c, ADMPlotNumber__c,
                 Active_Sales_Order__r.FundMovedToGRDate__c, Active_Sales_Order__r.Status__c
                 FROM UnitsProject__r 
                 WHERE Active_Sales_Order__c != null AND Active_Sales_Order__r.Status__c = :salesOrderStatus)
                FROM Project__c 
                WHERE Id = :projectRecordId];
    }
    
    public List<Project__c> getProjectsNBankAccounts(Set<Id> projectIdList){
        return [SELECT Id, Name,(SELECT Id,Name,BankNameCorporate__c,AccountNumberCorporate__c,IBANNoCorporate__c,SwiftCodeCorporate__c,Primary_for_Installment__c,Type__c FROM Bank_Accounts1__r) FROM Project__c WHERE Id IN:projectIdList];
    }
    public List<Project__c> getLeasingProjects(){
        return [SELECT id,Name,EjariTawtheeqFee__c,AdminFee__c,SecurityDeposit__c,LeasingApartmentSecurityDepositAmount__c,
                LeasingVillaSecurityDepositAmount__c,Leasing_Company__r.LeasingSAPCompanyCode__c,
                LeasingServiceCharge__c,City__c from Project__c where IsAvailableforLeasing__c = true order by Name];
    }
    
    public static List<Project__c> fetchProjectsByIds(Set<Id> projectIds) {
        if (projectIds.isEmpty()) return new List<Project__c>();
        return [
            SELECT Id, Name, Office_Location__c, Amenities__c, IsPublic__c, IsAvailableForBroker__c, OccupiedLeasingUnits__c, TotalLeasingUnits__c
            FROM Project__c
            WHERE Id IN :projectIds
        ];
    }
    
    public List<Project__c>getAvailableHandoverProject() {
        return [SELECT id,Name FROM Project__c where isHandoverAvailable__c=true];
    }
    
    //prashant
    public Project__c getADHAProjectById(String adhaProjectId){
        Project__c objProject = [ SELECT Id, Name, ADHAProjectID__c FROM Project__c WHERE ADHAProjectID__c = :adhaProjectId LIMIT 1 ];
        return objProject;
    }
}