public class DBRTriggerHelper {
    public static void updateLastDBRAssessmentDate(List<DBR__c> records) {
		LeadService objLeadService = LeadService.getInstance();
        
        Set<Id> leadIds = new Set<Id>();
        for (DBR__c dbr : records) {
            if (dbr.Lead__c != null) {
                leadIds.add(dbr.Lead__c);
            }
        }
        if (leadIds.isEmpty()) {
            return;
        }

        Map<Id, Date> latestAssessmentDateMap = new Map<Id, Date>();
        for (AggregateResult ar : [ SELECT Lead__c leadId, MAX(CreatedDate) latestDate FROM DBR__c WHERE Lead__c IN :leadIds GROUP BY Lead__c]) {
            latestAssessmentDateMap.put( (Id) ar.get('leadId'),  ((Datetime) ar.get('latestDate')).date());
        }

        List<Lead> leadsToUpdate = new List<Lead>();
        for (Id leadId : leadIds) {
            leadsToUpdate.add(new Lead(  Id = leadId, LastDBRAssessmentDate__c = latestAssessmentDateMap.get(leadId) ));
        }
		objLeadService.updateLeadsWithoutTrigger(leadsToUpdate);
    }
}