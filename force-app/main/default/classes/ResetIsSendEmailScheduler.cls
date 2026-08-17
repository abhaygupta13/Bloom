//Rushikesh

global class ResetIsSendEmailScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        BrokerUnitAssignmentHelper.resetIsSendMail();
    }
}