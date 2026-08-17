public class ActionItemsService {
    
    private static ActionItemsService instance;
     
     public ActionItemsService() {
         
     }
     
    public static ActionItemsService getInstance() { 
         if(instance == null) {
             instance = new ActionItemsService();
         }
         return instance;
     }
    
    public List<Action_Items__c> getActionItemsRelatedToServiceCatalog(set<Id> catalogIds, String actionType){
        
		String baseQuery = 'SELECT Service_Catalog__c, ' +
                   '(SELECT Project__c, EmailTemplateName__c, EmailRecipients__c, Send_Customer__c, Status__c, emailCCAddresses__c, ' +
                   'Task_Rule_Criteria__c, Task_Rule_Criteria__r.Rule_Criteria__c,Template__c,Title__c ' +
                   'FROM Task_Action__r) ' +
                   'FROM Action_Items__c ' +
                   'WHERE Service_Catalog__c IN :catalogIds';

        if (String.isNotBlank(actionType)) {
            baseQuery += ' AND Service__r.Name = :actionType';
        }
        
        return  Database.query(baseQuery);
    }

}