@isTest
public class TaskControllerTest {

    @isTest
    static void testCalculateSlaPercentage() {
        BusinessHours bh = [
            SELECT Id
            FROM BusinessHours
            LIMIT 1
        ];
        
        Task tsk = new Task();
        tsk.Subject = 'SLA Test Task';
        tsk.Status = 'Not Started';

        tsk.Priority = 'Normal';

        tsk.AssignedDateTime__c =
            System.now().addHours(-1);

        //tsk.CompletedDateTime = System.now();

        tsk.SLAHours__c = 4;

        tsk.BusinessHours__c = bh.Id;

        insert tsk;

       
        Test.startTest();

        Decimal result =
            TaskController.calculateSlaPercentage(
                tsk.Id
            );

        Test.stopTest();

      
        System.assertNotEquals(
            null,
            result
        );

        System.assert(
            result >= 0
        );

        System.assert(
            result <= 100
        );
    }

    @isTest
    static void testCalculateSlaPercentage_NoSLAHours() {

        Task tsk = new Task();

        tsk.Subject = 'No SLA Hours';

        tsk.Status = 'Not Started';

        tsk.Priority = 'Normal';

        tsk.AssignedDateTime__c =
            System.now();

        insert tsk;

        // =========================================
        // Test
        // =========================================
        Test.startTest();

        Decimal result =
            TaskController.calculateSlaPercentage(
                tsk.Id
            );

        Test.stopTest();

        // =========================================
        // Assert
        // =========================================
        System.assertEquals(
            0,
            result
        );
    }
}