import { LightningElement, api } from 'lwc';
import createSAWhenCustomerAvailable from '@salesforce/apex/ServiceAppointmentController.createSAWhenCustomerAvailable';

export default class CreateServiceAppointmentAction extends LightningElement {
    message = 'Processing...';
    _recordId;
    hasExecuted = false;

    @api 
    set recordId(value) {
        this._recordId = value;
        
        if (this._recordId && !this.hasExecuted) {
            this.hasExecuted = true;
            this.executeApex();
        }
    }

    get recordId() {
        return this._recordId;
    }

    executeApex() {
        createSAWhenCustomerAvailable({ recordId: this.recordId }).then((result) => {
            console.log(result);
            if(result == 'SA_CREATED') {
                this.message = 'A New Service Appointment has been created successfully!';
            } else if(result == 'SA_ALREADY_PRESENT') {
                this.message = 'The appointment has been created already.';
            }
            
        }).catch(error => {
            console.log('Hi '+ error.body);
            this.message = error.body ? error.body.message : 'An unknown error occurred.';

        });
    }
}