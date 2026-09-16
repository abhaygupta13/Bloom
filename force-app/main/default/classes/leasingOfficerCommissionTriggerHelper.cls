public class leasingOfficerCommissionTriggerHelper {
    public static void beforeFieldUpdates(List<LeasingOfficerCommission__c> newList , Map<id,LeasingOfficerCommission__c> oldMap){
        List<Schema.FieldSetMember> sapFieldSetFields = Schema.SObjectType.LeasingOfficerCommission__c.fieldSets.getMap().get('SAP_Integration_Fields').getFields();
        Set<Id> leasingOrderIdsAPI = new Set<Id>();
        
        for (LeasingOfficerCommission__c leasingOfficerCom : newList) {
            leasingOrderIdsAPI.add(leasingOfficerCom.LeasingOrder__c);
        }
        
        LeasingOrderService loService = LeasingOrderService.getInstance();
        Map<Id, LeasingOrder__c> leasingOrderMap =
            loService.getLeasingOrdersWithSAPContractId(leasingOrderIdsAPI);
        
        for(LeasingOfficerCommission__c leasingOfficerCommission  : newList ){
            LeasingOrder__c leasingOrder = leasingOrderMap.get(leasingOfficerCommission.LeasingOrder__c);
            if (leasingOrder != null &&
                !String.isBlank(leasingOrder.LeasingSAPContractId__c) &&
                String.isBlank(leasingOfficerCommission.RefDocno__c)) {
                    if(oldMap != null){
                        for (FieldSetMember member : sapFieldSetFields){
                            String field = member.getFieldPath();
                            if (leasingOfficerCommission.get(field) != oldMap.get(leasingOfficerCommission.Id).get(field)){
                                leasingOfficerCommission.SendToSAP__c = true;
                                break;
                            }
                        }
                        if(!oldMap.get(leasingOfficerCommission.Id).SendToSAP__c && leasingOfficerCommission.SendToSAP__c){
                            leasingOfficerCommission.IntegrationStatus__c = 'In Progress';
                        }
                    }
                }
        }
    }
    
    public static void afterFieldUpdates(List<LeasingOfficerCommission__c> newList , Map<id,LeasingOfficerCommission__c> oldMap){        
        Set<Id> leasingOfficerCommissionIds = new Set<Id>();
        
        for(LeasingOfficerCommission__c leasingOfficerCommission : newList){
            
            if(oldMap != null){
                
                if (!oldMap.get(leasingOfficerCommission.Id).SendToSAP__c && leasingOfficerCommission.SendToSAP__c) {
                    leasingOfficerCommissionIds.add(leasingOfficerCommission.Id);
                }
            }
        }
        
        if (!leasingOfficerCommissionIds.isEmpty()) {
            LeasingOfficerCommissionService leasingOfficerCommissionService = LeasingOfficerCommissionService.getInstance();
            List<IntegrationRecord__c> integrationRecordsToInsert = new List<IntegrationRecord__c>();
            List<LeasingOfficerCommission__c> leasingOfficerCommissionList = leasingOfficerCommissionService.getLeasingOfficerCommissionByIds(leasingOfficerCommissionIds);
            for(LeasingOfficerCommission__c leasingOfficerCommission : leasingOfficerCommissionList ){
                integrationRecordsToInsert.add(leasingOfficerCommissionService.getLeasingOfficerCommissionRecords(leasingOfficerCommission));
            }
            IntegrationRecordService integService = IntegrationRecordService.getInstance();
            integService.insertIntegrationRecords(integrationRecordsToInsert);
        }
        
    }
    
}