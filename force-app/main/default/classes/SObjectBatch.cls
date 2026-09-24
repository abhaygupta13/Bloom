/*
*********************************************************
Apex Class Name    : SobjectBatch
Created Date       : Sept 21, 2026
@description       : This class handles record retrieval and DML operations.
Modification Log   :
Ver   Date         : Author                               Modification
1.0   21-09-2026   : Abhay Gupta                          Created framework class for Batch classes to inherit
*********************************************************
*/
public virtual class SobjectBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {

    protected String query;
    protected Map<SObjectField, Object> fieldValueMap;

    protected SobjectBatch() {

    }

    public SobjectBatch(String query, Map<SObjectField, Object> fieldValueMap) {
        this.query = query;
        this.fieldValueMap = fieldValueMap;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<sObject> records) {
        this.performAction(records, bc);
    }

    public void finish(Database.BatchableContext param1) {
        this.performFinish(param1);
    }

    public virtual void performAction(List<sObject> records, Database.BatchableContext bc) {
        for (Sobject record : records) {
            for(SObjectField field: fieldValueMap.keySet()) {
                record.put(field, fieldValueMap.get(field));
            }
        }
        update records;
    }

    public virtual void performFinish(Database.BatchableContext param1) {
    }
}