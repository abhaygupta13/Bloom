/*****************************************************************************************
Class       : LeadSLAReshuffleBatch
Author      : Prashant SAHU 09/06/2026
Description : Automatic Lead Reshuffle on SLA Breach
*****************************************************************************************/
public class LeadSLAReshuffleBatch implements Database.Batchable<SObject>, Schedulable {
    
    private static final String MTD_LEAD_PAST_HOURS_VALUE {
        get { return 'LeadReshuffleHours'; }
    }
    
    private static final String MTD_SM_BUSINESSHOURS_ID {
        get { return 'SMBusinessHoursId'; }
    }
    
    private static final String MTD_LEAD_RESHUFFLE_CREATED_DATE {
        get { return 'LeadReshuffleCreatedDate'; }
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        
        System.debug('LeadSLAReshuffleBatch Started ');
        
        MetadataService objMetadataService = MetadataService.getInstance();
        
       // Date leadReshuffleCreatedDate =objMetadataService.getAppSettingDateValue(MTD_LEAD_RESHUFFLE_CREATED_DATE);
        Date leadReshuffleCreatedDate = Date.newInstance(2026, 1, 1);
        
        /*return Database.getQueryLocator([ SELECT Id, LeadManagerAssignedDate__c, LeadManagerStatus__c, Status, LeadTeam__c, CreatedById, OwnerId, ReshuffleCount__c FROM Lead 
                                         WHERE Status NOT IN ('Closed','Converted') AND LeadManagerStatus__c = 'New' AND LeadManagerAssignedDate__c != NULL AND IsConverted = FALSE 
                                         AND IsDraftLead__c = FALSE 
                                         AND LeadTeam__c = 'Sales' AND CreatedDate >= :leadReshuffleCreatedDate ]);*/
        
       return Database.getQueryLocator([ SELECT Id, LeadManagerAssignedDate__c, LeadManagerStatus__c, Status, LeadTeam__c, CreatedById, OwnerId, ReshuffleCount__c FROM Lead 
                                        WHERE Id = '00QFV007BfwUFoK2IW']);    //00QFV007AT3ve3Q2YQ
        
    }
    
    public void execute(Database.BatchableContext bc, List<Lead> scope) {
        System.debug('Scope Size : ' + scope.size());
        MetadataService objMetadataService = MetadataService.getInstance();
        LeadService objLeadService =LeadService.getInstance();
        BusinessHoursService objBHService = BusinessHoursService.getInstance();
        
       // Integer leadPastHours = objMetadataService.getAppSettingNumberValue(MTD_LEAD_PAST_HOURS_VALUE);
        Id smBusinessHoursId = objMetadataService.getAppSettingTextValue(MTD_SM_BUSINESSHOURS_ID);
        
        Integer leadPastHours = 1; // Test only
		//Id smBusinessHoursId = '01mFV000C6RUN7g'; // Your Business Hours Id 
       // Id smBusinessHoursId = '01mJ7000000sYyJIAU';
        
        System.debug('Lead Reshuffle Hours :---- ' + leadPastHours);
        System.debug('Business Hours Id :---- ' + smBusinessHoursId);
        
        Set<Id> reshuffleLeadIds = new Set<Id>();
        
        Set<Id> headOfSalesLeadIds = new Set<Id>();
        
        for (Lead objLead : scope) {
            
           Boolean exceeded = objBHService.hasExceededNoOfHour(smBusinessHoursId, objLead.LeadManagerAssignedDate__c, leadPastHours);

            System.debug('Exceeded SLA = ' + exceeded);
            System.debug('CreatedBy = ' + objLead.CreatedById);
            System.debug('Owner = ' + objLead.OwnerId);
            System.debug('Lead Id = ' + objLead.Id);
            System.debug('CreatedBy != Owner = ' + (objLead.CreatedById != objLead.OwnerId));
            
            if (objBHService.hasExceededNoOfHour(smBusinessHoursId,objLead.LeadManagerAssignedDate__c,leadPastHours)&& objLead.CreatedById != objLead.OwnerId) {
                
                Integer reshuffleCount = objLead.ReshuffleCount__c == null ? 0 : Integer.valueOf(objLead.ReshuffleCount__c);
                
                if (reshuffleCount < 2) {
                    reshuffleLeadIds.add(objLead.Id);
                    System.debug('Lead Added For Reshuffle : ' + objLead.Id);
                    
                } else {
                    
                    headOfSalesLeadIds.add(objLead.Id);
                    System.debug('Lead Sent To Head Of Sales : ' + objLead.Id);
                }
            }
        }
        
        System.debug('Reshuffle Lead Count :----- ' + reshuffleLeadIds.size());
        System.debug('Reshuffle Lead Ids :------ ' + reshuffleLeadIds);
        
        if (!reshuffleLeadIds.isEmpty()) {
            
            List<Lead> leadUpdateList = AssignmentRuleHandler.salesLeadReshuffle(reshuffleLeadIds);
            
            System.debug( 'Returned Lead Count From salesLeadReshuffle :---- ' + leadUpdateList.size() );
            System.debug( 'Leads To Update : ' + JSON.serializePretty(leadUpdateList) );
            
            for(Lead ld : leadUpdateList){
                
                Integer reshuffleCount = ld.ReshuffleCount__c == null ? 0 : Integer.valueOf(ld.ReshuffleCount__c);
                ld.ReshuffleCount__c = reshuffleCount + 1;
            }
            
            if (!leadUpdateList.isEmpty()) {
                objLeadService.updateLeadsWithoutDuplicateRule(leadUpdateList);
                System.debug( 'Successfully Updated Leads :---- ' + leadUpdateList.size() );
            }
        }
        
        if (!headOfSalesLeadIds.isEmpty()) {
            User headOfSales = UserService.getInstance().getHeadOfSalesUser();
            
            if (headOfSales != null) {
                List<Lead> hosLeadList = new List<Lead>();
                for (Lead ld : scope) {
                    
                    if (headOfSalesLeadIds.contains(ld.Id)) {
                        
                        ld.OwnerId = headOfSales.Id;
                        ld.ReshuffleCount__c = 3;
                        hosLeadList.add(ld);
                    }
                }
                
                if (!hosLeadList.isEmpty()) {
                    objLeadService.updateLeadsWithoutDuplicateRule(hosLeadList);
                }
            }
        }
    }
    public void finish(Database.BatchableContext bc) {
        System.debug('LeadSLAReshuffleBatch Finished');
    }
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new LeadSLAReshuffleBatch(), 200);
    }
    
}