import { LightningElement, track, api, wire } from 'lwc';
import BillInstallmentSendReminder from '@salesforce/apex/BillInstallmentSendReminderMilestone.BillInstallmentSendReminder';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class BillInstallmentReminder extends LightningElement {
    @api recordId;
    @track isLoading = false;

    connectedCallback() {

    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {

        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
            BillInstallmentSendReminder({ req: this.recordId })
                .then(result => {
                    if (result == null) {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: 'You Can Not Proceed At This Status',
                                variant: 'error'
                            })
                        );
                        this.dispatchEvent(new CloseActionScreenEvent());
                    } else if (result == 'Success') {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'Milestone Has Been Reached send reminders.',
                                variant: 'Success'
                            })
                        );
                        this.dispatchEvent(new CloseActionScreenEvent());

                    }
                })
                .catch(error => {
                    this.error = error;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: error.message,
                            variant: 'error'
                        })
                    );

                })
            this.dispatchEvent(new CloseActionScreenEvent());
        }

    }


}