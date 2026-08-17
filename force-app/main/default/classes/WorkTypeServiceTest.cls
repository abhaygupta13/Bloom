@isTest
public class WorkTypeServiceTest {
    @isTest
    static void setupTestData() {
        WorkType testWorkType = new WorkType(Name = 'TestWorkType', EstimatedDuration = 33);
        insert testWorkType;
        
        Test.startTest();
        WorkType result = WorkTypeService.getWorkTypeRecord('TestWorkType');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'The method should return a WorkType record.');
        System.assertEquals('TestWorkType', result.Name, 'The WorkType name should match the input.');
        
        WorkType nullResult = WorkTypeService.getWorkTypeRecord('');
        System.assertEquals(null, nullResult, 'The method should return null for a blank name.');
    }
    
}