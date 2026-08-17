@isTest
public class TaskNonContactableTest {
    @isTest static void TaskNonContactableTestMethod(){
        Task testTask=new Task(
        	Status='Open'
        );
        insert testTask;
        
        TaskNonContactable.rejectReq(testTask.id,'Test Reason');
        TaskNonContactable.requestDetail(testTask.id);
    }
}