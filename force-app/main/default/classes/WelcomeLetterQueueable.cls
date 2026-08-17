public class WelcomeLetterQueueable implements Queueable, Database.AllowsCallouts {

    private Set<Id> leasingOrderIds;

    public WelcomeLetterQueueable(Set<Id> leasingOrderIds) {
        this.leasingOrderIds = leasingOrderIds;
    }

    public void execute(QueueableContext context) {

        for (Id leasingOrderId : leasingOrderIds) {
            try {
                WelcomeLetterController.generateWelcomeLetter(leasingOrderId);
            } catch (Exception ex) {
                System.debug(
                    'Error generating Welcome Letter for Leasing Order ' +
                    leasingOrderId +
                    ': ' +
                    ex.getMessage()
                );
            }
        }
    }
}