import { LightningElement, api } from 'lwc';
import performRecalculation from '@salesforce/apex/RecalculatePaymentsController.performRecalculation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class RecalculatePaymentsAction extends LightningElement {
@api recordId;


connectedCallback() {
this.sleep(1000).then(() => {
    this.runAction();
});
}

sleep(ms) {
return new Promise((resolve) => setTimeout(resolve, ms));
}

runAction() {
    console.log('hi');
console.log('Record ID passed:', this.recordId); // For debugging
    performRecalculation({ caseId: this.recordId })
        .then(result => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: result,
                    variant: 'success'
                })
            );
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body?.message || 'Unknown error',
                    variant: 'error'
                })
            );
        })
        .finally(() => {
            this.dispatchEvent(new CloseActionScreenEvent());
        });
}
}