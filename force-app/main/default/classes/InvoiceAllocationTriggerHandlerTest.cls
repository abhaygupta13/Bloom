@isTest
public class InvoiceAllocationTriggerHandlerTest {
 @isTest static void test_handler_interface_hooks_are_safe_noops() {
        InvoiceAllocationTriggerHandler handler = new InvoiceAllocationTriggerHandler();
        List<sObject> emptyList = new List<sObject>();
        Map<Id, sObject> emptyMap = new Map<Id, sObject>();
        Boolean originalFlag = InvoiceAllocationTriggerHandler.isTriggerDisabled;

        Test.startTest();
        handler.beforeInsert(emptyList);
        handler.beforeUpdate(emptyList, emptyMap, emptyList, emptyMap);
        handler.beforeDelete(emptyList, emptyMap);
        handler.afterUpdate(emptyList, emptyMap, emptyList, emptyMap);
        handler.afterDelete(emptyList, emptyMap);
        handler.afterUnDelete(emptyList, emptyMap);
        Boolean disabledBefore = handler.isDisabled();
        InvoiceAllocationTriggerHandler.isTriggerDisabled = true;
        Boolean disabledAfter = handler.isDisabled();
        Test.stopTest();

        InvoiceAllocationTriggerHandler.isTriggerDisabled = originalFlag;
        System.assertEquals(false, disabledBefore, 'Handler should report enabled by default');
        System.assertEquals(true, disabledAfter, 'Handler should reflect static disabled flag');
    }
}