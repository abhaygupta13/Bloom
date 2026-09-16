/*****************************************************************************************
Class       : HandoverService
Author      : Rajat Rastogi
Description : Service class for handling Handover related operations.
Created Date: 02 SEP 2024
*****************************************************************************************/
public inherited sharing class HandoverService {
    
    private static HandoverService instance;
    
    private HandoverService(){
        
    }
    
    public static HandoverService getInstance() {
        if(instance == null) {
            instance = new HandoverService();
        }
        return instance;
    }

    private Boolean isAuthorizedUser() {
        Profile userProfile = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()];
        return userProfile.Name == 'CRM Operations' || userProfile.Name == 'HO Manager'|| userProfile.Name == 'System Administrator';
    }
    
    public List<Handover__c> getHandoverByUnitId(Id unitId) {
        return [SELECT Id,Englishformatteddate__c,unit__r.UnitNumber__c,Name,Unit__r.ADMAddressingNumber__c,Unit__r.Name,Account__r.Name,Account__r.NameinArabic__c,
                Unit_Plot_Number__c,Unit__r.DoorNumber__c, Unit__c,Unit__r.Status__c, Unit__r.SAP_Unit_Number__c, Sub_Status__c, 
                Customer_Email__c,CustomerEmail__c, Customer_Name__c, Is_BCC_Announcement_Sent__c, 
                Project__r.Name, Account_Manager_Name__c, Account_Manager_Email__c, Sales_Order__r.Status__c,
                Account_Manager_Phone__c, Project__c, Project__r.ProjectNameArabic__c, 
                Customer_Name_Arabic__c, Is_Notice_of_Completion_Sent__c, Drawloop_Next_1__c,Lease_Type__c,Lease_Amount__c,Lease_End_Date__c,
                CRM_Team_Assigned_User__r.Name_In_Arabic__c,Project_Name_Arabic__c,Project_Name__c,AccountManagerEmail__c,
                Location__c,Customer_Number__c,Bloom_Email__c,Bloom_Phone__c,Is_Manual__c,PropertyHomeOrientationByBloom__c,
                PropertyHomeOrientationReport_Sent__c,PropertyHomeOrientationWOCustomer__c,HasCHODesnaggingemailsent__c,
                Address__c, NOC_Date__c,SettlementFollowUpDate__c, HO_Agent_Assigned_User__c, Payment_Type__c,
                ProjectbyFormula__c, ProjectName__c,ProjectNameArabic__c,BuildingPhase__c, Is_Appointment_Booked__c,
                RecordTypeId, ServiceCatalog__c, PendingWithDepartment__c, OwnerId, Customer_Availability_for_CHO__c,
                HomeOrientationInvitationDate__c,HO_DD_MM_YYYY__c,Location_Name__c,Date__c,Unit_Code__c,
                Sales_Order__c, Previous_HO_Status__c, Current_User_Profile__c, Unit_Type__c, Handover_Phase__r.ExcludedHandoverStages__c,
                Handover_Phase__r.SkipHandoverCHOTasks__c, HandoverType__c
            FROM Handover__c WHERE Unit__c = :unitId LIMIT 1];
    }

    public List<Handover__c> getHandoverforDoorClarification(List<Id>recordIds) {
        return [SELECT Id, unit__r.UnitNumber__c, Account__r.Name, Unit__r.ADMAddressingNumber__c, Account__r.NameinArabic__c, Name, Unit__r.Name, Unit_Plot_Number__c, Unit__r.DoorNumber__c, Unit_Code__c, ProjectNameArabic__c, ProjectName__c, 
                Customer_Name__c, Sub_Status__c, Account_Manager_Name__c, 
                Account_Manager_Email__c, Account_Manager_Phone__c, 
                HO_DD_MM_YYYY__c, Location__c, Location_Name__c, Date__c, 
                CustomerEmail__c, Promise_to_Pay_Date__c, Customer_Number__c, 
                Address__c, Project__r.Handover_Community_Guidelines_English__c, 
                Project__r.Handover_Community_Guidelines_Arabic__c, 
                NOC_Expiry_Date__c, Purchase_Price__c, SettlementFollowUpDate__c, 
                NOC_Date__c, HomeOrientationInvitationDate__c, Customer_Name_Arabic__c, 
                ProjectbyFormula__c, Account_Manager_Name_Arabic__c, 
                LocationName__c, BloomPhone__c, BloomEmail__c, Sales_Order__c,
                Is_Notice_of_Completion_Sent__c, HasDoorNumberEmailSent__c
                FROM Handover__c 
                WHERE Id IN :recordIds 
                AND Is_Notice_of_Completion_Sent__c = true 
                AND HasDoorNumberEmailSent__c = false];
        
    }
    
    public Handover__c getHandoverRecordById(Id recordId) {
        return [SELECT Id,FinanceTeamAssingedUser__c, Name, Unit__c,Unit__r.Status__c, Unit__r.SAP_Unit_Number__c, Sub_Status__c, 
                Customer_Email__c,CustomerEmail__c, Customer_Name__c, Is_BCC_Announcement_Sent__c, 
                Project__r.Name, Account_Manager_Name__c, Account_Manager_Email__c, Sales_Order__r.Status__c,
                Account_Manager_Phone__c, Project__c, Project__r.ProjectNameArabic__c, Payment_Settled__c, Payment_Date__c,
                Customer_Name_Arabic__c, Is_Notice_of_Completion_Sent__c, Drawloop_Next_1__c,
                CRM_Team_Assigned_User__r.Name_In_Arabic__c,Project_Name_Arabic__c,Project_Name__c,AccountManagerEmail__c,
                Location__c,Customer_Number__c,Bloom_Email__c,Bloom_Phone__c,Is_Manual__c,CongratulationOnHandoverEmailsent__c,
                PropertyHomeOrientationReport_Sent__c,KeyHandoverInvitationSent__c,PropertyHomeOrientationByBloom__c,
                PropertyHomeOrientationWOCustomer__c,HasCHODesnaggingemailsent__c,Lease_Type__c,Lease_Amount__c,Lease_End_Date__c,
                Address__c, NOC_Date__c,SettlementFollowUpDate__c, HO_Agent_Assigned_User__c, Payment_Type__c,
                ProjectbyFormula__c, ProjectName__c,ProjectNameArabic__c,BuildingPhase__c, Is_Appointment_Booked__c,
                RecordTypeId, ServiceCatalog__c, PendingWithDepartment__c, OwnerId, Customer_Availability_for_CHO__c,
                HomeOrientationInvitationDate__c,HO_DD_MM_YYYY__c,Location_Name__c,Date__c,Unit_Code__c,
                Sales_Order__c, Previous_HO_Status__c, Current_User_Profile__c, Unit_Type__c,
                Property_Enrollment_Under_Tawtheeq_Accou__c, Property_Enrollment_Under_Tawtheeq__c, Account__c,
                Handover_Phase__r.ExcludedHandoverStages__c, Handover_Phase__r.SkipHandoverCHOTasks__c,
                HandoverType__c
                FROM Handover__c WHERE Id = :recordId LIMIT 1];
    }
    
    public List<Handover__c> getHandoversByIds(List<Handover__c> handoverIds) {
        return [SELECT Id, Name,NOC_Expiry_Date__c,Unit__r.Status__c, Unit__c,Project__r.Handover_Community_Guidelines_English__c,Project__r.Handover_Community_Guidelines_Arabic__c, Unit__r.SAP_Unit_Number__c, Sub_Status__c, 
                Customer_Email__c,CustomerEmail__c, Customer_Name__c, Project__r.Name, 
                Account_Manager_Name__c, Home_Orientation_Invitation_Date__c, 
                Promise_to_Pay_Date__c, Account_Manager_Email__c, Drawloop_Next_1__c,
                Account_Manager_Phone__c, Project__c, Project__r.ProjectNameArabic__c, 
                Customer_Name_Arabic__c, CRM_Team_Assigned_User__r.Name_In_Arabic__c, 
                Project__r.Office_Location__c, Account_Manager_Name_Arabic__c, 
                Notice_of_Completion_Date__c, Settlement_Follow_Up_Date__c, 
                Sales_Order__r.Account__r.PersonMailingCountry, Sales_Order__r.Account__r.Phone, 
                Sales_Order__r.Account__r.MobileCountryCode__pc, Payment_Settled__c, Payment_Date__c,
                Project_Name_Arabic__c,Project_Name__c,AccountManagerEmail__c,
                Location__c,Customer_Number__c,Bloom_Email__c,Bloom_Phone__c, Sales_Order__c,
                Address__c, NOC_Date__c,SettlementFollowUpDate__c,Lease_Type__c,Lease_Amount__c,Lease_End_Date__c,
                CongratulationOnHandoverEmailsent__c,PropertyHomeOrientationReport_Sent__c,KeyHandoverInvitationSent__c,
                PropertyHomeOrientationByBloom__c,PropertyHomeOrientationWOCustomer__c,HasCHODesnaggingemailsent__c,
                HomeOrientationInvitationDate__c,HO_DD_MM_YYYY__c,Location_Name__c,Date__c,Unit_Code__c,
                ProjectbyFormula__c, ProjectName__c,ProjectNameArabic__c,BuildingPhase__c,Handover_Phase__r.ExcludedHandoverStages__c,
                Handover_Phase__r.SkipHandoverCHOTasks__c, HandoverType__c
                FROM Handover__c WHERE Id IN :handoverIds];
    }
    
    public Handover__c getHandoverById(Id handoverId) {
        return [SELECT Id, Name,FinanceTeamAssingedUser__c,Englishformatteddate__c,IsOustandingPaymentconfirmedsent__c,IsHandoverSigningInvitationSent__c,Project__r.BloomPhoneArabic__c,Unit_Plot_Number__c,Unit__r.DoorNumber__c,Unit__r.Status__c,ProjectName__c,Sub_Status__c,ProjectNameArabic__c,BuildingPhase__c,LocationName__c,
                BloomPhone__c,BloomEmail__c,NOC_Expiry_Date__c, Unit__c,Project__r.Handover_Community_Guidelines_English__c,
                Project__r.Handover_Community_Guidelines_Arabic__c, Unit__r.SAP_Unit_Number__c, 
                Customer_Email__c,CustomerEmail__c, Customer_Name__c, Project__r.Name, 
                Account_Manager_Name__c, Home_Orientation_Invitation_Date__c, 
                Promise_to_Pay_Date__c, Account_Manager_Email__c, Drawloop_Next_1__c,
                Account_Manager_Phone__c, Project__c, Project__r.ProjectNameArabic__c, 
                Customer_Name_Arabic__c, CRM_Team_Assigned_User__r.Name_In_Arabic__c, 
                Project__r.Office_Location__c, Account_Manager_Name_Arabic__c, 
                Notice_of_Completion_Date__c, Settlement_Follow_Up_Date__c, Payment_Settled__c, Payment_Date__c,
                Sales_Order__r.Account__r.PersonMailingCountry, Sales_Order__r.Account__r.Phone, 
                Sales_Order__r.Account__r.MobileCountryCode__pc,Unit_Code__c,Lease_Type__c,Lease_Amount__c,Lease_End_Date__c,
                CongratulationOnHandoverEmailsent__c,PropertyHomeOrientationReport_Sent__c,KeyHandoverInvitationSent__c,
                PropertyHomeOrientationByBloom__c,PropertyHomeOrientationWOCustomer__c,HasCHODesnaggingemailsent__c,
                Project_Name_Arabic__c,Project_Name__c,AccountManagerEmail__c,
                Location__c,Customer_Number__c,Bloom_Email__c,Bloom_Phone__c,HO_Agent_Assigned_User__c,
                Address__c, NOC_Date__c,SettlementFollowUpDate__c,OwnerId,
                HomeOrientationInvitationDate__c,HO_DD_MM_YYYY__c,Location_Name__c,Date__c,ServiceCatalog__c,
                Previous_HO_Status__c, Customer_Availability_for_CHO__c, Handover_Phase__r.ExcludedHandoverStages__c,
                HandoverType__c
                FROM Handover__c WHERE Id = :handoverId LIMIT 1];
    }
    
    public List<Handover__c> getHandoverWithProjectAndUnit(Set<Id> handoverIds){
        return [SELECT Id, Name,HO_Agent_Assigned_User__c,Unit__r.Status__c,OwnerId,Is_Property_keys_given__c, Date__c, Project__r.RegisteredUnitTitleDeedFeeApt__c, Project__r.RegisteredUnitTitleDeedFeeVilla__c, Project__c, Project_Name__c,
             Project__r.MortgageUnitAdminFeeApt__c, Project__r.MortgageUnitAdminFeeVilla__c, Project__r.ResaleWithMortgageEvaluationFeeApt__c, Project__r.ResaleWithMortgageEvaluationFeeVilla__c,
             Project__r.MortgageUnitTitleDeedFeeApt__c, Project__r.MortgageUnitTitleDeedFeeVilla__c, Project__r.ResaleUnitADMFeeApt__c, Project__r.ResaleUnitADMFeeVilla__c, Customer_Availability_for_CHO__c,
             Project__r.ResaleUnitAdminFeeApt__c, Project__r.ResaleUnitAdminFeeVilla__c, Project__r.ResaleUnitEvaluationFeeApt__c, Project__r.ResaleUnitEvaluationFeeVilla__c,
             Project__r.ResaleWithMortgageADMFeeApt__c, Project__r.ResaleWithMortgageADMFeeVilla__c, Project__r.ResaleWithMortgageAdminFeeApt__c, Project__r.ResaleWithMortgageAdminFeeVilla__c,
             Project__r.NewSaleADMFeeApt__c, Project__r.NewSaleADMFeeVilla__c, Project__r.NewSaleAdminFeeApt__c, Project__r.NewSaleAdminFeeVilla__c, Project__r.NewSaleWithMortgageEvaluationFeeVilla__c,
             Project__r.NewSaleEvaluationFeeApt__c, Project__r.NewSaleEvaluationFeeVilla__c, Project__r.NewSaleWithMortgageADMFeeApt__c, Project__r.NewSaleWithMortgageADMFeeVilla__c,
             Project__r.NewSaleWithMortgageAdminFeeApt__c, Project__r.NewSaleWithMortgageAdminFeeVilla__c, Project__r.NewSaleWithMortgageEvaluationFeeApt__c,
             Sales_Order__r.NetAmount__c,Unit__r.UnitType__c,UnitCategory__c,Mortgage_Value__c, CongratulationOnHandoverEmailsent__c,PropertyHomeOrientationReport_Sent__c,KeyHandoverInvitationSent__c,
             PropertyHomeOrientationByBloom__c,PropertyHomeOrientationWOCustomer__c,HasCHODesnaggingemailsent__c,Lease_Type__c,Lease_Amount__c,Lease_End_Date__c,
             Account__c, Account__r.PersonEmail, Account__r.FirstName, Account__r.LastName, Unit__c, Unit__r.UnitNumber__c,Unit__r.HO_Agent__c, Handover_Phase__r.ExcludedHandoverStages__c,
             Sub_Status__c, Orientation_Appointment_Status__c, Is_Notice_of_Completion_Sent__c, Payment_Type__c, RecordTypeId, Is_Appointment_Booked__c, HandoverType__c, ProjectName__c
             FROM Handover__c WHERE Id IN :handoverIds];
    }
     public List<Handover__c> getHandoverByIds(Set<Id> handoverIds){
        return [SELECT Id,FinanceTeamAssingedUser__c,Handover_Phase__c,ProjectName__c,Unit_Plot_Number__c,Unit__r.Status__c,Name,CRM_Team_Assigned_User__c,CRM_Team_Assigned_User__r.Email,HO_Agent_Assigned_User__c,OwnerId,Is_Property_keys_given__c, Date__c, Project__r.RegisteredUnitTitleDeedFeeApt__c, Project__r.RegisteredUnitTitleDeedFeeVilla__c, Project__c, Project_Name__c,
             Project__r.MortgageUnitAdminFeeApt__c, Project__r.MortgageUnitAdminFeeVilla__c, Project__r.ResaleWithMortgageEvaluationFeeApt__c, Project__r.ResaleWithMortgageEvaluationFeeVilla__c,
             Project__r.MortgageUnitTitleDeedFeeApt__c, Project__r.MortgageUnitTitleDeedFeeVilla__c, Project__r.ResaleUnitADMFeeApt__c, Project__r.ResaleUnitADMFeeVilla__c,
             PropertyHomeOrientationReport_Sent__c,CongratulationOnHandoverEmailsent__c,KeyHandoverInvitationSent__c,PropertyHomeOrientationByBloom__c,PropertyHomeOrientationWOCustomer__c,
             HasCHODesnaggingemailsent__c,Lease_Type__c,Lease_Amount__c,Lease_End_Date__c, Sales_Order__c,
             Project__r.ResaleUnitAdminFeeApt__c, Project__r.ResaleUnitAdminFeeVilla__c, Project__r.ResaleUnitEvaluationFeeApt__c, Project__r.ResaleUnitEvaluationFeeVilla__c,
             Project__r.ResaleWithMortgageADMFeeApt__c, Project__r.ResaleWithMortgageADMFeeVilla__c, Project__r.ResaleWithMortgageAdminFeeApt__c, Project__r.ResaleWithMortgageAdminFeeVilla__c,
             Project__r.NewSaleADMFeeApt__c, Project__r.NewSaleADMFeeVilla__c, Project__r.NewSaleAdminFeeApt__c, Project__r.NewSaleAdminFeeVilla__c, Project__r.NewSaleWithMortgageEvaluationFeeVilla__c,
             Project__r.NewSaleEvaluationFeeApt__c, Project__r.NewSaleEvaluationFeeVilla__c, Project__r.NewSaleWithMortgageADMFeeApt__c, Project__r.NewSaleWithMortgageADMFeeVilla__c,
             Project__r.NewSaleWithMortgageAdminFeeApt__c, Project__r.NewSaleWithMortgageAdminFeeVilla__c, Project__r.NewSaleWithMortgageEvaluationFeeApt__c, Customer_Availability_for_CHO__c,
             Sales_Order__r.NetAmount__c,Unit__r.UnitType__c,UnitCategory__c,Mortgage_Value__c, ServiceCatalog__c, RecordTypeId, PendingWithDepartment__c, Previous_HO_Status__c,
             Account__c, Account__r.PersonEmail, Account__r.FirstName, Account__r.LastName, Unit__c, Unit__r.UnitNumber__c,Unit__r.HO_Agent__c, Sub_Status__c, Is_Manual__c,
             Orientation_Appointment_Status__c, Is_Notice_of_Completion_Sent__c, Payment_Type__c, Is_Appointment_Booked__c, Unit_Type__c, Handover_Phase__r.ExcludedHandoverStages__c, Handover_Phase__r.SkipHandoverCHOTasks__c,
             HandoverType__c
             FROM Handover__c WHERE Id IN :handoverIds];
    }
            
    public Map<Id, Handover__c> getHandoverWithSalesOrders(Set<Id> salesOrderIds) {
        return new Map<Id, Handover__c>([SELECT Id, Name, Sub_Status__c,Sales_Order__c FROM Handover__c WHERE Sales_Order__c IN :salesOrderIds AND Is_Property_keys_given__c = false]);
    }
    
    public List<Handover__c> getHandoversBasedOnProjectAndBuilding() {
        return [SELECT Id, Name, Unit__c, Unit__r.Name,Unit__r.Status__c, Unit__r.Unit_Status__c,Building_Phase__c, Building_Phase__r.Name, Project__c, 
                Project__r.Name, Customer_Email__c,CustomerEmail__c, Sales_Order__r.Name,CreatedDate, Owner_Name__c, Is_Orientation_Letter_Sent__c, 
                Sub_Status__c FROM Handover__c WHERE Unit_is_Ready__c = false AND Is_Orientation_Letter_Sent__c = false LIMIT 10000];
    }
    
    public List<Handover__c> getHandoversBasedOnBuilding(String buildingId) {
        return [SELECT Id, Name, Unit__c, Unit__r.Name,Unit__r.Status__c, Unit__r.Unit_Status__c,Building_Phase__c, Building_Phase__r.Name, Project__c, 
                Project__r.Name, Customer_Email__c,CustomerEmail__c, Sales_Order__r.Name,CreatedDate, Owner_Name__c, Is_Orientation_Letter_Sent__c, 
                Sub_Status__c FROM Handover__c WHERE Unit_is_Ready__c = false AND Building_Phase__c = :buildingId  AND Is_Orientation_Letter_Sent__c = false LIMIT 10000];
    }
    
     public List<Handover__c> getCHOHOByHandoverPhaseAndProject(String projectId,String handoverPhaseId) {
        
        return [SELECT Id, Name,Handover_Phase__c,ProjectbyFormula__c,Unit__r.Status__c,ProjectName__c,ProjectNameArabic__c,BuildingPhase__c, Unit__c, Unit__r.Name, Unit__r.Unit_Status__c,Building_Phase__c, Building_Phase__r.Name, Project__c, 
                Project__r.Name, Customer_Email__c, CustomerEmail__c,Sales_Order__r.Name,CreatedDate, Owner_Name__c, Is_Orientation_Letter_Sent__c, 
                Sub_Status__c FROM Handover__c WHERE Unit_is_Ready__c = false AND Handover_Phase__c = :handoverPhaseId  AND Is_Orientation_Letter_Sent__c = false AND  Project__c = :projectId LIMIT 10000];
    }    
 
    
    public List<Handover__c> getNOCHandoversBasedOnProjectAndBuilding() {
        return [SELECT Id, Name, Unit__c, Unit__r.Name, Unit__r.Unit_Status__c,Unit__r.Status__c,Building_Phase__c, Building_Phase__r.Name, Project__c, 
                Project__r.Name, Customer_Email__c,CustomerEmail__c, Sales_Order__r.Name,CreatedDate, Owner_Name__c, Is_Orientation_Letter_Sent__c, 
                Sub_Status__c FROM Handover__c WHERE Is_BCC_Announcement_Sent__c = TRUE AND Is_Notice_of_Completion_Sent__c = FALSE AND Sub_Status__c =: Constants.Handover_Sub_Status_CHO_DE_SNAGGING_COMPLETED
                LIMIT 10000];
    }
    
    public List<Handover__c> getNOCHandoversBasedOnBuilding(String buildingId) {
        return [SELECT Id, Name, Unit__c, Unit__r.Name, Unit__r.Unit_Status__c,Unit__r.Status__c,Building_Phase__c, Building_Phase__r.Name, Project__c, 
                Project__r.Name, Customer_Email__c,CustomerEmail__c, Sales_Order__r.Name,CreatedDate, Owner_Name__c, Is_Orientation_Letter_Sent__c, 
                Sub_Status__c FROM Handover__c WHERE Is_BCC_Announcement_Sent__c = TRUE AND Is_Notice_of_Completion_Sent__c = FALSE AND Sub_Status__c =: Constants.Handover_Sub_Status_CHO_DE_SNAGGING_COMPLETED
                AND Building_Phase__c = :buildingId LIMIT 10000];
    }
    public List<Handover__c> getNOCHandoversBasedOnProjectAndHandoverPhaseId(String projectId,String handoverPhaseId) {
        return [SELECT Id,ProjectbyFormula__c,Unit__r.Status__c,ProjectNameArabic__c, Name, Unit__c, Unit__r.Name, Unit__r.Unit_Status__c,Building_Phase__c,BuildingPhase__c, Building_Phase__r.Name, Project__c, 
                Project__r.Name, Customer_Email__c,CustomerEmail__c, Sales_Order__r.Name,CreatedDate, Owner_Name__c, Is_Orientation_Letter_Sent__c, 
                Sub_Status__c FROM Handover__c WHERE Is_BCC_Announcement_Sent__c = TRUE AND Is_Notice_of_Completion_Sent__c = FALSE AND Sub_Status__c =: Constants.Handover_Sub_Status_CHO_DE_SNAGGING_COMPLETED
                AND Handover_Phase__c = :handoverPhaseId AND Project__c = :projectId  LIMIT 10000];
    }
    
    
    public List<Handover__c> getNOCHandoversBasedOnProject(String projectId) {
        return [SELECT Id, Name, Unit__c, Unit__r.Name, Unit__r.Unit_Status__c,Unit__r.Status__c,Building_Phase__c, Building_Phase__r.Name, Project__c, 
                Project__r.Name, Customer_Email__c,CustomerEmail__c, Sales_Order__r.Name, CreatedDate, Owner_Name__c, Is_Orientation_Letter_Sent__c,Sub_Status__c FROM Handover__c 
                WHERE Is_BCC_Announcement_Sent__c = TRUE AND Is_Notice_of_Completion_Sent__c = FALSE AND Sub_Status__c =: Constants.Handover_Sub_Status_CHO_DE_SNAGGING_COMPLETED
                AND Project__c = :projectId LIMIT 10000];
    }
    
    public List<Handover__c> getHandoversBasedOnProject(String projectId) {
        return [SELECT Id, Name, Unit__c, Unit__r.Name, Unit__r.Unit_Status__c,Unit__r.Status__c,Building_Phase__c, Building_Phase__r.Name, Project__c, 
                Project__r.Name, Customer_Email__c,CustomerEmail__c, Sales_Order__r.Name, CreatedDate, Owner_Name__c, Is_Orientation_Letter_Sent__c,Sub_Status__c FROM Handover__c 
                WHERE Unit_is_Ready__c = false 
                AND Project__c = :projectId AND Is_Orientation_Letter_Sent__c = false LIMIT 10000];
    }
    public List<Handover__c> getNOCCHOHandoversBasedOnProjectAndHandoverPhaseId(String projectId,String handoverPhaseId) {
        return [SELECT Id,unit__r.DoorNumber__c,ProjectbyFormula__c,Sales_Order__c,Unit__r.Status__c,ProjectNameArabic__c, Name, Unit__c, Unit__r.Name, Unit__r.Unit_Status__c,Building_Phase__c,BuildingPhase__c, Building_Phase__r.Name, Project__c, 
                Project__r.Name, Customer_Email__c,CustomerEmail__c, Sales_Order__r.Name,CreatedDate, Owner_Name__c, Is_Orientation_Letter_Sent__c, 
                Sub_Status__c FROM Handover__c WHERE Is_Notice_of_Completion_Sent__c = FALSE AND HasDoorNumberEmailSent__c=false
                AND Handover_Phase__c = :handoverPhaseId AND (Is_BCC_Announcement_Sent__c = TRUE OR Handover_Phase__r.BCCRequired__c =False) AND Project__c = :projectId];
    }
    
    public List<Handover__c> getBCCWithHandoverPhaseAndProjectId(String projectId, String handoverPhaseId) {
        
        return [SELECT Id,Name,Unit__r.Name,Handover_Phase__c,Handover_Phase__r.BCCRequired__c, Status__c,Owner.Name, CreatedDate, Project__c,unit__r.DoorNumber__c,Unit__r.Status__c, Unit__c, Unit__r.Unit_Status__c,Building_Phase__c,BuildingPhase__c, Building_Phase__r.Name, 
                Project__r.Name, Customer_Email__c,CustomerEmail__c, Sales_Order__r.Name, Owner_Name__c, Is_Orientation_Letter_Sent__c, 
                Sub_Status__c From Handover__c WHERE Handover_Phase__c = :handoverPhaseId 
                AND Project__c = :projectId And  Is_BCC_Announcement_Sent__c =false AND Handover_Phase__r.BCCRequired__c =True];
    }
    
    public List<AggregateResult> getHandoversGroupByProject() {
        return [SELECT Project__c, Project__r.Name projectName  FROM Handover__c GROUP BY Project__c, Project__r.Name LIMIT 10000];
    }
    
    public List<AggregateResult> getHandoversGroupByBuilding() {
        return [SELECT Project__c, Building_Phase__c, Building_Phase__r.Name buildingName FROM Handover__c GROUP BY Project__c, Building_Phase__c, Building_Phase__r.Name 
                LIMIT 10000];
    }
    
    public List<Handover__c> insertHandovers(List<Handover__c> handoverList){
        if(handoverList != null && !handoverList.isEmpty()){
            insert handoverList;
        }
        return handoverList;
    }
    public Handover__c insertHandover(Handover__c handover){
        if(handover != null){
            handover = insertHandovers(new List<Handover__c>{handover})[0];
        }
        return handover;
    }
    
    
    public void updateHandovers(List<Handover__c> handoverList){
        if(handoverList != null && !handoverList.isEmpty()){
            update handoverList;
        }
    }
    
     public void updateHandover(Handover__c handover){
        if(handover != null){
            update handover;
        }
    }
   
     public List<Handover__c> getHandoversByUnitIds(Set<Id> unitIds) {
        return [SELECT Id, Name,Sales_Order__c,Unit__r.SAP_Unit_Number__c,Unit__r.Status__c,Unit__r.Project__c,Unit__r.BuildingSectionName__r.Project__c,Unit__r.Active_Sales_Order__r.Account__c, Unit__r.Active_Sales_Order__c, Sub_Status__c, Unit__c FROM Handover__c WHERE Unit__c IN :unitIds];
    }
    
     public List<Handover__c> getHandoversByUnitIdForResale(Set<Id> unitIds) {
        return [SELECT Id, Name,Sales_Order__c,Unit__r.SAP_Unit_Number__c,Unit__r.Status__c,Unit__r.Project__c,Unit__r.BuildingSectionName__r.Project__c,Unit__r.Active_Sales_Order__r.Account__c, Unit__r.Active_Sales_Order__c, Sub_Status__c, Unit__c FROM Handover__c WHERE Unit__c IN :unitIds and Is_Property_keys_given__c=:false];
    }
    
      public List<Handover__c> updateHandoversWithoutTrigger(List<Handover__c> handoverList){
        if(handoverList != NULL && !handoverList.isEmpty()){
            HandoverTriggerHandler.isTriggerDisabled = true;
            update handoverList;
            HandoverTriggerHandler.isTriggerDisabled = false;
        }
        return handoverList;
    }
    
    public List<Handover__c> geNoctHandoversByHandoverIds(set<id>recordIds) {
        return[
            SELECT Id, Name,ProjectbyFormula__c,Unit__r.Status__c,ProjectName__c,ProjectNameArabic__c,BuildingPhase__c, Unit__c,LocationName__c,BloomPhone__c,BloomEmail__c,HO_Agent_Assigned_User__c,NOC_Expiry_Date__c,Project__r.Handover_Community_Guidelines_English__c,Project__r.Handover_Community_Guidelines_Arabic__c, Unit__r.SAP_Unit_Number__c, Sub_Status__c, 
            Customer_Email__c,CustomerEmail__c, Customer_Name__c, Project__r.Name, 
            Account_Manager_Name__c, Home_Orientation_Invitation_Date__c, 
            Promise_to_Pay_Date__c, Account_Manager_Email__c, Drawloop_Next_1__c,
            Account_Manager_Phone__c, Project__c, Project__r.ProjectNameArabic__c, 
            Customer_Name_Arabic__c, CRM_Team_Assigned_User__r.Name_In_Arabic__c, 
            Project__r.Office_Location__c, Account_Manager_Name_Arabic__c, 
            Notice_of_Completion_Date__c, Settlement_Follow_Up_Date__c, 
            Sales_Order__r.Account__r.PersonMailingCountry, Sales_Order__r.Account__r.Phone, 
            Sales_Order__r.Account__r.MobileCountryCode__pc,
            Project_Name_Arabic__c,Project_Name__c,AccountManagerEmail__c,
            Location__c,Customer_Number__c,Bloom_Email__c,Bloom_Phone__c,
            Address__c, NOC_Date__c,SettlementFollowUpDate__c,
            HomeOrientationInvitationDate__c,HO_DD_MM_YYYY__c,Location_Name__c,Date__c,Unit_Code__c,Unit__r.NOCExpiryDate__c
            FROM Handover__c
            WHERE Id IN :recordIds AND Is_Notice_of_Completion_Sent__c = false 
            FOR UPDATE 
        ];
    }
    public List<Handover__c> geOrientationHandoversByHandoverIds(set<id>recordIds) {
        return[
            SELECT Id, Name,ProjectbyFormula__c,Unit__r.Status__c,ProjectName__c,ProjectNameArabic__c,BuildingPhase__c,LocationName__c,BloomPhone__c,BloomEmail__c,HO_Agent_Assigned_User__c, Unit__c, NOC_Expiry_Date__c, 
            Project__r.Handover_Community_Guidelines_English__c,
            Project__r.Handover_Community_Guidelines_Arabic__c,
            Unit__r.SAP_Unit_Number__c, Sub_Status__c,
            Customer_Email__c, CustomerEmail__c, Customer_Name__c, 
            Project__r.Name, Account_Manager_Name__c, 
            Home_Orientation_Invitation_Date__c, Promise_to_Pay_Date__c, 
            Account_Manager_Email__c, Drawloop_Next_1__c, Account_Manager_Phone__c, 
            Project__c, Project__r.ProjectNameArabic__c, Customer_Name_Arabic__c, 
            CRM_Team_Assigned_User__r.Name_In_Arabic__c, 
            Project__r.Office_Location__c, Account_Manager_Name_Arabic__c, 
            Notice_of_Completion_Date__c, Settlement_Follow_Up_Date__c, 
            Sales_Order__r.Account__r.PersonMailingCountry, 
            Sales_Order__r.Account__r.Phone, 
            Sales_Order__r.Account__r.MobileCountryCode__pc,
            Project_Name_Arabic__c, Project_Name__c, AccountManagerEmail__c,
            Location__c, Customer_Number__c, Bloom_Email__c, Bloom_Phone__c,
            Address__c, NOC_Date__c, SettlementFollowUpDate__c,
            HomeOrientationInvitationDate__c, HO_DD_MM_YYYY__c, 
            Location_Name__c, Date__c, Unit_Code__c
            FROM Handover__c
            WHERE Id IN :recordIds AND Is_Orientation_Letter_Sent__c=false
            
            FOR UPDATE
        ];
    }
     
     public List<Handover__c> getNOCHOByHandoverIds(set<id>recordIds) {
        return[
            SELECT Id,Englishformatteddate__c,Handover_Phase__r.AfterHONoticeSubstatus__c,Handover_Phase__r.DoorNumberClarificationrequired__c,Handover_Phase__r.NOCCHOEmailtemplateId__c,contact__c,unit__r.UnitNumber__c,
            Account__r.Name,Account__r.NameinArabic__c,
            Unit__r.ADMAddressingNumber__c,Name,Unit__r.Name,Unit_Plot_Number__c,
            Unit__r.DoorNumber__c,Purchase_Price__c,ProjectbyFormula__c,
            Unit__r.Status__c,ProjectName__c,ProjectNameArabic__c,BuildingPhase__c,
            LocationName__c,BloomPhone__c,BloomEmail__c,HO_Agent_Assigned_User__c,
            Unit__c, NOC_Expiry_Date__c, 
            Project__r.Handover_Community_Guidelines_English__c,
            Project__r.Handover_Community_Guidelines_Arabic__c,
            Unit__r.SAP_Unit_Number__c, Sub_Status__c,
            Customer_Email__c, CustomerEmail__c, Customer_Name__c, 
            Project__r.Name, Account_Manager_Name__c, 
            Home_Orientation_Invitation_Date__c, Promise_to_Pay_Date__c, 
            Account_Manager_Email__c, Drawloop_Next_1__c, Account_Manager_Phone__c, 
            Project__c, Project__r.ProjectNameArabic__c, Customer_Name_Arabic__c, 
            CRM_Team_Assigned_User__r.Name_In_Arabic__c, 
            Project__r.Office_Location__c, Account_Manager_Name_Arabic__c, 
            Notice_of_Completion_Date__c, Settlement_Follow_Up_Date__c, 
            Sales_Order__r.Account__r.PersonMailingCountry, 
            Sales_Order__r.Account__r.Phone, 
            Sales_Order__r.Account__r.MobileCountryCode__pc,
            Project_Name_Arabic__c, Project_Name__c, AccountManagerEmail__c,
            Location__c, Customer_Number__c, Bloom_Email__c, Bloom_Phone__c,
            Address__c, NOC_Date__c, SettlementFollowUpDate__c,
            HomeOrientationInvitationDate__c, HO_DD_MM_YYYY__c, 
            Location_Name__c, Date__c, Unit_Code__c
            FROM Handover__c
            WHERE Id IN :recordIds AND Is_Notice_of_Completion_Sent__c = FALSE AND HasDoorNumberEmailSent__c=false
            FOR UPDATE
        ];
    }
    
   
    public List<InstallmentLines__c> getSOInstallmentPendingAmt(Set<Id> salesOrderIds) {
        return [
            SELECT Id, Type__c, SalesOrder__c, Unit_Number__c, InstallmentPercentage__c, PendingAmount__c 
            FROM InstallmentLines__c 
            WHERE SalesOrder__r.Status__c NOT IN ('Book Cancelled','Cancelled') 
            AND Type__c = 'Handover' 
            AND SalesOrder__c IN :salesOrderIds
        ];
    }
    
    public List<Handover__c> getHandoverRecordsByUnitId(Set<Id> recordIds) {
        return [
            SELECT Id, Name,Englishformatteddate__c,Unit__r.DoorNumber__c,Contact__c,Unit__r.UnitNumber__c,Unit__r.Name,Account__r.Name,Account__r.NameinArabic__c,Unit_Plot_Number__c,Purchase_Price__c,Handover_Phase__r.BCCEmailTemplateId__c,ProjectbyFormula__c,Unit__r.Status__c,ProjectNameArabic__c,ProjectName__c,BuildingPhase__c, Unit__c,LocationName__c,BloomPhone__c,BloomEmail__c,NOC_Expiry_Date__c,Project__r.Handover_Community_Guidelines_English__c,Project__r.Handover_Community_Guidelines_Arabic__c, Unit__r.SAP_Unit_Number__c, Sub_Status__c, 
            Customer_Email__c,CustomerEmail__c, Customer_Name__c, Project__r.Name, 
            Account_Manager_Name__c, Home_Orientation_Invitation_Date__c, 
            Promise_to_Pay_Date__c, Account_Manager_Email__c, Drawloop_Next_1__c,
            Account_Manager_Phone__c, Project__c, Project__r.ProjectNameArabic__c, 
            Customer_Name_Arabic__c, CRM_Team_Assigned_User__r.Name_In_Arabic__c, 
            Project__r.Office_Location__c, Account_Manager_Name_Arabic__c, 
            Notice_of_Completion_Date__c, Settlement_Follow_Up_Date__c, 
            Sales_Order__r.Account__r.PersonMailingCountry, Sales_Order__r.Account__r.Phone, 
            Sales_Order__r.Account__r.MobileCountryCode__pc,
            Project_Name_Arabic__c,Project_Name__c,AccountManagerEmail__c,
            Location__c,Customer_Number__c,Bloom_Email__c,Bloom_Phone__c,
            Address__c, NOC_Date__c,SettlementFollowUpDate__c,
            HomeOrientationInvitationDate__c,HO_DD_MM_YYYY__c,Location_Name__c,Date__c,Unit_Code__c,Unit__r.UnitType__c
            FROM Handover__c WHERE Id IN :recordIds
        ];
    }

    public Handover__c insertHandoverRecord(Handover__c handoverRec){
        if(handoverRec != null){
            insert handoverRec;
        }
        return handoverRec;
    }
    
    public void updateHandoverWithoutTrigger(List<Handover__c> handoverList){
        if(handoverList != NULL && !handoverList.isEmpty()){
            HandoverTriggerHandler.isTriggerDisabled = true;
            update handoverList;
            HandoverTriggerHandler.isTriggerDisabled = false;
        }
        
    } 
    
    public Map<Id, List<Handover__History>> getLatestSubStatusHistoryBulk(Set<Id> hoIds) {
        Map<Id, List<Handover__History>> historyMap = new Map<Id, List<Handover__History>>();
        
        for (Handover__History hh : [
            SELECT ParentId, CreatedDate, Field, NewValue 
            FROM Handover__History 
            WHERE ParentId IN :hoIds 
            AND Field = 'Sub_Status__c' 
            ORDER BY CreatedDate DESC
        ]) {
            if (!historyMap.containsKey(hh.ParentId)) {
                historyMap.put(hh.ParentId, new List<Handover__History>());
            }
            historyMap.get(hh.ParentId).add(hh);
        }
        
        return historyMap;
    }
}