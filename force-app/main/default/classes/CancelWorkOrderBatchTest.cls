@IsTest
public class CancelWorkOrderBatchTest {
    @IsTest
    static void CancelWorkOrderBatchTestMethod() {
        
        // Create an Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Create a Unit
        Unit__c unt = new Unit__c(
            Name = 'Test Unit',
            Location__Latitude__s = 22.254653,
            Location__Longitude__s = 98.232564,
            Is_Property_keys_given__c = true
        );
        insert unt;
        
        // Create a WorkOrder with 'Customer not available' and no ServiceAppointment in the last 48 hours
        WorkOrder wo1 = new WorkOrder(
            Subject = 'Test Work Order 1',
            Status = 'Scheduled',
            Unit__c = unt.Id,
            Requester_Email__c = 'alt.jm-eef16gn@yopmail.com',
            AccountId = acc.Id,
            Cancel_Time__c = DateTime.now().addDays(-3),
            hasappointmentcanceled__c = true,
            Check_In_Time__c = DateTime.now().addDays(-3)
        );
        insert wo1;
          List<ServiceAppointment> sa = new List<ServiceAppointment>([Select Id from ServiceAppointment]);
        delete sa;
        // Create a related Service Appointment
        ServiceAppointment saRecent = new ServiceAppointment(
            ParentRecordId = wo1.Id,
            Status = 'Canceled'
        );
        insert saRecent;
       System.debug('appointment'+[Select id,ParentRecordId,status From ServiceAppointment]);
        Test.startTest();        
            // Execute the batch or schedulable class
           Database.executeBatch(new CancelWorkOrderBatch());
           CancelWorkOrderScheduler scheduler = new CancelWorkOrderScheduler();
        scheduler.execute(null);
        Test.stopTest();
    }
}